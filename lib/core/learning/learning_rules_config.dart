abstract final class LearningRulesConfig {
  // --- Pass / Fail Thresholds ---
  static const double vocabularyPassAccuracy = 0.70;
  static const double listeningPassAccuracy = 0.70;
  static const double speakingPassOverall = 0.65;
  static const double speakingPassPronunciation = 0.60;
  static const double speakingPassTone = 0.50;
  static const double hanziPassScore = 0.70;
  static const double hanziMasteryScore = 0.85;
  static const int hanziMasteryMinimumPractices = 3;
  static const double dialoguePassCompletion = 0.70;
  static const double defaultPassAccuracy = 0.70;
  static const double unitMasteryThreshold = 0.70;

  // --- Star Ratings Thresholds ---
  static const double star1Accuracy = 0.70;
  static const double star2Accuracy = 0.80;
  static const double star3Accuracy = 0.95;

  // --- Speaking Weights ---
  static const double speakingAccuracyWeight = 0.35;
  static const double speakingPronunciationWeight = 0.30;
  static const double speakingToneWeight = 0.20;
  static const double speakingFluencyWeight = 0.15;

  /// Calculate unit mastery across available skills with normalized weights
  /// (Default: Vocab 35%, Listening 25%, Speaking 20%, Hanzi 20%)
  static double calculateUnitMastery({
    double? vocabularyMastery,
    double? listeningMastery,
    double? speakingMastery,
    double? hanziMastery,
  }) {
    double totalWeight = 0.0;
    double totalWeightedScore = 0.0;

    if (vocabularyMastery != null) {
      totalWeight += 0.35;
      totalWeightedScore += vocabularyMastery * 0.35;
    }
    if (listeningMastery != null) {
      totalWeight += 0.25;
      totalWeightedScore += listeningMastery * 0.25;
    }
    if (speakingMastery != null) {
      totalWeight += 0.20;
      totalWeightedScore += speakingMastery * 0.20;
    }
    if (hanziMastery != null) {
      totalWeight += 0.20;
      totalWeightedScore += hanziMastery * 0.20;
    }

    if (totalWeight <= 0) return 0.0;
    return (totalWeightedScore / totalWeight).clamp(0.0, 1.0);
  }

  /// Standardized level state derived from progress
  static LearningLevelState deriveLevelState({
    required bool isUnlocked,
    required bool isCompleted,
    required int stars,
    required int attempts,
    bool hasActiveSession = false,
  }) {
    if (!isUnlocked) return LearningLevelState.locked;
    if (stars >= 3) return LearningLevelState.perfect;
    if (isCompleted) return LearningLevelState.completed;
    if (hasActiveSession) return LearningLevelState.inProgress;
    if (attempts > 0 && stars > 0) return LearningLevelState.passed;
    if (attempts > 0 && stars == 0) return LearningLevelState.failed;
    return LearningLevelState.available;
  }

  /// Evaluate unit state based on missions, mastery and boss requirement
  static UnitPassState evaluateUnitState({
    required bool allMissionsPassed,
    required double overallMastery,
    required bool hasBoss,
    required bool bossWon,
    double masteryThreshold = 0.70,
  }) {
    if (!allMissionsPassed || overallMastery < masteryThreshold) {
      return UnitPassState.inProgress;
    }
    if (hasBoss && !bossWon) {
      return UnitPassState.bossPending;
    }
    return UnitPassState.completed;
  }
}

enum LearningLevelState {
  locked,
  available,
  inProgress,
  passed,
  failed,
  completed,
  perfect,
}

enum UnitPassState {
  locked,
  inProgress,
  bossPending,
  completed,
}
