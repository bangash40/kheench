import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../engine/status_source.dart';
import '../../engine/media_info.dart';
import '../../widgets/common.dart';
import 'status_saver.dart';
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

class _StatusTabs extends ConsumerStatefulWidget {
  const _StatusTabs({super.key, required this.app});

  final StatusApp app;

  @override
  ConsumerState<_StatusTabs> createState() => _StatusTabsState();
}

class _StatusTabsState extends ConsumerState<_StatusTabs> {
  /// Selected status uris; non-empty means selection mode.
  final _selected = <String>{};
  bool _saving = false;
  TabController? _tabs;

  StatusApp get app => widget.app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = DefaultTabController.of(context);
    if (tabs != _tabs) {
      _tabs?.removeListener(_onTabChange);
      _tabs = tabs..addListener(_onTabChange);
    }
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChange);
    super.dispose();
  }

  /// Selection belongs to one tab; switching tabs clears it.
  void _onTabChange() {
    if (_tabs!.indexIsChanging) setState(_selected.clear);
  }

  void _toggle(StatusItem item) => setState(() {
    if (!_selected.remove(item.uri)) _selected.add(item.uri);
  });

  Future<void> _save(List<StatusItem> visible) async {
    final picked = visible.where((s) => _selected.contains(s.uri)).toList();
    setState(() => _saving = true);
    var count = 0;
    try {
      count = await ref.read(statusSaverProvider).save(app, picked);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _saving = false;
      _selected.clear();
    });
    final failed = picked.length - count;
    final message = failed == 0
        ? 'Saved ${_plural(count)}'
        : "Saved $count, $failed couldn't be saved";
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _plural(int n) => n == 1 ? '1 status' : '$n statuses';

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final items = ref.watch(statusItemsProvider(app));
    final saved =
        ref.watch(savedStatusHashesProvider).value ?? const <String>{};
    final all = items.value ?? const <StatusItem>[];
    final videos = all.where((s) => s.type == StatusType.video).toList();
    final photos = all.where((s) => s.type == StatusType.photo).toList();
    final visible = (_tabs?.index ?? 0) == 0 ? videos : photos;
    final selecting = _selected.isNotEmpty;
    final allSelected =
        visible.isNotEmpty && visible.every((s) => _selected.contains(s.uri));

    Future<void> refresh() async {
      ref.invalidate(statusItemsProvider(app));
      await ref
          .read(statusItemsProvider(app).future)
          .catchError((_) => <StatusItem>[]);
    }

    Widget grid(List<StatusItem> list) {
      if (items.isLoading && all.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: KColors.saffron),
        );
      }
      if (list.isEmpty) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            EmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: 'No statuses here yet',
              message:
                  'Open ${app.label}, view some statuses, then come back. '
                  'Pull down to refresh.',
            ),
          ],
        );
      }
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(20, 16, 20, selecting ? 110 : 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.76,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final item = list[i];
          return _StatusTile(
            item: item,
            saved: saved.contains(item.hashFor(app)),
            selecting: selecting,
            selected: _selected.contains(item.uri),
            onTap: selecting
                ? () => _toggle(item)
                : () => showStatusViewer(context, app, list, i),
            onLongPress: () => _toggle(item),
          );
        },
      );
    }

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Stack(
        children: [
          Column(
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
                    _IconTab(
                      Icons.play_arrow_rounded,
                      'Videos ${videos.length}',
                    ),
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
                        child: grid(list),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: IgnorePointer(
              ignoring: !selecting,
              child: AnimatedSlide(
                duration: context.ms(200),
                curve: Curves.easeOutCubic,
                offset: selecting ? Offset.zero : const Offset(0, 1.6),
                child: AnimatedOpacity(
                  duration: context.ms(150),
                  opacity: selecting ? 1 : 0,
                  child: _SelectionBar(
                    count: _selected.length,
                    allSelected: allSelected,
                    saving: _saving,
                    onSelectAll: () => setState(() {
                      if (allSelected) {
                        _selected.clear();
                      } else {
                        _selected.addAll(visible.map((s) => s.uri));
                      }
                    }),
                    onSave: () => _save(visible),
                    onClear: () => setState(_selected.clear),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.allSelected,
    required this.saving,
    required this.onSelectAll,
    required this.onSave,
    required this.onClear,
  });

  final int count;
  final bool allSelected;
  final bool saving;
  final VoidCallback onSelectAll;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KColors.ink,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.close_rounded, color: KColors.white),
              onPressed: onClear,
            ),
            Expanded(
              child: Text(
                '$count selected',
                style: const TextStyle(
                  color: KColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: onSelectAll,
              style: TextButton.styleFrom(foregroundColor: KColors.white),
              child: Text(allSelected ? 'Select none' : 'Select all'),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: saving || count == 0 ? null : onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                disabledBackgroundColor: KColors.saffron.withValues(alpha: 0.5),
              ),
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: KColors.ink,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends ConsumerWidget {
  const _StatusTile({
    required this.item,
    required this.saved,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final StatusItem item;
  final bool saved;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final thumb = ref.watch(statusThumbProvider((item.uri, item.type))).value;
    final video = item.type == StatusType.video;

    return Semantics(
      button: true,
      selected: selected,
      label: [
        video ? 'Video status' : 'Photo status',
        timeAgo(item.modified),
        if (saved) 'saved',
      ].join(', '),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: context.ms(150),
          padding: EdgeInsets.all(selected ? 3 : 0),
          decoration: BoxDecoration(
            color: KColors.saffron,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(selected ? 13 : 16),
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
                      shadows: [
                        Shadow(blurRadius: 8, color: Color(0x80000000)),
                      ],
                    ),
                  ),
                if (saved)
                  const Positioned(left: 6, top: 6, child: SavedBadge()),
                if (selecting)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: AnimatedContainer(
                      duration: context.ms(150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected
                            ? KColors.saffron
                            : const Color(0x33000000),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? KColors.saffron : KColors.white,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: KColors.ink,
                            )
                          : null,
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
      ),
    );
  }
}

/// Small teal "Saved" label for statuses already saved.
class SavedBadge extends StatelessWidget {
  const SavedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: KColors.teal,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Saved',
        style: TextStyle(
          color: KColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
