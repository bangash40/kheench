import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  bool _business = false;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final appName = _business ? 'WhatsApp Business' : 'WhatsApp';

    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            ScreenTitle(
              'Status',
              trailing: IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AppToggle(
                business: _business,
                onChanged: (v) => setState(() => _business = v),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: KColors.saffron,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: k.border,
                labelColor: k.text,
                unselectedLabelColor: k.textMuted,
                labelPadding: const EdgeInsets.only(right: 24),
                labelStyle: const TextStyle(
                  fontFamily: KFonts.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: KFonts.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  _IconTab(Icons.play_arrow_rounded, 'Videos'),
                  _IconTab(Icons.image_outlined, 'Photos'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final kind in const ['video', 'photo'])
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        AnimatedSwitcher(
                          duration: context.ms(200),
                          child: EmptyState(
                            key: ValueKey('$appName-$kind'),
                            icon: Icons.folder_open_rounded,
                            title: 'Allow access to $appName statuses',
                            message:
                                'Kheench needs one-time access to the '
                                '$appName status folder. Open a few statuses '
                                'in $appName first, then come back here.',
                            action: FilledButton(
                              onPressed: () =>
                                  showComingSoon(context, 'Status access'),
                              child: const Text('Allow folder access'),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTab extends StatelessWidget {
  const _IconTab(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _AppToggle extends StatelessWidget {
  const _AppToggle({required this.business, required this.onChanged});

  final bool business;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selBg = dark ? KColors.saffron : KColors.ink;
    final selFg = dark ? KColors.ink : KColors.white;

    Widget option(String label, bool value) {
      final selected = business == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: context.ms(200),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? selBg : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? selFg : k.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: k.border),
      ),
      child: Row(
        children: [option('WhatsApp', false), option('Business', true)],
      ),
    );
  }
}
