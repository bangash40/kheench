import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

/// Status values stored in [Downloads.status].
abstract final class DownloadStatus {
  static const waiting = 'waiting';
  static const running = 'running';
  static const paused = 'paused';
  static const done = 'done';
  static const failed = 'failed';

  static const active = [waiting, running, paused];
}

/// Download queue and history.
class Downloads extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get site => text()();
  TextColumn get thumbnail => text().nullable()();
  IntColumn get durationSec => integer().nullable()();

  /// `video` or `audio`.
  TextColumn get kind => text()();

  /// e.g. `1080p60 MP4`, `MP3 audio`.
  TextColumn get quality => text()();
  TextColumn get selector => text()();

  /// Extra yt-dlp arguments, one per line.
  TextColumn get extraArgs => text().withDefault(const Constant(''))();
  IntColumn get parts => integer().withDefault(const Constant(1))();

  TextColumn get status => text()();

  /// Last known progress (0–100), kept so a paused download shows where it stopped.
  RealColumn get percent => real().nullable()();
  TextColumn get uri => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get mime => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// WhatsApp statuses the user has saved, so the grid can mark them.
class SavedStatuses extends Table {
  /// `app|file name|size`: stable while the status exists.
  TextColumn get hash => text()();
  TextColumn get app => text()();
  TextColumn get type => text()();
  TextColumn get savedUri => text().nullable()();
  TextColumn get savedPath => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {hash};
}

@DriftDatabase(tables: [Downloads, SavedStatuses])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'kheench'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(downloads, downloads.percent);
      if (from < 3) await m.createTable(savedStatuses);
    },
  );

  Stream<List<Download>> watchAll() => (select(
    downloads,
  )..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).watch();

  Future<Download?> byId(String id) =>
      (select(downloads)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<List<Download>> unfinished() =>
      (select(downloads)..where(
            (d) =>
                d.status.isIn([DownloadStatus.waiting, DownloadStatus.running]),
          ))
          .get();

  Future<void> insertDownload(DownloadsCompanion row) =>
      into(downloads).insert(row);

  Future<void> patch(String id, DownloadsCompanion changes) =>
      (update(downloads)..where((d) => d.id.equals(id))).write(changes);

  Future<void> remove(String id) =>
      (delete(downloads)..where((d) => d.id.equals(id))).go();

  Stream<Set<String>> watchSavedStatusHashes() =>
      select(savedStatuses)
          .map((r) => r.hash)
          .watch()
          .map((list) => list.toSet());

  Future<void> markStatusSaved(SavedStatusesCompanion row) =>
      into(savedStatuses).insertOnConflictUpdate(row);
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
