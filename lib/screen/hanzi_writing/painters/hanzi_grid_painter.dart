import 'package:flutter/material.dart';

class HanziGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Helper to draw dotted lines
    void drawDottedLine(Offset p1, Offset p2) {
      final double distance = (p2 - p1).distance;
      const double dashWidth = 4.0;
      const double spaceWidth = 4.0;
      double currentDistance = 0;
      while (currentDistance < distance) {
        final double ratioStart = currentDistance / distance;
        final double ratioEnd = (currentDistance + dashWidth) / distance;

        final start = Offset(
          p1.dx + (p2.dx - p1.dx) * ratioStart,
          p1.dy + (p2.dy - p1.dy) * ratioStart,
        );
        final end = Offset(
          p1.dx + (p2.dx - p1.dx) * (ratioEnd > 1.0 ? 1.0 : ratioEnd),
          p1.dy + (p2.dy - p1.dy) * (ratioEnd > 1.0 ? 1.0 : ratioEnd),
        );

        canvas.drawLine(start, end, dashPaint);
        currentDistance += dashWidth + spaceWidth;
      }
    }

    // Horizontal line
    drawDottedLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2));
    // Vertical line
    drawDottedLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height));
    // Diagonals
    drawDottedLine(Offset.zero, Offset(size.width, size.height));
    drawDottedLine(Offset(size.width, 0), Offset(0, size.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
