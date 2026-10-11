import 'dart:async';

import 'package:get/get.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import 'duo_game_repository.dart';
import '../../../core/database/duo_db_helper.dart';
import '../../../core/services/speech_service.dart';
import '../../home/controller/home_controller.dart';

class DuoGameRunnerController extends GetxController {
  final int gameId;
  final String gameCode;
  final String levelId;
  final LearningRewardService _rewardService;

  DuoGameRunnerController({
    required this.gameId,
    required this.gameCode,
    required this.levelId,
    LearningRewardService? rewardService,
  }) : _rewardService = rewardService ?? LearningRewardService();

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final showMissionIntro = false.obs;

  // Danh sách các câu hỏi/thử thách
  final challenges = <dynamic>[].obs;

  final currentIndex = 0.obs;
  final isAnsweredCorrectly = RxnBool();

  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final score = 0.obs;
  final currentCombo = 0.obs;
  final bestCombo = 0.obs;
  final _pronunciationScores = <double>[];
  final _toneScores = <double>[];
  final _fluencyScores = <double>[];

  // Lưu danh sách câu sai để làm lại ở cuối
  final incorrectChallenges = <dynamic>[].obs;

  final isCompleted = false.obs;
  final calculatedStars = 0.obs;
  final finalScore = 0.obs;
  final rewardResult = Rxn<LearningResult>();

  late String _attemptId;
  late DateTime _startedAt;
  bool _isFinishing = false;
  bool _attemptStarted = false;

  @override
  void onInit() {
    super.onInit();
    initSession();
  }

  Future<void> initSession() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      // 1. Kiểm tra xem có session làm dở dang không
      final active =
          await DuoDbHelper.instance.getActiveSession(gameId, levelId);

      // Load questions tương ứng
      List<dynamic> list = [];
      if (gameCode == 'learn_words') {
        list = await DuoGameRepository.instance.getLearnWordsQuestions(levelId);
      } else if (gameCode == 'word_connect') {
        list =
            await DuoGameRepository.instance.getWordConnectQuestions(levelId);
      } else if (gameCode == 'select_answer') {
        list = await DuoGameRepository.instance.getSelectQuestions(levelId);
      } else if (gameCode == 'listen_select') {
        list = await DuoGameRepository.instance.getListenQuestions(levelId);
      } else if (gameCode == 'translate') {
        list = await DuoGameRepository.instance.getTranslateQuestions(levelId);
      } else if (gameCode == 'gap_fill') {
        list = await DuoGameRepository.instance.getGapFillQuestions(levelId);
      } else if (gameCode == 'tap_complete') {
        list =
            await DuoGameRepository.instance.getTapCompleteQuestions(levelId);
      } else if (gameCode == 'dialogue') {
        list = await DuoGameRepository.instance.getDialogueQuestions(levelId);
      } else if (gameCode == 'sentence_order') {
        list =
            await DuoGameRepository.instance.getSentenceOrderQuestions(levelId);
      } else if (gameCode == 'speaking') {
        list = await DuoGameRepository.instance.getSpeakingQuestions(levelId);
      }

      challenges.assignAll(list);

      if (active != null) {
        showMissionIntro.value = false;
        // Khôi phục session cũ
        currentIndex.value = active['current_index'] as int;
        score.value = active['score'] as int;
        correctCount.value = active['correct_count'] as int;
        wrongCount.value = active['wrong_count'] as int;
        _attemptId = '${active['attempt_id'] ?? ''}'.trim();
        if (_attemptId.isEmpty) _attemptId = _newAttemptId();
        _startedAt =
            DateTime.tryParse('${active['started_at'] ?? ''}')?.toLocal() ??
                DateTime.now();
      } else {
        showMissionIntro.value = true;
        currentIndex.value = 0;
        correctCount.value = 0;
        wrongCount.value = 0;
        score.value = 0;
        _attemptId = _newAttemptId();
        _startedAt = DateTime.now();
      }

      currentCombo.value = 0;
      bestCombo.value = 0;
      _pronunciationScores.clear();
      _toneScores.clear();
      _fluencyScores.clear();
      incorrectChallenges.clear();
      rewardResult.value = null;

      await _rewardService.startDuoGameAttempt(
        gameId: gameId,
        gameCode: gameCode,
        levelId: levelId,
        attemptId: _attemptId,
      );
      _attemptStarted = true;
      await _saveSession();

      isCompleted.value = false;
      _resetTurn();
    } catch (e) {
      errorMessage.value = 'Không thể tải nhiệm vụ. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retrySession() async {
    isCompleted.value = false;
    rewardResult.value = null;
    _attemptStarted = false;
    await initSession();
  }

  void startMission() => showMissionIntro.value = false;

  void _resetTurn() {
    isAnsweredCorrectly.value = null;
  }

  // Gửi câu trả lời
  void submitAnswer(bool isCorrect) async {
    if (isAnsweredCorrectly.value != null) return;

    isAnsweredCorrectly.value = isCorrect;

    if (isCorrect) {
      correctCount.value++;
      score.value += 10;
      currentCombo.value++;
      if (currentCombo.value > bestCombo.value) {
        bestCombo.value = currentCombo.value;
      }
    } else {
      wrongCount.value++;
      currentCombo.value = 0;
      incorrectChallenges.add(challenges[currentIndex.value]);
    }

    // Tự động lưu session dở dang vào Supabase (guest dùng local fallback)
    await _saveSession();
  }

  void submitSpeakingResult(SpeechResult result) {
    if (result.pronunciationScore != null) {
      _pronunciationScores.add(result.pronunciationScore!);
    }
    if (result.toneScore != null) _toneScores.add(result.toneScore!);
    if (result.fluencyScore != null) {
      _fluencyScores.add(result.fluencyScore!);
    }
    submitAnswer(result.isCorrect);
  }

  void nextChallenge() async {
    if (currentIndex.value < challenges.length - 1) {
      currentIndex.value++;
      _resetTurn();

      // Cập nhật session dở dang
      await _saveSession();
    } else {
      // Nếu có câu sai -> cho làm lại các câu sai
      if (incorrectChallenges.isNotEmpty) {
        challenges.assignAll(incorrectChallenges.toList());
        incorrectChallenges.clear();
        currentIndex.value = 0;
        _resetTurn();
      } else {
        _finishSession();
      }
    }
  }

  Future<void> _finishSession() async {
    if (_isFinishing) return;
    _isFinishing = true;
    try {
      final reward = await _rewardService.processDuoGameReward(
        gameId: gameId,
        gameCode: gameCode,
        levelId: levelId,
        attemptId: _attemptId,
        correctCount: correctCount.value,
        wrongCount: wrongCount.value,
        score: score.value,
        maxCombo: bestCombo.value,
        durationSeconds: DateTime.now().difference(_startedAt).inSeconds,
        pronunciationScore: _average(_pronunciationScores),
        toneScore: _average(_toneScores),
        fluencyScore: _average(_fluencyScores),
      );

      rewardResult.value = reward;
      calculatedStars.value = reward.stars;
      finalScore.value = reward.score.toInt();
      isCompleted.value = true;

      // Xóa session dở dang vì đã hoàn thành
      if (!DuoDbHelper.instance.isSignedIn) {
        await DuoDbHelper.instance.clearActiveSession(gameId, levelId);

        // Lưu kết quả tiến trình & mở khóa màn sau
        await DuoGameRepository.instance.saveProgress(
          gameId,
          levelId,
          reward.score.toInt(),
          reward.stars,
          reward.passed,
        );

        if (reward.passed) await _unlockNextGuestLevel();
      }

      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshStats();
      }

      // Xử lý logic Unlock Level kế tiếp nếu thi đỗ
    } catch (error) {
      errorMessage.value =
          'Không thể lưu kết quả. Tiến trình chưa bị cộng trùng; hãy thử lại.';
    } finally {
      _isFinishing = false;
    }
  }

  // Phương thức tìm và unlock level kế tiếp (bỏ qua các level bị Empty)
  Future<void> _unlockNextGuestLevel() async {
    final levels = await DuoDbHelper.instance.getGamePath(gameId, gameCode);
    bool foundCurrent = false;

    for (var l in levels) {
      final id = l['level_id'] as String;
      final cCount = l['challenge_count'] as int;

      if (foundCurrent) {
        if (cCount > 0) {
          await DuoDbHelper.instance.unlockLevel(gameId, id);
          break;
        }
      } else if (id == levelId) {
        foundCurrent = true;
      }
    }
  }

  Future<void> _saveSession() => DuoDbHelper.instance.saveActiveSession(
        gameId,
        levelId,
        currentIndex.value,
        score.value,
        correctCount.value,
        wrongCount.value,
        _attemptId,
      );

  String _newAttemptId() =>
      'duo_${gameId}_${levelId}_${DateTime.now().microsecondsSinceEpoch}';

  double? _average(List<double> values) => values.isEmpty
      ? null
      : values.reduce((left, right) => left + right) / values.length;

  @override
  void onClose() {
    if (_attemptStarted && !isCompleted.value) {
      unawaited(
        _rewardService.abandonAttempt(
          _attemptId,
          metadata: const <String, dynamic>{'reason': 'runner_closed'},
        ),
      );
    }
    super.onClose();
  }
}
