import 'package:get/get.dart';
import '../../../core/models/quiz_question.dart';
import '../../../core/models/word.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/quiz_service.dart';

class QuizController extends GetxController {
  final quiz = QuizService();
  final progress = ProgressService();
  final audio = AudioService();

  int unitId = 0;
  String title = 'Bài học';
  List<Word> reviewWords = [];

  final questions = <QuizQuestion>[].obs;
  final index = 0.obs;
  final score = 0.obs;
  final selected = RxnString();
  final loading = true.obs;
  final complete = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    unitId = (args?['unitId'] as int?) ?? 0;
    title = '${args?['unitTitle'] ?? 'Bài học'}';
    reviewWords = (args?['reviewWords'] as List<Word>?) ?? [];
    load();
  }

  @override
  void onClose() {
    audio.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    final q = reviewWords.isNotEmpty
        ? await quiz.generateForWords(reviewWords)
        : await quiz.generateForUnit(unitId);

    questions.value = q;
    index.value = 0;
    score.value = 0;
    selected.value = null;
    complete.value = false;
    loading.value = false;
  }

  Future<void> choose(QuizQuestion q, String value) async {
    if (selected.value != null) return;
    final correct = value == q.correctAnswer;
    selected.value = value;
    if (correct) score.value++;
    await progress.submitAnswer(wordId: q.wordId, isCorrect: correct);
  }

  void next() {
    if (index.value + 1 == questions.length) {
      complete.value = true;
    } else {
      index.value++;
      selected.value = null;
    }
  }

  void playAudio(String? url) {
    if (url != null) audio.playUrl(url);
  }
}
