import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../engine/status_source.dart';
import '../../engine/media_info.dart';
import '../../widgets/common.dart';
import 'status_viewer.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from WhatsApp usually means there are new statuses.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final app = ref.read(statusAppProvider);
    ref.invalidate(statusAccessProvider(app));
    await ref
        .read(statusItemsProvider(app).future)
        .catchError((_) => <StatusItem>[]);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(statusAppProvider);
    final access = ref.watch(statusAccessProvider(app));

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
                business: app == StatusApp.business,
                onChanged: (v) => ref
                    .read(statusAppProvider.notifier)
                    .set(v ? StatusApp.business : StatusApp.whatsapp),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.ms(200),
                child: switch (access) {
                  AsyncData(:final value) when !value.installed => _Message(
                    key: ValueKey('missing-$app'),
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '${app.label} isn\'t installed',
                    message:
                        'Install it and view some statuses, then come back.',
                  ),
                  AsyncData(:final value) when !value.granted => _GrantCard(
                    key: ValueKey('grant-$app'),
                    app: app,
                    usesPicker: value.needsFolderPicker,
                    onGranted: _refresh,
                  ),
                  AsyncData() => _StatusTabs(
                    key: ValueKey('tabs-$app'),
                    app: app,
                  ),
                  AsyncError(:final error) => _Message(
                    key: const ValueKey('error'),
                    icon: Icons.error_outline_rounded,
                    title: 'Couldn\'t read statuses',
                    message: '$error',
                  ),
                  _ => const Center(
                    key: ValueKey('loading'),
                    child: CircularProgressIndicator(color: KColors.saffron),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [EmptyState(icon: icon, title: title, message: message)],
    );
  }
}

/// One-time guided screen for status folder access.
class _GrantCard extends ConsumerStatefulWidget {
  const _GrantCard({
    super.key,
    required this.app,
    required this.usesPicker,
    required this.onGranted,
  });

  final StatusApp app;
  final bool usesPicker;
  final Future<void> Function() onGranted;

  @override
  ConsumerState<_GrantCard> createState() => _GrantCardState();
}

class _GrantCardState extends ConsumerState<_GrantCard> {
  bool _busy = false;

  Future<void> _ask({bool manual = false}) async {
    setState(() => _busy = true);
    final source = ref.read(statusSourceProvider);
    final ok = manual
        ? await source.pickFolder(widget.app)
        : await source.request(widget.app);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      await widget.onGranted();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Access wasn\'t given. You can try again any time'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final text = Theme.of(context).textTheme;
    final name = widget.app.label;
    final pickerSteps = widget.usesPicker;

    Widget step(int n, String line) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: k.saffronTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: k.onSaffronTint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(line, style: text.bodyMedium?.copyWith(height: 1.4)),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: k.tealTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.folder_open_rounded, color: k.teal),
                ),
                const SizedBox(height: 14),
                Text('Allow access to $name statuses', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'You only need to do this once.',
                  style: text.bodySmall?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 16),
                step(1, 'Open $name and view the statuses you want to keep.'),
                if (pickerSteps) ...[
                  step(
                    2,
                    'Tap Allow access below. A folder screen opens at the status folder.',
                  ),
                  step(3, 'Tap "Use this folder", then "Allow".'),
                ] else
                  step(2, 'Tap Allow access below and allow storage access.'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _ask,
                    child: Text(_busy ? 'Waiting…' : 'Allow access'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => _ask(manual: true),
                    child: const Text('Choose folder manually'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: Text(
            'Viewing a status still shows you in the poster\'s viewer list. '
            'Kheench only reads statuses you have already opened.',
            style: text.bodySmall?.copyWith(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _StatusTabs extends ConsumerWidget {
  const _StatusTabs({super.key, required this.app});

  final StatusApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final items = ref.watch(statusItemsProvider(app));
    final all = items.value ?? const <StatusItem>[];
    final videos = all.where((s) => s.type == StatusType.video).toList();
    final photos = all.where((s) => s.type == StatusType.photo).toList();

    Future<void> refresh() async {
      ref.invalidate(statusItemsProvider(app));
      await ref
          .read(statusItemsProvider(app).future)
          .catchError((_) => <StatusItem>[]);
    }

    return Column(
      children: [
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
            tabs: [
              _IconTab(Icons.play_arrow_rounded, 'Videos ${videos.length}'),
              _IconTab(Icons.image_outlined, 'Photos ${photos.length}'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              for (final list in [videos, photos])
                RefreshIndicator(
                  color: KColors.saffron,
                  onRefresh: refresh,
                  child: items.isLoading && all.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: KColors.saffron,
                          ),
                        )
                      : list.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            EmptyState(
                              icon: Icons.hourglass_empty_rounded,
                              title: 'No statuses here yet',
                              message:
                                  'Open ${app.label}, view some statuses, then come '
                                  'back. Pull down to refresh.',
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.76,
                              ),
                          itemCount: list.length,
                          itemBuilder: (_, i) =>
                              _StatusTile(items: list, index: i),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends ConsumerWidget {
  const _StatusTile({required this.items, required this.index});

  final List<StatusItem> items;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final item = items[index];
    final thumb = ref.watch(statusThumbProvider((item.uri, item.type))).value;
    final video = item.type == StatusType.video;

    return Semantics(
      button: true,
      label: '${video ? 'Video' : 'Photo'} status, ${timeAgo(item.modified)}',
      child: GestureDetector(
        onTap: () => showStatusViewer(context, items, index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: k.hero),
              if (thumb != null)
                Image.file(
                  File(thumb.path),
                  fit: BoxFit.cover,
                  cacheWidth: 360,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              if (video)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: KColors.white,
                    size: 32,
                    shadows: [Shadow(blurRadius: 8, color: Color(0x80000000))],
                  ),
                ),
              if (video && thumb?.duration != null)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC12262B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatDuration(thumb!.duration!),
                      style: const TextStyle(
                        color: KColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
