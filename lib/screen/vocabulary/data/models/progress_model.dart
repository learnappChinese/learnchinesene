import '../../domain/entities/progress_entity.dart';

class ProgressModel extends Progress {
  const ProgressModel({
    required super.wordId,
    required super.correctCount,
    required super.wrongCount,
    required super.lastPractice,
    required super.level,
    required super.mastered,
  });

  factory ProgressModel.fromMap(Map<String, Object?> map) {
    final masteredValue = map['mastered'];
    final lastPracticeValue =
        map['last_practice'] ?? map['last_review_at'];

    return ProgressModel(
      wordId: (map['word_id'] as num).toInt(),
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (map['wrong_count'] as num?)?.toInt() ?? 0,
      lastPractice: lastPracticeValue == null
          ? null
          : DateTime.tryParse(lastPracticeValue.toString()),
      level: (map['level'] as num?)?.toInt() ?? 0,
      mastered: masteredValue is bool
          ? masteredValue
          : (masteredValue as num?)?.toInt() == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word_id': wordId,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'last_practice': lastPractice?.toIso8601String(),
      'level': level,
      'mastered': mastered ? 1 : 0,
    };
  }
}
