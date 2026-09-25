import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
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
                _InfoTile(
                  icon: Icons.system_update_alt_rounded,
                  title: 'Download engine',
                  value: 'Not installed yet',
                ),
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
