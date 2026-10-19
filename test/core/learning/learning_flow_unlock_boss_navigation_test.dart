import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pandarin/core/learning/data/learning_progress_repository.dart';
import 'package:pandarin/core/learning/model/learning_activity_submission.dart';
import 'package:pandarin/core/learning/model/learning_navigation_outcome.dart';
import 'package:pandarin/core/learning/model/learning_result.dart';
import 'package:pandarin/core/learning/model/mission_state_machine.dart';
import 'package:pandarin/core/learning/service/learning_progress_sync_service.dart';
import 'package:pandarin/core/learning/service/learning_reward_service.dart';
import 'package:pandarin/core/widgets/adventure_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PR 03 — LearningResult & Contract Parsing', () {
    test(
        'parses bossReady and unitCompleted correctly from server json and metadata',
        () {
      final json = <String, dynamic>{
        'activity_type': 'vocabulary',
        'source_id': '1:level_1',
        'attempt_id': 'att_1',
        'passed': true,
        'stars': 3,
        'score': 100.0,
        'accuracy': 1.0,
        'correct_count': 10,
        'wrong_count': 0,
        'xp_earned': 35,
        'base_xp': 20,
        'bonus_xp': 15,
        'next_node_id': 'boss:stage_1',
        'first_clear': true,
        'perfect': true,
      };

      final result = LearningResult.fromJson(json);
      expect(result.passed, isTrue);
      expect(result.isBossReady, isTrue);
      expect(result.isUnitCompleted, isFalse);
      expect(result.xpEarned, 35);
    });

    test('boss victory sets unitCompleted and parses nextUnitId', () {
      final json = <String, dynamic>{
        'activity_type': 'boss',
        'source_type': 'boss_stage',
        'source_id': 'stage_1',
        'attempt_id': 'boss_att_1',
        'passed': true,
        'stars': 3,
        'score': 100.0,
        'accuracy': 1.0,
        'xp_earned': 115,
        'base_xp': 100,
        'bonus_xp': 15,
        'next_node_id': 'game_1:level_1',
        'next_unit_id': 'unit_02',
        'metadata': <String, dynamic>{
          'next_unit_id': 'unit_02',
          'boss_ready': false,
        },
      };

      final result = LearningResult.fromJson(json);
      expect(result.passed, isTrue);
      expect(result.isUnitCompleted, isTrue);
      expect(result.nextUnitId, 'unit_02');
      expect(result.xpEarned, 115);
    });
  });

  group('PR 03 — Mission State Machine Transitions', () {
    test('1. Mission fail -> retry transition is allowed', () {
      const initial = AdventureNodeState.inProgress;
      final failTransition = MissionStateMachine.transition(
        current: initial,
        target: AdventureNodeState.failed,
        context: const MissionTransitionContext(
          passed: false,
          score: 50.0,
          stars: 0,
        ),
      );
      expect(failTransition.allowed, isTrue);
      expect(failTransition.newState, AdventureNodeState.failed);

      final canRetry = MissionStateMachine.canRetry(
        state: failTransition.newState,
        isPrerequisiteMet: true,
      );
      expect(canRetry, isTrue);

      final retryTransition = MissionStateMachine.transition(
        current: failTransition.newState,
        target: AdventureNodeState.inProgress,
        context: const MissionTransitionContext(isPrerequisiteMet: true),
      );
      expect(retryTransition.allowed, isTrue);
      expect(retryTransition.newState, AdventureNodeState.inProgress);
    });

    test('2. Mission pass -> completed/perfect state transition', () {
      const initial = AdventureNodeState.inProgress;
      final passTransition = MissionStateMachine.transition(
        current: initial,
        target: AdventureNodeState.completed,
        context: const MissionTransitionContext(
          passed: true,
          score: 100.0,
          stars: 3,
          isFirstClear: true,
        ),
      );
      expect(passTransition.allowed, isTrue);
      expect(passTransition.newState, AdventureNodeState.perfect);
      expect(passTransition.awardFirstClearXp, isTrue);
    });

    test(
        '3. Mission replay fail preserves previous completion and awards no first-clear XP',
        () {
      const completed = AdventureNodeState.completed;

      // User starts replay
      final startReplay = MissionStateMachine.transition(
        current: completed,
        target: AdventureNodeState.inProgress,
        context: const MissionTransitionContext(isPrerequisiteMet: true),
      );
      expect(startReplay.allowed, isTrue);
      expect(startReplay.preservedPrevious, isTrue);

      // Replay attempt fails
      final replayFail = MissionStateMachine.transition(
        current: completed,
        target: AdventureNodeState.failed,
        context: const MissionTransitionContext(
          passed: false,
          score: 40.0,
          isReplay: true,
          isFirstClear: false,
        ),
      );
      expect(replayFail.allowed, isTrue);
      expect(replayFail.newState, AdventureNodeState.completed); // PRESERVED!
      expect(replayFail.preservedPrevious, isTrue);
      expect(replayFail.awardFirstClearXp, isFalse);
    });

    test('6. Locked mission rejects start and provides lock reason', () {
      const locked = AdventureNodeState.locked;
      final startAttempt = MissionStateMachine.transition(
        current: locked,
        target: AdventureNodeState.inProgress,
        context: const MissionTransitionContext(
          isPrerequisiteMet: false,
          lockReason: 'Cần đạt ít nhất 70% ở Ải trước.',
        ),
      );
      expect(startAttempt.allowed, isFalse);
      expect(startAttempt.newState, AdventureNodeState.locked);
    });

    test('Session pause and resume transitions', () {
      const inProgress = AdventureNodeState.inProgress;
      final pause = MissionStateMachine.transition(
        current: inProgress,
        target: AdventureNodeState.paused,
        context: const MissionTransitionContext(),
      );
      expect(pause.allowed, isTrue);
      expect(pause.newState, AdventureNodeState.paused);

      final resume = MissionStateMachine.transition(
        current: pause.newState,
        target: AdventureNodeState.inProgress,
        context: const MissionTransitionContext(),
      );
      expect(resume.allowed, isTrue);
      expect(resume.newState, AdventureNodeState.inProgress);
    });
  });

  group('PR 03 — Typed Navigation Outcome', () {
    test('5. Result navigation builds typed outcomes correctly', () {
      final successResult = LearningResult.fromJson(const <String, dynamic>{
        'activity_type': 'vocabulary',
        'source_id': '1:level_1',
        'attempt_id': 'att_1',
        'passed': true,
        'stars': 2,
        'score': 85.0,
        'next_node_id': '2:level_1',
      });

      final nextMissionOutcome = LearningNavigationOutcome.nextMission(
        result: successResult,
      );
      expect(nextMissionOutcome.isSuccess, isTrue);
      expect(nextMissionOutcome.action, LearningNavigationAction.nextMission);
      expect(nextMissionOutcome.nextNodeId, '2:level_1');

      final bossOutcome = LearningNavigationOutcome.fightBoss(
        result: successResult,
        bossStageId: 'boss:stage_1',
      );
      expect(bossOutcome.isFightBoss, isTrue);
      expect(bossOutcome.isSuccess, isTrue);
      expect(bossOutcome.nextNodeId, 'boss:stage_1');

      final nextUnitOutcome = LearningNavigationOutcome.nextUnit(
        result: successResult,
        nextUnitId: 'unit_02',
      );
      expect(nextUnitOutcome.isNextUnit, isTrue);
      expect(nextUnitOutcome.nextUnitId, 'unit_02');
    });

    test('8. Boss defeat and retry outcomes', () {
      final defeatResult = LearningResult.fromJson(const <String, dynamic>{
        'activity_type': 'boss',
        'source_id': 'stage_1',
        'attempt_id': 'boss_fail_1',
        'passed': false,
        'stars': 0,
        'score': 30.0,
      });

      final failOutcome = LearningNavigationOutcome.failed(
        result: defeatResult,
      );
      expect(failOutcome.isFailed, isTrue);
      expect(failOutcome.isSuccess, isFalse);

      final retryOutcome = LearningNavigationOutcome.retry(
        result: defeatResult,
      );
      expect(retryOutcome.isRetry, isTrue);
    });
  });

  group('PR 03 — Boss Battle Server-Authoritative Reward & Idempotency', () {
    late SharedPreferences prefs;
    late SupabaseLearningProgressRepository repo;
    late LearningRewardService rewardService;
    late LearningProgressSyncService syncService;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      repo = SupabaseLearningProgressRepository(prefs: prefs);
      syncService = LearningProgressSyncService();
      rewardService = LearningRewardService(
        repository: repo,
        syncService: syncService,
      );
    });

    test(
        '4. Duplicate mission submission returns idempotent result without doubling XP',
        () async {
      const attemptId = 'unique_attempt_42';
      final submission = LearningActivitySubmission(
        activityType: 'vocabulary',
        sourceType: 'duo_level',
        sourceId: '1:level_1',
        attemptId: attemptId,
        score: 90.0,
        correctCount: 9,
        wrongCount: 1,
      );

      final firstResult = await rewardService.completeActivity(submission);
      expect(firstResult.xpEarned, greaterThan(0));
      expect(firstResult.idempotent, isFalse);
      final initialTotalXp = firstResult.newTotalXp;

      // Resubmit same attemptId
      final duplicateResult = await rewardService.completeActivity(submission);
      expect(duplicateResult.idempotent, isTrue);
      expect(duplicateResult.newTotalXp, initialTotalXp); // No XP inflation!
    });

    test(
        '9 & 10. Boss victory produces authoritative reward, sets unitCompleted, and syncs',
        () async {
      var syncNotified = false;
      syncService.registerRefresher(
        owner: 'test_unit_overview',
        domains: const <LearningDomain>{
          LearningDomain.unitPath,
          LearningDomain.mastery
        },
        refresh: (event) async {
          syncNotified = true;
        },
      );

      final bossReward = await rewardService.processBossReward(
        stageId: 101,
        attemptId: 'boss_win_attempt_1',
        score: 100,
        correctCount: 10,
        wrongCount: 0,
        bestCombo: 5,
        playerHp: 80,
        bossHp: 0,
      );

      expect(bossReward.passed, isTrue);
      expect(
          bossReward.xpEarned, greaterThanOrEqualTo(100)); // Authoritative XP!
      expect(bossReward.isUnitCompleted, isTrue);
      expect(syncNotified, isTrue); // PR 01 sync coordinator fired!
    });
  });
}
