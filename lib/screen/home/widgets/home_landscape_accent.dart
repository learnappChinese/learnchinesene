import 'package:flutter/material.dart';

/// Quiet mountain silhouettes behind the foreground text and progress bars.
class HomeLandscapeAccent extends StatelessWidget {
  const HomeLandscapeAccent({
    super.key,
    required this.color,
    this.showPagoda = false,
  });

  final Color color;
  final bool showPagoda;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: _LandscapePainter(color, showPagoda),
          ),
        ),
      );
}

class _LandscapePainter extends CustomPainter {
  const _LandscapePainter(this.color, this.showPagoda);
  final Color color;
  final bool showPagoda;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (var layer = 0; layer < 3; layer++) {
      final base = .68 + layer * .11;
      final path = Path()..moveTo(0, h);
      path.lineTo(0, h * base);
      for (var i = 1; i <= 10; i++) {
        final x = i / 10;
        final peak = i.isOdd ? .18 + (i % 3) * .045 : 0.0;
        path.lineTo(w * x, h * (base - peak));
      }
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(
          path, Paint()..color = color.withValues(alpha: .035 + layer * .02));
    }
    if (!showPagoda) return;
    final paint = Paint()..color = color.withValues(alpha: .28);
    final x = w * .80;
    final towerWidth = w * .17;
    for (var floor = 0; floor < 3; floor++) {
      final y = h * (.35 + floor * .18);
      final roofWidth = towerWidth * (.68 + floor * .17);
      final roof = Path()
        ..moveTo(x - roofWidth * .58, y + h * .06)
        ..quadraticBezierTo(x - roofWidth * .16, y + h * .03, x, y - h * .04)
        ..quadraticBezierTo(
            x + roofWidth * .16, y + h * .03, x + roofWidth * .58, y + h * .06)
        ..close();
      canvas.drawPath(roof, paint);
      canvas.drawRect(
          Rect.fromLTWH(
              x - roofWidth * .32, y + h * .065, roofWidth * .64, h * .10),
          paint);
      final window = Paint()..color = Colors.white.withValues(alpha: .8);
      for (final offset in [-.17, .17]) {
        canvas.drawRect(
            Rect.fromLTWH(x + roofWidth * offset - w * .014, y + h * .083,
                w * .028, h * .065),
            window);
      }
    }
    canvas.drawRect(
        Rect.fromLTWH(x - towerWidth * .46, h * .85, towerWidth * .92, h * .10),
        paint);
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) =>
      color != oldDelegate.color || showPagoda != oldDelegate.showPagoda;
}
