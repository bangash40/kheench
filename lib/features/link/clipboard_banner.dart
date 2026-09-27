import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';

/// "Link found on clipboard · Open", from the Home design.
class ClipboardBanner extends StatelessWidget {
  const ClipboardBanner({
    super.key,
    required this.url,
    required this.onOpen,
    required this.onDismiss,
  });

  final String? url;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final link = url;
    return AnimatedSize(
      duration: context.ms(250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: link == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                decoration: BoxDecoration(
                  color: k.saffronTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.content_paste_rounded, color: k.onSaffronTint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Link found on clipboard',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: k.onSaffronTint),
                          ),
                          Text(
                            link.replaceFirst(
                              RegExp(r'^https?://(www\.)?'),
                              '',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: KColors.ink,
                        foregroundColor: KColors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: k.textMuted,
                        size: 20,
                      ),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
