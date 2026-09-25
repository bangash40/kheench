import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Video thumbnail with a play glyph and an optional duration badge.
class MediaThumb extends StatelessWidget {
  const MediaThumb({
    super.key,
    this.url,
    this.duration,
    this.width = 100,
    this.height = 64,
    this.radius = 12,
  });

  final String? url;
  final String? duration;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: context.k.hero);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              placeholder
            else
              Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: (width * 3).round(),
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, sync) =>
                    frame == null && !sync ? placeholder : child,
              ),
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: KColors.white,
                size: 26,
                shadows: [Shadow(blurRadius: 8, color: Color(0x80000000))],
              ),
            ),
            if (duration != null)
              Positioned(
                right: 5,
                bottom: 5,
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
                    duration!,
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
    );
  }
}
