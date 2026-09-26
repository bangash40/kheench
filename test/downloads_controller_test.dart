import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/data/database.dart';
import 'package:kheench/engine/download_choice.dart';
import 'package:kheench/engine/downloader.dart';
import 'package:kheench/engine/media_info.dart';
import 'package:kheench/features/downloads/downloads_controller.dart';

class FakeDownloader implements Downloader {
  final controller = StreamController<TaskEvent>.broadcast();
  final enqueued = <String>[];
  final paused = <String>[];
  final cancelled = <String>[];
  List<TaskEvent> states = [];

  @override
  Stream<TaskEvent> get events => controller.stream;

  @override
  Future<void> enqueue({
    required String taskId,
    required String url,
    required String title,
    required String selector,
    required List<String> args,
    required String kind,
    required int parts,
  }) async => enqueued.add(taskId);

  @override
  Future<void> pause(String taskId) async => paused.add(taskId);

  @override
  Future<void> cancel(String taskId) async => cancelled.add(taskId);

  @override
  Future<void> setParallel(int value) async {}

  @override
  Future<List<TaskEvent>> taskStates() async => states;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late FakeDownloader fake;
  late AppDatabase db;

  const info = MediaInfo(
    id: 'abc',
    title: 'Clip',
    url: 'https://example.com/v/abc',
    site: 'Example',
    videos: [
      VideoOption(
        formatId: '22',
        label: '720p',
        ext: 'mp4',
        codec: 'H.264',
        needsAudio: false,
        height: 720,
      ),
    ],
    audios: [],
  );

  setUp(() {
    fake = FakeDownloader();
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        downloaderProvider.overrideWithValue(fake),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Download> onlyRow() async => (await db.watchAll().first).single;

  Future<String> startOne() async {
    final c = container.read(downloadsControllerProvider);
    await c.start(
      info: info,
      url: info.url,
      choice: DownloadChoice.video(info.videos.first),
    );
    return (await onlyRow()).id;
  }

  Future<void> emit(TaskEvent e) async {
    fake.controller.add(e);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  test('start records a waiting row and enqueues it', () async {
    final id = await startOne();
    final row = await onlyRow();
    expect(row.status, DownloadStatus.waiting);
    expect(row.quality, '720p MP4');
    expect(fake.enqueued, [id]);
  });

  test('progress marks running, completion stores the file', () async {
    final id = await startOne();
    await emit(TaskEvent(taskId: id, status: TaskStatus.running, percent: 40));
    expect((await onlyRow()).status, DownloadStatus.running);
    expect(container.read(liveProgressProvider)[id]?.percent, 40);

    await emit(
      TaskEvent(
        taskId: id,
        status: TaskStatus.done,
        uri: 'content://media/1',
        path: 'Movies/Kheench/Clip.mp4',
        size: 1234,
      ),
    );
    final row = await onlyRow();
    expect(row.status, DownloadStatus.done);
    expect(row.uri, 'content://media/1');
    expect(row.sizeBytes, 1234);
    expect(container.read(liveProgressProvider), isEmpty);
  });

  test('failure keeps the error and retry re-enqueues', () async {
    final id = await startOne();
    await emit(
      TaskEvent(taskId: id, status: TaskStatus.failed, error: 'HTTP Error 403'),
    );
    expect((await onlyRow()).status, DownloadStatus.failed);
    expect((await onlyRow()).error, 'HTTP Error 403');

    await container.read(downloadsControllerProvider).resume(id);
    expect((await onlyRow()).status, DownloadStatus.waiting);
    expect(fake.enqueued, [id, id]);
  });

  test('pause keeps the row; cancel removes it', () async {
    final id = await startOne();
    final c = container.read(downloadsControllerProvider);
    await c.pause(id);
    expect((await onlyRow()).status, DownloadStatus.paused);
    // The native side reports the stopped worker as cancelled; a paused row stays.
    await emit(TaskEvent(taskId: id, status: TaskStatus.cancelled));
    expect((await onlyRow()).status, DownloadStatus.paused);

    await c.cancel(id);
    expect(await db.watchAll().first, isEmpty);
    expect(fake.cancelled, [id]);
  });

  test(
    'catches up on downloads that finished while the app was closed',
    () async {
      final id = await startOne();
      container.dispose();

      fake = FakeDownloader()
        ..states = [
          TaskEvent(
            taskId: id,
            status: TaskStatus.done,
            uri: 'content://media/9',
            size: 5,
          ),
        ];
      container = ProviderContainer(
        overrides: [
          downloaderProvider.overrideWithValue(fake),
          databaseProvider.overrideWithValue(db),
        ],
      );
      container.read(downloadsControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final row = await onlyRow();
      expect(row.status, DownloadStatus.done);
      expect(row.uri, 'content://media/9');
    },
  );
}
