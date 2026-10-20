import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/word.dart';
import '../../../core/services/tts_service.dart';
import '../models/flashcard_models.dart';
import '../services/fsrs_scheduler_service.dart';
import '../services/review_queue_service.dart';

/// Controller quản lý phiên học và ôn tập Flashcard theo thuật toán FSRS.
class FlashcardsStudyController extends GetxController {
  final isLoading = true.obs;
  final isSessionFinished = false.obs;
  final isFlipped = false.obs;
  final isAnswering = false.obs;

  final queueService = ReviewQueueService();
  late FsrsSchedulerService schedulerService;

  final currentItem = Rxn<FlashcardItem>();
  final remainingCount = 0.obs;
  final reviewedCount = 0.obs;
  final sessionXpEarned = 0.obs;

  // Gợi ý khoảng thời gian hiển thị trên 4 nút đánh giá
  final againHint = '1m'.obs;
  final hardHint = '5m'.obs;
  final goodHint = '10m'.obs;
  final easyHint = '7d'.obs;

  // Cấu hình phiên học
  final FlashcardDirection direction;
  final int? hskLevel;
  final int? unitId;
  final List<int>? unitIds;
  final bool onlyDue;
  final bool onlyNew;
  final int cardLimit;

  DateTime? _cardShownAt;

  FlashcardsStudyController({
    this.direction = FlashcardDirection.zhToVi,
    this.hskLevel,
    this.unitId,
    this.unitIds,
    this.onlyDue = false,
    this.onlyNew = false,
    this.cardLimit = 20,
  });

  @override
  void onInit() {
    super.onInit();
    _initAndLoadSession();
  }

  Future<void> _initAndLoadSession() async {
    isLoading.value = true;
    try {
      // 1. Tải cấu hình FSRS từ database
      final settings = await AppDatabase.instance.getFlashcardSettings();
      final retention = (settings['desired_retention'] as num?)?.toDouble() ?? 0.90;
      final maxInterval =
          ((settings['maximum_interval'] as num?)?.toInt() ?? 7).clamp(1, 7);

      schedulerService = FsrsSchedulerService(
        desiredRetention: retention,
        maximumInterval: maxInterval,
      );

      // 2. Nạp danh sách thẻ từ SQLite
      final rawCards = await AppDatabase.instance.fetchCardsForSession(
        hskLevel: hskLevel,
        unitId: unitId,
        unitIds: unitIds,
        onlyDue: onlyDue,
        onlyNew: onlyNew,
        limit: cardLimit,
        direction: direction.code,
      );

      final List<FlashcardItem> items = [];
      for (final row in rawCards) {
        final wordId = (row['id'] as num?)?.toInt() ?? (row['word_id'] as num?)?.toInt() ?? 0;
        final word = Word(
          id: wordId,
          chinese: row['word'] as String? ?? '',
          pinyin: row['pinyin'] as String? ?? '',
          vietnamese: row['meaning_vi'] as String? ?? '',
          english: row['meaning_en'] as String? ?? '',
          ttsUrl: row['tts_url'] as String? ?? '',
          hskLevelId: (row['hsk_level_id'] as num?)?.toInt() ?? 1,
          sectionTitle: row['unit_title'] as String? ?? '',
          groupSubtitle: '',
        );

        FlashcardProgress? progress;
        if (row['card_id'] != null) {
          progress = FlashcardProgress.fromMap(row);
        }

        // Lấy câu ví dụ và chữ Hán liên quan
        final examples = await AppDatabase.instance.getWordExamples(word.id);
        final characters = await AppDatabase.instance.getCharactersForWord(word.chinese);

        items.add(FlashcardItem(
          word: word,
          progress: progress,
          examples: examples,
          characters: characters,
          direction: direction,
        ));
      }

      queueService.initializeQueue(items);
      _prepareCurrentCard();
    } catch (e) {
      debugPrint('FlashcardsStudyController init error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _prepareCurrentCard() {
    if (queueService.isEmpty) {
      currentItem.value = null;
      remainingCount.value = 0;
      _finishSession();
      return;
    }

    final card = queueService.currentCard!;
    currentItem.value = card;
    remainingCount.value = queueService.remainingCount;
    reviewedCount.value = queueService.reviewedCount;
    isFlipped.value = false;
    isAnswering.value = false;
    _cardShownAt = DateTime.now();

    // Tính trước preview khoảng thời gian cho 4 nút theo FSRS
    final hints = schedulerService.previewIntervalHints(
      card.progress,
      card.cardId,
    );

    againHint.value = hints[fsrs.Rating.again] ?? '1m';
    hardHint.value = hints[fsrs.Rating.hard] ?? '5m';
    goodHint.value = hints[fsrs.Rating.good] ?? '10m';
    easyHint.value = hints[fsrs.Rating.easy] ?? '4d';
  }

  /// Lật thẻ
  void flipCard() {
    isFlipped.value = !isFlipped.value;
  }

  /// Phát âm thanh từ vựng qua TTS
  Future<void> playAudio() async {
    final card = currentItem.value;
    if (card == null) return;
    try {
      final tts = Get.isRegistered<TtsService>()
          ? Get.find<TtsService>()
          : TtsService();
      await tts.speak(card.word.chinese);
    } catch (_) {}
  }

  /// Đánh giá mức độ nhớ theo 4 nút chuẩn Anki (Again, Hard, Good, Easy)
  Future<void> rateCard(fsrs.Rating rating) async {
    if (isAnswering.value || currentItem.value == null) return;
    isAnswering.value = true;

    final card = currentItem.value!;
    final durationMs = _cardShownAt != null
        ? DateTime.now().difference(_cardShownAt!).inMilliseconds
        : 0;

    try {
      // 1. Tính toán lịch ôn và ReviewLog theo FSRS
      final result = schedulerService.reviewCard(
        progress: card.progress,
        cardId: card.cardId,
        rating: rating,
        durationMs: durationMs,
      );

      final stateBefore = card.progress?.state.value ?? 0;
      final stateAfter = result.card.state.value;
      final dueBefore = card.progress?.dueAtUtc;

      // 2. Ghi nhận giao dịch nguyên tử vào SQLite
      await AppDatabase.instance.recordFlashcardReviewAtomic(
        cardId: card.cardId,
        wordId: card.word.id,
        rating: rating.value,
        stateBefore: stateBefore,
        stateAfter: stateAfter,
        dueAfterUtc: result.card.due,
        stabilityAfter: result.card.stability ?? 1.0,
        difficultyAfter: result.card.difficulty ?? 5.0,
        dueBeforeUtc: dueBefore,
        lastReviewUtc: DateTime.now().toUtc(),
        step: result.card.step,
        durationMs: durationMs,
        scheduledDays: result.card.due.difference(DateTime.now().toUtc()).inDays,
        reps: (card.progress?.reps ?? 0) + 1,
        lapses: (card.progress?.lapses ?? 0) + (rating == fsrs.Rating.again ? 1 : 0),
        direction: card.direction.code,
      );

      // 3. Cập nhật ReviewQueue
      queueService.processCardRating(
        card: card,
        rating: rating,
        updatedFsrsCard: result.card,
      );

      // 4. Chuyển sang thẻ tiếp theo
      _prepareCurrentCard();
    } catch (e) {
      debugPrint('rateCard error: $e');
    } finally {
      isAnswering.value = false;
    }
  }

  Future<void> _finishSession() async {
    isSessionFinished.value = true;
    final xp = await AppDatabase.instance.recordFlashcardSessionCompleted(
      cardsReviewed: queueService.reviewedCount,
      correctCards: queueService.correctCount,
    );
    sessionXpEarned.value = xp;
  }
}
