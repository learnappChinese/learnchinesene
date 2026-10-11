import 'package:get/get.dart';
import '../../../core/services/history_service.dart';
import '../data/hsk_quiz_repository.dart';
import '../domain/hsk_quiz_question_generator.dart';

enum QuizState { setup, playing, finished }

class HskQuizController extends GetxController {
  HskQuizController({
    Future<List<dynamic>> Function(int)? loadVocabulary,
    HskQuizRepository? repository,
    HistoryService? historyService,
  })  : _historyService = historyService,
        loadVocabulary = loadVocabulary ??
            ((lvl) => (repository ?? CloudHskQuizRepository())
                .loadHskVocabulary(lvl));

  final HistoryService? _historyService;
  final Future<List<dynamic>> Function(int) loadVocabulary;

  final state = QuizState.setup.obs;
  final questions = <dynamic>[].obs;
  final currentIndex = 0.obs;
  final score = 0.obs;
  final userAnswers = <String?>[].obs;
  final isLoading = false.obs;
  final selectedAnswer = RxnString();
  final error = RxnString();
  final currentLevel = 1.obs;

  Future<void> generate(int level) async {
    if (isClosed || isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    currentLevel.value = level;
    state.value = QuizState.setup;
    try {
      final vocabulary = await loadVocabulary(level);
      if (isClosed) return;
      final generated = HskQuizQuestionGenerator.generate(vocabulary);
      questions.assignAll(generated);
      currentIndex.value = 0;
      score.value = 0;
      userAnswers.assignAll(List.filled(generated.length, null));
      selectedAnswer.value = null;
      state.value = QuizState.playing;
    } catch (_) {
      if (!isClosed) {
        error.value = 'Lỗi tải bài trắc nghiệm HSK $level. Vui lòng thử lại.';
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void answer(String answer) {
    if (isClosed ||
        state.value != QuizState.playing ||
        selectedAnswer.value != null ||
        questions.isEmpty) {
      return;
    }
    selectedAnswer.value = answer;
    userAnswers[currentIndex.value] = answer;
    if (answer == questions[currentIndex.value]['correctAnswer']) score.value++;
  }

  void nextQuestion() {
    if (isClosed ||
        state.value != QuizState.playing ||
        selectedAnswer.value == null ||
        questions.isEmpty) {
      return;
    }
    if (currentIndex.value < questions.length - 1) {
      currentIndex.value++;
      selectedAnswer.value = null;
    } else {
      state.value = QuizState.finished;
      _recordPracticeResult();
    }
  }

  void _recordPracticeResult() {
    final history = _historyService ??
        (Get.isRegistered<HistoryService>()
            ? Get.find<HistoryService>()
            : null);
    if (history == null) return;

    try {
      final practicedWordIds = questions
          .map((q) => q['source_word_id'] ?? q['word_id'])
          .whereType<int>()
          .toList();

      history.saveHistory(
        HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Trắc nghiệm HSK',
          timestamp: DateTime.now().toIso8601String(),
          summary:
              'Trắc nghiệm HSK ${currentLevel.value}: Đạt ${score.value}/${questions.length}',
          content: {
            'level': currentLevel.value,
            'score': score.value,
            'total': questions.length,
            'word_ids': practicedWordIds,
            'mode': 'practice',
          },
        ),
      );
    } catch (_) {}
  }
}
