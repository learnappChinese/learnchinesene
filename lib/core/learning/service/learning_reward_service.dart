import 'dart:math' as math;

import '../data/learning_progress_repository.dart';
import '../learning_rules_config.dart';
import '../model/learning_result.dart';

class LearningRewardService {
  LearningRewardService({LearningProgressRepository? repository})
      : _repository = repository ?? SupabaseLearningProgressRepository();

  final LearningProgressRepository _repository;

  /// 1. Process Vocabulary Session Reward
  Future<LearningResult> processVocabularyReward({
    required String levelId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    required int maxCombo,
    required bool isFirstClear,
    int? totalQuestions,
  }) async {
    final total = correctCount + wrongCount;
    final accuracy = total > 0 ? (correctCount / total) : 0.0;
    final passed = accuracy >= LearningRulesConfig.vocabularyPassAccuracy &&
        (totalQuestions == null || total >= totalQuestions);

    final stars = passed ? LearningRulesConfig.evaluateStars(accuracy) : 0;
    final score = accuracy * 100.0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = LearningRulesConfig.vocabularyBaseXp;
      if (accuracy >= 1.0) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (accuracy >= 0.85) bonusXp += LearningRulesConfig.highAccuracyBonusXp;
      if (maxCombo >= 5) bonusXp += LearningRulesConfig.comboBonusXp;
      if (isFirstClear) bonusXp += LearningRulesConfig.firstClearBonusXp;
    } else {
      baseXp = LearningRulesConfig.practiceEffortXp;
    }

    return _repository.recordReward(
      activityType: 'vocabulary',
      sourceType: 'level',
      sourceId: levelId,
      attemptId: attemptId,
      score: score,
      accuracy: accuracy,
      correctCount: correctCount,
      wrongCount: wrongCount,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'vocab:$levelId:$attemptId',
      metadata: {
        'max_combo': maxCombo,
        'total_questions': total,
      },
    );
  }

  /// 2. Process Listening Session Reward
  Future<LearningResult> processListeningReward({
    required String sourceId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    required int maxCombo,
    bool isFirstClear = false,
  }) async {
    final total = correctCount + wrongCount;
    final accuracy = total > 0 ? (correctCount / total) : 0.0;
    final passed = accuracy >= LearningRulesConfig.listeningPassAccuracy;
    final stars = passed ? LearningRulesConfig.evaluateStars(accuracy) : 0;
    final score = accuracy * 100.0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = LearningRulesConfig.listeningBaseXp;
      if (accuracy >= 1.0) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (accuracy >= 0.85) bonusXp += LearningRulesConfig.highAccuracyBonusXp;
      if (maxCombo >= 5) bonusXp += LearningRulesConfig.comboBonusXp;
      if (isFirstClear) bonusXp += LearningRulesConfig.firstClearBonusXp;
    } else {
      baseXp = LearningRulesConfig.practiceEffortXp;
    }

    return _repository.recordReward(
      activityType: 'listening',
      sourceType: 'listening_challenge',
      sourceId: sourceId,
      attemptId: attemptId,
      score: score,
      accuracy: accuracy,
      correctCount: correctCount,
      wrongCount: wrongCount,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'listen:$sourceId:$attemptId',
      metadata: {'max_combo': maxCombo},
    );
  }

  /// 3. Process Speaking Session Reward (Weighted calculation)
  Future<LearningResult> processSpeakingReward({
    required String sourceId,
    required String attemptId,
    required double accuracyScore,
    required double pronunciationScore,
    required double toneScore,
    required double fluencyScore,
    String? recognizedText,
  }) async {
    final overallScore = LearningRulesConfig.calculateSpeakingOverall(
      accuracy: accuracyScore,
      pronunciation: pronunciationScore,
      tone: toneScore,
      fluency: fluencyScore,
    );

    // Pass rule: overall >= 65 and tone >= 50
    final passed =
        overallScore >= (LearningRulesConfig.speakingPassOverall * 100.0) &&
            toneScore >= (LearningRulesConfig.speakingPassTone * 100.0);

    final ratio = overallScore / 100.0;
    final stars = passed ? LearningRulesConfig.evaluateStars(ratio) : 0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = LearningRulesConfig.speakingBaseXp;
      if (ratio >= 0.95) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (ratio >= 0.85) bonusXp += LearningRulesConfig.highAccuracyBonusXp;
    } else {
      baseXp = LearningRulesConfig.practiceEffortXp;
    }

    return _repository.recordReward(
      activityType: 'speaking',
      sourceType: 'speaking_practice',
      sourceId: sourceId,
      attemptId: attemptId,
      score: overallScore,
      accuracy: ratio,
      correctCount: passed ? 1 : 0,
      wrongCount: passed ? 0 : 1,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'speak:$sourceId:$attemptId',
      metadata: {
        'accuracy_score': accuracyScore,
        'pronunciation_score': pronunciationScore,
        'tone_score': toneScore,
        'fluency_score': fluencyScore,
        'recognized_text': recognizedText,
      },
    );
  }

  /// 4. Process Hanzi Writing Reward
  Future<LearningResult> processHanziReward({
    required int characterId,
    required String attemptId,
    required double bestScore,
    required int attempts,
  }) async {
    final passed = bestScore >= (LearningRulesConfig.hanziPassScore * 100.0);
    final ratio = (bestScore / 100.0).clamp(0.0, 1.0);
    final stars = passed ? LearningRulesConfig.evaluateStars(ratio) : 0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = LearningRulesConfig.hanziBaseXp;
      if (bestScore >= 95.0) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (bestScore >= 85.0) bonusXp += LearningRulesConfig.highAccuracyBonusXp;
    } else {
      baseXp = LearningRulesConfig.practiceEffortXp;
    }

    return _repository.recordReward(
      activityType: 'hanzi',
      sourceType: 'character',
      sourceId: '$characterId',
      attemptId: attemptId,
      score: bestScore,
      accuracy: ratio,
      correctCount: passed ? 1 : 0,
      wrongCount: passed ? 0 : 1,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'hanzi:$characterId:$attemptId',
      metadata: {
        'practice_attempts': attempts,
      },
    );
  }

  /// 5. Process Boss Battle Reward
  Future<LearningResult> processBossReward({
    required int stageId,
    required String attemptId,
    required bool won,
    required int score,
    required int bestCombo,
    required int playerHp,
    required int bossHp,
    bool isFirstClear = false,
  }) async {
    final passed = won && bossHp <= 0 && playerHp > 0;
    final accuracy =
        passed ? 1.0 : (bossHp < 100 ? (100 - bossHp) / 100.0 : 0.0);
    final stars = passed ? (playerHp >= 80 ? 3 : (playerHp >= 50 ? 2 : 1)) : 0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = LearningRulesConfig.bossBaseXp;
      if (isFirstClear) bonusXp += LearningRulesConfig.bossFirstClearBonusXp;
      if (playerHp >= 80) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (bestCombo >= 5) bonusXp += LearningRulesConfig.comboBonusXp;
    } else {
      baseXp = math.min(15, (100 - bossHp) ~/ 10);
    }

    return _repository.recordReward(
      activityType: 'boss',
      sourceType: 'boss_stage',
      sourceId: '$stageId',
      attemptId: attemptId,
      score: score.toDouble(),
      accuracy: accuracy,
      correctCount: passed ? 1 : 0,
      wrongCount: passed ? 0 : 1,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'boss:$stageId:$attemptId',
      metadata: {
        'player_hp': playerHp,
        'boss_hp': bossHp,
        'best_combo': bestCombo,
      },
    );
  }

  /// 6. Process Dialogue & Roleplay Reward
  Future<LearningResult> processDialogueReward({
    required String dialogueId,
    required String attemptId,
    required int completedObjectives,
    required int totalObjectives,
    int maxCombo = 0,
    bool isFirstClear = false,
  }) async {
    final completionRatio = totalObjectives > 0
        ? (completedObjectives / totalObjectives).clamp(0.0, 1.0)
        : 1.0;
    final passed =
        completionRatio >= LearningRulesConfig.dialoguePassCompletion;
    final stars =
        passed ? LearningRulesConfig.evaluateStars(completionRatio) : 0;
    final score = completionRatio * 100.0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = LearningRulesConfig.dialogueBaseXp;
      if (completionRatio >= 1.0) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (completionRatio >= 0.85) {
        bonusXp += LearningRulesConfig.highAccuracyBonusXp;
      }
      if (isFirstClear) bonusXp += LearningRulesConfig.firstClearBonusXp;
    } else {
      baseXp = LearningRulesConfig.practiceEffortXp;
    }

    return _repository.recordReward(
      activityType: 'dialogue',
      sourceType: 'dialogue_practice',
      sourceId: dialogueId,
      attemptId: attemptId,
      score: score,
      accuracy: completionRatio,
      correctCount: completedObjectives,
      wrongCount: math.max(0, totalObjectives - completedObjectives),
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'dialogue:$dialogueId:$attemptId',
      metadata: {
        'total_objectives': totalObjectives,
        'completed_objectives': completedObjectives,
        'max_combo': maxCombo,
      },
    );
  }

  /// 7. Process Central Duo Game Session Reward
  Future<LearningResult> processDuoGameReward({
    required int gameId,
    required String gameCode,
    required String levelId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    required int score,
    int maxCombo = 0,
    bool isFirstClear = false,
  }) async {
    final total = correctCount + wrongCount;
    final accuracy = total > 0
        ? (correctCount / total).clamp(0.0, 1.0)
        : (score > 0 ? 1.0 : 0.0);

    final double requiredPassAccuracy = switch (gameCode) {
      'speaking' => LearningRulesConfig.speakingPassOverall,
      'dialogue' => LearningRulesConfig.dialoguePassCompletion,
      'listen_select' => LearningRulesConfig.listeningPassAccuracy,
      _ => LearningRulesConfig.vocabularyPassAccuracy,
    };

    final passed = accuracy >= requiredPassAccuracy;
    final stars = passed ? LearningRulesConfig.evaluateStars(accuracy) : 0;

    int baseXp = 0;
    int bonusXp = 0;

    if (passed) {
      baseXp = switch (gameCode) {
        'speaking' => LearningRulesConfig.speakingBaseXp,
        'dialogue' => LearningRulesConfig.dialogueBaseXp,
        'listen_select' => LearningRulesConfig.listeningBaseXp,
        'learn_words' => LearningRulesConfig.vocabularyBaseXp,
        _ => LearningRulesConfig.missionBaseXp,
      };
      if (accuracy >= 1.0) bonusXp += LearningRulesConfig.perfectBonusXp;
      if (accuracy >= 0.85) bonusXp += LearningRulesConfig.highAccuracyBonusXp;
      if (maxCombo >= 5) bonusXp += LearningRulesConfig.comboBonusXp;
      if (isFirstClear) bonusXp += LearningRulesConfig.firstClearBonusXp;
    } else {
      baseXp = LearningRulesConfig.practiceEffortXp;
    }

    final activityType = switch (gameCode) {
      'speaking' => 'speaking',
      'dialogue' => 'dialogue',
      'listen_select' => 'listening',
      'learn_words' => 'vocabulary',
      _ => 'game_mission',
    };

    return _repository.recordReward(
      activityType: activityType,
      sourceType: 'duo_level',
      sourceId: '$gameId:$levelId',
      attemptId: attemptId,
      score: score.toDouble(),
      accuracy: accuracy,
      correctCount: correctCount,
      wrongCount: wrongCount,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: 'duo:$gameId:$levelId:$attemptId',
      metadata: {
        'game_code': gameCode,
        'game_id': gameId,
        'level_id': levelId,
        'max_combo': maxCombo,
      },
    );
  }
}
