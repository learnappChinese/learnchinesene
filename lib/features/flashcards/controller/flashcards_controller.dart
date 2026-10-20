import 'package:get/get.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';
import '../../../core/learning/service/spaced_repetition_service.dart';
import '../../../core/models/word.dart';

class FlashcardsController extends GetxController {
  FlashcardsController({
    DbHelper? database,
    LearningProgressSyncService? syncService,
    SpacedRepetitionService srsService = const SpacedRepetitionService(),
  })  : _database = database ?? DbHelper.instance,
        _syncService = syncService ?? _registeredSyncService(),
        _srsService = srsService;

  final DbHelper _database;
  final LearningProgressSyncService? _syncService;
  final SpacedRepetitionService _srsService;

  final deck = <Word>[].obs;
  final isLoading = false.obs;
  final isUnavailableLevel = false.obs;

  // Session stats
  final sessionReviewedCount = 0.obs;
  final sessionCorrectCount = 0.obs;
  final sessionXpEarned = 0.obs;
  final isSessionFinished = false.obs;

  int _request = 0;

  static LearningProgressSyncService? _registeredSyncService() {
    if (!Get.isRegistered<LearningProgressSyncService>()) return null;
    return Get.find<LearningProgressSyncService>();
  }

  /// Nạp danh sách thẻ từ vựng cho cấp độ được chọn.
  /// - `level == 0`: Các thẻ đến hạn ôn tập (Spaced Repetition Due)
  /// - `level 1..4`: Toàn bộ từ vựng thuộc HSK tương ứng (xáo trộn 30 từ)
  /// - `level > 4`: HSK 5-6 chưa mở
  Future<void> loadDeck(int level) async {
    if (isClosed) return;
    final request = ++_request;
    isLoading.value = true;
    isUnavailableLevel.value = false;
    isSessionFinished.value = false;
    sessionReviewedCount.value = 0;
    sessionCorrectCount.value = 0;
    sessionXpEarned.value = 0;
    deck.clear();

    try {
      if (level > 4) {
        isUnavailableLevel.value = true;
        return;
      }

      final words = <Word>[];
      if (level == 0) {
        words.addAll(await _database.getReviewWords(limit: 30));
      } else {
        // Fast single SQLite query
        words.addAll(await _database.getWordsByHskLevel(level, limit: 50));
      }

      if (isClosed || request != _request) return;
      words.shuffle();
      deck.assignAll(words.take(30));
    } catch (_) {
      // Giữ presentation danh sách rỗng nếu có lỗi
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  /// Đánh giá từ vựng theo thuật toán SM-2.
  Future<void> rate(Word word, String rating) async {
    if (isClosed) return;

    final srsRating = switch (rating) {
      'hard' => SrsRating.hard,
      'easy' => SrsRating.easy,
      _ => SrsRating.good,
    };

    final isCorrect = srsRating != SrsRating.hard;
    sessionReviewedCount.value++;
    if (isCorrect) {
      sessionCorrectCount.value++;
    }

    try {
      await _database.upsertProgress(
        wordId: word.id,
        isCorrect: isCorrect,
        rating: srsRating,
      );
    } catch (_) {}
  }

  /// Lấy trạng thái SRS hiện tại của từ vựng để hiển thị gợi ý (hints) trên nút.
  Future<SrsCardState> getWordSrsState(int wordId) async {
    if (AppDatabase.instance.isOpen) {
      final row = await AppDatabase.instance.getWordSrsState(wordId);
      if (row != null) {
        return SrsCardState.fromMap(row);
      }
    }
    return SrsCardState.initial();
  }

  /// Lấy gợi ý khoảng thời gian ôn tập tiếp theo cho một từ và mức đánh giá.
  Future<String> getIntervalHint(int wordId, SrsRating rating) async {
    final state = await getWordSrsState(wordId);
    return _srsService.getIntervalHint(state, rating);
  }

  /// Hoàn tất session ôn tập flashcard: cộng XP, cập nhật streak vào sổ cái SQLite.
  Future<int> finishSession() async {
    if (isClosed) return 0;
    var xpEarned = 0;
    try {
      if (AppDatabase.instance.isOpen) {
        xpEarned = await AppDatabase.instance.recordFlashcardSessionCompleted(
          cardsReviewed: sessionReviewedCount.value,
          correctCards: sessionCorrectCount.value,
        );
      } else {
        xpEarned = 10 + sessionCorrectCount.value * 2;
      }

      sessionXpEarned.value = xpEarned;
      isSessionFinished.value = true;

      try {
        await _syncService?.syncAfterLexiconChange();
      } catch (_) {}
    } catch (_) {}

    return xpEarned;
  }
}
