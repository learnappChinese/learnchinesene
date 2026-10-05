import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/history_service.dart';

class ConversationsController extends GetxController {
  final GeminiService _gemini = Get.find<GeminiService>();
  final HistoryService _history = Get.find<HistoryService>();
  final FlutterTts _tts = FlutterTts();

  final selectedLevel = 1.obs;
  final topicController = TextEditingController();

  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final lines = <Map<String, dynamic>>[].obs;
  final currentTopic = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _tts.setLanguage('zh-CN');
    _tts.setSpeechRate(0.8);
  }

  Future<void> speak(String text) async {
    if (text.trim().isNotEmpty) {
      await _tts.speak(text);
    }
  }

  Future<void> startConversation() async {
    isLoading.value = true;
    lines.clear();
    currentTopic.value = '';

    final topic = topicController.text.trim();

    try {
      final res = await _gemini.fetchConversation(
          selectedLevel.value, topic.isEmpty ? null : topic);

      lines.assignAll(
          res.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      if (lines.isNotEmpty) {
        currentTopic.value = lines.first['topic'] ?? topic;
      }

      // Save to History
      await _history.saveHistory(
        HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Hội thoại',
          timestamp: DateTime.now().toIso8601String(),
          summary:
              'Hội thoại HSK ${selectedLevel.value}: ${currentTopic.value}',
          content: {
            'level': selectedLevel.value,
            'topic': currentTopic.value,
            'lines': lines
          },
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạo hội thoại từ AI. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreLines() async {
    if (lines.isEmpty || isMoreLoading.value) return;

    isMoreLoading.value = true;

    try {
      final res = await _gemini.fetchMoreConversationLines(
        lines,
        selectedLevel.value,
      );

      final newLines =
          res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      lines.addAll(newLines);
    } catch (e) {
      Get.snackbar(
        'Thông báo',
        'Không thể tải thêm dòng hội thoại tiếp theo.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isMoreLoading.value = false;
    }
  }

  @override
  void onClose() {
    topicController.dispose();
    _tts.stop();
    super.onClose();
  }
}
