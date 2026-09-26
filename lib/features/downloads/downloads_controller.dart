import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../engine/download_choice.dart';
import '../../engine/downloader.dart';
import '../../engine/media_info.dart';

/// Every download, newest first.
final downloadsProvider = StreamProvider<List<Download>>(
  (ref) => ref.watch(databaseProvider).watchAll(),
);

/// Number of downloads still in progress (for the tab badge).
final activeCountProvider = Provider<int>((ref) {
  final list = ref.watch(downloadsProvider).value ?? const [];
  return list.where((d) => DownloadStatus.active.contains(d.status)).length;
});

/// Live progress per task. Kept in memory: it changes several times a second.
class LiveProgress extends Notifier<Map<String, TaskEvent>> {
  @override
  Map<String, TaskEvent> build() => const {};

  void put(TaskEvent e) => state = {...state, e.taskId: e};

  void drop(String id) {
    if (!state.containsKey(id)) return;
    state = {...state}..remove(id);
  }
}

final liveProgressProvider =
    NotifierProvider<LiveProgress, Map<String, TaskEvent>>(LiveProgress.new);

/// Starts, pauses, resumes and records downloads; keeps the database in step
/// with the native worker.
class DownloadsController {
  DownloadsController(this._ref) {
    _sub = _downloader.events.listen(_onEvent, onError: (_) {});
    _reconcile();
  }

  final Ref _ref;

  /// Tasks started in this app session; they are tracked live, not caught up.
  final _startedHere = <String>{};
  late final StreamSubscription<TaskEvent> _sub;
  final _markedRunning = <String>{};

  AppDatabase get _db => _ref.read(databaseProvider);
  Downloader get _downloader => _ref.read(downloaderProvider);
  LiveProgress get _live => _ref.read(liveProgressProvider.notifier);

  Future<void> start({
    required MediaInfo info,
    required String url,
    required DownloadChoice choice,
  }) async {
    final id = Downloader.newTaskId();
    _startedHere.add(id);
    await _db.insertDownload(
      DownloadsCompanion.insert(
        id: id,
        url: url,
        title: info.title,
        site: info.site,
        thumbnail: Value(info.thumbnail),
        durationSec: Value(info.duration?.inSeconds),
        kind: choice.kind.name,
        quality: choice.label,
        selector: choice.selector,
        extraArgs: Value(choice.extraArgs.join('\n')),
        parts: Value(choice.selector.contains('+') ? 2 : 1),
        status: DownloadStatus.waiting,
        sizeBytes: Value(choice.sizeBytes),
        createdAt: DateTime.now(),
      ),
    );
    await _enqueue(id);
  }

  Future<void> pause(String id) async {
    final last = _ref.read(liveProgressProvider)[id]?.percent;
    await _downloader.pause(id);
    await _db.patch(
      id,
      DownloadsCompanion(
        status: const Value(DownloadStatus.paused),
        percent: last == null ? const Value.absent() : Value(last),
      ),
    );
    _markedRunning.remove(id);
    _live.drop(id);
  }

  /// Resumes a paused download or retries a failed one.
  Future<void> resume(String id) async {
    _startedHere.add(id);
    await _db.patch(
      id,
      const DownloadsCompanion(
        status: Value(DownloadStatus.waiting),
        error: Value(null),
      ),
    );
    await _enqueue(id);
  }

  Future<void> cancel(String id) async {
    await _downloader.cancel(id);
    await _db.remove(id);
    _markedRunning.remove(id);
    _live.drop(id);
  }

  /// Removes a finished or failed entry from the list (the file stays).
  Future<void> forget(String id) => _db.remove(id);

  Future<void> _enqueue(String id) async {
    final row = await _db.byId(id);
    if (row == null) return;
    try {
      await _downloader.enqueue(
        taskId: id,
        url: row.url,
        title: row.title,
        selector: row.selector,
        args: row.extraArgs.isEmpty ? const [] : row.extraArgs.split('\n'),
        kind: row.kind,
        parts: row.parts,
      );
    } catch (e) {
      await _fail(id, '$e');
    }
  }

  Future<void> _onEvent(TaskEvent e) async {
    switch (e.status) {
      case TaskStatus.waiting || TaskStatus.running:
        _live.put(e);
        if (e.status == TaskStatus.running && _markedRunning.add(e.taskId)) {
          await _db.patch(
            e.taskId,
            const DownloadsCompanion(status: Value(DownloadStatus.running)),
          );
        }
      case TaskStatus.paused:
        _markedRunning.remove(e.taskId);
        _live.drop(e.taskId);
      case TaskStatus.cancelled:
        _markedRunning.remove(e.taskId);
        _live.drop(e.taskId);
        final row = await _db.byId(e.taskId);
        if (row != null && row.status != DownloadStatus.paused) {
          await _db.remove(e.taskId);
        }
      case TaskStatus.done:
        await _finish(e);
      case TaskStatus.failed:
        await _fail(e.taskId, e.error ?? 'Download failed');
    }
  }

  Future<void> _finish(TaskEvent e, {bool live = true}) async {
    _markedRunning.remove(e.taskId);
    _live.drop(e.taskId);
    if (live) unawaited(HapticFeedback.lightImpact());
    await _db.patch(
      e.taskId,
      DownloadsCompanion(
        status: const Value(DownloadStatus.done),
        percent: const Value(100),
        uri: Value(e.uri),
        filePath: Value(e.path),
        mime: Value(e.mime),
        sizeBytes: e.size == null ? const Value.absent() : Value(e.size),
        finishedAt: Value(DateTime.now()),
        error: const Value(null),
      ),
    );
  }

  Future<void> _fail(String id, String error) async {
    _markedRunning.remove(id);
    _live.drop(id);
    await _db.patch(
      id,
      DownloadsCompanion(
        status: const Value(DownloadStatus.failed),
        error: Value(error),
        finishedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Catches up on tasks that finished while the app was closed.
  Future<void> _reconcile() async {
    final List<TaskEvent> states;
    try {
      states = await _downloader.taskStates();
    } catch (_) {
      return;
    }
    final byId = {for (final s in states) s.taskId: s};
    for (final row in await _db.unfinished()) {
      if (_startedHere.contains(row.id)) continue;
      final s = byId[row.id];
      switch (s?.status) {
        case TaskStatus.done:
          await _finish(s!, live: false);
        case TaskStatus.failed:
          await _fail(row.id, s!.error ?? 'Download failed');
        case TaskStatus.cancelled:
          await _db.remove(row.id);
        case TaskStatus.waiting || TaskStatus.running:
          if (s!.percent != null) _live.put(s);
        case null || TaskStatus.paused:
          await _fail(row.id, 'The download was interrupted');
      }
    }
  }

  void dispose() => _sub.cancel();
}

final downloadsControllerProvider = Provider<DownloadsController>((ref) {
  final c = DownloadsController(ref);
  ref.onDispose(c.dispose);
  return c;
});
