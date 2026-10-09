class HanziCharacter {
  final int id;
  final String character;
  final String? pinyin;
  final String? meaning;
  final int? hskLevel;
  final String strokePathData;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final int strokeCount;
  final int practiceCount;
  final double bestScore;
  final double lastScore;
  final DateTime? nextReviewAt;

  HanziCharacter({
    required this.id,
    required this.character,
    this.pinyin,
    this.meaning,
    this.hskLevel,
    required this.strokePathData,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.strokeCount,
    this.practiceCount = 0,
    this.bestScore = 0,
    this.lastScore = 0,
    this.nextReviewAt,
  });

  HanziLearningState get learningState {
    if (bestScore >= 85 && practiceCount >= 3) {
      return HanziLearningState.mastered;
    }
    if (nextReviewAt != null && !nextReviewAt!.isAfter(DateTime.now())) {
      return HanziLearningState.needsReview;
    }
    if (practiceCount > 0) return HanziLearningState.learning;
    return HanziLearningState.fresh;
  }

  factory HanziCharacter.fromMap(Map<String, Object?> map) {
    return HanziCharacter(
      id: map['id'] as int,
      character: map['character'] as String? ?? '',
      pinyin: map['pinyin'] as String?,
      meaning: map['meaning'] as String?,
      hskLevel: map['hsk_level_id'] as int?,
      strokePathData: map['stroke_paths'] as String? ?? '',
      viewBoxWidth: (map['stroke_width'] as num?)?.toDouble() ?? 110.0,
      viewBoxHeight: (map['stroke_height'] as num?)?.toDouble() ?? 110.0,
      strokeCount: map['stroke_count'] as int? ?? 0,
      practiceCount: (map['practice_count'] as num?)?.toInt() ?? 0,
      bestScore: (map['best_score'] as num?)?.toDouble() ?? 0,
      lastScore: (map['last_score'] as num?)?.toDouble() ?? 0,
      nextReviewAt: DateTime.tryParse('${map['next_review_at'] ?? ''}'),
    );
  }
}

enum HanziLearningState { fresh, learning, needsReview, mastered }
