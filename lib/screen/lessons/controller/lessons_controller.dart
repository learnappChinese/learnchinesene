import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../../../core/services/gemini_service.dart';

class LessonsController extends GetxController {
  final GeminiService _gemini = Get.find<GeminiService>();
  final FlutterTts _tts = FlutterTts();

  final selectedLevel = 1.obs;

  final isTopicsLoading = false.obs;
  final isDetailLoading = false.obs;

  final topics = <Map<String, String>>[].obs;

  // Lesson detail fields
  final lessonTitle = ''.obs;
  final dialogue = <Map<String, String>>[].obs;
  final keyVocabulary = <Map<String, String>>[].obs;
  final grammarPoints = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _tts.setLanguage('zh-CN');
    _tts.setSpeechRate(0.85);
    loadTopics();
  }

  Future<void> speak(String text) async {
    if (text.trim().isNotEmpty) {
      await _tts.speak(text);
    }
  }

  Future<void> loadTopics() async {
    isTopicsLoading.value = true;
    topics.clear();

    try {
      final res = await _gemini.fetchLessonTopics(selectedLevel.value);
      topics.value = res.map((e) {
        final map = e as Map;
        return {
          'title': map['title']?.toString() ?? '',
          'description': map['description']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách bài học chủ đề.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isTopicsLoading.value = false;
    }
  }

  Future<void> loadLessonDetail(String topicTitle) async {
    isDetailLoading.value = true;
    lessonTitle.value = topicTitle;
    dialogue.clear();
    keyVocabulary.clear();
    grammarPoints.clear();

    try {
      final res =
          await _gemini.fetchLessonDetail(selectedLevel.value, topicTitle);

      final rawDialogue = res['dialogue'] as List<dynamic>? ?? [];
      dialogue.value = rawDialogue.map((e) {
        final map = e as Map;
        return {
          'speaker': map['speaker']?.toString() ?? '',
          'zh': map['zh']?.toString() ?? '',
          'pinyin': map['pinyin']?.toString() ?? '',
          'vi': map['vi']?.toString() ?? '',
        };
      }).toList();

      final rawVocab = res['key_vocabulary'] as List<dynamic>? ?? [];
      keyVocabulary.value = rawVocab.map((e) {
        final map = e as Map;
        return {
          'hanzi': map['hanzi']?.toString() ?? '',
          'pinyin': map['pinyin']?.toString() ?? '',
          'meaning_vi': map['meaning_vi']?.toString() ?? '',
        };
      }).toList();

      final rawGrammar = res['grammar_points'] as List<dynamic>? ?? [];
      grammarPoints.value = rawGrammar.map((e) {
        final map = e as Map;
        final rawExamples = map['examples'] as List<dynamic>? ?? [];
        final examples = rawExamples.map((ex) {
          final exMap = ex as Map;
          return {
            'zh': exMap['zh']?.toString() ?? '',
            'pinyin': exMap['pinyin']?.toString() ?? '',
            'vi': exMap['vi']?.toString() ?? '',
          };
        }).toList();

        return {
          'point': map['point']?.toString() ?? '',
          'explanation_vi': map['explanation_vi']?.toString() ?? '',
          'examples': examples,
        };
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạo nội dung bài học chi tiết.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDetailLoading.value = false;
    }
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}
