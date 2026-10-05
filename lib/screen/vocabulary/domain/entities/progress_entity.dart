class Progress {
  final int wordId;
  final int correctCount;
  final int wrongCount;
  final DateTime? lastPractice;
  final int level;
  final bool mastered;

  const Progress({
    required this.wordId,
    required this.correctCount,
    required this.wrongCount,
    required this.lastPractice,
    required this.level,
    required this.mastered,
  });

  Progress copyWith({
    int? correctCount,
    int? wrongCount,
    DateTime? lastPractice,
    int? level,
    bool? mastered,
  }) {
    return Progress(
      wordId: wordId,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastPractice: lastPractice ?? this.lastPractice,
      level: level ?? this.level,
      mastered: mastered ?? this.mastered,
    );
  }
}
