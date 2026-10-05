class UserStats {
  final int id;
  final int totalExp;
  final int currentStreak;
  final DateTime lastStudyDate;
  final int totalWordsMastered;
  final int totalFavorites;

  UserStats({
    required this.id,
    required this.totalExp,
    required this.currentStreak,
    required this.lastStudyDate,
    required this.totalWordsMastered,
    required this.totalFavorites,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_exp': totalExp,
      'current_streak': currentStreak,
      'last_study_date': lastStudyDate.toIso8601String(),
      'total_words_mastered': totalWordsMastered,
      'total_favorites': totalFavorites,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'] ?? 1,
      totalExp: map['total_exp'] ?? 0,
      currentStreak: map['current_streak'] ?? 0,
      lastStudyDate: DateTime.parse(
          map['last_study_date'] ?? DateTime.now().toIso8601String()),
      totalWordsMastered: map['total_words_mastered'] ?? 0,
      totalFavorites: map['total_favorites'] ?? 0,
    );
  }

  UserStats copyWith({
    int? id,
    int? totalExp,
    int? currentStreak,
    DateTime? lastStudyDate,
    int? totalWordsMastered,
    int? totalFavorites,
  }) {
    return UserStats(
      id: id ?? this.id,
      totalExp: totalExp ?? this.totalExp,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalWordsMastered: totalWordsMastered ?? this.totalWordsMastered,
      totalFavorites: totalFavorites ?? this.totalFavorites,
    );
  }
}
