import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/word.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';
import '../../../core/services/progress_service.dart';

class WordListController extends GetxController {
  final progress = ProgressService();
  final pageController = PageController(viewportFraction: .92);

  int unitId = 0;
  String title = 'Từ vựng';

  final words = <Word>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  final index = 0.obs;
  final learned = <int>{}.obs;

  LearningProgressSyncService? get _syncService =>
      Get.isRegistered<LearningProgressSyncService>()
          ? Get.find<LearningProgressSyncService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    unitId = (args?['unitId'] as int?) ?? 0;
    title = '${args?['unitTitle'] ?? 'Từ vựng'}';
    loadWords();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> loadWords() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await DbHelper.instance.getWordsByUnit(unitId);
      words.value = res;
    } catch (e) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markLearned(Word word) async {
    await progress.markLearned(word.id);
    learned.add(word.id);
    try {
      await _syncService?.syncAfterLexiconChange();
    } catch (_) {
      // The learned state is persisted; a later sync will refresh other views.
    }
  }

  void setIndex(int i) {
    index.value = i;
  }

  void next() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}
