import 'dart:async';

import 'package:get/get.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/models/example_sentence.dart';
import '../../../core/models/hsk_level.dart';
import '../../../core/models/word.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/tts_service.dart';

class LessonsController extends GetxController {
  LessonsController({DbHelper? database, TtsService? tts})
      : _database = database ?? DbHelper.instance,
        _tts = tts ?? Get.find<TtsService>();

  final DbHelper _database;
  final GeminiService _gemini = Get.find<GeminiService>();
  final TtsService _tts;

  final selectedLevel = 1.obs;
  final levels = <HskLevel>[].obs;

  final isTopicsLoading = false.obs;
  final isDetailLoading = false.obs;

  /// Curriculum units from Supabase.
  ///
  /// Map keys are kept string-based to preserve the existing presentation API:
  /// unit_id, title, description.
  final topics = <Map<String, String>>[].obs;

  final lessonTitle = ''.obs;
  final dialogue = <Map<String, String>>[].obs;
  final keyVocabulary = <Map<String, String>>[].obs;
  final grammarPoints = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCurriculum();
  }

  Future<void> speak(String text) async {
    if (text.trim().isNotEmpty) {
      await _tts.speakChinese(text);
    }
  }

  Future<void> loadCurriculum() async {
    isTopicsLoading.value = true;
    try {
      final cloudLevels = await _database.getHskLevels();
      levels.assignAll(cloudLevels);

      if (levels.isEmpty) {
        topics.clear();
        return;
      }

      final hasSelected =
          levels.any((level) => level.id == selectedLevel.value);
      if (!hasSelected) {
        selectedLevel.value = levels.first.id;
      }

      await _loadTopicsForSelectedLevel();
    } catch (_) {
      topics.clear();
      Get.snackbar(
        'Lỗi dữ liệu',
        'Không thể tải lộ trình bài học từ Supabase.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isTopicsLoading.value = false;
    }
  }

  Future<void> loadTopics() async {
    isTopicsLoading.value = true;
    try {
      await _loadTopicsForSelectedLevel();
    } catch (_) {
      topics.clear();
      Get.snackbar(
        'Lỗi dữ liệu',
        'Không thể tải Unit của cấp độ đã chọn.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isTopicsLoading.value = false;
    }
  }

  Future<void> _loadTopicsForSelectedLevel() async {
    final units = await _database.getUnitsByLevel(selectedLevel.value);
    topics.assignAll(
      units.map(
        (unit) => <String, String>{
          'unit_id': '${unit.id}',
          'title': unit.title,
          'description':
              'Unit ${unit.order} • Nội dung học lấy trực tiếp từ Supabase',
        },
      ),
    );
  }

  Future<void> loadLessonDetail(String topicTitle) async {
    isDetailLoading.value = true;
    lessonTitle.value = topicTitle;
    dialogue.clear();
    keyVocabulary.clear();
    grammarPoints.clear();

    try {
      final topic = topics.firstWhereOrNull(
        (item) => item['title'] == topicTitle,
      );
      final unitId = int.tryParse(topic?['unit_id'] ?? '');

      if (unitId == null) {
        throw StateError('Không tìm thấy Unit trong curriculum.');
      }

      final results = await Future.wait<Object>([
        _database.getWordsByUnit(unitId),
        _database.getExamplesByUnit(unitId),
        _database.getUnitMetrics(unitId),
      ]);

      final words = results[0] as List<Word>;
      final examples = results[1] as List<ExampleSentence>;
      final metrics = results[2] as Map<String, int>;

      keyVocabulary.assignAll(
        [
          for (final word in words)
            <String, String>{
              'word_id': '${word.id}',
              'hanzi': word.chinese,
              'pinyin': word.pinyin,
              'meaning_vi': word.vietnamese,
              'tts_url': word.ttsUrl,
            },
        ],
      );

      dialogue.assignAll(
        [
          for (var i = 0; i < examples.length; i++)
            <String, String>{
              'example_id': '${examples[i].id}',
              'speaker': i.isEven ? 'A' : 'B',
              'zh': examples[i].chinese,
              'pinyin': examples[i].pinyin,
              'vi': examples[i].vietnamese,
            },
        ],
      );

      grammarPoints.assignAll([
        <String, dynamic>{
          'point': 'Nội dung Unit',
          'explanation_vi':
              '${metrics['words'] ?? words.length} từ vựng • '
              '${metrics['examples'] ?? examples.length} câu ví dụ • '
              '${metrics['learned'] ?? 0} từ đã học.',
          'examples': [
            for (final example in examples.take(5))
              <String, String>{
                'zh': example.chinese,
                'pinyin': example.pinyin,
                'vi': example.vietnamese,
              },
          ],
        },
      ]);

      // Supabase is the source of truth. AI only enriches the grammar tab.
      unawaited(_loadGrammarEnrichment(topicTitle));
    } catch (_) {
      Get.snackbar(
        'Lỗi bài học',
        'Không thể tải nội dung Unit từ Supabase.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> _loadGrammarEnrichment(String topicTitle) async {
    try {
      final res =
          await _gemini.fetchLessonDetail(selectedLevel.value, topicTitle);
      final rawGrammar = res['grammar_points'] as List<dynamic>? ?? [];
      if (rawGrammar.isEmpty) return;

      final aiGrammar = rawGrammar.map((e) {
        final map = e as Map;
        final rawExamples = map['examples'] as List<dynamic>? ?? [];
        final examples = rawExamples.map((ex) {
          final exMap = ex as Map;
          return <String, String>{
            'zh': exMap['zh']?.toString() ?? '',
            'pinyin': exMap['pinyin']?.toString() ?? '',
            'vi': exMap['vi']?.toString() ?? '',
          };
        }).toList();

        return <String, dynamic>{
          'point': map['point']?.toString() ?? '',
          'explanation_vi': map['explanation_vi']?.toString() ?? '',
          'examples': examples,
        };
      }).toList();

      if (!isClosed && lessonTitle.value == topicTitle) {
        grammarPoints.assignAll(aiGrammar);
      }
    } catch (_) {
      // Database lesson remains fully usable when AI enrichment is unavailable.
    }
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}
