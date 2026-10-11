import 'package:get/get.dart';
import '../../../core/learning/data/learning_history_repository.dart';
import '../../../core/services/history_service.dart';

class HistoryController extends GetxController {
  HistoryController({
    HistoryService? historyService,
    LearningHistoryRepository? learningHistoryRepository,
  })  : _historyService = historyService ??
            (Get.isRegistered<HistoryService>()
                ? Get.find<HistoryService>()
                : HistoryService()),
        _learningHistoryRepo =
            learningHistoryRepository ?? SupabaseLearningHistoryRepository();

  final HistoryService _historyService;
  final LearningHistoryRepository _learningHistoryRepo;

  // 0: Lịch sử học tập (Chính thức), 1: Lịch sử công cụ AI (Tiện ích)
  final selectedTab = 0.obs;
  final isLoading = false.obs;

  // Authoritative official learning progress and XP ledger
  final learningItems = <Map<String, dynamic>>[].obs;

  // Local AI utility conversations, translations, lookups
  final aiHistoryItems = <HistoryItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void switchTab(int index) {
    selectedTab.value = index;
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _learningHistoryRepo.fetchRecentTimeline(limit: 50),
        _historyService.getHistory(),
      ]);

      learningItems.assignAll(results[0] as List<Map<String, dynamic>>);
      aiHistoryItems.assignAll(results[1] as List<HistoryItem>);
    } catch (_) {
      if (Get.context != null) {
        Get.snackbar('Lỗi', 'Không thể tải lịch sử.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAiHistory() async {
    isLoading.value = true;
    try {
      await _historyService.clearHistory();
      aiHistoryItems.clear();
      if (Get.context != null) {
        Get.snackbar(
          'Thông báo',
          'Đã xóa lịch sử công cụ AI. Lịch sử học tập chính thức được bảo lưu an toàn.',
        );
      }
    } catch (_) {
      if (Get.context != null) {
        Get.snackbar('Lỗi', 'Không thể xóa lịch sử công cụ AI.');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
