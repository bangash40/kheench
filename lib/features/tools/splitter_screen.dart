import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../engine/engine.dart';
import '../../engine/files.dart';
import '../../engine/media_info.dart';
import '../../engine/splitter.dart';
import '../downloads/downloads_controller.dart';

/// Cuts a long video into WhatsApp-status-length parts.
class SplitterScreen extends ConsumerStatefulWidget {
  const SplitterScreen({super.key});

  @override
  ConsumerState<SplitterScreen> createState() => _SplitterScreenState();
}

class _SplitterScreenState extends ConsumerState<SplitterScreen> {
  static const _presets = [15, 30, 60];

  VideoProbe? _video;
  VideoPlayerController? _player;
  Duration _part = const Duration(seconds: 60);
  RangeValues _trim = const RangeValues(0, 1);
  bool _loading = false;

  bool _splitting = false;
  SplitProgress? _progress;
  StreamSubscription<SplitProgress>? _progressSub;
  List<SplitPart>? _saved;

  Splitter get _splitter => ref.read(splitterProvider);

  @override
  void dispose() {
    _player?.dispose();
    _progressSub?.cancel();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- choosing a video ---------------------------------------------------

  Future<void> _pickFromPhone() async {
    final uri = await _splitter.pickVideo();
    if (uri != null) await _load(uri);
  }

  Future<void> _pickFromDownloads() async {
    final videos = (ref.read(downloadsProvider).value ?? const <Download>[])
        .where((d) => d.status == DownloadStatus.done && d.kind == 'video')
        .where((d) => d.uri != null)
        .toList();
    if (videos.isEmpty) {
      _snack('No downloaded videos yet');
      return;
    }
    final picked = await showModalBottomSheet<Download>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final d in videos)
                ListTile(
                  minTileHeight: 56,
                  leading: Icon(Icons.movie_outlined, color: sheet.k.teal),
                  title: Text(
                    d.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${d.site} · ${d.quality}'),
                  onTap: () => Navigator.pop(sheet, d),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked?.uri != null) await _load(picked!.uri!);
  }

  Future<void> _load(String uri) async {
    setState(() {
      _loading = true;
      _saved = null;
    });
    final probe = await _splitter.probe(uri);
    if (!mounted) return;
    if (probe == null) {
      setState(() => _loading = false);
      _snack("Couldn't read this video");
      return;
    }
    await _player?.dispose();
    final player = VideoPlayerController.contentUri(Uri.parse(uri));
    setState(() {
      _video = probe;
      _player = player;
      _trim = RangeValues(0, probe.duration.inMilliseconds.toDouble());
      _loading = false;
    });
    try {
      await player.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      // Preview is optional; splitting still works.
    }
  }

  // --- part length ---------------------------------------------------------

  Future<void> _customLength() async {
    final controller = TextEditingController(text: '${_part.inSeconds}');
    final seconds = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Part length'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'seconds'),
          onSubmitted: (v) => Navigator.pop(context, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (seconds != null && seconds >= 5 && seconds <= 600) {
      setState(() => _part = Duration(seconds: seconds));
    } else if (seconds != null) {
      _snack('Pick between 5 and 600 seconds');
    }
  }

  // --- splitting -------------------------------------------------------------

  Duration get _trimStart => Duration(milliseconds: _trim.start.round());
  Duration get _trimEnd => Duration(milliseconds: _trim.end.round());

  Future<void> _split({required bool share}) async {
    final video = _video;
    if (video == null) return;
    await _player?.pause();
    setState(() {
      _splitting = true;
      _progress = null;
      _saved = null;
    });
    _progressSub = _splitter.progress.listen(
      (p) => setState(() => _progress = p),
    );
    try {
      final parts = await _splitter.split(
        video: video,
        part: _part,
        trimStart: _trimStart,
        trimEnd: _trimEnd,
      );
      if (!mounted) return;
      setState(() => _saved = parts);
      if (share) await _splitter.share(parts);
    } on EngineException catch (e) {
      if (mounted && e.message != 'Cancelled') {
        _snack('Splitting failed: ${e.message}');
      }
    } finally {
      await _progressSub?.cancel();
      if (mounted) setState(() => _splitting = false);
    }
  }

  // --- UI ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final ranges = video == null
        ? const <(Duration, Duration)>[]
        : splitRanges(_trimStart, _trimEnd, _part);

    return Scaffold(
      appBar: AppBar(title: const Text('Status splitter')),
      body: video == null
          ? _Picker(
              loading: _loading,
              onPhone: _pickFromPhone,
              onDownloads: _pickFromDownloads,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                _Preview(
                  video: video,
                  player: _player,
                  onChange: _splitting ? null : _pickFromPhone,
                ),
                const _Label('Part length'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _presets)
                      _Chip(
                        label: '$s s',
                        selected: _part.inSeconds == s,
                        onTap: _splitting
                            ? null
                            : () =>
                                  setState(() => _part = Duration(seconds: s)),
                      ),
                    _Chip(
                      label: _presets.contains(_part.inSeconds)
                          ? 'Custom'
                          : 'Custom · ${_part.inSeconds} s',
                      selected: !_presets.contains(_part.inSeconds),
                      onTap: _splitting ? null : _customLength,
                    ),
                  ],
                ),
                if (video.duration > const Duration(seconds: 5)) ...[
                  _Label(
                    'Trim',
                    trailing:
                        '${formatDuration(_trimStart)} – ${formatDuration(_trimEnd)}',
                  ),
                  RangeSlider(
                    values: _trim,
                    min: 0,
                    max: video.duration.inMilliseconds.toDouble(),
                    activeColor: KColors.saffron,
                    inactiveColor: context.k.border,
                    labels: RangeLabels(
                      formatDuration(_trimStart),
                      formatDuration(_trimEnd),
                    ),
                    onChanged: _splitting
                        ? null
                        : (v) {
                            if (v.end - v.start >= 1000) {
                              setState(() => _trim = v);
                            }
                          },
                  ),
                ],
                _Label(
                  'Timeline',
                  trailing: ranges.length == 1
                      ? '1 part'
                      : '${ranges.length} parts',
                ),
                _Timeline(
                  ranges: ranges,
                  progress: _splitting ? _progress : null,
                ),
                const SizedBox(height: 12),
                _PartList(ranges: ranges),
                if (_saved != null) ...[
                  const SizedBox(height: 16),
                  _SavedCard(parts: _saved!),
                ],
              ],
            ),
      bottomNavigationBar: video == null
          ? null
          : _BottomBar(
              splitting: _splitting,
              progress: _progress,
              onSplit: () => _split(share: false),
              onSplitShare: () => _split(share: true),
              onCancel: _splitter.cancel,
            ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.loading,
    required this.onPhone,
    required this.onDownloads,
  });

  final bool loading;
  final VoidCallback onPhone;
  final VoidCallback onDownloads;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: k.saffronTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: Color(0xFF9A5B0A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pick a video to split',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Kheench cuts it into status-length parts you can post in order.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : onPhone,
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(loading ? 'Opening…' : 'From phone'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onDownloads,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    icon: const Icon(Icons.download_done_rounded),
                    label: const Text('From Kheench downloads'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.video, required this.player, this.onChange});

  final VideoProbe video;
  final VideoPlayerController? player;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final ready = p != null && p.value.isInitialized;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.k.hero),
            if (ready)
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: p.value.size.width,
                  height: p.value.size.height,
                  child: VideoPlayer(p),
                ),
              ),
            if (ready)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: p,
                builder: (context, v, _) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => v.isPlaying ? p.pause() : p.play(),
                  child: AnimatedOpacity(
                    opacity: v.isPlaying ? 0 : 1,
                    duration: context.ms(150),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xF2FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 38,
                          color: KColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC12262B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${video.name} · ${formatDuration(video.duration)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            if (onChange != null)
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  tooltip: 'Pick another video',
                  onPressed: onChange,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: KColors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x8812262B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              this.text,
              style: text.titleSmall?.copyWith(fontSize: 15),
            ),
          ),
          if (trailing != null) Text(trailing!, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected ? (dark ? KColors.saffron : KColors.ink) : k.surface;
    final fg = selected ? (dark ? KColors.ink : KColors.white) : k.text;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.ms(150),
          constraints: const BoxConstraints(minHeight: 46, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: selected ? bg : k.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloured segments, one per part, sized by length; they appear one by one.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.ranges, this.progress});

  final List<(Duration, Duration)> ranges;
  final SplitProgress? progress;

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(KColors.saffron, KColors.white, 0.35)!;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (final (i, (a, b)) in ranges.indexed)
            Expanded(
              flex: (b - a).inMilliseconds.clamp(1, 1 << 30),
              child: _Segment(
                key: ValueKey('$i-${ranges.length}'),
                index: i,
                color: i.isEven ? KColors.saffron : light,
                done: progress != null && i < progress!.part - 1,
                active: progress != null && i == progress!.part - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    super.key,
    required this.index,
    required this.color,
    required this.done,
    required this.active,
  });

  final int index;
  final Color color;
  final bool done;
  final bool active;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // 60 ms apart, as parts are worked out.
    Future.delayed(Duration(milliseconds: 60 * widget.index.clamp(0, 20)), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown || context.reduceMotion;
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: context.ms(150),
      child: AnimatedScale(
        scale: shown ? 1 : 0.8,
        duration: context.ms(150),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.done ? KColors.teal : widget.color,
            borderRadius: BorderRadius.circular(10),
            border: widget.active
                ? Border.all(color: KColors.ink, width: 2)
                : null,
          ),
          child: widget.done
              ? const Icon(Icons.check_rounded, size: 18, color: KColors.white)
              : Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: KColors.ink,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PartList extends StatelessWidget {
  const _PartList({required this.ranges});

  final List<(Duration, Duration)> ranges;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (final (i, (a, b)) in ranges.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: k.saffronTint,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: k.onSaffronTint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Part ${i + 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${formatDuration(a)} – ${formatDuration(b)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 14),
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

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.parts});

  final List<SplitPart> parts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final splitter = ref.read(splitterProvider);
    final folder = parts.isEmpty ? '' : parts.first.folder;
    return Card(
      color: k.tealTint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: k.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${parts.length} parts saved',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(folder, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => splitter.share(parts),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('Share to WhatsApp'),
                ),
                TextButton(
                  onPressed: () => splitter.share(parts, whatsapp: false),
                  child: const Text('Share…'),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(fileActionsProvider)
                        .openFolder(folder);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text('Saved in $folder')),
                        );
                    }
                  },
                  child: const Text('Open folder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.splitting,
    required this.progress,
    required this.onSplit,
    required this.onSplitShare,
    required this.onCancel,
  });

  final bool splitting;
  final SplitProgress? progress;
  final VoidCallback onSplit;
  final VoidCallback onSplitShare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final p = progress;
    return Container(
      decoration: BoxDecoration(
        color: k.background,
        border: Border(top: BorderSide(color: k.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: splitting
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p == null
                            ? 'Starting…'
                            : 'Splitting part ${p.part} of ${p.parts} · ${p.percent.round()}%',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p == null ? null : p.percent / 100,
                          minHeight: 7,
                          color: KColors.saffron,
                          backgroundColor: k.border,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: onCancel, child: const Text('Cancel')),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onSplit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    icon: const Icon(Icons.content_cut_rounded),
                    label: const Text('Split'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: onSplitShare,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Split and share all'),
                  ),
                ),
              ],
            ),
    );
  }
}
