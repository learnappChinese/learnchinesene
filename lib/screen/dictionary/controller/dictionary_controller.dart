import 'package:get/get.dart';
import '../../../core/services/history_service.dart';

class DictionaryController extends GetxController {
  DictionaryController({required this.lookup, required this.saveHistory});
  final Future<Map<String, dynamic>> Function(String) lookup;
  final Future<void> Function(HistoryItem) saveHistory;
  final isLoading = false.obs;
  final error = ''.obs;
  final entry = Rxn<Map<String, dynamic>>();
  int _request = 0;

  Future<void> search(String input) async {
    final word = input.trim();
    if (word.isEmpty || isClosed) return;
    final request = ++_request;
    isLoading.value = true;
    error.value = '';
    entry.value = null;
    try {
      final result = await lookup(word);
      if (isClosed || request != _request) return;
      entry.value = result;
      await saveHistory(HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Từ điển',
        timestamp: DateTime.now().toIso8601String(),
        summary: 'Đã tra từ: "$word"',
        content: result,
      ));
    } catch (_) {
      if (!isClosed && request == _request) {
        error.value = 'Không thể tra cứu từ này. Vui lòng thử lại.';
      }
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }
}
