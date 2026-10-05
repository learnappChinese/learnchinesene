import 'dart:math';
import 'package:flutter/material.dart';

class StrokeSampler {
  static List<Offset> resample(List<Offset> points, int targetCount) {
    if (points.isEmpty) return [];
    if (points.length == 1) {
      return List.generate(targetCount, (_) => points.first);
    }

    double totalLength = 0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final d = (points[i + 1] - points[i]).distance;
      segmentLengths.add(d);
      totalLength += d;
    }

    if (totalLength == 0) {
      return List.generate(targetCount, (_) => points.first);
    }

    final List<Offset> resampled = [points.first];
    final double interval = totalLength / (targetCount - 1);
    int currentSegmentIndex = 0;
    double currentSegmentAccumulated = 0;

    for (int i = 1; i < targetCount - 1; i++) {
      final double targetDistance = i * interval;

      while (currentSegmentIndex < segmentLengths.length &&
          currentSegmentAccumulated + segmentLengths[currentSegmentIndex] <
              targetDistance) {
        currentSegmentAccumulated += segmentLengths[currentSegmentIndex];
        currentSegmentIndex++;
      }

      if (currentSegmentIndex >= segmentLengths.length) {
        resampled.add(points.last);
        continue;
      }

      final double segRatio = segmentLengths[currentSegmentIndex] == 0
          ? 0
          : (targetDistance - currentSegmentAccumulated) /
              segmentLengths[currentSegmentIndex];

      final pA = points[currentSegmentIndex];
      final pB = points[currentSegmentIndex + 1];
      final interpolated = Offset(
        pA.dx + (pB.dx - pA.dx) * segRatio,
        pA.dy + (pB.dy - pA.dy) * segRatio,
      );
      resampled.add(interpolated);
    }

    resampled.add(points.last);
    return resampled;
  }
}
