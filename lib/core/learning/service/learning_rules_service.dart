import 'dart:math' as math;

import '../learning_reward_config.dart';
import '../learning_rules_config.dart';
import '../model/learning_activity_submission.dart';

class LearningRuleEvaluation {
  const LearningRuleEvaluation({
    required this.passed,
    required this.score,
    required this.accuracy,
    required this.stars,
    required this.baseXp,
    required this.bonusXp,
    required this.perfect,
    required this.reason,
    this.hanziMastered = false,
  });

  final bool passed;
  final double score;
  final double accuracy;
  final int stars;
  final int baseXp;
  final int bonusXp;
  final bool perfect;
  final String reason;
  final bool hanziMastered;

  int get xpEarned => baseXp + bonusXp;
}

class LearningRulesService {
  const LearningRulesService();

  LearningRuleEvaluation evaluate(
    LearningActivitySubmission submission, {
    required bool firstClear,
    int previousHanziPracticeCount = 0,
    double previousHanziBestScore = 0,
  }) {
    final total = submission.correctCount + submission.wrongCount;
    final derivedAccuracy = submission.accuracy ??
        (total > 0 ? submission.correctCount / total : 0.0);
    final accuracy = derivedAccuracy.clamp(0.0, 1.0).toDouble();

    var score = submission.score.clamp(0.0, 100.0).toDouble();
    var passed = false;
    var perfect = false;
    var reason = 'accuracy_below_threshold';
    var hanziMastered = false;

    switch (submission.activityType) {
      case 'vocabulary':
        final requiredQuestions =
            (submission.metadata['required_questions'] as num?)?.toInt();
        final completedRequired =
            requiredQuestions == null || total >= requiredQuestions;
        passed = completedRequired &&
            accuracy >= LearningRulesConfig.vocabularyPassAccuracy;
        reason = !completedRequired
            ? 'required_questions_incomplete'
            : passed
                ? 'passed'
                : 'accuracy_below_threshold';
        score = accuracy * 100;
        break;
      case 'listening':
        passed = accuracy >= LearningRulesConfig.listeningPassAccuracy;
        reason = passed ? 'passed' : 'accuracy_below_threshold';
        score = accuracy * 100;
        break;
      case 'speaking':
        final speakingAccuracy = (submission.accuracy ?? 0) * 100;
        final pronunciation = submission.pronunciation ?? 0;
        final tone = submission.tone ?? 0;
        final fluency = submission.fluency ?? 0;
        score = calculateSpeakingOverall(
          accuracy: speakingAccuracy,
          pronunciation: pronunciation,
          tone: tone,
          fluency: fluency,
        );
        passed = score >= LearningRulesConfig.speakingPassOverall * 100 &&
            pronunciation >=
                LearningRulesConfig.speakingPassPronunciation * 100 &&
            tone >= LearningRulesConfig.speakingPassTone * 100;
        reason = _speakingReason(
          score: score,
          pronunciation: pronunciation,
          tone: tone,
          passed: passed,
        );
        break;
      case 'hanzi':
        score = (submission.hanziScore ?? submission.score)
            .clamp(0.0, 100.0)
            .toDouble();
        passed = score >= LearningRulesConfig.hanziPassScore * 100;
        final practiceCount = previousHanziPracticeCount +
            math
                .max(
                  1,
                  (submission.metadata['practice_attempts'] as num?)?.toInt() ??
                      1,
                )
                .toInt();
        final bestScore = math.max(previousHanziBestScore, score);
        hanziMastered = isHanziMastered(
          bestScore: bestScore,
          practiceCount: practiceCount,
        );
        reason = passed ? 'passed' : 'hanzi_score_below_threshold';
        break;
      case 'dialogue':
        final completion = (submission.objectiveCompletion ?? accuracy)
            .clamp(0.0, 1.0)
            .toDouble();
        passed = completion >= LearningRulesConfig.dialoguePassCompletion;
        score = completion * 100;
        reason = passed ? 'passed' : 'objective_incomplete';
        break;
      case 'boss':
        passed =
            (submission.bossHp ?? 1) <= 0 && (submission.playerHp ?? 0) > 0;
        score = submission.score.clamp(0.0, 1000000.0).toDouble();
        reason = passed ? 'boss_defeated' : 'boss_not_defeated';
        break;
      case 'review':
        passed = total > 0;
        score = accuracy * 100;
        reason = passed ? 'review_completed' : 'review_incomplete';
        break;
      default:
        passed = accuracy >= LearningRulesConfig.defaultPassAccuracy;
        score = accuracy * 100;
        reason = passed ? 'passed' : 'accuracy_below_threshold';
        break;
    }

    final starRatio = submission.activityType == 'hanzi' ||
            submission.activityType == 'speaking'
        ? (score / 100).clamp(0.0, 1.0).toDouble()
        : accuracy;
    final stars = passed ? evaluateStars(starRatio) : 0;
    perfect = passed &&
        (submission.activityType == 'boss'
            ? (submission.bossHp ?? 1) <= 0 && (submission.playerHp ?? 0) >= 100
            : starRatio >= 1.0);

    final reward = _reward(
      submission: submission,
      passed: passed,
      ratio: starRatio,
      perfect: perfect,
      firstClear: firstClear,
    );

    return LearningRuleEvaluation(
      passed: passed,
      score: score,
      accuracy: starRatio,
      stars: stars,
      baseXp: reward.baseXp,
      bonusXp: reward.bonusXp,
      perfect: perfect,
      reason: reason,
      hanziMastered: hanziMastered,
    );
  }

  int evaluateStars(double ratio) {
    if (ratio >= LearningRulesConfig.star3Accuracy) return 3;
    if (ratio >= LearningRulesConfig.star2Accuracy) return 2;
    if (ratio >= LearningRulesConfig.star1Accuracy) return 1;
    return 0;
  }

  double calculateSpeakingOverall({
    required double accuracy,
    required double pronunciation,
    required double tone,
    required double fluency,
  }) {
    return (accuracy * LearningRulesConfig.speakingAccuracyWeight) +
        (pronunciation * LearningRulesConfig.speakingPronunciationWeight) +
        (tone * LearningRulesConfig.speakingToneWeight) +
        (fluency * LearningRulesConfig.speakingFluencyWeight);
  }

  bool isHanziMastered({
    required double bestScore,
    required int practiceCount,
  }) {
    return bestScore >= LearningRulesConfig.hanziMasteryScore * 100 &&
        practiceCount >= LearningRulesConfig.hanziMasteryMinimumPractices;
  }

  ({int baseXp, int bonusXp}) _reward({
    required LearningActivitySubmission submission,
    required bool passed,
    required double ratio,
    required bool perfect,
    required bool firstClear,
  }) {
    if (!passed) {
      final effort = submission.activityType == 'boss'
          ? math.min(
              15,
              math.max(0, 100 - (submission.bossHp ?? 100)) ~/ 10,
            )
          : LearningRewardConfig.practiceEffortXp;
      return (baseXp: effort, bonusXp: 0);
    }

    var baseXp = LearningRewardConfig.baseXpFor(submission.activityType);
    var bonusXp = 0;
    if (perfect) bonusXp += LearningRewardConfig.perfectBonusXp;
    if (ratio >= LearningRewardConfig.highAccuracyThreshold) {
      bonusXp += LearningRewardConfig.highAccuracyBonusXp;
    }
    bonusXp += LearningRewardConfig.comboBonusFor(submission.bestCombo);
    bonusXp += LearningRewardConfig.difficultyBonusFor(
      (submission.metadata['difficulty'] as num?)?.toInt() ?? 1,
    );
    if (firstClear) {
      bonusXp +=
          LearningRewardConfig.firstClearBonusFor(submission.activityType);
    } else {
      baseXp = math.min(baseXp, LearningRewardConfig.replayXpCap);
      bonusXp = 0;
    }

    final cap = LearningRewardConfig.xpCapFor(submission.activityType);
    final total = math.min(baseXp + bonusXp, cap);
    return (baseXp: math.min(baseXp, total), bonusXp: total - baseXp);
  }

  String _speakingReason({
    required double score,
    required double pronunciation,
    required double tone,
    required bool passed,
  }) {
    if (passed) return 'passed';
    if (pronunciation < LearningRulesConfig.speakingPassPronunciation * 100) {
      return 'pronunciation_below_threshold';
    }
    if (tone < LearningRulesConfig.speakingPassTone * 100) {
      return 'tone_below_threshold';
    }
    if (score < LearningRulesConfig.speakingPassOverall * 100) {
      return 'speaking_overall_below_threshold';
    }
    return 'speaking_metrics_incomplete';
  }
}
