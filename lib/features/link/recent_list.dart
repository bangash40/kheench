import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../engine/media_info.dart';
import '../../widgets/common.dart';
import '../../widgets/media_thumb.dart';
import '../downloads/download_actions.dart';
import '../downloads/downloads_controller.dart';
import '../downloads/downloads_screen.dart';

/// The three newest downloads, shown on Home.
class RecentList extends ConsumerWidget {
  const RecentList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = (ref.watch(downloadsProvider).value ?? const <Download>[])
        .take(3)
        .toList();

    return AnimatedSwitcher(
      duration: context.ms(200),
      child: recent.isEmpty
          ? const EmptyState(
              key: ValueKey('empty'),
              icon: Icons.download_rounded,
              title: 'Nothing downloaded yet',
              message:
                  'Paste a link above or share one to Kheench from any app.',
            )
          : Column(
              key: const ValueKey('list'),
              children: [
                for (final d in recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentCard(download: d),
                  ),
              ],
            ),
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.download});

  final Download download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    final d = download;
    final done = d.status == DownloadStatus.done;
    final failed = d.status == DownloadStatus.failed;
    final active = !done && !failed;
    final live = ref.watch(liveProgressProvider.select((m) => m[d.id]));
    final (status, trailing, percent, indeterminate) = describeProgress(
      d,
      live,
    );

    final detail = done
        ? [
            d.quality,
            if (d.sizeBytes != null) formatBytes(d.sizeBytes!),
          ].join(' · ')
        : failed
        ? 'Failed · tap to see why'
        : status;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            done ? playDownload(context, ref, d) : context.go('/downloads'),
        onLongPress: done ? () => showDownloadActions(context, ref, d) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MediaThumb(
                url: d.thumbnail,
                duration: d.durationSec == null
                    ? null
                    : formatDuration(Duration(seconds: d.durationSec!)),
                width: 100,
                height: 64,
              ),
              const SizedBox(width: 14),
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
                      d.site,
                      style: TextStyle(
                        color: k.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: failed ? KColors.error : null,
                                ),
                          ),
                        ),
                        if (active && trailing != null)
                          Text(
                            trailing,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    if (active) ...[
                      const SizedBox(height: 6),
                      DownloadProgressBar(
                        value: percent,
                        indeterminate: indeterminate,
                        dimmed: d.status == DownloadStatus.paused,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
