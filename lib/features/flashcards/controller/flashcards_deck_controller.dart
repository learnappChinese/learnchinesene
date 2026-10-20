import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
import '../models/flashcard_models.dart';

/// Controller quản lý danh sách bộ thẻ theo HSK / Section và tổng quan Dashboard Flashcard.
class FlashcardsDeckController extends GetxController {
  final isLoading = true.obs;
  final dashboardStats = Rxn<FlashcardDashboardStats>();
  final hskDecks = <FlashcardHskDeck>[].obs;

  final selectedHskLevel = 1.obs;
  final cardLimit = 20.obs;
  final cardDirection = FlashcardDirection.zhToVi.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardAndDecks();
  }

  Future<void> loadDashboardAndDecks() async {
    isLoading.value = true;
    try {
      if (AppDatabase.instance.isOpen) {
        // 1. Thống kê Dashboard
        final rawStats = await AppDatabase.instance.getFlashcardDashboardSummary();
        dashboardStats.value = FlashcardDashboardStats.fromMap(rawStats);

        // 2. Danh sách bộ thẻ HSK & Sections
        final rawDecks = await AppDatabase.instance.getFlashcardDecksHierarchy();
        final List<FlashcardHskDeck> decks = [];

        for (final item in rawDecks) {
          final lvlMap = item['level'] as Map<String, dynamic>;
          final lvlId = (lvlMap['id'] as num?)?.toInt() ?? 1;
          final lvlName = '${lvlMap['name'] ?? 'HSK $lvlId'}';
          final lvlDesc = '${lvlMap['description'] ?? 'Cấp độ $lvlId'}';
          final sectionsRaw = item['sections'] as List<Map<String, dynamic>>? ?? [];

          final List<FlashcardSectionDeck> sections = [];
          for (final s in sectionsRaw) {
            final uMap = s['unit'] as Map<String, dynamic>;
            final uId = (uMap['id'] as num?)?.toInt() ?? 1;
            final uNumber = (uMap['unit_number'] as num?)?.toInt() ?? 1;
            final uTitle = '${uMap['title'] ?? 'Bài $uNumber'}';

            sections.add(FlashcardSectionDeck(
              unitId: uId,
              unitNumber: uNumber,
              title: uTitle,
              totalWords: (s['total_words'] as num?)?.toInt() ?? 0,
              dueWords: (s['due_words'] as num?)?.toInt() ?? 0,
              learningWords: (s['learning_words'] as num?)?.toInt() ?? 0,
              reviewWords: (s['review_words'] as num?)?.toInt() ?? 0,
              newWords: (s['new_words'] as num?)?.toInt() ?? 0,
            ));
          }

          decks.add(FlashcardHskDeck(
            level: lvlId,
            name: lvlName,
            description: lvlDesc,
            sections: sections,
            isAvailable: lvlId <= 4, // HSK 5 & 6 đang được biên soạn
          ));
        }

        hskDecks.assignAll(decks);
      }
    } catch (e) {
      debugPrint('FlashcardsDeckController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectHsk(int level) {
    selectedHskLevel.value = level;
  }

  void setCardLimit(int limit) {
    cardLimit.value = limit;
  }

  void setDirection(FlashcardDirection dir) {
    cardDirection.value = dir;
  }
}
