import 'package:fsrs/fsrs.dart' as fsrs;

import '../models/flashcard_models.dart';

/// Bộ lập lịch ôn tập ngắt quãng thông minh FSRS (Free Spaced Repetition Scheduler).
/// Đóng gói thư viện chính thức fsrs và cung cấp tính toán trước (preview) khoảng thời gian cho 4 nút:
/// Again, Hard, Good, Easy.
class FsrsSchedulerService {
  final fsrs.Scheduler scheduler;
  final int maximumInterval;

  FsrsSchedulerService({
    double desiredRetention = 0.90,
    this.maximumInterval = 7, // Giới hạn tối đa 7 ngày theo yêu cầu người học
    bool enableFuzzing = false, // Tắt fuzzing khi tính preview để đảm bảo số ngày nhất quán
    List<Duration> learningSteps = const [
      Duration(minutes: 1),
      Duration(minutes: 10),
    ],
    List<Duration> relearningSteps = const [
      Duration(minutes: 10),
    ],
  }) : scheduler = fsrs.Scheduler(
          desiredRetention: desiredRetention.clamp(0.70, 0.99),
          maximumInterval: maximumInterval,
          enableFuzzing: enableFuzzing,
          learningSteps: learningSteps,
          relearningSteps: relearningSteps,
        );

  /// Chuyển đổi FlashcardProgress cục bộ sang đối tượng Card của FSRS.
  fsrs.Card toFsrsCard(FlashcardProgress? progress, int cardId) {
    if (progress == null || progress.state == FlashcardCardState.newCard) {
      return fsrs.Card(
        cardId: cardId,
        state: fsrs.State.learning,
        step: 0,
        due: DateTime.now().toUtc(),
      );
    }

    final fsrsState = switch (progress.state) {
      FlashcardCardState.learning => fsrs.State.learning,
      FlashcardCardState.review => fsrs.State.review,
      FlashcardCardState.relearning => fsrs.State.relearning,
      FlashcardCardState.newCard => fsrs.State.learning,
    };

    return fsrs.Card(
      cardId: cardId,
      state: fsrsState,
      step: progress.step,
      stability: progress.stability,
      difficulty: progress.difficulty,
      due: progress.dueAtUtc,
      lastReview: progress.lastReviewAtUtc,
    );
  }

  /// Tính toán trước khoảng thời gian dự kiến cho 4 nút rating mà không làm thay đổi state.
  Map<fsrs.Rating, String> previewIntervalHints(
    FlashcardProgress? progress,
    int cardId, {
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final card = toFsrsCard(progress, cardId);

    final result = <fsrs.Rating, String>{};
    final maxDiff = Duration(days: maximumInterval);
    for (final rating in fsrs.Rating.values) {
      final reviewResult = scheduler.reviewCard(
        card,
        rating,
        reviewDateTime: currentTime,
      );
      final rawDiff = reviewResult.card.due.difference(currentTime);
      final effectiveDiff = rawDiff > maxDiff ? maxDiff : rawDiff;
      result[rating] = formatDurationHint(effectiveDiff);
    }

    return result;
  }

  /// Thực hiện đánh giá thẻ thực tế theo FSRS và trả về card mới cùng review log.
  ({fsrs.Card card, fsrs.ReviewLog reviewLog}) reviewCard({
    required FlashcardProgress? progress,
    required int cardId,
    required fsrs.Rating rating,
    DateTime? now,
    int? durationMs,
  }) {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final card = toFsrsCard(progress, cardId);

    final reviewResult = scheduler.reviewCard(
      card,
      rating,
      reviewDateTime: currentTime,
      reviewDuration: durationMs,
    );

    final maxDue = currentTime.add(Duration(days: maximumInterval));
    final clampedDue = reviewResult.card.due.isAfter(maxDue) ? maxDue : reviewResult.card.due;
    final finalCard = fsrs.Card(
      cardId: reviewResult.card.cardId,
      state: reviewResult.card.state,
      step: reviewResult.card.step,
      stability: reviewResult.card.stability,
      difficulty: reviewResult.card.difficulty,
      due: clampedDue,
      lastReview: reviewResult.card.lastReview,
    );

    return (card: finalCard, reviewLog: reviewResult.reviewLog);
  }

  /// Định dạng thời gian ôn tập tự nhiên và trực quan cho người học.
  static String formatDurationHint(Duration duration) {
    if (duration.inSeconds <= 45) {
      return '< 1m';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours}h';
    }
    final days = duration.inDays;
    if (days < 30) {
      return '${days}d';
    }
    if (days < 365) {
      final months = (days / 30).round();
      return '${months}mo';
    }
    final years = (days / 365).round();
    return '${years}y';
  }

  /// Định dạng thời gian chi tiết có kèm tiếng Việt.
  static String formatNaturalVietnamese(Duration duration) {
    if (duration.inMinutes <= 1) {
      return '1 phút';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} phút';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours} giờ';
    }
    final days = duration.inDays;
    if (days < 30) {
      return '$days ngày';
    }
    if (days < 365) {
      final months = (days / 30).round();
      return '$months tháng';
    }
    final years = (days / 365).toStringAsFixed(1);
    return '$years năm';
  }
}
