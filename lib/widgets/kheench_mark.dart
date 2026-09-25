import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The saffron tile with a download arrow dropping into a tray.
///
/// [arrowDrop] runs from 0 (arrow above, hidden) to 1 (arrow resting in tray),
/// so the splash can animate it; everywhere else it stays at 1.
class KheenchMark extends StatelessWidget {
  const KheenchMark({super.key, this.size = 36, this.arrowDrop = 1});

  final double size;
  final double arrowDrop;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(arrowDrop)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.arrowDrop);

  final double arrowDrop;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * 0.28),
    );
    canvas.drawRRect(tile, Paint()..color = KColors.saffron);

    final stroke = Paint()
      ..color = KColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.068
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tray = Path()
      ..moveTo(s * 0.33, s * 0.55)
      ..lineTo(s * 0.33, s * 0.64)
      ..quadraticBezierTo(s * 0.33, s * 0.70, s * 0.39, s * 0.70)
      ..lineTo(s * 0.61, s * 0.70)
      ..quadraticBezierTo(s * 0.67, s * 0.70, s * 0.67, s * 0.64)
      ..lineTo(s * 0.67, s * 0.55);
    canvas.drawPath(tray, stroke);

    if (arrowDrop <= 0) return;
    final dy = (1 - arrowDrop) * -s * 0.3;
    final alpha = arrowDrop.clamp(0.0, 1.0);
    stroke.color = KColors.ink.withValues(alpha: alpha);

    canvas.save();
    canvas.clipRRect(tile);
    canvas.translate(0, dy);
    final arrow = Path()
      ..moveTo(s * 0.5, s * 0.28)
      ..lineTo(s * 0.5, s * 0.56)
      ..moveTo(s * 0.40, s * 0.465)
      ..lineTo(s * 0.5, s * 0.565)
      ..lineTo(s * 0.60, s * 0.465);
    canvas.drawPath(arrow, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.arrowDrop != arrowDrop;
}
