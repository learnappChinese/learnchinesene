import 'package:fsrs/fsrs.dart' as fsrs;

import '../models/flashcard_models.dart';

/// Quản lý hàng đợi ôn tập thông minh (Review Queue) trong một phiên học.
/// Ưu tiên thẻ đến hạn ôn (Due) trước thẻ mới (New), và tái lập lịch các thẻ Learning/Again
/// ngay trong cùng phiên học khi interval ngắn (<= 15 phút).
class ReviewQueueService {
  final List<FlashcardItem> _queue = [];
  final List<FlashcardItem> _completedSessionCards = [];

  int _reviewedCount = 0;
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;

  ReviewQueueService([List<FlashcardItem>? initialCards]) {
    if (initialCards != null && initialCards.isNotEmpty) {
      _queue.addAll(initialCards);
    }
  }

  void initializeQueue(List<FlashcardItem> cards) {
    _queue.clear();
    _completedSessionCards.clear();
    _reviewedCount = 0;
    _againCount = 0;
    _hardCount = 0;
    _goodCount = 0;
    _easyCount = 0;
    _queue.addAll(cards);
  }

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int get remainingCount => _queue.length;
  int get reviewedCount => _reviewedCount;
  int get againCount => _againCount;
  int get hardCount => _hardCount;
  int get goodCount => _goodCount;
  int get easyCount => _easyCount;

  int get correctCount => _goodCount + _easyCount;
  double get accuracyPercent =>
      _reviewedCount == 0 ? 100.0 : ((correctCount / _reviewedCount) * 100).clamp(0.0, 100.0);

  FlashcardItem? get currentCard => _queue.isNotEmpty ? _queue.first : null;

  /// Xử lý sau khi người dùng đánh giá thẻ hiện tại.
  /// Nếu thẻ có interval ngắn (<= 15 phút, ví dụ Again hoặc bước Learning 1m/10m),
  /// thẻ sẽ được đẩy về phía sau hàng đợi để kiểm tra lại trước khi kết thúc session.
  void processCardRating({
    required FlashcardItem card,
    required fsrs.Rating rating,
    required fsrs.Card updatedFsrsCard,
  }) {
    if (_queue.isEmpty) return;

    // Loại bỏ thẻ vừa làm khỏi đầu hàng đợi
    _queue.removeAt(0);
    _reviewedCount++;

    switch (rating) {
      case fsrs.Rating.again:
        _againCount++;
        break;
      case fsrs.Rating.hard:
        _hardCount++;
        break;
      case fsrs.Rating.good:
        _goodCount++;
        break;
      case fsrs.Rating.easy:
        _easyCount++;
        break;
    }

    final now = DateTime.now().toUtc();
    final nextDueDiff = updatedFsrsCard.due.difference(now);

    // Cập nhật tiến độ của thẻ
    final updatedProgress = FlashcardProgress(
      cardId: updatedFsrsCard.cardId,
      wordId: card.word.id,
      direction: card.direction.code,
      state: FlashcardCardState.fromValue(updatedFsrsCard.state.value),
      step: updatedFsrsCard.step,
      stability: updatedFsrsCard.stability,
      difficulty: updatedFsrsCard.difficulty,
      dueAtUtc: updatedFsrsCard.due,
      lastReviewAtUtc: now,
      reps: (card.progress?.reps ?? 0) + 1,
      lapses: (card.progress?.lapses ?? 0) + (rating == fsrs.Rating.again ? 1 : 0),
      scheduledDays: nextDueDiff.inDays,
    );

    final updatedItem = FlashcardItem(
      word: card.word,
      progress: updatedProgress,
      examples: card.examples,
      characters: card.characters,
      direction: card.direction,
    );

    // Nếu thời gian gặp lại ngắn (<= 15 phút) và chưa tốt nghiệp sang Review:
    // Tái xếp hàng thẻ vào cuối hàng đợi để người học ôn lại trong buổi học
    if (nextDueDiff.inMinutes <= 15 && updatedFsrsCard.state != fsrs.State.review) {
      _queue.add(updatedItem);
    } else {
      _completedSessionCards.add(updatedItem);
    }
  }
}
