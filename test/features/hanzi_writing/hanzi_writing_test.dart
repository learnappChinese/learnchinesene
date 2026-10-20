import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/database/db_helper.dart';
import 'package:pandarin/core/learning/data/guest_learning_progress_store.dart';
import 'package:pandarin/core/learning/data/learning_progress_repository.dart';
import 'package:pandarin/core/learning/model/learning_source_context.dart';
import 'package:pandarin/core/learning/service/learning_reward_service.dart';
import 'package:pandarin/core/models/hanzi_character.dart';
import 'package:pandarin/features/hanzi_writing/controller/hanzi_writing_controller.dart';
import 'package:pandarin/features/hanzi_writing/models/hanzi_practice_config.dart';
import 'package:pandarin/features/hanzi_writing/services/hanzi_stroke_cache.dart';
import 'package:pandarin/features/hanzi_writing/services/svg_stroke_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HanziStrokeCache & SvgStrokeParser Verification', () {
    setUp(() {
      HanziStrokeCache.instance.clear();
    });

    test('1. SvgStrokeParser parses valid stroke path data', () {
      const sampleSvg =
          'M 10 10 L 90 10 | M 50 10 L 50 90';
      final paths = SvgStrokeParser.parseStrokesToPaths(sampleSvg);
      expect(paths, hasLength(2));
      expect(paths.first, isA<Path>());
    });

    test('2. HanziStrokeCache stores and retrieves character metadata and paths', () {
      final cache = HanziStrokeCache.instance;
      expect(cache.getCharacter(101), isNull);
      expect(cache.getPaths(101), isNull);

      final char = HanziCharacter.fromMap({
        'id': 101,
        'character': '一',
        'stroke_count': 1,
        'stroke_paths': 'M 10 50 L 90 50',
      });

      cache.putCharacter(char);
      expect(cache.getCharacter(101)?.character, equals('一'));

      final paths = SvgStrokeParser.parseStrokesToPaths(char.strokePathData);
      cache.putPaths(101, paths);
      expect(cache.getPaths(101), hasLength(1));
    });

    test('3. HanziStrokeCache prefetch parses and caches multiple characters', () {
      final cache = HanziStrokeCache.instance;
      final characters = [
        HanziCharacter.fromMap({
          'id': 1,
          'character': '一',
          'stroke_count': 1,
          'stroke_paths': 'M 10 50 L 90 50',
        }),
        HanziCharacter.fromMap({
          'id': 2,
          'character': '二',
          'stroke_count': 2,
          'stroke_paths': 'M 20 30 L 80 30 | M 10 70 L 90 70',
        }),
      ];

      cache.prefetch(characters);

      expect(cache.getCharacter(1)?.character, equals('一'));
      expect(cache.getPaths(1), hasLength(1));
      expect(cache.getCharacter(2)?.character, equals('二'));
      expect(cache.getPaths(2), hasLength(2));
    });
  });

  group('Slice 5 — Hanzi Writing Local-First Integration', () {
    late AppDatabase appDb;
    late LearningProgressRepository progressRepo;
    late LearningRewardService rewardService;
    late GuestLearningProgressStore guestStore;

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

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      guestStore = GuestLearningProgressStore();
      progressRepo = SupabaseLearningProgressRepository(
        guestStore: guestStore,
      );
      rewardService = LearningRewardService(
        repository: progressRepo,
      );
    });

    tearDownAll(() async {
      await appDb.close();
    });

    test('4. Fast 1-row lookup via getCharacterById in SQLite without scanning catalog', () async {
      final dbHelper = DbHelper.instance;
      final char = await dbHelper.getCharacterForWritingById(1);

      expect(char, isNotNull);
      expect(char!.id, equals(1));
      expect(char.character.isNotEmpty, isTrue);
      expect(char.strokePathData.isNotEmpty, isTrue);
    });

    test('5. getCharactersByHskLevel returns only characters for that HSK level', () async {
      final dbHelper = DbHelper.instance;
      final hsk1Chars = await dbHelper.getCharactersForWriting(hskLevel: 1);

      expect(hsk1Chars.isNotEmpty, isTrue);
      for (final c in hsk1Chars) {
        expect(c.hskLevel, equals(1));
      }
    });

    test('6. nextCharacter with characterSequence advances in O(1) without DB query', () async {
      final controller = HanziWritingController(
        characterSequence: [10, 20, 30],
      );

      final next1 = await controller.nextCharacter(10);
      expect(next1.id, equals(20));
      expect(next1.hasCharacters, isTrue);

      final next2 = await controller.nextCharacter(20);
      expect(next2.id, equals(30));
      expect(next2.hasCharacters, isTrue);

      final next3 = await controller.nextCharacter(30);
      expect(next3.id, isNull);
      expect(next3.hasCharacters, isTrue);
    });

    test('7. Saving a Hanzi writing session records into local_hanzi_progress', () async {
      final controller = HanziWritingController(
        rewardService: rewardService,
      );

      final rounds = [
        const HanziRoundResult(
          roundNumber: 1,
          mode: HanziPracticeMode.guidedTrace,
          drawnStrokeCount: 2,
          attemptCount: 2,
          score: 95.0,
          durationMilliseconds: 1500,
        ),
        const HanziRoundResult(
          roundNumber: 2,
          mode: HanziPracticeMode.fromScratch,
          drawnStrokeCount: 2,
          attemptCount: 3,
          score: 90.0,
          durationMilliseconds: 2000,
        ),
      ];

      await controller.saveProgress(
        1,
        rounds,
        sourceContext: const LearningSourceContext(
          courseId: 'duo_chinese',
          duoUnitId: 'unit_1',
          lexiconUnitId: 1,
          levelId: 'level_1_2',
          gameCode: 'hanzi',
          mode: LearningMode.duoMission,
        ),
      );

      expect(controller.learningResult.value, isNotNull);
      expect(controller.learningResult.value!.passed, isTrue);
      expect(controller.learningResult.value!.xpEarned, greaterThan(0));

      // Verify persistence in local_hanzi_progress table
      final progressRow = await appDb.getHanziProgress(1);
      expect(progressRow, isNotNull);
      expect(progressRow!['character_id'], equals(1));
      expect(progressRow['attempts'], equals(5));
      expect(progressRow['best_accuracy'], equals(92.5));
      expect(progressRow['is_mastered'], equals(1));

      // Verify persistence in immutable XP events ledger
      final totalXp = await appDb.getTotalXp();
      expect(totalXp, greaterThan(0));

      // Verify streak recorded in local_study_days
      final streak = await appDb.getCurrentStreak();
      expect(streak, greaterThanOrEqualTo(1));
    });

    test('8. Re-querying character tile returns updated practice_count and best_score', () async {
      final dbHelper = DbHelper.instance;
      final char = await dbHelper.getCharacterForWritingById(1);

      expect(char, isNotNull);
      expect(char!.practiceCount, greaterThanOrEqualTo(5));
      expect(char.bestScore, greaterThanOrEqualTo(90.0));
    });

    test('9. Writing session completion marks curriculum stage completed in local_stage_progress', () async {
      final rows = await appDb.database.query(
        'local_stage_progress',
        where: 'level_id = ?',
        whereArgs: ['level_1_2'],
      );

      expect(rows, isNotEmpty);
      expect(rows.first['status'], equals('completed'));
    });
  });
}
