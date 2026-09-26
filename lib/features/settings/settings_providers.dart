import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../engine/downloader.dart';

/// What happens when you tap "Show qualities".
enum DefaultQuality {
  ask('Ask every time'),
  best('Best available'),
  p1080('1080p'),
  p720('720p'),
  audio('Audio only');

  const DefaultQuality(this.label);
  final String label;
}

enum AudioFormat {
  m4a('M4A'),
  mp3('MP3');

  const AudioFormat(this.label);
  final String label;
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultQuality = DefaultQuality.ask,
    this.audioFormat = AudioFormat.m4a,
    this.parallel = 2,
    this.autoSaveStatuses = false,
  });

  final ThemeMode themeMode;
  final DefaultQuality defaultQuality;
  final AudioFormat audioFormat;

  /// Downloads running at once (1–3).
  final int parallel;
  final bool autoSaveStatuses;

  AppSettings copyWith({
    ThemeMode? themeMode,
    DefaultQuality? defaultQuality,
    AudioFormat? audioFormat,
    int? parallel,
    bool? autoSaveStatuses,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    defaultQuality: defaultQuality ?? this.defaultQuality,
    audioFormat: audioFormat ?? this.audioFormat,
    parallel: parallel ?? this.parallel,
    autoSaveStatuses: autoSaveStatuses ?? this.autoSaveStatuses,
  );

  Map<String, String> toStorage() => {
    'theme': themeMode.name,
    'defaultQuality': defaultQuality.name,
    'audioFormat': audioFormat.name,
    'parallel': '$parallel',
    'autoSaveStatuses': '$autoSaveStatuses',
  };

  factory AppSettings.fromStorage(Map<String, String> m) {
    T pick<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.asNameMap()[name] ?? fallback;
    return AppSettings(
      themeMode: pick(ThemeMode.values, m['theme'], ThemeMode.system),
      defaultQuality: pick(
        DefaultQuality.values,
        m['defaultQuality'],
        DefaultQuality.ask,
      ),
      audioFormat: pick(AudioFormat.values, m['audioFormat'], AudioFormat.m4a),
      parallel: (int.tryParse(m['parallel'] ?? '') ?? 2).clamp(1, 3),
      autoSaveStatuses: m['autoSaveStatuses'] == 'true',
    );
  }
}

/// App settings, loaded from the database at start and saved on every change.
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final stored = await ref.read(databaseProvider).readSettings();
      state = AppSettings.fromStorage(stored);
      // Keep the native download limit in step with the saved setting.
      await ref.read(downloaderProvider).setParallel(state.parallel);
    } catch (_) {
      // Keep defaults if the database can't be read.
    }
  }

  Future<void> update(AppSettings Function(AppSettings) change) async {
    final before = state;
    state = change(state);
    final db = ref.read(databaseProvider);
    final old = before.toStorage();
    for (final MapEntry(:key, :value) in state.toStorage().entries) {
      if (old[key] != value) await db.writeSetting(key, value);
    }
    if (before.parallel != state.parallel) {
      try {
        await ref.read(downloaderProvider).setParallel(state.parallel);
      } catch (_) {}
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)),
);
