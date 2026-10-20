import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';

/// Controller quản lý màn hình Thống kê học tập Flashcard (Heatmap, Forecast, Phân bổ).
class FlashcardsStatsController extends GetxController {
  final isLoading = true.obs;
  final heatmapData = <Map<String, dynamic>>[].obs;
  final ratingCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0}.obs;
  final forecastData = <Map<String, dynamic>>[].obs;

  final totalReviews = 0.obs;
  final correctReviews = 0.obs;
  final retentionRate = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      if (AppDatabase.instance.isOpen) {
        final history = await AppDatabase.instance.getFlashcardStatsHistory(days: 90);
        final rawHeatmap = history['heatmap'] as List<Map<String, dynamic>>? ?? [];
        final rawRatings = history['ratings'] as Map<int, int>? ?? {};
        final rawForecast = history['forecast'] as List<Map<String, dynamic>>? ?? [];

        heatmapData.assignAll(rawHeatmap);
        ratingCounts.assignAll(rawRatings);
        forecastData.assignAll(rawForecast);

        var total = 0;
        var correct = 0;
        for (final row in rawHeatmap) {
          total += (row['total_reviews'] as num?)?.toInt() ?? 0;
          correct += (row['correct_reviews'] as num?)?.toInt() ?? 0;
        }

        totalReviews.value = total;
        correctReviews.value = correct;
        retentionRate.value = total > 0 ? ((correct / total) * 100) : 0.0;
      }
    } catch (e) {
      debugPrint('FlashcardsStatsController error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
