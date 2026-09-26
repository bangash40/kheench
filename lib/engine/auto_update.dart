import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import 'engine.dart';

/// Updates yt-dlp once a week, only on Wi-Fi and only when nothing is
/// downloading (replacing the engine mid-download could break it).
/// Sites change often, so this keeps downloads working without the user
/// having to remember "Update engine".
class EngineAutoUpdate {
  EngineAutoUpdate(this._ref);

  final Ref _ref;

  static const interval = Duration(days: 7);
  static const _key = 'engineCheckedAt';

  Future<void> run() async {
    final db = _ref.read(databaseProvider);
    final engine = _ref.read(engineProvider);

    final stored = (await db.readSettings())[_key];
    final last = DateTime.tryParse(stored ?? '');
    if (last != null && DateTime.now().difference(last) < interval) return;

    // Let the engine finish unpacking first.
    await _ref.read(engineVersionProvider.future);
    if (!await engine.isUnmetered()) return;

    final busy = (await db.watchAll().first).any(
      (d) => DownloadStatus.active.contains(d.status),
    );
    if (busy) return;

    await engine.update();
    _ref.invalidate(engineVersionProvider);
    await db.writeSetting(_key, DateTime.now().toIso8601String());
  }
}

/// Watched once by the app shell; runs the weekly check in the background.
final engineAutoUpdateProvider = FutureProvider<void>((ref) async {
  try {
    await EngineAutoUpdate(ref).run();
  } catch (_) {
    // Try again on the next launch.
  }
});
