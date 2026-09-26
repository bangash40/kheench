import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../engine/downloader.dart';
import '../../engine/engine_error.dart';
import '../../engine/media_info.dart';
import '../../widgets/common.dart';
import '../../widgets/media_thumb.dart';
import 'downloads_controller.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
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
      'Finished downloads are listed here.',
    ),
    (
      Icons.error_outline_rounded,
      'No failed downloads',
      'If a download fails you can retry it from here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(downloadsProvider).value ?? const <Download>[];
    final active = all
        .where((d) => DownloadStatus.active.contains(d.status))
        .toList();
    final saved = all.where((d) => d.status == DownloadStatus.done).toList();
    final failed = all.where((d) => d.status == DownloadStatus.failed).toList();
    final lists = [active, saved, failed];
    final items = lists[_tab];
    final (icon, title, message) = _empty[_tab];

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle('Downloads'),
          PillTabs(
            labels: [
              'Active · ${active.length}',
              'Saved · ${saved.length}',
              'Failed · ${failed.length}',
            ],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: context.ms(200),
              child: items.isEmpty
                  ? ListView(
                      key: ValueKey('empty$_tab'),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        EmptyState(icon: icon, title: title, message: message),
                      ],
                    )
                  : ListView(
                      key: ValueKey('list$_tab'),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: switch (_tab) {
                        0 => [
                          for (final d in active)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ActiveCard(download: d),
                            ),
                        ],
                        1 => _savedGroups(context, saved),
                        _ => [
                          for (final d in failed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FailedCard(download: d),
                            ),
                        ],
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _savedGroups(BuildContext context, List<Download> saved) {
    final groups = <String, List<Download>>{};
    for (final d in saved) {
      groups
          .putIfAbsent(_dayLabel(d.finishedAt ?? d.createdAt), () => [])
          .add(d);
    }
    return [
      for (final MapEntry(key: day, value: rows) in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 0, 8),
          child: Text(
            day,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: context.k.textMuted),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final (i, d) in rows.indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                _SavedRow(download: d),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  static String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${t.day} ${months[t.month - 1]}${t.year == now.year ? '' : ' ${t.year}'}';
  }
}

String? _durationText(Download d) => d.durationSec == null
    ? null
    : formatDuration(Duration(seconds: d.durationSec!));

class _ActiveCard extends ConsumerWidget {
  const _ActiveCard({required this.download});

  final Download download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final d = download;
    final live = ref.watch(liveProgressProvider.select((m) => m[d.id]));
    final controller = ref.read(downloadsControllerProvider);
    final paused = d.status == DownloadStatus.paused;
    final (status, trailing, percent, indeterminate) = _describe(d, live);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 14),
        child: Column(
          children: [
            Row(
              children: [
                MediaThumb(
                  url: d.thumbnail,
                  duration: _durationText(d),
                  width: 92,
                  height: 58,
                  radius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${d.site} · ${d.quality}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: paused ? 'Resume' : 'Pause',
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: k.text,
                  ),
                  onPressed: () =>
                      paused ? controller.resume(d.id) : controller.pause(d.id),
                ),
                IconButton(
                  tooltip: 'Cancel',
                  icon: Icon(Icons.close_rounded, color: k.text),
                  onPressed: () => controller.cancel(d.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ProgressBar(
                value: percent,
                indeterminate: indeterminate,
                dimmed: paused,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (status text, right-hand text, 0–1 progress, indeterminate)
  static (String, String?, double, bool) _describe(Download d, TaskEvent? e) {
    if (d.status == DownloadStatus.paused) return ('Paused', null, 0, false);
    final p = ((e?.percent ?? 0) / 100).clamp(0.0, 1.0);
    switch (e?.stage) {
      case TaskStage.merging:
        return ('Merging video and audio', 'Almost done', 1, true);
      case TaskStage.converting:
        return ('Converting audio', 'Almost done', 1, true);
      case TaskStage.saving:
        return ('Saving', 'Almost done', 1, true);
      case TaskStage.downloading when e!.percent != null && e.percent! > 0:
        final speed = e.speed == null
            ? ''
            : ' · ${e.speed!.replaceAll('B/s', ' B/s').replaceAll('  ', ' ')}';
        final eta = e.eta == null ? null : '${_eta(e.eta!)} left';
        return ('Downloading ${e.percent!.round()}%$speed', eta, p, false);
      default:
        return (
          d.status == DownloadStatus.running ? 'Starting' : 'Waiting',
          null,
          0,
          d.status == DownloadStatus.running,
        );
    }
  }

  static String _eta(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }
}

/// Saffron progress bar; shimmers while the final size isn't measurable.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.value,
    required this.indeterminate,
    this.dimmed = false,
  });

  final double value;
  final bool indeterminate;
  final bool dimmed;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_ProgressBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final run = widget.indeterminate && !context.reduceMotion;
    if (run && !_shimmer.isAnimating) _shimmer.repeat();
    if (!run && _shimmer.isAnimating) _shimmer.stop();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final color = widget.dimmed ? k.textMuted : KColors.saffron;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: k.border),
            TweenAnimationBuilder<double>(
              tween: Tween(end: widget.value),
              duration: context.ms(300),
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: ColoredBox(color: color),
              ),
            ),
            if (widget.indeterminate)
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  final t = _shimmer.value * 3 - 1;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(t - 1, 0),
                        end: Alignment(t + 1, 0),
                        colors: const [
                          Color(0x00FFFFFF),
                          Color(0x99FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.download});

  final Download download;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final d = download;
    final meta = [
      d.site,
      d.quality,
      if (d.sizeBytes != null) formatBytes(d.sizeBytes!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          MediaThumb(
            url: d.thumbnail,
            duration: _durationText(d),
            width: 80,
            height: 50,
            radius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: k.tealTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 18, color: k.teal),
          ),
        ],
      ),
    );
  }
}

class _FailedCard extends ConsumerWidget {
  const _FailedCard({required this.download});

  final Download download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final d = download;
    final error = EngineError.from(d.error ?? '');
    final controller = ref.read(downloadsControllerProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MediaThumb(
                  url: d.thumbnail,
                  duration: _durationText(d),
                  width: 80,
                  height: 50,
                  radius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${d.site} · ${d.quality}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: KColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error.kind == EngineErrorKind.unknown
                        ? 'Download failed'
                        : error.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: KColors.error),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => controller.resume(d.id),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => _details(context, d.error ?? ''),
                  child: const Text('Details'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.delete_outline_rounded, color: k.textMuted),
                  onPressed: () => controller.forget(d.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _details(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Engine message'),
        content: SingleChildScrollView(
          child: SelectableText(message, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
