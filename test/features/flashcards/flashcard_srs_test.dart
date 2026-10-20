import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/database/db_helper.dart';
import 'package:pandarin/core/learning/service/spaced_repetition_service.dart';
import 'package:pandarin/core/models/word.dart';
import 'package:pandarin/features/flashcards/controller/flashcards_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SM-2 SpacedRepetitionService Algorithmic Verification', () {
    const srs = SpacedRepetitionService();
    final fixedNow = DateTime.utc(2026, 10, 20, 12, 0, 0);

    test('1. Initial state has default values', () {
      final initial = SrsCardState.initial();
      expect(initial.srsStage, equals(0));
      expect(initial.easeFactor, equals(2.5));
      expect(initial.intervalDays, equals(0));
      expect(initial.repetitionCount, equals(0));
      expect(initial.isMastered, isFalse);
    });

    test('2. First successful recall (Good) sets interval=1, repetition=1', () {
      final initial = SrsCardState.initial();
      final next = srs.calculateNextState(
        current: initial,
        rating: SrsRating.good,
        now: fixedNow,
      );

      expect(next.srsStage, equals(1));
      expect(next.repetitionCount, equals(1));
      expect(next.intervalDays, equals(1));
      expect(next.easeFactor, equals(2.5));
      expect(next.nextReviewAt, equals(fixedNow.add(const Duration(days: 1))));
      expect(next.correctCount, equals(1));
      expect(next.wrongCount, equals(0));
      expect(srs.getIntervalHint(initial, SrsRating.good), equals('Ngày mai'));
    });

    test('3. First recall (Easy) sets interval=1, increases Ease Factor to 2.6',
        () {
      final initial = SrsCardState.initial();
      final next = srs.calculateNextState(
        current: initial,
        rating: SrsRating.easy,
        now: fixedNow,
      );

      expect(next.srsStage, equals(1));
      expect(next.repetitionCount, equals(1));
      expect(next.intervalDays, equals(1));
      expect(next.easeFactor, equals(2.6));
    });

    test('4. Second recall (Good vs Easy) expands interval to 4 or 6 days', () {
      final stage1 = SrsCardState(
        srsStage: 1,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitionCount: 1,
      );

      final nextGood = srs.calculateNextState(
        current: stage1,
        rating: SrsRating.good,
        now: fixedNow,
      );
      expect(nextGood.intervalDays, equals(4));
      expect(nextGood.repetitionCount, equals(2));
      expect(srs.getIntervalHint(stage1, SrsRating.good), equals('4 ngày'));

      final nextEasy = srs.calculateNextState(
        current: stage1,
        rating: SrsRating.easy,
        now: fixedNow,
      );
      expect(nextEasy.intervalDays, equals(6));
      expect(nextEasy.repetitionCount, equals(2));
      expect(srs.getIntervalHint(stage1, SrsRating.easy), equals('6 ngày'));
    });

    test('5. Third recall multiplies interval by Ease Factor', () {
      final stage2 = SrsCardState(
        srsStage: 2,
        easeFactor: 2.5,
        intervalDays: 4,
        repetitionCount: 2,
      );

      final next = srs.calculateNextState(
        current: stage2,
        rating: SrsRating.good,
        now: fixedNow,
      );

      expect(next.intervalDays, equals(10)); // 4 * 2.5 = 10
      expect(next.repetitionCount, equals(3));
      expect(next.srsStage, equals(3));
      expect(srs.getIntervalHint(stage2, SrsRating.good), equals('1 tuần'));
    });

    test('6. Rating Hard resets repetitions and sets interval to 1 day', () {
      final advanced = SrsCardState(
        srsStage: 3,
        easeFactor: 2.5,
        intervalDays: 10,
        repetitionCount: 3,
      );

      final next = srs.calculateNextState(
        current: advanced,
        rating: SrsRating.hard,
        now: fixedNow,
      );

      expect(next.repetitionCount, equals(0));
      expect(next.intervalDays, equals(1));
      expect(next.srsStage, equals(0));
      expect(next.wrongCount, equals(1));
      expect(next.easeFactor, lessThan(2.5));
      expect(next.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('7. Mastery is reached after stage 4 or 21+ days interval', () {
      final nearMastery = SrsCardState(
        srsStage: 3,
        easeFactor: 2.5,
        intervalDays: 10,
        repetitionCount: 3,
      );

      final mastered = srs.calculateNextState(
        current: nearMastery,
        rating: SrsRating.good,
        now: fixedNow,
      );

      expect(mastered.srsStage, equals(4));
      expect(mastered.isMastered, isTrue);
    });
  });

  group('Slice 4 — Flashcard & SRS Local-First Integration', () {
    late AppDatabase appDb;
    late FlashcardsController controller;

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

    setUp(() {
      controller = FlashcardsController();
    });

    tearDownAll(() async {
      await appDb.close();
    });

    test('8. Offline Deck Loading for HSK 1 returns up to 30 words fast',
        () async {
      await controller.loadDeck(1);
      expect(controller.isLoading.value, isFalse);
      expect(controller.isUnavailableLevel.value, isFalse);
      expect(controller.deck.length, inInclusiveRange(1, 30));

      final firstWord = controller.deck.first;
      expect(firstWord.chinese, isNotEmpty);
      expect(firstWord.vietnamese, isNotEmpty);
    });

    test('9. HSK 5 and 6 are marked as unavailable gracefully', () async {
      await controller.loadDeck(5);
      expect(controller.isUnavailableLevel.value, isTrue);
      expect(controller.deck, isEmpty);

      await controller.loadDeck(6);
      expect(controller.isUnavailableLevel.value, isTrue);
      expect(controller.deck, isEmpty);
    });

    test('10. Rating a word persists real SM-2 values into local_word_srs table',
        () async {
      final testWord = Word(
        id: 101,
        chinese: '你好',
        pinyin: 'nǐ hǎo',
        vietnamese: 'Xin chào',
        english: 'Hello',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'HSK 1',
        groupSubtitle: '',
      );

      // First rating: Good
      await controller.rate(testWord, 'good');

      var row = await appDb.getWordSrsState(101);
      expect(row, isNotNull);
      expect(row!['srs_stage'], equals(1));
      expect(row['interval_days'], equals(1));
      expect(row['repetition_count'], equals(1));
      expect(row['correct_count'], equals(1));
      expect(row['wrong_count'], equals(0));

      // Second rating: Easy -> interval should jump to 6
      await controller.rate(testWord, 'easy');
      row = await appDb.getWordSrsState(101);
      expect(row!['srs_stage'], equals(2));
      expect(row['interval_days'], equals(6));
      expect(row['repetition_count'], equals(2));
      expect(row['correct_count'], equals(2));
      expect(row['ease_factor'], greaterThan(2.5));
    });

    test(
        '11. Rating Hard resets repetitions and records mistake in local_word_srs',
        () async {
      final testWord = Word(
        id: 102,
        chinese: '谢谢',
        pinyin: 'xièxie',
        vietnamese: 'Cảm ơn',
        english: 'Thanks',
        ttsUrl: '',
        hskLevelId: 1,
        sectionTitle: 'HSK 1',
        groupSubtitle: '',
      );

      // First rating: Good
      await controller.rate(testWord, 'good');

      // Second rating: Hard (forgot)
      await controller.rate(testWord, 'hard');

      final row = await appDb.getWordSrsState(102);
      expect(row!['srs_stage'], equals(0));
      expect(row['interval_days'], equals(1));
      expect(row['repetition_count'], equals(0));
      expect(row['wrong_count'], equals(1));
    });

    test('12. Due SRS query returns words needing review', () async {
      final dueWords = await appDb.getDueSrsWords();
      expect(dueWords, isNotEmpty);
      // Word 102 has wrong_count > 0 so it must be in the due list
      final ids = dueWords.map((r) => (r['id'] as num).toInt()).toList();
      expect(ids.contains(102), isTrue);
    });

    test(
        '13. Finishing flashcard session awards XP to ledger and records study day',
        () async {
      final initialXp = await appDb.getTotalXp();

      // Simulate reviewing 5 cards with 4 correct
      controller.sessionReviewedCount.value = 5;
      controller.sessionCorrectCount.value = 4;

      final xpEarned = await controller.finishSession();
      // Base XP = 10, bonus = 4 * 2 = 8 -> total = 18
      expect(xpEarned, equals(18));
      expect(controller.sessionXpEarned.value, equals(18));
      expect(controller.isSessionFinished.value, isTrue);

      final newTotalXp = await appDb.getTotalXp();
      expect(newTotalXp, equals(initialXp + 18));

      // Check streak and study day
      final streak = await appDb.getCurrentStreak();
      expect(streak, greaterThanOrEqualTo(1));

      final stats = await DbHelper.instance.getStats();
      expect(stats['totalExp'], equals(newTotalXp));
      expect(stats['streak'], equals(streak));
    });
  });
}
