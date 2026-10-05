import 'package:flutter/material.dart';

class UserStrokePainter extends CustomPainter {
  final List<Offset> points;
  final Color strokeColor;

  UserStrokePainter({
    required this.points,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant UserStrokePainter oldDelegate) {
    // Re-draw only if points or color change
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor;
  }
}
