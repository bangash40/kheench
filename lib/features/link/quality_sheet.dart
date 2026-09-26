import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../engine/download_choice.dart';
import '../../engine/media_info.dart';
import '../../widgets/media_thumb.dart';

/// Opens the quality picker; resolves to the chosen option, or null.
Future<DownloadChoice?> showQualitySheet(BuildContext context, MediaInfo info) {
  return showModalBottomSheet<DownloadChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (_) => QualitySheet(info: info),
  );
}

class QualitySheet extends StatefulWidget {
  const QualitySheet({super.key, required this.info});

  final MediaInfo info;

  @override
  State<QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends State<QualitySheet> {
  late DownloadChoice _selected = DownloadChoice.best(widget.info);

  void _select(DownloadChoice choice) => setState(() => _selected = choice);

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final k = context.k;

    // Rows animate in one after another (30 ms apart, first 8 only).
    var index = 0;
    Widget staggered(Widget child) {
      final delay = (index++).clamp(0, 8) * 30;
      return _StaggerIn(delayMs: delay, child: child);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: k.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  _Header(info: info),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickPick(
                          dark: true,
                          icon: Icons.auto_awesome_rounded,
                          title: 'Best quality',
                          subtitle: info.bestVideo == null
                              ? 'Highest available'
                              : '${info.bestVideo!.label}'
                                    '${info.bestVideo!.needsAudio ? ' + audio' : ''}',
                          selected: _selected.id == 'best',
                          onTap: () => _select(DownloadChoice.best(info)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickPick(
                          icon: Icons.music_note_rounded,
                          title: 'MP3 audio',
                          subtitle: 'Best, converted',
                          selected: _selected.id == 'mp3',
                          onTap: () => _select(DownloadChoice.mp3(info)),
                        ),
                      ),
                    ],
                  ),
                  if (info.videos.isNotEmpty) ...[
                    _SectionLabel('Video · ${_count(info.videos.length)}'),
                    for (final v in info.videos)
                      staggered(
                        _OptionRow(
                          title: v.label,
                          container: v.container,
                          badge: v.needsAudio
                              ? 'audio added'
                              : v.watermarked
                              ? 'watermark'
                              : null,
                          subtitle: _join([
                            v.codec,
                            DownloadChoice.video(v).sizeText,
                          ]),
                          selected: _selected.id == 'v:${v.formatId}',
                          onTap: () => _select(DownloadChoice.video(v)),
                        ),
                      ),
                  ],
                  if (info.audios.isNotEmpty) ...[
                    _SectionLabel('Audio only · ${_count(info.audios.length)}'),
                    for (final a in info.audios)
                      staggered(
                        _OptionRow(
                          title: a.kbps == null ? 'Audio' : '${a.kbps} kbps',
                          container: a.container,
                          subtitle: _join([
                            a.codec,
                            DownloadChoice.audio(a).sizeText,
                          ]),
                          selected: _selected.id == 'a:${a.formatId}',
                          onTap: () => _select(DownloadChoice.audio(a)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Container(
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
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _selected),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    _join([
                          'Download ${_selected.label}',
                          _selected.sizeText,
                        ]) ??
                        'Download',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _count(int n) => n == 1 ? '1 option' : '$n options';

  static String? _join(List<String?> parts) {
    final list = parts.whereType<String>().where((s) => s.isNotEmpty);
    return list.isEmpty ? null : list.join(' · ');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info});

  final MediaInfo info;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaThumb(
          url: info.thumbnail,
          duration: info.duration == null
              ? null
              : formatDuration(info.duration!),
          width: 92,
          height: 64,
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
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  if (info.uploader != null) info.uploader!,
                  info.site,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: Icon(Icons.close_rounded, color: k.text),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 0, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: context.k.textMuted),
      ),
    );
  }
}

class _QuickPick extends StatelessWidget {
  const _QuickPick({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final bg = dark ? k.hero : k.surface;
    final fg = dark ? KColors.white : k.text;
    final sub = dark ? const Color(0xFFB9C6C8) : k.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.ms(150),
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? KColors.saffron : (dark ? bg : k.border),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: dark ? KColors.saffron : k.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 13),
                    ),
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

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.container,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String container;
  final String? subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: [title, container, ?badge, ?subtitle].join(', '),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: context.ms(150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? k.saffronTint : k.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? KColors.saffron : k.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                _RadioDot(selected: selected),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: selected ? k.onSaffronTint : k.text,
                            ),
                          ),
                          Text(
                            container,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected ? k.onSaffronTint : k.textMuted,
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: k.tealTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  color: k.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final color = selected ? k.text : k.textMuted;
    return AnimatedContainer(
      duration: context.ms(150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        duration: context.ms(150),
        scale: selected ? 1 : 0,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Fades and slides a row in after [delayMs].
class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _c.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
