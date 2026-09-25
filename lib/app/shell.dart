import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'motion.dart';
import 'theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.album_outlined, Icons.album, 'Status'),
    (Icons.download_outlined, Icons.download_rounded, 'Downloads'),
    (Icons.widgets_outlined, Icons.widgets, 'Tools'),
  ];

  @override
  Widget build(BuildContext context) {
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
            for (final (outlined, filled, label) in _items)
              NavigationDestination(
                icon: Icon(outlined),
                selectedIcon: Icon(filled),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}
