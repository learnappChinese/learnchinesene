import 'package:get/get.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/tts_service.dart';

class HskExamController extends GetxController {
  HskExamController({TtsService? tts}) : _tts = tts ?? Get.find<TtsService>();

  final GeminiService _gemini = Get.find<GeminiService>();
  final HistoryService _history = Get.find<HistoryService>();
  final TtsService _tts;

  final selectedLevel = 1.obs;

  // Exam state
  final examState =
      'notStarted'.obs; // notStarted, loading, started, submitting, submitted
  final questions = <Map<String, dynamic>>[].obs;
  final userAnswers = <String?>[].obs;

  // Analysis result
  final score = 0.obs;
  final analysisLoading = false.obs;
  final overallAssessment = ''.obs;
  final strengths = <String>[].obs;
  final weaknesses = <String>[].obs;
  final studySuggestions = <String>[].obs;

  Future<void> speak(String text) async {
    if (text.trim().isNotEmpty) {
      await _tts.speakChinese(text);
    }
  }

  Future<void> generateExam() async {
    examState.value = 'loading';
    questions.clear();
    userAnswers.clear();
    score.value = 0;
    overallAssessment.value = '';
    strengths.clear();
    weaknesses.clear();
    studySuggestions.clear();

    try {
      final res = await _gemini.fetchHskExam(selectedLevel.value);

      questions.assignAll(res.map((e) {
        final map = e as Map;
        final rawOptions = map['options'] as List<dynamic>? ?? [];
        return {
          'section': map['section']?.toString() ?? '',
          'question_text': map['question_text']?.toString() ?? '',
          'audio_script': map['audio_script']?.toString(),
          'options': rawOptions.map((opt) => opt.toString()).toList(),
          'correct_answer': map['correct_answer']?.toString() ?? '',
          'explanation': map['explanation']?.toString() ?? '',
        };
      }).toList());

      userAnswers.assignAll(List<String?>.filled(questions.length, null));
      examState.value = 'started';
    } catch (e, stack) {
      print('=== ERROR GENERATING EXAM ===');
      print(e);
      print(stack);
      examState.value = 'notStarted';
      Get.snackbar(
        'Lỗi',
        'Không thể tạo đề thi thử: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectOption(int questionIndex, String option) {
    if (examState.value == 'started') {
      userAnswers[questionIndex] = option;
    }
  }

  Future<void> submitExam() async {
    if (examState.value != 'started') return;

    examState.value = 'submitting';

    // Calculate score
    int correctCount = 0;
    for (int i = 0; i < questions.length; i++) {
      final correct =
          questions[i]['correct_answer'].toString().trim().toLowerCase();
      final userAns = userAnswers[i]?.trim().toLowerCase() ?? '';
      if (correct == userAns && correct.isNotEmpty) {
        correctCount++;
      }
    }
    score.value = correctCount;

    // Get Gemini Analysis
    analysisLoading.value = true;
    examState.value = 'submitted';

    try {
      final formattedQnA = <Map<String, dynamic>>[];
      for (int i = 0; i < questions.length; i++) {
        formattedQnA.add({
          'question_text': questions[i]['question_text'],
          'section': questions[i]['section'],
          'user_answer': userAnswers[i],
          'correct_answer': questions[i]['correct_answer'],
        });
      }

      final analysis = await _gemini.analyzeHskExamPerformance(
        level: selectedLevel.value,
        questionsAndAnswers: formattedQnA,
        score: score.value,
        totalQuestions: questions.length,
      );

      overallAssessment.value = analysis['overall_assessment'] ?? '';
      final rawStrengths = analysis['strengths'] as List<dynamic>? ?? [];
      strengths.assignAll(rawStrengths.map((e) => e.toString()).toList());

      final rawWeaknesses = analysis['weaknesses'] as List<dynamic>? ?? [];
      weaknesses.assignAll(rawWeaknesses.map((e) => e.toString()).toList());

      final rawSuggestions =
          analysis['study_suggestions'] as List<dynamic>? ?? [];
      studySuggestions
          .assignAll(rawSuggestions.map((e) => e.toString()).toList());

      // Save to History
      await _history.saveHistory(
        HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Thi HSK',
          timestamp: DateTime.now().toIso8601String(),
          summary:
              'Thi HSK ${selectedLevel.value}: Đạt ${score.value}/${questions.length}',
          content: {
            'level': selectedLevel.value,
            'score': score.value,
            'total': questions.length,
            'analysis': analysis,
            'questions': questions,
            'userAnswers': userAnswers,
          },
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Thông báo',
        'Đã chấm điểm thành công, nhưng không thể tải phân tích chi tiết từ AI.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      analysisLoading.value = false;
    }
  }

  void reset() {
    examState.value = 'notStarted';
    questions.clear();
    userAnswers.clear();
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}
