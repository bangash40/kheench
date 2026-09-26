import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../engine/status_source.dart';

/// Hashes of statuses already saved (see [StatusItem.hashFor]).
final savedStatusHashesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(databaseProvider).watchSavedStatusHashes(),
);

/// Saves statuses and remembers them so the grid can mark them.
class StatusSaver {
  StatusSaver(this._ref);

  final Ref _ref;

  /// Returns how many were saved.
  Future<int> save(StatusApp app, List<StatusItem> items) async {
    if (items.isEmpty) return 0;
    final saved = (await _ref.read(statusSourceProvider).save(items)).toSet();
    final db = _ref.read(databaseProvider);
    final now = DateTime.now();
    for (final item in items.where((i) => saved.contains(i.uri))) {
      await db.markStatusSaved(
        SavedStatusesCompanion.insert(
          hash: item.hashFor(app),
          app: app.name,
          type: item.type.name,
          savedAt: now,
          savedUri: const Value.absent(),
        ),
      );
    }
    return saved.length;
  }
}

final statusSaverProvider = Provider<StatusSaver>((ref) => StatusSaver(ref));
