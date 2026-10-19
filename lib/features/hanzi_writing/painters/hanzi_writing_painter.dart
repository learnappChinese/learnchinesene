import 'dart:math' as math;
import 'package:flutter/material.dart';

class HanziWritingPainter extends CustomPainter {
  final List<Path> strokePaths;
  final Set<int> completedIndexes;
  final int currentIndex;
  final double viewBoxWidth;
  final double viewBoxHeight;

  // Round specific configurations
  final double guideOpacity;
  final bool showCurrentStroke;
  final bool showStartPoint;
  final bool showDirectionArrow;

  // Snap animation variables
  final int? animatingStrokeIndex;
  final double snapAnimationValue;

  HanziWritingPainter({
    required this.strokePaths,
    required this.completedIndexes,
    required this.currentIndex,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.guideOpacity,
    required this.showCurrentStroke,
    required this.showStartPoint,
    required this.showDirectionArrow,
    this.animatingStrokeIndex,
    this.snapAnimationValue = 1.0,
  });

  Paint _createStrokePaint({
    required Color color,
    required double strokeWidth,
  }) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (strokePaths.isEmpty) return;

    // Calculate uniform scale to prevent distortion
    final scaleX = size.width / viewBoxWidth;
    final scaleY = size.height / viewBoxHeight;
    final scale = math.min(scaleX, scaleY);
    final offsetX = (size.width - viewBoxWidth * scale) / 2;
    final offsetY = (size.height - viewBoxHeight * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // 1. Draw entire character in light grey outline based on guideOpacity
    if (guideOpacity > 0) {
      final guidePaint = _createStrokePaint(
        color: Colors.grey[300]!.withOpacity(guideOpacity),
        strokeWidth: 4.5,
      );
      for (int i = 0; i < strokePaths.length; i++) {
        if (!completedIndexes.contains(i) && i != currentIndex) {
          canvas.drawPath(strokePaths[i], guidePaint);
        }
      }
    }

    // 2. Draw current stroke template/hint if active
    if (currentIndex < strokePaths.length && currentIndex >= 0) {
      if (showCurrentStroke) {
        final hintPaint = _createStrokePaint(
          color: Colors.orange.withOpacity(0.5),
          strokeWidth: 4.5,
        );
        canvas.drawPath(strokePaths[currentIndex], hintPaint);
      } else if (guideOpacity > 0) {
        final guidePaint = _createStrokePaint(
          color: Colors.grey[300]!.withOpacity(guideOpacity),
          strokeWidth: 4.5,
        );
        canvas.drawPath(strokePaths[currentIndex], guidePaint);
      }

      // Draw start point and direction arrow if configured
      if (showStartPoint) {
        final path = strokePaths[currentIndex];
        final metrics = path.computeMetrics().toList();
        if (metrics.isNotEmpty) {
          final firstMetric = metrics.first;
          final tangent = firstMetric.getTangentForOffset(0);
          final startPoint = tangent?.position;
          final directionVector = tangent?.vector;

          if (startPoint != null) {
            // Draw start point circle (draw as filled circle)
            final startPaint = Paint()
              ..color = Colors.orange
              ..style = PaintingStyle.fill;
            canvas.drawCircle(startPoint, 3.5, startPaint);

            if (showDirectionArrow && directionVector != null) {
              final arrowPaint = Paint()
                ..color = Colors.orange
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..strokeCap = StrokeCap.round;

              final V = directionVector;
              const arrowLen = 9.0;
              final arrowEnd = startPoint + V * arrowLen;

              // Draw arrow line
              canvas.drawLine(startPoint, arrowEnd, arrowPaint);

              // Draw arrowhead wings
              final revV = Offset(-V.dx, -V.dy);
              const angle = math.pi / 6; // 30 degrees
              final wing1 = Offset(
                    revV.dx * math.cos(angle) - revV.dy * math.sin(angle),
                    revV.dx * math.sin(angle) + revV.dy * math.cos(angle),
                  ) *
                  3.5;
              final wing2 = Offset(
                    revV.dx * math.cos(-angle) - revV.dy * math.sin(-angle),
                    revV.dx * math.sin(-angle) + revV.dy * math.cos(-angle),
                  ) *
                  3.5;

              canvas.drawLine(arrowEnd, arrowEnd + wing1, arrowPaint);
              canvas.drawLine(arrowEnd, arrowEnd + wing2, arrowPaint);
            }
          }
        }
      }
    }

    // 3. Draw completed strokes in black (using snap animation if applicable)
    final completedPaint = _createStrokePaint(
      color: Colors.black,
      strokeWidth: 4.5,
    );

    for (int i = 0; i < strokePaths.length; i++) {
      if (completedIndexes.contains(i)) {
        if (i == animatingStrokeIndex) {
          final animPaint = _createStrokePaint(
            color: Colors.black.withOpacity(snapAnimationValue),
            strokeWidth: 4.5,
          );
          final bounds = strokePaths[i].getBounds();
          final center = bounds.center;

          canvas.save();
          canvas.translate(center.dx, center.dy);
          // Scale from 1.15 down to 1.0 based on animation value
          final scaleFactor = 1.0 + 0.15 * (1.0 - snapAnimationValue);
          canvas.scale(scaleFactor);
          canvas.translate(-center.dx, -center.dy);
          canvas.drawPath(strokePaths[i], animPaint);
          canvas.restore();
        } else {
          canvas.drawPath(strokePaths[i], completedPaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HanziWritingPainter oldDelegate) {
    return oldDelegate.completedIndexes.length != completedIndexes.length ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.guideOpacity != guideOpacity ||
        oldDelegate.showCurrentStroke != showCurrentStroke ||
        oldDelegate.showStartPoint != showStartPoint ||
        oldDelegate.showDirectionArrow != showDirectionArrow ||
        oldDelegate.animatingStrokeIndex != animatingStrokeIndex ||
        oldDelegate.snapAnimationValue != snapAnimationValue;
  }
}
