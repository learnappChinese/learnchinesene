import 'dart:async';

import 'package:get/get.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/service/learning_reward_service.dart';
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
  final isCompleting = false.obs;
  final errorMessage = RxnString();
  final learningResult = Rxn<LearningResult>();
  final combo = 0.obs;
  final bestCombo = 0.obs;
  final LearningRewardService _rewardService = LearningRewardService();

  late String _attemptId;
  late DateTime _startedAt;
  bool _attemptStarted = false;

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
    if (_attemptStarted && !complete.value) {
      unawaited(
        _rewardService.abandonAttempt(
          _attemptId,
          metadata: const <String, dynamic>{'reason': 'review_closed'},
        ),
      );
    }
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
    combo.value = 0;
    bestCombo.value = 0;
    selected.value = null;
    complete.value = false;
    learningResult.value = null;
    errorMessage.value = null;
    _attemptId = 'review_${unitId}_${DateTime.now().microsecondsSinceEpoch}';
    _startedAt = DateTime.now();
    if (q.isNotEmpty) {
      await _rewardService.startReviewAttempt(
        sourceId: 'unit:$unitId',
        attemptId: _attemptId,
      );
      _attemptStarted = true;
    }
    loading.value = false;
  }

  Future<void> choose(QuizQuestion q, String value) async {
    if (selected.value != null) return;
    final correct = value == q.correctAnswer;
    selected.value = value;
    if (correct) {
      score.value++;
      combo.value++;
      if (combo.value > bestCombo.value) bestCombo.value = combo.value;
    } else {
      combo.value = 0;
    }
    await progress.submitAnswer(wordId: q.wordId, isCorrect: correct);
  }

  Future<void> next() async {
    if (index.value + 1 == questions.length) {
      if (isCompleting.value) return;
      isCompleting.value = true;
      errorMessage.value = null;
      try {
        learningResult.value = await _rewardService.processReviewReward(
          sourceId: 'unit:$unitId',
          attemptId: _attemptId,
          correctCount: score.value,
          wrongCount: questions.length - score.value,
          bestCombo: bestCombo.value,
          durationSeconds: DateTime.now().difference(_startedAt).inSeconds,
        );
        complete.value = true;
      } catch (error) {
        errorMessage.value = 'Không thể lưu kết quả ôn tập: $error';
      } finally {
        isCompleting.value = false;
      }
    } else {
      index.value++;
      selected.value = null;
    }
  }

  void playAudio(String? url) {
    if (url != null) audio.playUrl(url);
  }
}
