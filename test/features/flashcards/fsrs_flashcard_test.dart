import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/models/word.dart';
import 'package:pandarin/features/flashcards/models/flashcard_models.dart';
import 'package:pandarin/features/flashcards/services/fsrs_scheduler_service.dart';
import 'package:pandarin/features/flashcards/services/review_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FSRS Mathematical Algorithm Verification', () {
    late FsrsSchedulerService schedulerService;
    final fixedNow = DateTime.utc(2026, 10, 20, 12, 0, 0);

    setUp(() {
      schedulerService = FsrsSchedulerService(
        desiredRetention: 0.90,
        enableFuzzing: false,
      );
    });

    test('1. Thẻ mới chưa từng học: toFsrsCard khởi tạo state=learning, step=0', () {
      final card = schedulerService.toFsrsCard(null, 101);
      expect(card.cardId, equals(101));
      expect(card.state, equals(fsrs.State.learning));
      expect(card.step, equals(0));
      expect(card.stability, isNull);
      expect(card.difficulty, isNull);
    });

    test('2. Thẻ mới chọn Again: duy trì state=learning, step=0, khoảng cách 1 phút', () {
      final card = schedulerService.toFsrsCard(null, 101);
      final result = schedulerService.scheduler.reviewCard(
        card,
        fsrs.Rating.again,
        reviewDateTime: fixedNow,
      );

      expect(result.card.state, equals(fsrs.State.learning));
      expect(result.card.step, equals(0));
      expect(result.card.due.difference(fixedNow).inMinutes, equals(1));
      expect(result.card.stability, isNotNull);
      expect(result.card.difficulty, isNotNull);
    });

    test('3. Thẻ mới chọn Hard: duy trì state=learning, khoảng cách 5 phút', () {
      final card = schedulerService.toFsrsCard(null, 101);
      final result = schedulerService.scheduler.reviewCard(
        card,
        fsrs.Rating.hard,
        reviewDateTime: fixedNow,
      );

      expect(result.card.state, equals(fsrs.State.learning));
      expect(result.card.due.difference(fixedNow).inMinutes, equals(5));
    });

    test('4. Thẻ mới chọn Good: tiến bước lên step=1, khoảng cách 10 phút', () {
      final card = schedulerService.toFsrsCard(null, 101);
      final result = schedulerService.scheduler.reviewCard(
        card,
        fsrs.Rating.good,
        reviewDateTime: fixedNow,
      );

      expect(result.card.state, equals(fsrs.State.learning));
      expect(result.card.step, equals(1));
      expect(result.card.due.difference(fixedNow).inMinutes, equals(10));
    });

    test('5. Thẻ mới chọn Easy: tốt nghiệp ngay sang Review với khoảng cách tối đa 7 ngày', () {
      final card = schedulerService.toFsrsCard(null, 101);
      final result = schedulerService.reviewCard(
        progress: null,
        cardId: 101,
        rating: fsrs.Rating.easy,
        now: fixedNow,
      );

      expect(result.card.state, equals(fsrs.State.review));
      expect(result.card.due.difference(fixedNow).inDays, lessThanOrEqualTo(7));
      final hints = schedulerService.previewIntervalHints(null, 101, now: fixedNow);
      expect(hints[fsrs.Rating.easy], equals('7d'));
    });

    test('6. Thẻ đang Learning ở step 1 chọn Good: tốt nghiệp sang Review', () {
      final card = schedulerService.toFsrsCard(null, 101);
      // Lần 1: Good
      final step1 = schedulerService.scheduler.reviewCard(
        card,
        fsrs.Rating.good,
        reviewDateTime: fixedNow,
      ).card;
      expect(step1.step, equals(1));

      // Lần 2: Good
      final step2 = schedulerService.scheduler.reviewCard(
        step1,
        fsrs.Rating.good,
        reviewDateTime: fixedNow.add(const Duration(minutes: 10)),
      ).card;

      expect(step2.state, equals(fsrs.State.review));
      expect(step2.step, isNull);
      expect(step2.due.isAfter(fixedNow), isTrue);
    });

    test('7. Thẻ Review sau nhiều ngày chọn Again: chuyển sang Relearning và ghi nhận lapse', () {
      final card = schedulerService.toFsrsCard(null, 101);
      // Tốt nghiệp bằng Easy
      final reviewCard = schedulerService.scheduler.reviewCard(
        card,
        fsrs.Rating.easy,
        reviewDateTime: fixedNow,
      ).card;
      expect(reviewCard.state, equals(fsrs.State.review));

      // Đến hạn 20 ngày sau, người học bị quên và chọn Again
      final after20Days = fixedNow.add(const Duration(days: 20));
      final relearning = schedulerService.scheduler.reviewCard(
        reviewCard,
        fsrs.Rating.again,
        reviewDateTime: after20Days,
      ).card;

      expect(relearning.state, equals(fsrs.State.relearning));
      expect(relearning.due.difference(after20Days).inMinutes, equals(10));
      expect(relearning.stability, lessThan(reviewCard.stability!));
    });

    test('8. Preview thời gian trên 4 nút dự đoán chính xác theo scheduler', () {
      final hints = schedulerService.previewIntervalHints(null, 101, now: fixedNow);
      expect(hints[fsrs.Rating.again], equals('1m'));
      expect(hints[fsrs.Rating.hard], equals('5m'));
      expect(hints[fsrs.Rating.good], equals('10m'));
      expect(hints[fsrs.Rating.easy], contains('d'));
    });

    test('9. Thay đổi Desired Retention (0.80 vs 0.95) tạo chu kỳ ôn dài ngắn tương ứng', () {
      final scheduler80 = FsrsSchedulerService(desiredRetention: 0.80, maximumInterval: 365, enableFuzzing: false);
      final scheduler95 = FsrsSchedulerService(desiredRetention: 0.95, maximumInterval: 365, enableFuzzing: false);

      final card = fsrs.Card(cardId: 1);
      final easy80 = scheduler80.scheduler.reviewCard(card, fsrs.Rating.easy, reviewDateTime: fixedNow).card;
      final easy95 = scheduler95.scheduler.reviewCard(card, fsrs.Rating.easy, reviewDateTime: fixedNow).card;

      // Retention cao hơn (95%) đòi hỏi khoảng cách ôn ngắn hơn (ôn thường xuyên hơn)
      expect(easy95.due.difference(fixedNow).inDays, lessThan(easy80.due.difference(fixedNow).inDays));
    });
  });

  group('ReviewQueueService Intelligent Queue Verification', () {
    test('10. Hàng đợi khởi tạo và xác định số thẻ còn lại chính xác', () {
      final w1 = Word(
        id: 1,
        chinese: '你好',
        pinyin: 'nǐ hǎo',
        vietnamese: 'Xin chào',
        english: 'Hello',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'Chào hỏi',
        groupSubtitle: '',
      );
      final w2 = Word(
        id: 2,
        chinese: '谢谢',
        pinyin: 'xièxie',
        vietnamese: 'Cảm ơn',
        english: 'Thanks',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'Chào hỏi',
        groupSubtitle: '',
      );

      final item1 = FlashcardItem(word: w1);
      final item2 = FlashcardItem(word: w2);

      final queue = ReviewQueueService([item1, item2]);
      expect(queue.remainingCount, equals(2));
      expect(queue.currentCard?.word.id, equals(1));
    });

    test('11. Thẻ chọn Again trong session được đẩy về cuối hàng đợi ôn lại', () {
      final w1 = Word(
        id: 1,
        chinese: '你好',
        pinyin: 'nǐ hǎo',
        vietnamese: 'Xin chào',
        english: 'Hello',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'Chào hỏi',
        groupSubtitle: '',
      );
      final w2 = Word(
        id: 2,
        chinese: '谢谢',
        pinyin: 'xièxie',
        vietnamese: 'Cảm ơn',
        english: 'Thanks',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'Chào hỏi',
        groupSubtitle: '',
      );

      final item1 = FlashcardItem(word: w1);
      final item2 = FlashcardItem(word: w2);
      final queue = ReviewQueueService([item1, item2]);

      final scheduler = FsrsSchedulerService();
      final fsrsCard1 = scheduler.toFsrsCard(null, item1.cardId);
      final result1 = scheduler.scheduler.reviewCard(fsrsCard1, fsrs.Rating.again);

      queue.processCardRating(
        card: item1,
        rating: fsrs.Rating.again,
        updatedFsrsCard: result1.card,
      );

      // Thẻ 1 bị xếp lại phía sau, hiện tại đang làm thẻ 2
      expect(queue.currentCard?.word.id, equals(2));
      expect(queue.remainingCount, equals(2)); // Thẻ 2 + Thẻ 1 (ôn lại)
      expect(queue.reviewedCount, equals(1));
      expect(queue.againCount, equals(1));
    });

    test('12. Thẻ chọn Easy tốt nghiệp khỏi phiên học ngay lập tức', () {
      final w1 = Word(
        id: 1,
        chinese: '你好',
        pinyin: 'nǐ hǎo',
        vietnamese: 'Xin chào',
        english: 'Hello',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'Chào hỏi',
        groupSubtitle: '',
      );

      final item1 = FlashcardItem(word: w1);
      final queue = ReviewQueueService([item1]);

      final scheduler = FsrsSchedulerService();
      final fsrsCard1 = scheduler.toFsrsCard(null, item1.cardId);
      final result1 = scheduler.scheduler.reviewCard(fsrsCard1, fsrs.Rating.easy);

      queue.processCardRating(
        card: item1,
        rating: fsrs.Rating.easy,
        updatedFsrsCard: result1.card,
      );

      expect(queue.isEmpty, isTrue);
      expect(queue.reviewedCount, equals(1));
      expect(queue.easyCount, equals(1));
      expect(queue.accuracyPercent, equals(100.0));
    });
  });

  group('SQLite FSRS Local-First Persistence Verification', () {
    late AppDatabase appDb;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});

      appDb = AppDatabase.instance;
      await appDb.init(customPath: inMemoryDatabasePath);

      final packFile = File('assets/data/hsk_curriculum_pack_v1.json');
      if (packFile.existsSync()) {
        final jsonString = await packFile.readAsString();
        await appDb.ensureContentPackSeeded(jsonOverride: jsonString);
      }
    });

    tearDownAll(() async {
      await appDb.close();
    });

    test('13. fetchCardsForSession returns HSK 1 words properly ordered', () async {
      final cards = await appDb.fetchCardsForSession(hskLevel: 1, limit: 10);
      expect(cards, isNotEmpty);
      expect(cards.length, equals(10));
      for (final c in cards) {
        expect(c['hsk_level_id'], equals(1));
      }
    });

    test('14. recordFlashcardReviewAtomic writes progress, review log, streak, and XP atomically', () async {
      final now = DateTime.now().toUtc();
      final nextDue = now.add(const Duration(days: 4));

      await appDb.recordFlashcardReviewAtomic(
        cardId: 10,
        wordId: 1,
        rating: 3, // Good
        stateBefore: 0,
        stateAfter: 2, // Review
        dueAfterUtc: nextDue,
        stabilityAfter: 4.5,
        difficultyAfter: 5.0,
        scheduledDays: 4,
        reps: 1,
        lapses: 0,
        direction: 'zh_vi',
      );

      // 1. Kiểm tra local_flashcard_progress
      final progressRows = await appDb.database.query(
        'local_flashcard_progress',
        where: 'card_id = ?',
        whereArgs: [10],
      );
      expect(progressRows, isNotEmpty);
      expect(progressRows.first['state'], equals(2));
      expect(progressRows.first['scheduled_days'], equals(4));

      // 2. Kiểm tra local_flashcard_review_logs
      final logRows = await appDb.database.query(
        'local_flashcard_review_logs',
        where: 'card_id = ?',
        whereArgs: [10],
      );
      expect(logRows, isNotEmpty);
      expect(logRows.first['rating'], equals(3));
      expect(logRows.first['state_after'], equals(2));

      // 3. Kiểm tra đồng bộ sang local_word_srs
      final srsRows = await appDb.database.query(
        'local_word_srs',
        where: 'word_id = ?',
        whereArgs: [1],
      );
      expect(srsRows, isNotEmpty);
      expect(srsRows.first['srs_stage'], equals(2));

      // 4. Kiểm tra tổng XP được cộng
      final totalXp = await appDb.getTotalXp();
      expect(totalXp, greaterThan(0));

      // 5. Kiểm tra streak ghi nhận
      final streak = await appDb.getCurrentStreak();
      expect(streak, greaterThanOrEqualTo(1));
    });

    test('15. getFlashcardDecksHierarchy returns sections with real counts', () async {
      final decks = await appDb.getFlashcardDecksHierarchy();
      expect(decks, isNotEmpty);
      final firstLevel = decks.first;
      expect(firstLevel['level'], isNotNull);
      final sections = firstLevel['sections'] as List;
      expect(sections, isNotEmpty);
      final firstSection = sections.first as Map<String, dynamic>;
      expect(firstSection['total_words'], greaterThan(0));
    });

    test('16. getCharactersForWord retrieves matching Hanzi for writing practice', () async {
      final characters = await appDb.getCharactersForWord('你好');
      expect(characters, isNotEmpty);
      final chars = characters.map((c) => c['character'] as String).toList();
      expect(chars, contains('你'));
    });

    test('17. Settings persistence: saveFlashcardSettings updates values', () async {
      await appDb.saveFlashcardSettings({
        'desired_retention': 0.95,
        'new_cards_per_day': 30,
        'max_reviews_per_day': 150,
        'card_direction': 'vi_zh',
        'auto_play_audio': 1,
        'preset_name': 'Chuyên sâu',
      });

      final settings = await appDb.getFlashcardSettings();
      expect(settings['desired_retention'], equals(0.95));
      expect(settings['new_cards_per_day'], equals(30));
      expect(settings['preset_name'], equals('Chuyên sâu'));
    });
  });
}
