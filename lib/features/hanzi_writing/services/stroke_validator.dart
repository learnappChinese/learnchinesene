import 'dart:ui';
import '../../../core/models/stroke_validation_result.dart';
import 'stroke_sampler.dart';

class StrokeValidator {
  static StrokeValidationResult validate({
    required List<Offset> userPoints,
    required Path refPath,
    int sampleCount = 70,
    double maxAverageDistance = 9.5,
    double maxStartDistance = 15.0,
    double maxEndDistance = 16.0,
    double maxLengthRatioDifference = 0.58,
    int minRawPoints = 5,
  }) {
    if (userPoints.length < minRawPoints) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: 'Nét quá ngắn.',
      );
    }

    final refMetrics = refPath.computeMetrics().toList();
    if (refMetrics.isEmpty) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: 'Lỗi nét mẫu.',
      );
    }

    final refMetric = refMetrics.first;
    final refLength = refMetric.length;
    final List<Offset> refPoints = [];
    final double step = refLength / (sampleCount - 1);
    for (int i = 0; i < sampleCount; i++) {
      final tangent = refMetric.getTangentForOffset(i * step);
      if (tangent != null) {
        refPoints.add(tangent.position);
      }
    }

    if (refPoints.length < sampleCount) {
      while (refPoints.length < sampleCount) {
        refPoints.add(refPoints.isNotEmpty ? refPoints.last : Offset.zero);
      }
    }

    final List<Offset> userResampled =
        StrokeSampler.resample(userPoints, sampleCount);

    final startToStart = (userResampled.first - refPoints.first).distance;
    final startToEnd = (userResampled.first - refPoints.last).distance;
    final endToStart = (userResampled.last - refPoints.first).distance;
    final endToEnd = (userResampled.last - refPoints.last).distance;

    if (startToEnd < maxStartDistance &&
        endToStart < maxEndDistance &&
        startToStart > startToEnd) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: 'Sai chiều viết.',
      );
    }

    if (startToStart > maxStartDistance) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: 'Điểm bắt đầu chưa đúng.',
      );
    }

    if (endToEnd > maxEndDistance) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: 'Điểm kết thúc chưa đúng.',
      );
    }

    double totalDistance = 0;
    for (int i = 0; i < sampleCount; i++) {
      totalDistance += (userResampled[i] - refPoints[i]).distance;
    }
    final avgDistance = totalDistance / sampleCount;

    if (avgDistance > maxAverageDistance) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: 'Nét lệch quá xa.',
      );
    }

    double userLength = 0;
    for (int i = 0; i < userPoints.length - 1; i++) {
      userLength += (userPoints[i + 1] - userPoints[i]).distance;
    }

    final lengthRatioDiff = (userLength - refLength).abs() / refLength;
    if (lengthRatioDiff > maxLengthRatioDifference) {
      return StrokeValidationResult(
        isValid: false,
        errorMessage: userLength < refLength ? 'Nét quá ngắn.' : 'Nét quá dài.',
      );
    }

    return StrokeValidationResult(
      isValid: true,
      score: 100.0 - (avgDistance * 5).clamp(0, 100),
    );
  }
}
