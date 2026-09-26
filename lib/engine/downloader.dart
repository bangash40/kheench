import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'download_choice.dart';
import 'engine.dart';

enum TaskStatus { waiting, running, paused, done, failed, cancelled }

enum TaskStage { waiting, downloading, merging, converting, saving }

/// One progress or result update for a download task.
class TaskEvent {
  const TaskEvent({
    required this.taskId,
    required this.status,
    this.stage,
    this.percent,
    this.speed,
    this.eta,
    this.uri,
    this.path,
    this.name,
    this.size,
    this.mime,
    this.error,
  });

  final String taskId;
  final TaskStatus status;
  final TaskStage? stage;
  final double? percent;

  /// e.g. `2.40MB/s`.
  final String? speed;
  final Duration? eta;

  final String? uri;
  final String? path;
  final String? name;
  final int? size;
  final String? mime;
  final String? error;

  factory TaskEvent.fromMap(Map<Object?, Object?> m) {
    final eta = (m['eta'] as num?)?.toInt();
    return TaskEvent(
      taskId: m['taskId'] as String,
      status: TaskStatus.values.asNameMap()[m['status']] ?? TaskStatus.running,
      stage: TaskStage.values.asNameMap()[m['stage']],
      percent: (m['percent'] as num?)?.toDouble(),
      speed: m['speed'] as String?,
      eta: eta == null || eta < 0 ? null : Duration(seconds: eta),
      uri: m['uri'] as String?,
      path: m['path'] as String?,
      name: m['name'] as String?,
      size: (m['size'] as num?)?.toInt(),
      mime: m['mime'] as String?,
      error: m['error'] as String?,
    );
  }
}

/// Dart side of the native download worker (see DownloadWorker.kt).
class Downloader {
  static const _method = MethodChannel('kheench/engine');
  static const _progress = EventChannel('kheench/progress');

  late final Stream<TaskEvent> events = _progress.receiveBroadcastStream().map(
    (e) => TaskEvent.fromMap(e as Map<Object?, Object?>),
  );

  static String newTaskId() {
    final r = Random().nextInt(1 << 20).toRadixString(36);
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$r';
  }

  /// Starts (or resumes, with the same [taskId]) a download.
  Future<void> enqueue({
    required String taskId,
    required String url,
    required String title,
    required DownloadChoice choice,
  }) => _call('enqueue', {
    'taskId': taskId,
    'url': url,
    'title': title,
    'selector': choice.selector,
    'args': choice.extraArgs,
    'kind': choice.kind.name,
    'parts': choice.selector.contains('+') ? 2 : 1,
  });

  Future<void> pause(String taskId) => _call('pause', {'taskId': taskId});

  Future<void> cancel(String taskId) => _call('cancel', {'taskId': taskId});

  Future<void> setParallel(int value) => _call('setParallel', {'value': value});

  /// Tasks known to the background scheduler, for catching up after restarts.
  Future<List<TaskEvent>> taskStates() async {
    final list = await _method.invokeListMethod<Object?>('taskStates') ?? [];
    return [
      for (final m in list.whereType<Map<Object?, Object?>>())
        TaskEvent.fromMap(m),
    ];
  }

  Future<void> _call(String method, Map<String, Object?> args) async {
    try {
      await _method.invokeMethod<Object?>(method, args);
    } on PlatformException catch (e) {
      throw EngineException(e.message ?? e.code);
    } on MissingPluginException {
      throw const EngineException('Downloads are only available on Android');
    }
  }
}

final downloaderProvider = Provider<Downloader>((_) => Downloader());
