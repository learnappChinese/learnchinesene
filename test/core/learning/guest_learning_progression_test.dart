import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flash_learn_chinese/core/learning/data/guest_learning_progress_store.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_journey_models.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';
import 'package:flash_learn_chinese/core/learning/service/guest_journey_resolver.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_rules_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GuestLearningProgressStore store;
  late GuestJourneyResolver resolver;

  final sampleUnitPath = <Map<String, dynamic>>[
    {
      'node_id': '1:level_01',
      'node_type': 'learning',
      'node_order': 1,
      'game_id': 1,
      'game_code': 'learn_words',
      'level_id': 'level_01',
      'is_unlocked': true,
      'is_completed': false,
      'required_node_id': null,
    },
    {
      'node_id': '2:level_02',
      'node_type': 'learning',
      'node_order': 2,
      'game_id': 2,
      'game_code': 'listen_select',
      'level_id': 'level_02',
      'is_unlocked': false,
      'is_completed': false,
      'required_node_id': '1:level_01',
    },
    {
      'node_id': '3:level_03',
      'node_type': 'learning',
      'node_order': 3,
      'game_id': 3,
      'game_code': 'speak_phrase',
      'level_id': 'level_03',
      'is_unlocked': false,
      'is_completed': false,
      'required_node_id': '2:level_02',
    },
    {
      'node_id': 'boss:boss_01',
      'node_type': 'boss',
      'node_order': 4,
      'boss_stage_id': 1,
      'boss_name': 'Hắc Phong Ma Vương',
      'is_unlocked': false,
      'is_completed': false,
    },
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = GuestLearningProgressStore();
    resolver = const GuestJourneyResolver();
  });

  group('P0 Guest Learning Progression — Requirement Verification', () {
    test('1. Guest mới -> Stage 1 available, Stage 2 và Boss locked', () async {
      final overlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        overallMastery: 0.0,
        isUnitUnlocked: true,
      );

      expect(overlaid[0]['is_unlocked'], isTrue, reason: 'Stage 1 phải mở');
      expect(overlaid[0]['is_completed'], isFalse);

      expect(overlaid[1]['is_unlocked'], isFalse, reason: 'Stage 2 phải khóa');
      expect(overlaid[1]['is_completed'], isFalse);

      expect(overlaid[2]['is_unlocked'], isFalse, reason: 'Stage 3 phải khóa');
      expect(overlaid[3]['is_unlocked'], isFalse, reason: 'Boss phải khóa');
    });

    test('2 & 3. Pass Stage 1 -> Stage 2 available (kể cả khác gameCode)',
        () async {
      await store.recordStagePassed(
        gameId: 1,
        levelId: 'level_01',
        unitId: 'unit_01',
        score: 100,
        stars: 3,
        activityType: 'vocabulary',
      );

      final overlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        overallMastery: 0.5,
        isUnitUnlocked: true,
      );

      expect(overlaid[0]['is_completed'], isTrue);
      expect(overlaid[1]['is_unlocked'], isTrue,
          reason:
              'Stage 2 (listen_select) phải mở sau khi pass Stage 1 (learn_words)');
      expect(overlaid[2]['is_unlocked'], isFalse);
      expect(overlaid[3]['is_unlocked'], isFalse);

      final nextResolution = await resolver.resolveNextNodeAfterStageCompletion(
        unitId: 'unit_01',
        completedGameId: 1,
        completedLevelId: 'level_01',
        pathRows: sampleUnitPath,
        store: store,
        overallMastery: 0.5,
      );

      expect(nextResolution.nextNodeId, '2:level_02');
      expect(nextResolution.unlockedNext, isTrue);
      expect(nextResolution.bossReady, isFalse);
    });

    test('4. Failed Stage 1 -> không unlock Stage 2', () async {
      final repo = SupabaseLearningProgressRepository(
        rulesService: LearningRulesService(),
        guestStore: store,
        guestResolver: resolver,
      );

      final result = await repo.completeActivity(
        LearningActivitySubmission(
          activityType: 'vocabulary',
          sourceType: 'duo_level',
          sourceId: '1:level_01',
          attemptId: 'att_fail_01',
          unitId: 'unit_01',
          levelId: 'level_01',
          score: 30.0,
          correctCount: 3,
          wrongCount: 7,
          durationSeconds: 60,
        ),
      );

      expect(result.passed, isFalse);
      expect(result.unlockedNext, isFalse);
      expect(result.nextNodeId, isNull);

      final isPassed = await store.isStagePassed(1, 'level_01');
      expect(isPassed, isFalse);

      final overlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        isUnitUnlocked: true,
      );
      expect(overlaid[1]['is_unlocked'], isFalse);
    });

    test('5. Replay Stage 1 -> không nhận trùng XP và giữ best score',
        () async {
      final repo = SupabaseLearningProgressRepository(
        rulesService: LearningRulesService(),
        guestStore: store,
        guestResolver: resolver,
      );

      final firstPlay = await repo.completeActivity(
        LearningActivitySubmission(
          activityType: 'vocabulary',
          sourceType: 'duo_level',
          sourceId: '1:level_01',
          attemptId: 'att_pass_01',
          unitId: 'unit_01',
          levelId: 'level_01',
          score: 80.0,
          correctCount: 8,
          wrongCount: 2,
          durationSeconds: 50,
        ),
      );
      expect(firstPlay.passed, isTrue);
      expect(firstPlay.firstClear, isTrue);
      expect(firstPlay.xpEarned, greaterThan(0));

      final replay = await repo.completeActivity(
        LearningActivitySubmission(
          activityType: 'vocabulary',
          sourceType: 'duo_level',
          sourceId: '1:level_01',
          attemptId: 'att_pass_02',
          unitId: 'unit_01',
          levelId: 'level_01',
          score: 100.0,
          correctCount: 10,
          wrongCount: 0,
          durationSeconds: 40,
        ),
      );
      expect(replay.passed, isTrue);
      expect(replay.firstClear, isFalse);

      final stageRecord = await store.getStageRecord(1, 'level_01');
      expect(stageRecord?['score'], 100);
      expect(stageRecord?['attempts'], 2);
    });

    test('6. Stage có prerequisite -> chỉ unlock khi đủ điều kiện', () async {
      await store.recordStagePassed(
        gameId: 1,
        levelId: 'level_01',
        unitId: 'unit_01',
        score: 100,
        stars: 3,
      );

      var overlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        isUnitUnlocked: true,
      );
      expect(overlaid[1]['is_unlocked'], isTrue);
      expect(overlaid[2]['is_unlocked'], isFalse);

      await store.recordStagePassed(
        gameId: 2,
        levelId: 'level_02',
        unitId: 'unit_01',
        score: 90,
        stars: 3,
      );

      overlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        isUnitUnlocked: true,
      );
      expect(overlaid[2]['is_unlocked'], isTrue,
          reason: 'Stage 3 chỉ mở khi Stage 2 đã pass');
    });

    test(
        '7 & 8. Boss availability: Mastery chưa đủ -> Boss khóa; đủ -> Boss available',
        () async {
      await store.recordStagePassed(
          gameId: 1,
          levelId: 'level_01',
          unitId: 'unit_01',
          score: 100,
          stars: 3);
      await store.recordStagePassed(
          gameId: 2,
          levelId: 'level_02',
          unitId: 'unit_01',
          score: 100,
          stars: 3);
      await store.recordStagePassed(
          gameId: 3,
          levelId: 'level_03',
          unitId: 'unit_01',
          score: 100,
          stars: 3);

      final lowMasteryOverlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        overallMastery: 0.60,
        isUnitUnlocked: true,
      );
      expect(lowMasteryOverlaid[3]['is_unlocked'], isFalse);
      expect(lowMasteryOverlaid[3]['lock_reason'], 'mastery_too_low');

      final highMasteryOverlaid = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        overallMastery: 0.85,
        isUnitUnlocked: true,
      );
      expect(highMasteryOverlaid[3]['is_unlocked'], isTrue);
      expect(highMasteryOverlaid[3]['lock_reason'], isNull);

      final resolution = await resolver.resolveNextNodeAfterStageCompletion(
        unitId: 'unit_01',
        completedGameId: 3,
        completedLevelId: 'level_03',
        pathRows: sampleUnitPath,
        store: store,
        overallMastery: 0.85,
      );
      expect(resolution.bossReady, isTrue);
      expect(resolution.nextNodeId, 'boss:1');
    });

    test('9 & 10. Boss win -> Unit completed & Unit 2 unlocked', () async {
      final sampleUnits = <LearningUnitViewModel>[
        const LearningUnitViewModel(
          id: 'unit_01',
          sectionId: 'sec_01',
          sectionNumber: 1,
          unitNumber: 1,
          title: 'Bài 1: Chào hỏi',
          subtitle: '',
          teachingObjective: '',
          missionCount: 3,
          completedMissionCount: 3,
          mastery: 0.9,
          state: UnitCompletionState.bossPending,
          isUnlocked: true,
          bossAvailable: true,
          bossWon: false,
          bossStageId: 1,
        ),
        const LearningUnitViewModel(
          id: 'unit_02',
          sectionId: 'sec_01',
          sectionNumber: 1,
          unitNumber: 2,
          title: 'Bài 2: Gia đình',
          subtitle: '',
          teachingObjective: '',
          missionCount: 3,
          completedMissionCount: 0,
          mastery: 0.0,
          state: UnitCompletionState.inProgress,
          isUnlocked: false,
          bossAvailable: false,
          bossWon: false,
          bossStageId: 2,
          requiredUnitId: 'unit_01',
        ),
      ];

      var unitsOverlaid = await resolver.overlayUnits(
        sectionId: 'sec_01',
        units: sampleUnits,
        store: store,
        isSectionUnlocked: true,
      );
      expect(unitsOverlaid[0].isUnlocked, isTrue);
      expect(unitsOverlaid[0].bossWon, isFalse);
      expect(unitsOverlaid[1].isUnlocked, isFalse);

      await store.recordBossWon(
        unitId: 'unit_01',
        stageId: 1,
        score: 100,
        stars: 3,
      );

      final isWon = await store.isBossWon('unit_01');
      expect(isWon, isTrue);

      unitsOverlaid = await resolver.overlayUnits(
        sectionId: 'sec_01',
        units: sampleUnits,
        store: store,
        isSectionUnlocked: true,
      );
      expect(unitsOverlaid[0].bossWon, isTrue);
      expect(unitsOverlaid[0].state, UnitCompletionState.completed);
      expect(unitsOverlaid[1].isUnlocked, isTrue,
          reason: 'Unit 2 phải mở sau khi thắng Boss Unit 1');
    });

    test('11. Close/relaunch -> states được giữ nguyên', () async {
      await store.recordStagePassed(
        gameId: 1,
        levelId: 'level_01',
        unitId: 'unit_01',
        score: 95,
        stars: 3,
      );
      await store.recordBossWon(
        unitId: 'unit_01',
        stageId: 1,
        score: 100,
        stars: 3,
      );

      final freshStore = GuestLearningProgressStore();
      final freshResolver = const GuestJourneyResolver();

      expect(await freshStore.isStagePassed(1, 'level_01'), isTrue);
      expect(await freshStore.isBossWon('unit_01'), isTrue);

      final overlaid = await freshResolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: freshStore,
        isUnitUnlocked: true,
      );
      expect(overlaid[0]['is_completed'], isTrue);
      expect(overlaid[1]['is_unlocked'], isTrue);
      expect(overlaid[3]['is_completed'], isTrue);
    });

    test('12. Home/Unit/Section tabs cập nhật thống nhất', () async {
      await store.recordBossWon(
          unitId: 'unit_01', stageId: 1, score: 100, stars: 3);

      final sampleSections = <LearningSectionViewModel>[
        const LearningSectionViewModel(
          id: 'sec_01',
          sectionNumber: 1,
          title: 'Phần 1: Khởi động',
          subtitle: '',
          unitCount: 1,
          completedUnitCount: 0,
          isUnlocked: true,
        ),
        const LearningSectionViewModel(
          id: 'sec_02',
          sectionNumber: 2,
          title: 'Phần 2: Mở rộng',
          subtitle: '',
          unitCount: 2,
          completedUnitCount: 0,
          isUnlocked: false,
          requiredSectionNumber: 1,
        ),
      ];

      final overlaidSections = await resolver.overlaySections(
        sections: sampleSections,
        store: store,
        unitsLoader: (secId) async => [
          const LearningUnitViewModel(
            id: 'unit_01',
            sectionId: 'sec_01',
            sectionNumber: 1,
            unitNumber: 1,
            title: 'Bài 1',
            subtitle: '',
            teachingObjective: '',
            missionCount: 1,
            completedMissionCount: 1,
            mastery: 1.0,
            state: UnitCompletionState.completed,
            isUnlocked: true,
            bossWon: true,
          ),
        ],
      );

      expect(overlaidSections[0].completedUnitCount, 1);
      expect(overlaidSections[1].isUnlocked, isTrue,
          reason: 'Section 2 phải mở sau khi Section 1 hoàn thành toàn bộ bài');
    });

    test('13. Migration từ legacy data cũ của Guest', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('guest_learning_attempts_v2', [
        jsonEncode({
          'status': 'passed',
          'activity_type': 'vocabulary',
          'source_id': '1:legacy_level_1',
          'level_id': 'legacy_level_1',
          'score': 85.0,
          'stars': 3,
          'metadata': {'game_id': 1},
        }),
        jsonEncode({
          'status': 'passed',
          'activity_type': 'boss',
          'source_id': 'boss_1',
          'unit_id': 'unit_legacy_01',
          'score': 100.0,
          'stars': 3,
        }),
      ]);

      final migratedStore = GuestLearningProgressStore();
      await migratedStore.ensureMigrated();

      expect(await migratedStore.isStagePassed(1, 'legacy_level_1'), isTrue);
      expect(await migratedStore.isBossWon('unit_legacy_01'), isTrue);
    });

    test(
        '14 & 15. Idempotent submission: Submit trùng không nhận thưởng lặp lại',
        () async {
      final repo = SupabaseLearningProgressRepository(
        rulesService: LearningRulesService(),
        guestStore: store,
        guestResolver: resolver,
      );

      final submission = LearningActivitySubmission(
        activityType: 'vocabulary',
        sourceType: 'duo_level',
        sourceId: '1:level_01',
        attemptId: 'att_unique_01',
        unitId: 'unit_01',
        levelId: 'level_01',
        score: 100.0,
        correctCount: 10,
        wrongCount: 0,
        durationSeconds: 30,
      );

      final res1 = await repo.completeActivity(submission);
      final res2 = await repo.completeActivity(submission);

      expect(res1.xpEarned, greaterThan(0));
      expect(res2.idempotent, isTrue);
      expect(res2.newTotalXp, equals(res1.newTotalXp),
          reason:
              'XP không được tăng thêm ở lần submit thứ 2 với cùng event key');
    });

    test(
        'E2E CRITICAL: Stage 1 pass -> save local -> reload repository/path -> Stage 2 available',
        () async {
      final repo = SupabaseLearningProgressRepository(
        rulesService: LearningRulesService(),
        guestStore: store,
        guestResolver: resolver,
      );

      // 1. New Guest: Verify Stage 1 available, Stage 2 locked
      var currentPath = await resolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: store,
        isUnitUnlocked: true,
      );
      expect(currentPath[0]['is_unlocked'], isTrue);
      expect(currentPath[1]['is_unlocked'], isFalse);

      // 2. Play and complete Stage 1
      final result = await repo.completeActivity(
        LearningActivitySubmission(
          activityType: 'vocabulary',
          sourceType: 'duo_level',
          sourceId: '1:level_01',
          attemptId: 'att_e2e_01',
          unitId: 'unit_01',
          levelId: 'level_01',
          score: 100.0,
          correctCount: 10,
          wrongCount: 0,
          durationSeconds: 45,
        ),
      );
      expect(result.passed, isTrue);

      // 3. Simulate reload by creating brand new store & resolver instances
      final reloadedStore = GuestLearningProgressStore();
      final reloadedResolver = const GuestJourneyResolver();

      final reloadedPath = await reloadedResolver.overlayUnitPath(
        unitId: 'unit_01',
        pathRows: sampleUnitPath,
        store: reloadedStore,
        isUnitUnlocked: true,
      );

      // 4. Verify Stage 1 is completed and Stage 2 is unlocked
      expect(reloadedPath[0]['is_completed'], isTrue);
      expect(reloadedPath[1]['is_unlocked'], isTrue,
          reason: 'Stage 2 PHẢI mở sau khi reload!');
      expect(reloadedPath[1]['lock_reason'], isNull);
    });
  });
}
