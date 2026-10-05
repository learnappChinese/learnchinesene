import 'package:get/get.dart';
import '../domain/hsk_quiz_question_generator.dart';

enum QuizState { setup, playing, finished }

class HskQuizController extends GetxController {
  HskQuizController({required this.loadVocabulary});
  final Future<List<dynamic>> Function(int) loadVocabulary;
  final state = QuizState.setup.obs;
  final questions = <dynamic>[].obs;
  final currentIndex = 0.obs;
  final score = 0.obs;
  final userAnswers = <String?>[].obs;
  final isLoading = false.obs;
  final selectedAnswer = RxnString();
  final error = RxnString();

  Future<void> generate(int level) async {
    if (isClosed || isLoading.value) return;
    isLoading.value = true;
    error.value = null;
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
    }
  }
}
