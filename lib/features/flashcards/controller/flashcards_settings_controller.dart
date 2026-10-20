import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
import '../models/flashcard_models.dart';

/// Controller quản lý màn hình Cài đặt ôn tập FSRS.
class FlashcardsSettingsController extends GetxController {
  final isLoading = true.obs;

  final desiredRetention = 0.90.obs;
  final newCardsPerDay = 20.obs;
  final maxReviewsPerDay = 100.obs;
  final cardDirection = FlashcardDirection.zhToVi.obs;
  final autoPlayAudio = true.obs;
  final currentPreset = 'Cân bằng'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      if (AppDatabase.instance.isOpen) {
        final settings = await AppDatabase.instance.getFlashcardSettings();
        desiredRetention.value =
            (settings['desired_retention'] as num?)?.toDouble() ?? 0.90;
        newCardsPerDay.value =
            (settings['new_cards_per_day'] as num?)?.toInt() ?? 20;
        maxReviewsPerDay.value =
            (settings['max_reviews_per_day'] as num?)?.toInt() ?? 100;
        cardDirection.value = FlashcardDirection.fromCode(
          settings['card_direction'] as String? ?? 'zh_vi',
        );
        autoPlayAudio.value = (settings['auto_play_audio'] as num?)?.toInt() == 1;
        currentPreset.value =
            settings['preset_name'] as String? ?? 'Cân bằng';
      }
    } catch (e) {
      debugPrint('FlashcardsSettingsController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    try {
      await AppDatabase.instance.saveFlashcardSettings({
        'desired_retention': desiredRetention.value,
        'new_cards_per_day': newCardsPerDay.value,
        'max_reviews_per_day': maxReviewsPerDay.value,
        'card_direction': cardDirection.value.code,
        'auto_play_audio': autoPlayAudio.value ? 1 : 0,
        'preset_name': currentPreset.value,
      });
    } catch (e) {
      debugPrint('saveSettings error: $e');
    }
  }

  void applyPreset(String preset) {
    currentPreset.value = preset;
    switch (preset) {
      case 'Nhẹ nhàng':
        newCardsPerDay.value = 10;
        maxReviewsPerDay.value = 50;
        desiredRetention.value = 0.85;
        break;
      case 'Cân bằng':
        newCardsPerDay.value = 20;
        maxReviewsPerDay.value = 100;
        desiredRetention.value = 0.90;
        break;
      case 'Chuyên sâu':
        newCardsPerDay.value = 40;
        maxReviewsPerDay.value = 200;
        desiredRetention.value = 0.95;
        break;
    }
    saveSettings();
  }
}
