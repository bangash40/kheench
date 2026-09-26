import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/data/database.dart';
import 'package:kheench/features/settings/settings_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('settings survive a round trip through storage', () {
    const s = AppSettings(
      themeMode: ThemeMode.dark,
      defaultQuality: DefaultQuality.p720,
      audioFormat: AudioFormat.mp3,
      parallel: 3,
      autoSaveStatuses: true,
    );
    final back = AppSettings.fromStorage(s.toStorage());
    expect(back.themeMode, ThemeMode.dark);
    expect(back.defaultQuality, DefaultQuality.p720);
    expect(back.audioFormat, AudioFormat.mp3);
    expect(back.parallel, 3);
    expect(back.autoSaveStatuses, isTrue);
  });

  test('bad or missing values fall back to defaults', () {
    final s = AppSettings.fromStorage({'theme': 'purple', 'parallel': '9'});
    expect(s.themeMode, ThemeMode.system);
    expect(s.defaultQuality, DefaultQuality.ask);
    expect(s.parallel, 3);
  });

  test('changes are saved and loaded again on the next start', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    ProviderContainer start() =>
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

    final first = start();
    first.read(settingsProvider);
    await first
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(themeMode: ThemeMode.light, parallel: 1));
    first.dispose();

    final second = start();
    addTearDown(second.dispose);
    second.read(settingsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(second.read(themeModeProvider), ThemeMode.light);
    expect(second.read(settingsProvider).parallel, 1);
  });
}
