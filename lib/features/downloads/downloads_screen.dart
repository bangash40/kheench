import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../widgets/common.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  int _tab = 0;

  static const _empty = [
    (
      Icons.downloading_rounded,
      'No active downloads',
      'Downloads in progress show up here with their speed and time left.',
    ),
    (
      Icons.check_circle_outline_rounded,
      'Nothing saved yet',
      'Finished downloads are listed here so you can play, share or delete them.',
    ),
    (
      Icons.error_outline_rounded,
      'No failed downloads',
      'If a download fails you can retry it from here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = _empty[_tab];
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenTitle(
            'Downloads',
            trailing: IconButton(
              tooltip: 'Search downloads',
              icon: const Icon(Icons.search_rounded),
              onPressed: () => showComingSoon(context, 'Search'),
            ),
          ),
          PillTabs(
            labels: const ['Active · 0', 'Saved · 0', 'Failed · 0'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                AnimatedSwitcher(
                  duration: context.ms(200),
                  child: EmptyState(
                    key: ValueKey(_tab),
                    icon: icon,
                    title: title,
                    message: message,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
