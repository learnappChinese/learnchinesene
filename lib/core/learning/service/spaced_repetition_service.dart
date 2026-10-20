/// Đánh giá mức độ ghi nhớ của người học cho một thẻ từ vựng.
enum SrsRating {
  /// Quên hoặc rất khó nhớ (q = 1) -> Reset số lần lặp, ôn lại ngày mai, giảm Ease Factor.
  hard,

  /// Nhớ ra được sau chút suy nghĩ (q = 4) -> Tăng số lần lặp, mở rộng khoảng cách ôn tập.
  good,

  /// Nhớ tức thì, hoàn hảo (q = 5) -> Nhảy vọt khoảng cách ôn tập, tăng Ease Factor.
  easy,
}

/// Trạng thái Spaced Repetition (SRS) của một từ vựng trong cơ sở dữ liệu local.
class SrsCardState {
  final int srsStage;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final int correctCount;
  final int wrongCount;
  final bool isMastered;

  const SrsCardState({
    required this.srsStage,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isMastered = false,
  });

  factory SrsCardState.initial() => const SrsCardState(
        srsStage: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        repetitionCount: 0,
        correctCount: 0,
        wrongCount: 0,
        isMastered: false,
      );

  factory SrsCardState.fromMap(Map<String, dynamic> map) {
    final stage = (map['srs_stage'] as num?)?.toInt() ?? 0;
    final interval = (map['interval_days'] as num?)?.toInt() ?? 0;
    final nextStr = map['next_review_at_utc'] as String?;
    final lastStr = map['last_reviewed_at_utc'] as String?;

    return SrsCardState(
      srsStage: stage,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: interval,
      repetitionCount: (map['repetition_count'] as num?)?.toInt() ?? 0,
      nextReviewAt:
          nextStr != null ? DateTime.tryParse(nextStr)?.toUtc() : null,
      lastReviewedAt:
          lastStr != null ? DateTime.tryParse(lastStr)?.toUtc() : null,
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (map['wrong_count'] as num?)?.toInt() ?? 0,
      isMastered: stage >= 4 || interval >= 21,
    );
  }

  Map<String, dynamic> toMap({required String localId, required int wordId}) {
    return {
      'local_id': localId,
      'word_id': wordId,
      'srs_stage': srsStage,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'repetition_count': repetitionCount,
      'next_review_at_utc': nextReviewAt?.toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      'last_reviewed_at_utc': lastReviewedAt?.toIso8601String(),
      'correct_count': correctCount,
      'wrong_count': wrongCount,
    };
  }
}

/// Bộ lập lịch ôn tập ngắt quãng Spaced Repetition chuẩn SM-2 (SuperMemo-2).
class SpacedRepetitionService {
  const SpacedRepetitionService();

  /// Tính toán trạng thái SRS tiếp theo theo thuật toán SM-2 chuẩn.
  ///
  /// Công thức SM-2:
  /// - EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  /// - EF' tối thiểu là 1.3
  /// - Nếu q < 3 (Hard): repetition = 0, interval = 1
  /// - Nếu q >= 3 (Good/Easy):
  ///     rep == 0 -> interval = 1
  ///     rep == 1 -> interval = (q == 5 ? 6 : 4)
  ///     rep >= 2 -> interval = round(interval_prev * EF')
  SrsCardState calculateNextState({
    required SrsCardState current,
    required SrsRating rating,
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final int quality = switch (rating) {
      SrsRating.hard => 1,
      SrsRating.good => 4,
      SrsRating.easy => 5,
    };

    // 1. Tính toán Ease Factor mới
    final double efDelta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    double newEaseFactor = current.easeFactor + efDelta;
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    int newRepetitionCount;
    int newIntervalDays;
    int newStage;
    int newCorrectCount = current.correctCount;
    int newWrongCount = current.wrongCount;

    if (quality < 3) {
      // Đánh giá thất bại / Quên (Hard)
      newRepetitionCount = 0;
      newIntervalDays = 1;
      newStage = 0;
      newWrongCount++;
    } else {
      // Đánh giá thành công (Good / Easy)
      newCorrectCount++;
      newRepetitionCount = current.repetitionCount + 1;
      newStage = current.srsStage + 1;

      if (current.repetitionCount == 0) {
        newIntervalDays = 1;
      } else if (current.repetitionCount == 1) {
        newIntervalDays = (rating == SrsRating.easy) ? 6 : 4;
      } else {
        newIntervalDays = (current.intervalDays * newEaseFactor).round();
        if (newIntervalDays <= current.intervalDays) {
          newIntervalDays = current.intervalDays + 1;
        }
      }
    }

    final nextReview = currentTime.add(Duration(days: newIntervalDays));
    final isMastered = newStage >= 4 || newIntervalDays >= 21;

    return SrsCardState(
      srsStage: newStage,
      easeFactor: double.parse(newEaseFactor.toStringAsFixed(2)),
      intervalDays: newIntervalDays,
      repetitionCount: newRepetitionCount,
      nextReviewAt: nextReview,
      lastReviewedAt: currentTime,
      correctCount: newCorrectCount,
      wrongCount: newWrongCount,
      isMastered: isMastered,
    );
  }

  /// Trả về mô tả khoảng thời gian ôn tiếp theo để hiển thị gợi ý (hint) trên nút bấm.
  String getIntervalHint(SrsCardState current, SrsRating rating) {
    final next = calculateNextState(current: current, rating: rating);
    final days = next.intervalDays;
    if (days <= 1) return 'Ngày mai';
    if (days < 7) return '$days ngày';
    if (days < 30) return '${(days / 7).round()} tuần';
    return '${(days / 30).round()} tháng';
  }
}
