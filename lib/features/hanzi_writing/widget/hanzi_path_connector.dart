import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';

/// Vẽ đường nối uốn lượn (Cubic Bezier) giữa hai node chữ Hán liên tiếp.
class HanziPathConnectorPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final bool isCompleted;
  final bool isDashed;

  const HanziPathConnectorPainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.isCompleted,
    this.isDashed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(startX, startY);

    // Điểm uốn mượt mà tạo đường cong S chữ uốn lượn tự nhiên
    final midY = (startY + endY) / 2;
    path.cubicTo(
      startX,
      midY,
      endX,
      midY,
      endX,
      endY,
    );

    if (isCompleted) {
      // Đường nét đã hoàn thành: có hiệu ứng đổ bóng 3D xanh rực rỡ
      final basePaint = Paint()
        ..color = GameVisualTokens.primaryGreenDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round;

      final highlightPaint = Paint()
        ..color = GameVisualTokens.primaryGreenLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, basePaint);
      canvas.drawPath(path, highlightPaint);
    } else {
      // Đường nét chưa hoàn thành: nét đứt hoặc nét xám mềm mại
      final inactivePaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      if (isDashed) {
        final dashedPath = _createDashedPath(path, dashWidth: 8.0, dashSpace: 6.0);
        canvas.drawPath(dashedPath, inactivePaint);
      } else {
        canvas.drawPath(path, inactivePaint);
      }
    }
  }

  Path _createDashedPath(Path source,
      {required double dashWidth, required double dashSpace}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant HanziPathConnectorPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.startY != startY ||
        oldDelegate.endX != endX ||
        oldDelegate.endY != endY ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isDashed != isDashed;
  }
}
