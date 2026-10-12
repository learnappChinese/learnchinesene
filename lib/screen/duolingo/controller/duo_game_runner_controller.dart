import 'dart:async';

import 'package:get/get.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../../../core/learning/service/learning_session_composer.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/models/duo_flashcard.dart';
import 'duo_game_repository.dart';
import '../../../core/database/duo_db_helper.dart';
import '../../../core/services/speech_service.dart';

class DuoGameRunnerController extends GetxController {
  final int gameId;
  final String gameCode;
  final String levelId;
  final String? unitId;
  final LearningRewardService _rewardService;
  final LearningSessionComposer _sessionComposer;

  DuoGameRunnerController({
    required this.gameId,
    required this.gameCode,
    required this.levelId,
    this.unitId,
    LearningRewardService? rewardService,
    LearningSessionComposer? sessionComposer,
  })  : _rewardService = rewardService ?? LearningRewardService(),
        _sessionComposer = sessionComposer ??
            (Get.isRegistered<LearningSessionComposer>()
                ? Get.find<LearningSessionComposer>()
                : LearningSessionComposer());

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
      final resolvedUnitId = (unitId != null && unitId!.isNotEmpty)
          ? unitId!
          : (levelId.contains('_') ? levelId.split('_').first : levelId);

      final sourceContext = LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: resolvedUnitId,
        levelId: levelId,
        gameCode: gameCode,
        mode: LearningMode.duoMission,
      );

      final session = await _sessionComposer.composeSession(
        sourceContext: sourceContext,
        gameId: gameId,
      );

      challenges.assignAll(session.items.map((i) => i.payload).toList());

      if (session.isResumed) {
        showMissionIntro.value = false;
        currentIndex.value = session.currentIndex;
        score.value = session.score;
        correctCount.value = session.correctCount;
        wrongCount.value = session.wrongCount;
        _attemptId = session.sessionId;
        _startedAt = session.startedAt;
      } else {
        showMissionIntro.value = true;
        currentIndex.value = 0;
        correctCount.value = 0;
        wrongCount.value = 0;
        score.value = 0;
        _attemptId = session.sessionId;
        _startedAt = session.startedAt;
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
        unitId: resolvedUnitId,
      );
      _attemptStarted = true;
      await _saveSession();

      isCompleted.value = false;
      _resetTurn();
    } on ContentUnavailableException catch (e) {
      errorMessage.value = e.message;
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
      final resolvedUnitId = (unitId != null && unitId!.isNotEmpty)
          ? unitId!
          : (levelId.contains('_') ? levelId.split('_').first : levelId);

      final reward = await _rewardService.processDuoGameReward(
        gameId: gameId,
        gameCode: gameCode,
        levelId: levelId,
        unitId: resolvedUnitId,
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

        if (reward.passed) await _unlockNextGuestLevel(reward);
      }

      // Xử lý logic Unlock Level kế tiếp nếu thi đỗ
    } catch (error) {
      errorMessage.value =
          'Không thể lưu kết quả. Tiến trình chưa bị cộng trùng; hãy thử lại.';
    } finally {
      _isFinishing = false;
    }
  }

  // Phương thức tìm và unlock level kế tiếp theo server contract hoặc canonical unit path
  Future<void> _unlockNextGuestLevel(LearningResult reward) async {
    if (reward.nextNodeId != null && reward.nextNodeId!.isNotEmpty) {
      if (reward.nextNodeId!.startsWith('boss:')) {
        return; // Boss gate ready
      }
      final parts = reward.nextNodeId!.split(':');
      if (parts.length == 2) {
        final nextGameId = int.tryParse(parts[0]);
        final nextLevelId = parts[1];
        if (nextGameId != null && nextLevelId.isNotEmpty) {
          await DuoDbHelper.instance.unlockLevel(nextGameId, nextLevelId);
          return;
        }
      }
    }

    final resolvedUnitId = (unitId != null && unitId!.isNotEmpty)
        ? unitId!
        : (levelId.contains('_') ? levelId.split('_').first : levelId);

    try {
      final unitPath =
          await DuoDbHelper.instance.getUnitLearningPath(resolvedUnitId);
      final learningNodes =
          unitPath.where((r) => r['node_type'] == 'learning').toList();
      final currentIndex = learningNodes.indexWhere(
        (r) =>
            ((r['game_id'] as num?)?.toInt() == gameId) &&
            ('${r['level_id'] ?? ''}' == levelId),
      );

      if (currentIndex >= 0 && currentIndex + 1 < learningNodes.length) {
        final nextNode = learningNodes[currentIndex + 1];
        final nextGameId = (nextNode['game_id'] as num?)?.toInt();
        final nextLevelId = '${nextNode['level_id'] ?? ''}';
        if (nextGameId != null && nextLevelId.isNotEmpty) {
          await DuoDbHelper.instance.unlockLevel(nextGameId, nextLevelId);
          return;
        }
      }
    } catch (_) {}

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

  Future<void> _saveSession() {
    final challengeIds = challenges
        .map((c) {
          if (c is DuoChallenge) return c.id;
          if (c is DuoFlashcard) return '${c.id}';
          if (c is Map && c['id'] != null) return '${c['id']}';
          return null;
        })
        .whereType<String>()
        .toList();

    return DuoDbHelper.instance.saveActiveSession(
      gameId,
      levelId,
      currentIndex.value,
      score.value,
      correctCount.value,
      wrongCount.value,
      _attemptId,
      challengeIds: challengeIds.isNotEmpty ? challengeIds : null,
    );
  }

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
