import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/downloads/downloads_controller.dart';
import 'motion.dart';
import 'theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.album_outlined, Icons.album, 'Status'),
    (Icons.download_outlined, Icons.download_rounded, 'Downloads'),
    (Icons.widgets_outlined, Icons.widgets, 'Tools'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the controller alive so native progress events are always recorded.
    ref.watch(downloadsControllerProvider);
    final active = ref.watch(activeCountProvider);

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.k.border)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          animationDuration: context.ms(200),
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final (i, (outlined, filled, label)) in _items.indexed)
              NavigationDestination(
                icon: _badged(context, Icon(outlined), i == 2 ? active : 0),
                selectedIcon: _badged(
                  context,
                  Icon(filled),
                  i == 2 ? active : 0,
                ),
                label: label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _badged(BuildContext context, Widget icon, int count) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: context.k.teal,
      textColor: KColors.white,
      offset: const Offset(10, -6),
      child: icon,
    );
  }
}
