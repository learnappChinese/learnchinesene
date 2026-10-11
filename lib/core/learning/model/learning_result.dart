class LearningResult {
  final String activityType;
  final String sourceId;
  final String attemptId;
  final bool passed;
  final int stars; // 0..3
  final double score;
  final double accuracy; // 0.0 .. 1.0
  final int correctCount;
  final int wrongCount;
  final int xpEarned;
  final int baseXp;
  final int bonusXp;
  final int newTotalXp;
  final int newStreak;
  final bool isFirstClear;
  final bool isPerfect;
  final String? failReason;
  final double masteryDelta;
  final Map<String, dynamic> metadata;

  const LearningResult({
    required this.activityType,
    required this.sourceId,
    required this.attemptId,
    required this.passed,
    required this.stars,
    required this.score,
    required this.accuracy,
    required this.correctCount,
    required this.wrongCount,
    required this.xpEarned,
    required this.baseXp,
    required this.bonusXp,
    required this.newTotalXp,
    required this.newStreak,
    required this.isFirstClear,
    required this.isPerfect,
    this.failReason,
    this.masteryDelta = 0.0,
    this.metadata = const {},
  });

  factory LearningResult.fromJson(Map<String, dynamic> json) {
    return LearningResult(
      activityType: '${json['activity_type'] ?? ''}',
      sourceId: '${json['source_id'] ?? ''}',
      attemptId: '${json['attempt_id'] ?? ''}',
      passed: json['passed'] == true,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      xpEarned: (json['xp_earned'] ?? json['xp_awarded'] as num?)?.toInt() ?? 0,
      baseXp: (json['base_xp'] as num?)?.toInt() ?? 0,
      bonusXp: (json['bonus_xp'] as num?)?.toInt() ?? 0,
      newTotalXp:
          (json['new_total_xp'] ?? json['total_exp'] as num?)?.toInt() ?? 0,
      newStreak:
          (json['new_streak'] ?? json['current_streak'] as num?)?.toInt() ?? 0,
      isFirstClear: json['is_first_clear'] == true,
      isPerfect: json['is_perfect'] == true,
      failReason: json['fail_reason'] as String?,
      masteryDelta: (json['mastery_delta'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'activity_type': activityType,
        'source_id': sourceId,
        'attempt_id': attemptId,
        'passed': passed,
        'stars': stars,
        'score': score,
        'accuracy': accuracy,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'xp_earned': xpEarned,
        'base_xp': baseXp,
        'bonus_xp': bonusXp,
        'new_total_xp': newTotalXp,
        'new_streak': newStreak,
        'is_first_clear': isFirstClear,
        'is_perfect': isPerfect,
        'fail_reason': failReason,
        'mastery_delta': masteryDelta,
        'metadata': metadata,
      };
}
