import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../data/boss_battle_repository.dart';
import '../domain/boss_battle_question_generator.dart';
import '../domain/boss_battle_rules.dart';
import '../model/boss_battle_question.dart';
import '../model/boss_battle_stage.dart';

enum BossBattlePhase {
  loading,
  intro,
  question,
  resolving,
  playerAttack,
  bossAttack,
  transition,
  won,
  lost,
  reward,
  result,
  error,
}

class BossBattleController extends GetxController {
  BossBattleController({
    required BossBattleQuestionSource source,
    BossBattleQuestionGenerator? generator,
    BossBattleRules? rules,
    LearningRewardService? rewardService,
    this.stage,
    this.resolveDelay = const Duration(milliseconds: 220),
    this.attackDelay = const Duration(milliseconds: 560),
    this.transitionDelay = const Duration(milliseconds: 460),
  })  : _source = source,
        _generator = generator ?? BossBattleQuestionGenerator(),
        _rules = rules ?? const BossBattleRules(),
        _rewardService = rewardService ?? LearningRewardService();

  static const int maxBossHp = 100;
  static const int maxPlayerHp = 100;

  final BossBattleQuestionSource _source;
  final BossBattleQuestionGenerator _generator;
  final BossBattleRules _rules;
  final LearningRewardService _rewardService;
  final BossBattleStage? stage;

  final Duration resolveDelay;
  final Duration attackDelay;
  final Duration transitionDelay;

  final phase = BossBattlePhase.loading.obs;
  final questions = <BossBattleQuestion>[].obs;
  final currentIndex = 0.obs;
  final bossHp = maxBossHp.obs;
  final playerHp = maxPlayerHp.obs;
  final combo = 0.obs;
  final maxCombo = 0.obs;
  final score = 0.obs;
  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final isInputLocked = true.obs;
  final selectedAnswer = RxnString();
  final lastAnswerCorrect = RxnBool();
  final errorMessage = ''.obs;
  final sessionId = ''.obs;
  final lastBossDamage = 0.obs;
  final lastPlayerDamage = 0.obs;
  final rewardResult = Rxn<LearningResult>();

  int _flowToken = 0;
  DateTime? _startedAt;
  bool _attemptStarted = false;

  BossBattleQuestion? get currentQuestion {
    final index = currentIndex.value;
    if (index < 0 || index >= questions.length) return null;
    return questions[index];
  }

  int get questionNumber =>
      questions.isEmpty ? 0 : min(currentIndex.value + 1, questions.length);

  int get bossHpMax => stage?.bossHp ?? maxBossHp;

  int get playerHpMax => stage?.playerHp ?? maxPlayerHp;

  String get bossName => stage?.bossName ?? 'Rồng Lửa';

  int get bossLevel => stage?.difficulty ?? 3;

  String get stageLabel => stage?.label ?? 'Đấu tự do';

  double get bossHealthFraction =>
      (bossHp.value / bossHpMax).clamp(0.0, 1.0).toDouble();

  double get playerHealthFraction =>
      (playerHp.value / playerHpMax).clamp(0.0, 1.0).toDouble();

  bool get battleFinished =>
      phase.value == BossBattlePhase.result ||
      phase.value == BossBattlePhase.won ||
      phase.value == BossBattlePhase.lost;

  bool get canAnswer =>
      phase.value == BossBattlePhase.question &&
      !isInputLocked.value &&
      currentQuestion != null;

  String get phaseHint {
    switch (phase.value) {
      case BossBattlePhase.question:
        return 'Chạm một đáp án để ra đòn';
      case BossBattlePhase.resolving:
        return 'Đang kiểm tra đáp án...';
      case BossBattlePhase.playerAttack:
        return 'Đòn của bạn đang trúng boss!';
      case BossBattlePhase.bossAttack:
        return 'Boss đang phản công!';
      case BossBattlePhase.transition:
        return 'Chuẩn bị câu tiếp theo...';
      default:
        return '';
    }
  }

  String get feedbackText {
    final result = lastAnswerCorrect.value;
    final question = currentQuestion;
    if (result == null || question == null) return '';
    if (result) return 'Chính xác! Tung đòn!';
    return 'Đáp án đúng: ${question.correctAnswer}';
  }

  @override
  void onInit() {
    super.onInit();
    startBattle();
  }

  Future<void> startBattle() async {
    final token = ++_flowToken;
    _resetState();
    sessionId.value = 'boss_${DateTime.now().microsecondsSinceEpoch}';
    _startedAt = DateTime.now();
    phase.value = BossBattlePhase.loading;

    try {
      final requested =
          stage == null ? 16 : min(16, max(3, stage!.questionCount));
      final seeds = await _source.loadQuestionSeeds(
        limit: stage == null ? 48 : requested,
        stageId: stage?.id,
      );
      if (token != _flowToken) return;

      final built = _generator.build(
        seeds,
        count: min(requested, seeds.length),
      );
      if (built.isEmpty) {
        throw StateError('No usable Boss Battle questions found.');
      }

      questions.assignAll(built);
      try {
        await _rewardService.startBossAttempt(
          stageId: stage?.id ?? 0,
          attemptId: sessionId.value,
        );
        _attemptStarted = true;
      } catch (_) {
        // Gameplay can start offline; completion retains the same attempt id.
      }
      if (token != _flowToken) return;
      phase.value = BossBattlePhase.intro;
      isInputLocked.value = true;
    } catch (_) {
      if (token != _flowToken) return;
      errorMessage.value =
          'Không thể tải câu hỏi Boss Battle từ dữ liệu hiện tại.';
      phase.value = BossBattlePhase.error;
      isInputLocked.value = true;
    }
  }

  void beginBattle() {
    if (phase.value != BossBattlePhase.intro || questions.isEmpty) return;
    selectedAnswer.value = null;
    lastAnswerCorrect.value = null;
    phase.value = BossBattlePhase.question;
    isInputLocked.value = false;
  }

  Future<void> answer(String answer) async {
    if (!canAnswer) return;

    final question = currentQuestion;
    if (question == null) return;

    final token = _flowToken;
    final isCorrect = answer == question.correctAnswer;

    isInputLocked.value = true;
    selectedAnswer.value = answer;
    lastAnswerCorrect.value = isCorrect;
    phase.value = BossBattlePhase.resolving;

    if (!await _wait(resolveDelay, token)) return;

    if (isCorrect) {
      correctCount.value += 1;
      combo.value += 1;
      maxCombo.value = max(maxCombo.value, combo.value);
      score.value += _rules.scoreForCorrect(combo.value);
      lastBossDamage.value = _rules.damageToBoss(combo.value);
      lastPlayerDamage.value = 0;
      phase.value = BossBattlePhase.playerAttack;

      if (!await _wait(attackDelay, token)) return;

      bossHp.value = max(
        0,
        bossHp.value - lastBossDamage.value,
      );

      if (bossHp.value <= 0) {
        await _finish(won: true, token: token);
        return;
      }
    } else {
      wrongCount.value += 1;
      combo.value = 0;
      lastPlayerDamage.value = min(
        34,
        _rules.damageToPlayer() + max(0, bossLevel - 1) * 2,
      );
      lastBossDamage.value = 0;
      phase.value = BossBattlePhase.bossAttack;

      if (!await _wait(attackDelay, token)) return;

      playerHp.value = max(
        0,
        playerHp.value - lastPlayerDamage.value,
      );

      if (playerHp.value <= 0) {
        await _finish(won: false, token: token);
        return;
      }
    }

    phase.value = BossBattlePhase.transition;
    if (!await _wait(transitionDelay, token)) return;
    await _advanceQuestion(token);
  }

  Future<void> _advanceQuestion(int token) async {
    if (token != _flowToken) return;

    final nextIndex = currentIndex.value + 1;
    if (nextIndex >= questions.length) {
      await _finish(
        won: bossHp.value <= 0 && playerHp.value > 0,
        token: token,
      );
      return;
    }

    currentIndex.value = nextIndex;
    selectedAnswer.value = null;
    lastAnswerCorrect.value = null;
    phase.value = BossBattlePhase.question;
    isInputLocked.value = false;
  }

  Future<void> _finish({
    required bool won,
    required int token,
  }) async {
    if (token != _flowToken) return;

    isInputLocked.value = true;
    phase.value = won ? BossBattlePhase.won : BossBattlePhase.lost;

    final stageId = stage?.id ?? 0;

    try {
      final result = await _rewardService.processBossReward(
        stageId: stageId,
        attemptId: sessionId.value,
        score: score.value,
        correctCount: correctCount.value,
        wrongCount: wrongCount.value,
        bestCombo: maxCombo.value,
        playerHp: playerHp.value,
        bossHp: bossHp.value,
        durationSeconds:
            DateTime.now().difference(_startedAt ?? DateTime.now()).inSeconds,
      );
      rewardResult.value = result;
    } catch (_) {}

    if (!await _wait(attackDelay, token)) return;

    if (rewardResult.value?.passed ?? won) {
      phase.value = BossBattlePhase.reward;
      if (!await _wait(transitionDelay, token)) return;
    }

    phase.value = BossBattlePhase.result;
  }

  Future<bool> _wait(Duration duration, int token) async {
    if (duration > Duration.zero) {
      await Future<void>.delayed(duration);
    }
    return token == _flowToken;
  }

  void _resetState() {
    questions.clear();
    currentIndex.value = 0;
    bossHp.value = bossHpMax;
    playerHp.value = playerHpMax;
    combo.value = 0;
    maxCombo.value = 0;
    score.value = 0;
    correctCount.value = 0;
    wrongCount.value = 0;
    isInputLocked.value = true;
    selectedAnswer.value = null;
    lastAnswerCorrect.value = null;
    errorMessage.value = '';
    lastBossDamage.value = 0;
    lastPlayerDamage.value = 0;
  }

  @override
  void onClose() {
    _flowToken += 1;
    if (_attemptStarted && rewardResult.value == null) {
      unawaited(
        _rewardService.abandonAttempt(
          sessionId.value,
          metadata: const <String, dynamic>{'reason': 'boss_closed'},
        ),
      );
    }
    _source.close();
    super.onClose();
  }
}
