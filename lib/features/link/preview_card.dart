import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../engine/engine_error.dart';
import '../../engine/media_info.dart';
import '../../widgets/media_thumb.dart';
import 'link_lookup.dart';

/// Shows loading, the fetched preview, or a clear error under the link card.
class PreviewArea extends StatelessWidget {
  const PreviewArea({
    super.key,
    required this.state,
    required this.onChooseQuality,
    required this.onRetry,
    required this.onUpdateEngine,
    required this.onClear,
    this.updatingEngine = false,
  });

  final LookupState state;
  final VoidCallback onChooseQuality;
  final VoidCallback onRetry;
  final VoidCallback onUpdateEngine;
  final VoidCallback onClear;
  final bool updatingEngine;

  @override
  Widget build(BuildContext context) {
    final child = switch (state) {
      LookupIdle() => const SizedBox(
        key: ValueKey('idle'),
        width: double.infinity,
      ),
      LookupLoading() => const _LoadingCard(key: ValueKey('loading')),
      LookupLoaded(:final info) => _PreviewCard(
        key: ValueKey('loaded-${info.id}'),
        info: info,
        onChooseQuality: onChooseQuality,
        onClear: onClear,
      ),
      LookupFailed(:final error) => _ErrorCard(
        key: const ValueKey('error'),
        error: error,
        onRetry: onRetry,
        onUpdateEngine: onUpdateEngine,
        onClear: onClear,
        updating: updatingEngine,
      ),
    };
    return AnimatedSize(
      duration: context.ms(250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: context.ms(250),
        child: state is LookupIdle
            ? child
            : Padding(
                key: child.key,
                padding: const EdgeInsets.only(top: 16),
                child: child,
              ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    super.key,
    required this.info,
    required this.onChooseQuality,
    required this.onClear,
  });

  final MediaInfo info;
  final VoidCallback onChooseQuality;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final meta = [
      if (info.uploader != null) info.uploader!,
      if (info.duration != null) formatDuration(info.duration!),
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MediaThumb(
                  url: info.thumbnail,
                  duration: info.duration == null
                      ? null
                      : formatDuration(info.duration!),
                  width: 112,
                  height: 70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        info.site,
                        style: TextStyle(
                          color: k.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Clear',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, color: k.textMuted),
                  onPressed: onClear,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: info.videos.isEmpty && info.audios.isEmpty
                    ? null
                    : onChooseQuality,
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  info.isLive
                      ? 'Live streams aren\'t supported yet'
                      : 'Choose quality',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard({super.key});

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _pulse.value = 0.7;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget bar(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: k.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Semantics(
      label: 'Loading link details',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FadeTransition(
            opacity: _pulse,
            child: Row(
              children: [
                Container(
                  width: 112,
                  height: 70,
                  decoration: BoxDecoration(
                    color: k.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(double.infinity),
                      const SizedBox(height: 8),
                      bar(140),
                      const SizedBox(height: 12),
                      Text(
                        'Reading link…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onUpdateEngine,
    required this.onClear,
    required this.updating,
  });

  final EngineError error;
  final VoidCallback onRetry;
  final VoidCallback onUpdateEngine;
  final VoidCallback onClear;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: KColors.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.message,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, color: k.textMuted),
                  onPressed: onClear,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton(onPressed: onRetry, child: const Text('Try again')),
                if (error.suggestsUpdate)
                  TextButton(
                    onPressed: updating ? null : onUpdateEngine,
                    child: Text(updating ? 'Updating…' : 'Update engine'),
                  ),
                TextButton(
                  onPressed: () => _showDetails(context),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Engine message'),
        content: SingleChildScrollView(
          child: SelectableText(
            error.raw,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
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
