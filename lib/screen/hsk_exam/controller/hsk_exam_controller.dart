import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/ai/model/ai_gateway_exception.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/tts_service.dart';

class HskExamController extends GetxController {
  HskExamController({
    GeminiService? geminiService,
    HistoryService? historyService,
    TtsService? ttsService,
  })  : _gemini = geminiService ?? Get.find<GeminiService>(),
        _history = historyService ?? Get.find<HistoryService>(),
        _tts = ttsService ??
            (Get.isRegistered<TtsService>()
                ? Get.find<TtsService>()
                : TtsService());

  final GeminiService _gemini;
  final HistoryService _history;
  final TtsService _tts;

  final selectedLevel = 1.obs;

  // Exam state: 'notStarted', 'loading', 'started', 'submitting', 'submitted'
  final examState = 'notStarted'.obs;
  final questions = <Map<String, dynamic>>[].obs;
  final userAnswers = <String?>[].obs;

  // Analysis result
  final score = 0.obs;
  final analysisLoading = false.obs;
  final analysisError = RxnString();
  final overallAssessment = ''.obs;
  final strengths = <String>[].obs;
  final weaknesses = <String>[].obs;
  final studySuggestions = <String>[].obs;

  String? _currentAttemptId;

  Future<void> speak(String text) async {
    await _tts.speak(text, speechRate: 0.75);
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
    analysisError.value = null;
    _currentAttemptId = null;

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
    } catch (e) {
      debugPrint('Error generating exam: $e');
      examState.value = 'notStarted';
      final msg =
          e is AiGatewayException ? e.message : 'Không thể tạo đề thi thử: $e';
      Get.snackbar(
        'Lỗi',
        msg,
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

    // 1. Calculate deterministic objective score
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

    final attemptId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentAttemptId = attemptId;

    // 2. Persist raw exam score and answers BEFORE calling AI
    try {
      await _history.saveHistory(
        HistoryItem(
          id: attemptId,
          type: 'Thi HSK',
          timestamp: DateTime.now().toIso8601String(),
          summary:
              'Thi HSK ${selectedLevel.value}: Đạt ${score.value}/${questions.length}',
          content: {
            'level': selectedLevel.value,
            'score': score.value,
            'total': questions.length,
            'has_ai_analysis': false,
            'questions': questions.toList(),
            'userAnswers': userAnswers.toList(),
          },
        ),
      );
    } catch (e) {
      debugPrint('Failed to save raw exam history: $e');
    }

    // 3. Transition to submitted state so user sees verified score immediately
    examState.value = 'submitted';

    // 4. Request AI Performance Analysis
    await _runAiAnalysis(attemptId);
  }

  Future<void> _runAiAnalysis(String attemptId) async {
    analysisLoading.value = true;
    analysisError.value = null;

    Map<String, dynamic>? analysis;
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

      analysis = await _gemini.analyzeHskExamPerformance(
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

      // Update existing saved history item without duplicating
      await _history.updateHistoryContent(attemptId, {
        'has_ai_analysis': true,
        'analysis': analysis,
      });
    } catch (e) {
      final msg = e is AiGatewayException
          ? e.message
          : 'Không thể kết nối AI để tải phân tích chi tiết. Điểm thi (${score.value}/${questions.length}) đã được lưu an toàn.';
      analysisError.value = msg;
    } finally {
      analysisLoading.value = false;
    }
  }

  /// Retries AI analysis for the currently submitted exam without resubmitting
  /// or duplicating exam score/history items.
  Future<void> retryAnalysis() async {
    if (examState.value != 'submitted' ||
        questions.isEmpty ||
        analysisLoading.value) {
      return;
    }
    final attemptId =
        _currentAttemptId ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _runAiAnalysis(attemptId);
  }

  void reset() {
    examState.value = 'notStarted';
    questions.clear();
    userAnswers.clear();
    analysisError.value = null;
    _currentAttemptId = null;
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}
