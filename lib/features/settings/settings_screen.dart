import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../engine/engine.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final k = context.k;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Theme',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: k.textMuted),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: k.surface,
                selectedBackgroundColor: KColors.saffron,
                selectedForegroundColor: KColors.ink,
                side: BorderSide(color: k.border),
                minimumSize: const Size(0, 48),
                textStyle: const TextStyle(
                  fontFamily: KFonts.body,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.high_quality_outlined,
                  title: 'Default quality',
                  value: 'Ask every time',
                ),
                const Divider(indent: 16, endIndent: 16),
                _InfoTile(
                  icon: Icons.audiotrack_outlined,
                  title: 'Default audio format',
                  value: 'M4A',
                ),
                const Divider(indent: 16, endIndent: 16),
                _InfoTile(
                  icon: Icons.layers_outlined,
                  title: 'Parallel downloads',
                  value: '2',
                ),
                const Divider(indent: 16, endIndent: 16),
                const _EngineTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ListTile(
      minTileHeight: 56,
      leading: Icon(icon, color: k.teal),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      trailing: Text(value, style: Theme.of(context).textTheme.bodySmall),
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
