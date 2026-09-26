import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../engine/engine.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _Section('Appearance'),
          _Segmented<ThemeMode>(
            value: s.themeMode,
            options: const {
              ThemeMode.system: 'System',
              ThemeMode.light: 'Light',
              ThemeMode.dark: 'Dark',
            },
            onChanged: (v) => notifier.update((s) => s.copyWith(themeMode: v)),
          ),
          const _Section('Downloads'),
          Card(
            child: Column(
              children: [
                _Tile(
                  icon: Icons.high_quality_outlined,
                  title: 'Default quality',
                  subtitle: s.defaultQuality == DefaultQuality.ask
                      ? 'Show every option before downloading'
                      : 'Starts right away; "More qualities" is still one tap away',
                  trailing: s.defaultQuality.label,
                  onTap: () => _pickQuality(context, ref, s.defaultQuality),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Tile(
                  icon: Icons.audiotrack_outlined,
                  title: 'Audio format',
                  subtitle: 'Used when the default is "Audio only"',
                  control: _Segmented<AudioFormat>(
                    compact: true,
                    value: s.audioFormat,
                    options: {for (final f in AudioFormat.values) f: f.label},
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(audioFormat: v)),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Tile(
                  icon: Icons.layers_outlined,
                  title: 'Downloads at once',
                  subtitle: 'Others wait their turn',
                  control: _Segmented<int>(
                    compact: true,
                    value: s.parallel,
                    options: const {1: '1', 2: '2', 3: '3'},
                    onChanged: (v) =>
                        notifier.update((s) => s.copyWith(parallel: v)),
                  ),
                ),
              ],
            ),
          ),
          const _Section('WhatsApp status'),
          Card(
            child: SwitchListTile(
              value: s.autoSaveStatuses,
              onChanged: (v) =>
                  notifier.update((s) => s.copyWith(autoSaveStatuses: v)),
              activeThumbColor: KColors.saffron,
              secondary: Icon(
                Icons.bookmark_add_outlined,
                color: context.k.teal,
              ),
              title: Text(
                'Auto-save new statuses',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                'When you open the Status tab or pull to refresh',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const _Section('Engine'),
          const Card(child: _EngineTile()),
          const _Section('Saved to'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Videos: Movies/Kheench\n'
              'Audio: Music/Kheench\n'
              'Statuses: Movies/Kheench/Status and Pictures/Kheench/Status',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickQuality(
    BuildContext context,
    WidgetRef ref,
    DefaultQuality current,
  ) async {
    final picked = await showModalBottomSheet<DefaultQuality>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: RadioGroup<DefaultQuality>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(sheet, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Default quality',
                    style: Theme.of(sheet).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final q in DefaultQuality.values)
                RadioListTile<DefaultQuality>(
                  value: q,
                  activeColor: KColors.saffron,
                  title: Text(q.label),
                  subtitle:
                      q == DefaultQuality.p1080 || q == DefaultQuality.p720
                      ? Text(
                          'Or the closest lower quality',
                          style: Theme.of(sheet).textTheme.bodySmall,
                        )
                      : null,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(defaultQuality: picked));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: context.k.textMuted),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.control,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? control;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: k.teal),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (subtitle != null)
                        Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing!,
                    style: text.titleSmall?.copyWith(color: k.teal),
                  ),
                  Icon(Icons.chevron_right_rounded, color: k.textMuted),
                ],
              ],
            ),
            if (control != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: control!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          backgroundColor: k.surface,
          selectedBackgroundColor: KColors.saffron,
          selectedForegroundColor: KColors.ink,
          side: BorderSide(color: k.border),
          minimumSize: Size(0, compact ? 40 : 48),
          textStyle: const TextStyle(
            fontFamily: KFonts.body,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        segments: [
          for (final MapEntry(:key, :value) in options.entries)
            ButtonSegment(value: key, label: Text(value)),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _EngineTile extends ConsumerStatefulWidget {
  const _EngineTile();

  @override
  ConsumerState<_EngineTile> createState() => _EngineTileState();
}

class _EngineTileState extends ConsumerState<_EngineTile> {
  bool _updating = false;

  Future<void> _update() async {
    setState(() => _updating = true);
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final result = await ref.read(engineProvider).update();
      ref.invalidate(engineVersionProvider);
      final version = await ref.read(engineVersionProvider.future);
      message = result == EngineUpdateResult.updated
          ? 'Engine updated to $version'
          : 'Engine is already up to date';
    } on EngineException catch (e) {
      message = 'Update failed: ${e.message}';
    }
    if (!mounted) return;
    setState(() => _updating = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final version = ref.watch(engineVersionProvider);
    final subtitle = switch (version) {
      AsyncData(:final value) => 'yt-dlp $value',
      AsyncError() => 'Not available',
      _ => 'Preparing…',
    };

    return ListTile(
      minTileHeight: 64,
      leading: Icon(Icons.system_update_alt_rounded, color: k.teal),
      title: Text(
        'Download engine',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: _updating
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: KColors.saffron,
              ),
            )
          : TextButton(
              onPressed: version.isLoading ? null : _update,
              child: const Text('Update'),
            ),
    );
  }
}
