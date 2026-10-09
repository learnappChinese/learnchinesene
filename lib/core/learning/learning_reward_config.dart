import 'dart:math' as math;

abstract final class LearningRewardConfig {
  static const int vocabularyBaseXp = 20;
  static const int listeningBaseXp = 25;
  static const int speakingBaseXp = 30;
  static const int hanziBaseXp = 25;
  static const int dialogueBaseXp = 30;
  static const int missionBaseXp = 30;
  static const int bossBaseXp = 100;
  static const int reviewBaseXp = 20;

  static const int perfectBonusXp = 15;
  static const int highAccuracyBonusXp = 10;
  static const double highAccuracyThreshold = 0.85;
  static const int comboStep = 5;
  static const int comboStepBonusXp = 5;
  static const int comboBonusCapXp = 10;
  static const int firstClearBonusXp = 20;
  static const int bossFirstClearBonusXp = 50;
  static const int practiceEffortXp = 5;
  static const int replayXpCap = 15;
  static const int regularXpCap = 100;
  static const int bossXpCap = 250;
  static const int difficultyBonusPerLevelXp = 2;
  static const int difficultyBonusCapXp = 10;

  static int baseXpFor(String activityType) => switch (activityType) {
        'vocabulary' => vocabularyBaseXp,
        'listening' => listeningBaseXp,
        'speaking' => speakingBaseXp,
        'hanzi' => hanziBaseXp,
        'dialogue' => dialogueBaseXp,
        'boss' => bossBaseXp,
        'review' => reviewBaseXp,
        _ => missionBaseXp,
      };

  static int firstClearBonusFor(String activityType) =>
      activityType == 'boss' ? bossFirstClearBonusXp : firstClearBonusXp;

  static int comboBonusFor(int bestCombo) {
    if (bestCombo < comboStep) return 0;
    return math.min(
      (bestCombo ~/ comboStep) * comboStepBonusXp,
      comboBonusCapXp,
    );
  }

  static int difficultyBonusFor(int difficulty) => math.min(
        math.max(0, difficulty - 1) * difficultyBonusPerLevelXp,
        difficultyBonusCapXp,
      );

  static int xpCapFor(String activityType) =>
      activityType == 'boss' ? bossXpCap : regularXpCap;
}
