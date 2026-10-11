class LearningResult {
  final String activityType;
  final String sourceId;
  final String attemptId;
  final bool passed;
  final bool failed;
  final int stars; // 0..3
  final double score;
  final double accuracy; // 0.0 .. 1.0
  final int correctCount;
  final int wrongCount;
  final int xpEarned;
  final int baseXp;
  final int bonusXp;
  final int newTotalXp;
  final int currentStreak;
  final double masteryBefore;
  final double masteryAfter;
  final int bestCombo;
  final bool firstClear;
  final bool perfect;
  final int attemptNumber;
  final bool unlockedNext;
  final String? nextNodeId;
  final String reason;
  final bool idempotent;
  final Map<String, dynamic> metadata;

  const LearningResult({
    required this.activityType,
    required this.sourceId,
    required this.attemptId,
    required this.passed,
    bool? failed,
    required this.stars,
    required this.score,
    required this.accuracy,
    required this.correctCount,
    required this.wrongCount,
    required this.xpEarned,
    required this.baseXp,
    required this.bonusXp,
    required this.newTotalXp,
    required this.currentStreak,
    this.masteryBefore = 0.0,
    this.masteryAfter = 0.0,
    this.bestCombo = 0,
    required this.firstClear,
    required this.perfect,
    this.attemptNumber = 1,
    this.unlockedNext = false,
    this.nextNodeId,
    this.reason = '',
    this.idempotent = false,
    this.metadata = const {},
  }) : failed = failed ?? !passed;

  double get masteryDelta => masteryAfter - masteryBefore;
  int get newStreak => currentStreak;
  bool get isFirstClear => firstClear;
  bool get isPerfect => perfect;
  String? get failReason => failed && reason.isNotEmpty ? reason : null;

  factory LearningResult.fromJson(Map<String, dynamic> json) {
    return LearningResult(
      activityType: '${json['activity_type'] ?? ''}',
      sourceId: '${json['source_id'] ?? ''}',
      attemptId: '${json['attempt_id'] ?? ''}',
      passed: json['passed'] == true,
      failed: json['failed'] == true,
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
      currentStreak:
          (json['current_streak'] ?? json['new_streak'] as num?)?.toInt() ?? 0,
      masteryBefore: (json['mastery_before'] as num?)?.toDouble() ?? 0.0,
      masteryAfter: (json['mastery_after'] as num?)?.toDouble() ?? 0.0,
      bestCombo: (json['best_combo'] as num?)?.toInt() ?? 0,
      firstClear: json['first_clear'] == true || json['is_first_clear'] == true,
      perfect: json['perfect'] == true || json['is_perfect'] == true,
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      unlockedNext: json['unlocked_next'] == true,
      nextNodeId: json['next_node_id'] as String?,
      reason: '${json['reason'] ?? json['fail_reason'] ?? ''}',
      idempotent: json['idempotent'] == true,
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
        'failed': failed,
        'stars': stars,
        'score': score,
        'accuracy': accuracy,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'xp_earned': xpEarned,
        'base_xp': baseXp,
        'bonus_xp': bonusXp,
        'new_total_xp': newTotalXp,
        'current_streak': currentStreak,
        'mastery_before': masteryBefore,
        'mastery_after': masteryAfter,
        'best_combo': bestCombo,
        'first_clear': firstClear,
        'perfect': perfect,
        'attempt_number': attemptNumber,
        'unlocked_next': unlockedNext,
        'next_node_id': nextNodeId,
        'reason': reason,
        'idempotent': idempotent,
        'metadata': metadata,
      };

  factory LearningResult.fromMap(Map<String, dynamic> map) =>
      LearningResult.fromJson(map);
}
