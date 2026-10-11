class LearningActivitySubmission {
  const LearningActivitySubmission({
    required this.activityType,
    required this.sourceType,
    required this.sourceId,
    required this.attemptId,
    this.unitId,
    this.levelId,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.durationSeconds = 0,
    this.bestCombo = 0,
    this.accuracy,
    this.pronunciation,
    this.tone,
    this.fluency,
    this.hanziScore,
    this.objectiveCompletion,
    this.bossHp,
    this.playerHp,
    this.metadata = const <String, dynamic>{},
  });

  final String activityType;
  final String sourceType;
  final String sourceId;
  final String attemptId;
  final String? unitId;
  final String? levelId;
  final double score;
  final int correctCount;
  final int wrongCount;
  final int durationSeconds;
  final int bestCombo;

  /// Normalized ratio in the 0..1 range when supplied by gameplay.
  final double? accuracy;

  /// Speaking sub-scores use the 0..100 range.
  final double? pronunciation;
  final double? tone;
  final double? fluency;

  /// Hanzi score uses the 0..100 range.
  final double? hanziScore;

  /// Dialogue objective completion uses the 0..1 range.
  final double? objectiveCompletion;

  final int? bossHp;
  final int? playerHp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toRpcParams() => <String, dynamic>{
        'p_activity_type': activityType,
        'p_source_type': sourceType,
        'p_source_id': sourceId,
        'p_unit_id': unitId,
        'p_level_id': levelId,
        'p_score': score,
        'p_correct_count': correctCount,
        'p_wrong_count': wrongCount,
        'p_duration_seconds': durationSeconds,
        'p_best_combo': bestCombo,
        'p_accuracy': accuracy,
        'p_pronunciation': pronunciation,
        'p_tone': tone,
        'p_fluency': fluency,
        'p_hanzi_score': hanziScore,
        'p_objective_completion': objectiveCompletion,
        'p_boss_hp': bossHp,
        'p_player_hp': playerHp,
        'p_metadata': metadata,
        'p_attempt_id': attemptId,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'activity_type': activityType,
        'source_type': sourceType,
        'source_id': sourceId,
        'attempt_id': attemptId,
        'unit_id': unitId,
        'level_id': levelId,
        'score': score,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'duration_seconds': durationSeconds,
        'best_combo': bestCombo,
        'accuracy': accuracy,
        'pronunciation': pronunciation,
        'tone': tone,
        'fluency': fluency,
        'hanzi_score': hanziScore,
        'objective_completion': objectiveCompletion,
        'boss_hp': bossHp,
        'player_hp': playerHp,
        'metadata': metadata,
      };

  factory LearningActivitySubmission.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();

    return LearningActivitySubmission(
      activityType: '${json['activity_type'] ?? ''}',
      sourceType: '${json['source_type'] ?? ''}',
      sourceId: '${json['source_id'] ?? ''}',
      attemptId: '${json['attempt_id'] ?? ''}',
      unitId: json['unit_id'] as String?,
      levelId: json['level_id'] as String?,
      score: number('score') ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      bestCombo: (json['best_combo'] as num?)?.toInt() ?? 0,
      accuracy: number('accuracy'),
      pronunciation: number('pronunciation'),
      tone: number('tone'),
      fluency: number('fluency'),
      hanziScore: number('hanzi_score'),
      objectiveCompletion: number('objective_completion'),
      bossHp: (json['boss_hp'] as num?)?.toInt(),
      playerHp: (json['player_hp'] as num?)?.toInt(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const <String, dynamic>{},
    );
  }
}
