import 'package:get/get.dart';
import '../../../core/services/history_service.dart';

class HistoryController extends GetxController {
  final HistoryService _historyService = Get.find<HistoryService>();

  final isLoading = false.obs;
  final historyItems = <HistoryItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final list = await _historyService.getHistory();
      historyItems.value = list;
    } catch (_) {
      Get.snackbar('Lỗi', 'Không thể tải lịch sử học tập.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAll() async {
    isLoading.value = true;
    try {
      await _historyService.clearHistory();
      historyItems.clear();
      Get.snackbar('Thông báo', 'Đã xóa toàn bộ lịch sử học tập.');
    } catch (_) {
      Get.snackbar('Lỗi', 'Không thể xóa lịch sử.');
    } finally {
      isLoading.value = false;
    }
  }
}
