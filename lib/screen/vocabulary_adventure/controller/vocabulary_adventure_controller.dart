import 'dart:async';

import 'package:get/get.dart';

import '../../../core/learning/learning_rules_config.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../home/controller/home_controller.dart';
import '../data/vocabulary_adventure_repository.dart';
import '../model/vocabulary_adventure.dart';
import '../service/vocabulary_audio_service.dart';

class VocabularyAdventureController extends GetxController {
  VocabularyAdventureController({
    required this.levelId,
    required this.gameId,
    required this.gameName,
    required VocabularyAdventureRepository repository,
    required VocabularyAudioService audioService,
  })  : _repository = repository,
        _audioService = audioService;

  final String levelId;
  final int gameId;
  final String gameName;
  final VocabularyAdventureRepository _repository;
  final VocabularyAudioService _audioService;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final syncWarning = RxnString();
  final mission = Rxn<VocabularyMission>();
  final isIntroVisible = true.obs;
  final isCompleted = false.obs;
  final isFinishing = false.obs;
  final currentIndex = 0.obs;
  final selectedAnswer = RxnString();
  final feedback = Rxn<VocabularyAnswerFeedback>();
  final score = 0.obs;
  final xpEarned = 0.obs;
  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final combo = 0.obs;
  final bestCombo = 0.obs;
  final masteredWords = 0.obs;

  final Set<int> _newlyMasteredWordIds = {};
  final learningResult = Rxn<LearningResult>();
  final List<Future<void>> _pendingWrites = [];
  var _requestId = 0;

  VocabularyGameplayEvent? get currentEvent {
    final value = mission.value;
    if (value == null || value.events.isEmpty) return null;
    final index = currentIndex.value.clamp(0, value.events.length - 1);
    return value.events[index];
  }

  int get totalSteps => mission.value?.events.length ?? 0;
  int get visibleStep => totalSteps == 0 ? 0 : currentIndex.value + 1;

  int get accuracy {
    final total = correctCount.value + wrongCount.value;
    return total == 0 ? 100 : ((correctCount.value / total) * 100).round();
  }

  int get stars =>
      learningResult.value?.stars ??
      LearningRulesConfig.evaluateStars(accuracy / 100.0);

  @override
  void onInit() {
    super.onInit();
    loadMission();
  }

  Future<void> loadMission() async {
    final requestId = ++_requestId;
    isLoading.value = true;
    errorMessage.value = null;
    syncWarning.value = null;
    try {
      final loaded = await _repository.loadMission(
        levelId: levelId,
        gameId: gameId,
      );
      if (!_accepts(requestId)) return;
      mission.value = loaded;
      if (loaded == null) {
        _resetRun();
        return;
      }

      final active = await _repository.loadActiveRun(
        levelId: levelId,
        gameId: gameId,
      );
      if (!_accepts(requestId)) return;

      final maxIndex = loaded.events.length - 1;
      currentIndex.value =
          active == null ? 0 : active.currentIndex.clamp(0, maxIndex);
      score.value = active?.score ?? 0;
      xpEarned.value = active?.score ?? 0;
      correctCount.value = active?.correctCount ?? 0;
      wrongCount.value = active?.wrongCount ?? 0;
      isIntroVisible.value = active == null ||
          (active.currentIndex == 0 &&
              active.correctCount == 0 &&
              active.wrongCount == 0);
      isCompleted.value = false;
      isFinishing.value = false;
      selectedAnswer.value = null;
      feedback.value = null;
      combo.value = 0;
      bestCombo.value = 0;
      masteredWords.value = 0;
      _newlyMasteredWordIds.clear();
    } catch (_) {
      if (_accepts(requestId)) {
        errorMessage.value = 'Không thể mở nhiệm vụ từ vựng. Hãy thử lại nhé.';
        mission.value = null;
      }
    } finally {
      if (_accepts(requestId)) isLoading.value = false;
    }
  }

  void startMission() {
    isIntroVisible.value = false;
  }

  void clearSyncWarning() {
    syncWarning.value = null;
  }

  Future<void> speakCurrent({bool slow = false}) async {
    final event = currentEvent;
    if (event == null) return;
    try {
      await _audioService.speak(event.word.chinese, slow: slow);
    } catch (_) {
      if (!isClosed) {
        syncWarning.value = 'Chưa phát được âm thanh. Bạn có thể thử lại.';
      }
    }
  }

  Future<void> completeDiscovery() async {
    final event = currentEvent;
    if (event == null || !event.isDiscovery || isFinishing.value) return;
    score.value += event.xpReward;
    xpEarned.value += event.xpReward;
    await _advance();
  }

  void submitAnswer(String answer) {
    final event = currentEvent;
    if (event == null ||
        event.isDiscovery ||
        feedback.value != null ||
        isFinishing.value) {
      return;
    }

    selectedAnswer.value = answer;
    final isCorrect = answer == event.correctAnswer;
    feedback.value = isCorrect
        ? VocabularyAnswerFeedback.correct
        : VocabularyAnswerFeedback.wrong;

    if (isCorrect) {
      correctCount.value++;
      combo.value++;
      if (combo.value > bestCombo.value) bestCombo.value = combo.value;
      final comboBonus = combo.value >= 10
          ? 4
          : combo.value >= 5
              ? 2
              : 0;
      final gained = event.xpReward + comboBonus;
      score.value += gained;
      xpEarned.value += gained;
    } else {
      wrongCount.value++;
      combo.value = 0;
    }

    if (!isCorrect ||
        event.stage == VocabularyStage.recall ||
        event.stage == VocabularyStage.use) {
      _queueWordOutcome(event, isCorrect);
    }
    _queueSnapshot();
  }

  void retryCurrent() {
    if (feedback.value != VocabularyAnswerFeedback.wrong || isFinishing.value) {
      return;
    }
    selectedAnswer.value = null;
    feedback.value = null;
  }

  Future<void> continueAfterFeedback() async {
    if (feedback.value != VocabularyAnswerFeedback.correct ||
        isFinishing.value) {
      return;
    }
    await _advance();
  }

  Future<void> _advance() async {
    final value = mission.value;
    if (value == null || value.events.isEmpty) return;

    if (currentIndex.value < value.events.length - 1) {
      currentIndex.value++;
      selectedAnswer.value = null;
      feedback.value = null;
      await _saveSnapshot();
      return;
    }
    await _finishMission();
  }

  Future<void> _finishMission() async {
    if (isFinishing.value || isCompleted.value) return;
    isFinishing.value = true;
    var saved = false;
    try {
      await Future.wait(List<Future<void>>.from(_pendingWrites));
      final res = await _repository.completeMission(
        levelId: levelId,
        gameId: gameId,
        score: score.value,
        stars: stars,
        correctCount: correctCount.value,
        wrongCount: wrongCount.value,
        maxCombo: combo.value,
      );
      if (isClosed) return;
      learningResult.value = res;
      if (res != null && res.xpEarned > 0) {
        xpEarned.value = res.xpEarned;
      }
      isCompleted.value = true;
      saved = true;
    } catch (_) {
      if (!isClosed) {
        syncWarning.value = 'Kết quả chưa đồng bộ được. Hãy thử hoàn tất lại.';
      }
    } finally {
      if (!isClosed) isFinishing.value = false;
    }

    if (saved && !isClosed && Get.isRegistered<HomeController>()) {
      try {
        await Get.find<HomeController>().refreshStats();
      } catch (_) {
        if (!isClosed) {
          syncWarning.value =
              'Thống kê Home sẽ được cập nhật ở lần tải tiếp theo.';
        }
      }
    }
  }

  void _queueWordOutcome(VocabularyGameplayEvent event, bool isCorrect) {
    late final Future<void> write;
    write = _persistWordOutcome(event, isCorrect).whenComplete(
      () => _pendingWrites.remove(write),
    );
    _pendingWrites.add(write);
    unawaited(write);
  }

  Future<void> _persistWordOutcome(
    VocabularyGameplayEvent event,
    bool isCorrect,
  ) async {
    try {
      final update = await _repository.recordWordOutcome(
        wordId: event.word.id,
        isCorrect: isCorrect,
        masteryLevel: event.masteryLevel,
      );
      if (isClosed || update?.mastered != true) return;
      if (event.missionWord.progress.mastered) return;
      if (_newlyMasteredWordIds.add(event.word.id)) {
        masteredWords.value = _newlyMasteredWordIds.length;
      }
    } catch (_) {
      if (!isClosed) {
        syncWarning.value = 'Tiến độ từ này sẽ được đồng bộ khi bạn thử lại.';
      }
    }
  }

  void _queueSnapshot() {
    late final Future<void> write;
    write = _saveSnapshot().whenComplete(() => _pendingWrites.remove(write));
    _pendingWrites.add(write);
    unawaited(write);
  }

  Future<void> _saveSnapshot() async {
    try {
      await _repository.saveActiveRun(
        levelId: levelId,
        gameId: gameId,
        snapshot: VocabularyRunSnapshot(
          currentIndex: currentIndex.value,
          score: score.value,
          correctCount: correctCount.value,
          wrongCount: wrongCount.value,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        syncWarning.value = 'Run hiện tại chưa được đồng bộ lên cloud.';
      }
    }
  }

  void _resetRun() {
    currentIndex.value = 0;
    score.value = 0;
    xpEarned.value = 0;
    correctCount.value = 0;
    wrongCount.value = 0;
    combo.value = 0;
    bestCombo.value = 0;
    masteredWords.value = 0;
    selectedAnswer.value = null;
    feedback.value = null;
    isIntroVisible.value = true;
    isCompleted.value = false;
    isFinishing.value = false;
  }

  bool _accepts(int requestId) => !isClosed && requestId == _requestId;

  @override
  void onClose() {
    _requestId++;
    _audioService.dispose();
    super.onClose();
  }
}
