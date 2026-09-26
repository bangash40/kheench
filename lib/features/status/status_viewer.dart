import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../engine/media_info.dart';
import '../../engine/status_source.dart';
import 'status_saver.dart';
import 'status_screen.dart' show SavedBadge;

/// Opens [items] full screen at [index]; swipe to move between them.
Future<void> showStatusViewer(
  BuildContext context,
  StatusApp app,
  List<StatusItem> items,
  int index,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: context.ms(200),
      reverseTransitionDuration: context.ms(150),
      pageBuilder: (_, _, _) =>
          StatusViewer(app: app, items: items, initialIndex: index),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class StatusViewer extends ConsumerStatefulWidget {
  const StatusViewer({
    super.key,
    required this.app,
    required this.items,
    required this.initialIndex,
  });

  final StatusApp app;
  final List<StatusItem> items;
  final int initialIndex;

  @override
  ConsumerState<StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends ConsumerState<StatusViewer> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _saving = false;

  Future<void> _save(StatusItem item) async {
    setState(() => _saving = true);
    var ok = false;
    try {
      ok = await ref.read(statusSaverProvider).save(widget.app, [item]) == 1;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't save this status")),
        );
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final saved = (ref.watch(savedStatusHashesProvider).value ?? const {})
        .contains(item.hashFor(widget.app));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final it = widget.items[i];
                return it.type == StatusType.video
                    ? _VideoPage(item: it, active: i == _index)
                    : _PhotoPage(item: it);
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Color(0x00000000)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: KColors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_index + 1} of ${widget.items.length}',
                                style: const TextStyle(
                                  color: KColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                timeAgo(item.modified),
                                style: const TextStyle(
                                  color: Color(0xFFB9C6C8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (saved)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SavedBadge(),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilledButton.icon(
                              onPressed: _saving ? null : () => _save(item),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 20,
                              ),
                              label: Text(_saving ? 'Saving' : 'Save'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `just now`, `12m ago`, `3h ago`, `yesterday`.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return d.inDays == 1 ? 'yesterday' : '${d.inDays} days ago';
}

class _PhotoPage extends ConsumerWidget {
  const _PhotoPage({required this.item});

  final StatusItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(statusSourceProvider).localCopy(item.uri),
      builder: (context, snap) {
        final path = snap.data;
        if (path == null) {
          return Center(
            child: snap.connectionState == ConnectionState.done
                ? const Text(
                    'Couldn\'t open this photo',
                    style: TextStyle(color: KColors.white),
                  )
                : const CircularProgressIndicator(color: KColors.saffron),
          );
        }
        return InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              semanticLabel: 'Status photo',
            ),
          ),
        );
      },
    );
  }
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.item, required this.active});

  final StatusItem item;

  /// Only the page on screen plays.
  final bool active;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _video;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    if (widget.active && _video == null) _load();
    if (!widget.active) _video?.pause();
  }

  Future<void> _load() async {
    final uri = Uri.parse(widget.item.uri);
    final c = uri.scheme == 'file'
        ? VideoPlayerController.file(File(uri.toFilePath()))
        : VideoPlayerController.contentUri(uri);
    _video = c;
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() {});
      if (widget.active) await c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  @override
  Widget build(BuildContext context) {
    final c = _video;
    if (_failed) {
      return const Center(
        child: Text(
          'Couldn\'t play this video',
          style: TextStyle(color: KColors.white),
        ),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: KColors.saffron),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: c,
            builder: (context, v, _) => AnimatedOpacity(
              opacity: v.isPlaying ? 0 : 1,
              duration: context.ms(150),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: KColors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (context, v, _) => Row(
                children: [
                  Text(
                    formatDuration(v.position),
                    style: const TextStyle(color: KColors.white, fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      colors: const VideoProgressColors(
                        playedColor: KColors.saffron,
                        bufferedColor: Color(0x55FFFFFF),
                        backgroundColor: Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatDuration(v.duration),
                    style: const TextStyle(color: KColors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
