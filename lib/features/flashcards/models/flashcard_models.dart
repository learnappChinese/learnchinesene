import '../../../core/models/word.dart';

/// Hướng học của thẻ Flashcard.
enum FlashcardDirection {
  /// Mặt trước: Chữ Hán -> Mặt sau: Pinyin + Nghĩa tiếng Việt + Ví dụ
  zhToVi('zh_vi', 'Trung → Việt'),

  /// Mặt trước: Nghĩa tiếng Việt -> Mặt sau: Chữ Hán + Pinyin + Phát âm
  viToZh('vi_zh', 'Việt → Trung'),

  /// Mặt trước: Âm thanh -> Mặt sau: Chữ Hán + Pinyin + Nghĩa
  listenToMeaning('listen', 'Nghe → Đoán');

  final String code;
  final String label;
  const FlashcardDirection(this.code, this.label);

  static FlashcardDirection fromCode(String code) {
    return FlashcardDirection.values.firstWhere(
      (d) => d.code == code,
      orElse: () => FlashcardDirection.zhToVi,
    );
  }
}

/// Trạng thái học tập của thẻ theo FSRS.
enum FlashcardCardState {
  /// Thẻ mới chưa từng học
  newCard(0, 'Mới'),

  /// Đang học các bước đầu
  learning(1, 'Đang học'),

  /// Đã tốt nghiệp, ôn tập định kỳ
  review(2, 'Đã thuộc'),

  /// Đã từng thuộc nhưng quên, cần học lại
  relearning(3, 'Ôn lại');

  final int value;
  final String label;
  const FlashcardCardState(this.value, this.label);

  static FlashcardCardState fromValue(int val) {
    return FlashcardCardState.values.firstWhere(
      (s) => s.value == val,
      orElse: () => FlashcardCardState.newCard,
    );
  }
}

/// Trạng thái chi tiết lưu trong SQLite cho từng thẻ của người dùng.
class FlashcardProgress {
  final int cardId;
  final int wordId;
  final String direction;
  final FlashcardCardState state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime dueAtUtc;
  final DateTime? lastReviewAtUtc;
  final int reps;
  final int lapses;
  final int scheduledDays;

  const FlashcardProgress({
    required this.cardId,
    required this.wordId,
    required this.direction,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.dueAtUtc,
    this.lastReviewAtUtc,
    this.reps = 0,
    this.lapses = 0,
    this.scheduledDays = 0,
  });

  factory FlashcardProgress.fromMap(Map<String, dynamic> map) {
    final wordId = (map['word_id'] as num?)?.toInt() ?? (map['id'] as num?)?.toInt() ?? 0;
    final cardId = (map['card_id'] as num?)?.toInt() ?? wordId;
    final stateVal = (map['state'] as num?)?.toInt() ?? (map['card_state'] as num?)?.toInt() ?? 0;
    final dueAtRaw = map['due_at_utc'] as String?;
    final dueAtUtc = dueAtRaw != null ? (DateTime.tryParse(dueAtRaw) ?? DateTime.now().toUtc()) : DateTime.now().toUtc();

    return FlashcardProgress(
      cardId: cardId,
      wordId: wordId,
      direction: map['direction'] as String? ?? 'zh_vi',
      state: FlashcardCardState.fromValue(stateVal),
      step: (map['step'] as num?)?.toInt(),
      stability: (map['stability'] as num?)?.toDouble(),
      difficulty: (map['difficulty'] as num?)?.toDouble(),
      dueAtUtc: dueAtUtc,
      lastReviewAtUtc: map['last_review_at_utc'] != null
          ? DateTime.tryParse(map['last_review_at_utc'] as String)
          : null,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      lapses: (map['lapses'] as num?)?.toInt() ?? 0,
      scheduledDays: (map['scheduled_days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Thẻ Flashcard hoàn chỉnh bao gồm từ vựng, ví dụ, chữ Hán và tiến độ FSRS.
class FlashcardItem {
  final Word word;
  final FlashcardProgress? progress;
  final List<Map<String, dynamic>> examples;
  final List<Map<String, dynamic>> characters;
  final FlashcardDirection direction;

  const FlashcardItem({
    required this.word,
    this.progress,
    this.examples = const [],
    this.characters = const [],
    this.direction = FlashcardDirection.zhToVi,
  });

  int get cardId => word.id * 10 + direction.index;

  bool get isNew => progress == null || progress!.state == FlashcardCardState.newCard;

  bool get isDue {
    if (progress == null) return false;
    return progress!.dueAtUtc.isBefore(DateTime.now().toUtc());
  }

  FlashcardCardState get state => progress?.state ?? FlashcardCardState.newCard;
}

/// Thống kê bộ thẻ theo Section (Unit).
class FlashcardSectionDeck {
  final int unitId;
  final int unitNumber;
  final String title;
  final int totalWords;
  final int dueWords;
  final int learningWords;
  final int reviewWords;
  final int newWords;

  const FlashcardSectionDeck({
    required this.unitId,
    required this.unitNumber,
    required this.title,
    required this.totalWords,
    required this.dueWords,
    required this.learningWords,
    required this.reviewWords,
    required this.newWords,
  });

  double get progressPercent =>
      totalWords == 0 ? 0.0 : ((reviewWords / totalWords) * 100).clamp(0.0, 100.0);
}

/// Thống kê bộ thẻ theo cấp độ HSK.
class FlashcardHskDeck {
  final int level;
  final String name;
  final String description;
  final List<FlashcardSectionDeck> sections;
  final bool isAvailable;

  const FlashcardHskDeck({
    required this.level,
    required this.name,
    required this.description,
    required this.sections,
    this.isAvailable = true,
  });

  int get totalWords => sections.fold(0, (sum, s) => sum + s.totalWords);
  int get dueWords => sections.fold(0, (sum, s) => sum + s.dueWords);
  int get newWords => sections.fold(0, (sum, s) => sum + s.newWords);
  int get learningWords => sections.fold(0, (sum, s) => sum + s.learningWords);
  int get reviewWords => sections.fold(0, (sum, s) => sum + s.reviewWords);

  double get progressPercent =>
      totalWords == 0 ? 0.0 : ((reviewWords / totalWords) * 100).clamp(0.0, 100.0);
}

/// Tổng quan số liệu trên Dashboard trang chủ Flashcard.
class FlashcardDashboardStats {
  final int dueToday;
  final int overdueCount;
  final int learningCount;
  final int reviewCount;
  final int newAvailable;
  final int totalWords;
  final int streakDays;

  const FlashcardDashboardStats({
    required this.dueToday,
    required this.overdueCount,
    required this.learningCount,
    required this.reviewCount,
    required this.newAvailable,
    required this.totalWords,
    required this.streakDays,
  });

  factory FlashcardDashboardStats.fromMap(Map<String, dynamic> map) {
    return FlashcardDashboardStats(
      dueToday: (map['due_today'] as num?)?.toInt() ?? 0,
      overdueCount: (map['overdue_count'] as num?)?.toInt() ?? 0,
      learningCount: (map['learning_count'] as num?)?.toInt() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      newAvailable: (map['new_available'] as num?)?.toInt() ?? 0,
      totalWords: (map['total_words'] as num?)?.toInt() ?? 0,
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
    );
  }

  factory FlashcardDashboardStats.empty() {
    return const FlashcardDashboardStats(
      dueToday: 0,
      overdueCount: 0,
      learningCount: 0,
      reviewCount: 0,
      newAvailable: 0,
      totalWords: 0,
      streakDays: 0,
    );
  }
}
