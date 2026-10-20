import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/database/local_guest_migration_service.dart';
import 'package:pandarin/core/learning/data/guest_learning_progress_store.dart';
import 'package:pandarin/core/learning/data/learning_progress_repository.dart';
import 'package:pandarin/core/learning/model/learning_activity_submission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalGuestMigrationService & Atomic Progress Tests', () {
    late AppDatabase appDb;
    late String testDbPath;
    int testIndex = 0;

    setUp(() async {
      testIndex++;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      testDbPath = p.join(
        Directory.systemTemp.path,
        'pandarin_stage2_test_${DateTime.now().microsecondsSinceEpoch}_$testIndex.db',
      );
      appDb = AppDatabase.instance;
      await appDb.init(customPath: testDbPath);
    });

    tearDown(() async {
      await appDb.close();
      try {
        final f = File(testDbPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    });

    test('1. Migration converts guest stages, bosses, attempts and XP to SQLite',
        () async {
      // Setup legacy guest data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'guest_learning_completed_stages_v1',
        jsonEncode(<String, dynamic>{
          '1:unit_1_stage_1': {
            'game_id': 1,
            'level_id': 'unit_1_stage_1',
            'unit_id': 'unit_1',
            'score': 95,
            'stars': 3,
            'attempts': 1,
            'passed': true,
            'completed_at': '2026-03-01T10:00:00.000Z',
            'activity_type': 'vocabulary',
          },
          '1:unit_1_stage_2': {
            'game_id': 1,
            'level_id': 'unit_1_stage_2',
            'unit_id': 'unit_1',
            'score': 88,
            'stars': 2,
            'attempts': 2,
            'passed': true,
            'completed_at': '2026-03-02T10:00:00.000Z',
            'activity_type': 'listening',
          },
        }),
      );

      await prefs.setString(
        'guest_learning_completed_bosses_v1',
        jsonEncode(<String, dynamic>{
          'unit_1': {
            'unit_id': 'unit_1',
            'stage_id': 10,
            'score': 100,
            'stars': 3,
            'attempts': 1,
            'won': true,
            'completed_at': '2026-03-03T10:00:00.000Z',
          },
        }),
      );

      await prefs.setStringList(
        'guest_learning_attempts_v2',
        <String>[
          jsonEncode(<String, dynamic>{
            'id': 'att_001',
            'activity_type': 'vocabulary',
            'source_type': 'duo_level',
            'source_id': '1:unit_1_stage_1',
            'unit_id': 'unit_1',
            'level_id': 'unit_1_stage_1',
            'started_at': '2026-03-01T09:55:00.000Z',
            'completed_at': '2026-03-01T10:00:00.000Z',
            'status': 'passed',
            'score': 95.0,
            'accuracy': 0.95,
            'correct_count': 19,
            'wrong_count': 1,
            'stars': 3,
            'duration_seconds': 300,
            'metadata': {'test': true},
          }),
        ],
      );

      await prefs.setStringList(
        'guest_learning_xp_events_v2',
        <String>[
          jsonEncode(<String, dynamic>{
            'event_key': 'xp_att_001',
            'source_type': 'duo_level',
            'source_id': '1:unit_1_stage_1',
            'base_xp': 20,
            'bonus_xp': 5,
            'xp_amount': 25,
            'created_at': '2026-03-01T10:00:00.000Z',
          }),
        ],
      );

      await prefs.setString(
        'guest_learning_stats_v2',
        jsonEncode(<String, dynamic>{
          'total_exp': 25,
          'current_streak': 1,
          'last_study_date': '2026-03-01T10:00:00.000Z',
        }),
      );

      // Execute migration
      final migrationService = LocalGuestMigrationService(
        database: appDb,
        prefs: prefs,
      );
      final result = await migrationService.migrateGuestDataToSqlite();

      expect(result.success, isTrue);
      expect(result.alreadyMigrated, isFalse);
      expect(result.rowsImported, greaterThanOrEqualTo(4));

      // Verify stages in SQLite
      final stages = await appDb.database.query(
        'local_stage_progress',
        orderBy: 'level_id ASC',
      );
      expect(stages.length, equals(3)); // 2 regular stages + 1 boss
      final stageIds = stages.map((s) => s['level_id']).toList();
      expect(stageIds, contains('unit_1_stage_1'));
      expect(stageIds, contains('unit_1_stage_2'));
      expect(stageIds, contains('boss:unit_1'));

      // Verify attempts in SQLite
      final attempts = await appDb.database.query('local_activity_attempts');
      expect(attempts.length, equals(1));
      expect(attempts.first['attempt_id'], equals('att_001'));
      expect(attempts.first['score'], equals(95.0));

      // Verify XP events and total XP in SQLite
      final xpEvents = await appDb.database.query('local_xp_events');
      expect(xpEvents.length, equals(1));
      expect(xpEvents.first['event_key'], equals('xp_att_001'));
      expect(xpEvents.first['xp_amount'], equals(25));

      final totalXp = await appDb.getTotalXp();
      expect(totalXp, equals(25));

      // Verify study days
      final studyDays = await appDb.database.query('local_study_days');
      expect(studyDays.length, greaterThanOrEqualTo(1));
      expect(studyDays.any((d) => d['local_date'] == '2026-03-01'), isTrue);

      // Verify migration log
      final log = await appDb.database.query('local_migration_log');
      expect(log.length, equals(1));
      expect(log.first['source_key'], equals('shared_preferences_guest_v1'));
    });

    test('2. Idempotency: re-running migration does not duplicate data or XP',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'guest_learning_completed_stages_v1',
        jsonEncode(<String, dynamic>{
          '1:level_test': {
            'game_id': 1,
            'level_id': 'level_test',
            'score': 100,
            'stars': 3,
            'passed': true,
          },
        }),
      );
      await prefs.setStringList(
        'guest_learning_xp_events_v2',
        <String>[
          jsonEncode(<String, dynamic>{
            'event_key': 'key_unique_1',
            'source_type': 'level',
            'source_id': 'level_test',
            'xp_amount': 50,
          }),
        ],
      );

      final migrationService = LocalGuestMigrationService(
        database: appDb,
        prefs: prefs,
      );

      // Run 1
      final result1 = await migrationService.migrateGuestDataToSqlite();
      expect(result1.success, isTrue);
      expect(result1.alreadyMigrated, isFalse);

      // Run 2 (without force) -> returns alreadyMigrated
      final result2 = await migrationService.migrateGuestDataToSqlite();
      expect(result2.success, isTrue);
      expect(result2.alreadyMigrated, isTrue);

      // Run 3 (with force = true) -> executes safely with ON CONFLICT & INSERT OR IGNORE
      final result3 = await migrationService.migrateGuestDataToSqlite(force: true);
      expect(result3.success, isTrue);

      // Check total XP is still exactly 50 (never doubled!)
      final totalXp = await appDb.getTotalXp();
      expect(totalXp, equals(50));

      final stages = await appDb.database.query('local_stage_progress');
      expect(stages.length, equals(1));
    });

    test('3. SharedPreferences keys are NOT wiped or deleted during migration',
        () async {
      final prefs = await SharedPreferences.getInstance();
      const stageJson = '{"1:node_a":{"game_id":1,"level_id":"node_a","passed":true}}';
      await prefs.setString('guest_learning_completed_stages_v1', stageJson);
      await prefs.setString('guest_learning_stats_v2', '{"total_exp":100}');

      final migrationService = LocalGuestMigrationService(
        database: appDb,
        prefs: prefs,
      );
      await migrationService.migrateGuestDataToSqlite();

      // Original SharedPreferences data must remain 100% intact
      expect(prefs.getString('guest_learning_completed_stages_v1'), equals(stageJson));
      expect(prefs.getString('guest_learning_stats_v2'), equals('{"total_exp":100}'));
    });

    test('4. Fallback baseline XP is created if total_exp in stats exceeds ledger',
        () async {
      final prefs = await SharedPreferences.getInstance();
      // stats has 200 XP, but ledger only has 1 event of 50 XP
      await prefs.setString(
        'guest_learning_stats_v2',
        jsonEncode(<String, dynamic>{'total_exp': 200}),
      );
      await prefs.setStringList(
        'guest_learning_xp_events_v2',
        <String>[
          jsonEncode(<String, dynamic>{
            'event_key': 'existing_xp_50',
            'xp_amount': 50,
          }),
        ],
      );

      final migrationService = LocalGuestMigrationService(
        database: appDb,
        prefs: prefs,
      );
      await migrationService.migrateGuestDataToSqlite();

      // Total XP in SQLite must match 200
      final totalXp = await appDb.getTotalXp();
      expect(totalXp, equals(200));

      // Should have 2 events: the original 50 + baseline delta of 150
      final events = await appDb.database.query('local_xp_events');
      expect(events.length, equals(2));
      final deltaEvent = events.firstWhere(
        (e) => e['event_key'] == 'legacy_guest_initial_xp_migration',
      );
      expect(deltaEvent['xp_amount'], equals(150));
    });

    test('5. Atomic Learning Completion persists to SQLite and handles double tap',
        () async {
      final repo = SupabaseLearningProgressRepository();
      const attemptId = 'test_attempt_123';
      final submission = LearningActivitySubmission(
        activityType: 'vocabulary',
        sourceType: 'duo_level',
        sourceId: '1:unit_1_stage_1',
        attemptId: attemptId,
        unitId: 'unit_1',
        levelId: 'unit_1_stage_1',
        score: 100.0,
        correctCount: 10,
        wrongCount: 0,
        durationSeconds: 120,
        bestCombo: 10,
      );

      // Start attempt
      await repo.startAttempt(submission);
      final startedAttempts = await appDb.database.query(
        'local_activity_attempts',
        where: 'attempt_id = ?',
        whereArgs: [attemptId],
      );
      expect(startedAttempts.length, equals(1));
      expect(startedAttempts.first['status'], equals('started'));

      // First complete
      final result1 = await repo.completeActivity(submission);
      expect(result1.passed, isTrue);
      expect(result1.xpEarned, greaterThan(0));

      // Verify SQLite records
      final completedAttempt = await appDb.database.query(
        'local_activity_attempts',
        where: 'attempt_id = ?',
        whereArgs: [attemptId],
      );
      expect(completedAttempt.first['status'], equals('passed'));

      final stageProgress = await appDb.database.query(
        'local_stage_progress',
        where: 'level_id = ?',
        whereArgs: ['unit_1_stage_1'],
      );
      expect(stageProgress.length, equals(1));
      expect(stageProgress.first['status'], equals('completed'));

      final xpBefore = await appDb.getTotalXp();
      expect(xpBefore, equals(result1.xpEarned));

      // Double-tap completion with same attempt
      final result2 = await repo.completeActivity(submission);
      expect(result2.idempotent, isTrue);

      // XP must NOT be awarded twice
      final xpAfter = await appDb.getTotalXp();
      expect(xpAfter, equals(xpBefore));
    });

    test('6. GuestLearningProgressStore reads & writes SQLite cohesively',
        () async {
      final store = GuestLearningProgressStore();

      expect(await store.isStagePassed(1, 'stage_xyz'), isFalse);

      await store.recordStagePassed(
        gameId: 1,
        levelId: 'stage_xyz',
        score: 90,
        stars: 3,
      );

      expect(await store.isStagePassed(1, 'stage_xyz'), isTrue);

      final passedKeys = await store.getAllPassedStageKeys();
      expect(passedKeys, contains('stage_xyz'));

      // Boss test
      expect(await store.isBossWon('unit_99'), isFalse);
      await store.recordBossWon(
        unitId: 'unit_99',
        stageId: 5,
        score: 100,
        stars: 3,
      );
      expect(await store.isBossWon('unit_99'), isTrue);

      final wonBosses = await store.getAllWonBossUnitIds();
      expect(wonBosses, contains('unit_99'));
    });
  });
}
