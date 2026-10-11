import 'dart:async';

import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_progress_sync_service.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningProgressSyncService', () {
    late LearningProgressSyncService sync;

    tearDown(() {
      sync.onClose();
    });

    test('completion refreshes only owners whose domains are affected',
        () async {
      sync = LearningProgressSyncService(maxRefreshAttempts: 1);
      var homeRefreshes = 0;
      var unitRefreshes = 0;
      var identityRefreshes = 0;
      sync.registerRefresher(
        owner: 'home',
        domains: const {LearningDomain.stats},
        refresh: (_) async => homeRefreshes++,
      );
      sync.registerRefresher(
        owner: 'unit',
        domains: const {LearningDomain.unitPath},
        refresh: (_) async => unitRefreshes++,
      );
      sync.registerRefresher(
        owner: 'identity-only',
        domains: const {LearningDomain.identity},
        refresh: (_) async => identityRefreshes++,
      );

      final report = await sync.syncAfterCompletion(_result(), _submission());

      expect(report.isComplete, isTrue);
      expect(report.refreshedOwners, containsAll(<String>{'home', 'unit'}));
      expect(homeRefreshes, 1);
      expect(unitRefreshes, 1);
      expect(identityRefreshes, 0);
    });

    test('one failed owner is retried without hiding successful slices',
        () async {
      sync = LearningProgressSyncService(maxRefreshAttempts: 2);
      var successfulRefreshes = 0;
      var failedAttempts = 0;
      sync.registerRefresher(
        owner: 'history',
        domains: const {LearningDomain.history},
        refresh: (_) async => successfulRefreshes++,
      );
      sync.registerRefresher(
        owner: 'review',
        domains: const {LearningDomain.review},
        refresh: (_) async {
          failedAttempts++;
          throw StateError('review endpoint unavailable');
        },
      );

      final report = await sync.syncAfterCompletion(_result(), _submission());

      expect(successfulRefreshes, 1);
      expect(failedAttempts, 2);
      expect(report.refreshedOwners, contains('history'));
      expect(report.failures, contains('review'));
      expect(sync.lastFailures, contains('review'));
    });

    test('rapid invalidations are coalesced and cannot overlap', () async {
      sync = LearningProgressSyncService(maxRefreshAttempts: 1);
      var refreshes = 0;
      var activeRefreshes = 0;
      var maxConcurrentRefreshes = 0;
      final release = Completer<void>();
      sync.registerRefresher(
        owner: 'mounted-tab',
        domains: const {LearningDomain.stats, LearningDomain.review},
        refresh: (_) async {
          refreshes++;
          activeRefreshes++;
          if (activeRefreshes > maxConcurrentRefreshes) {
            maxConcurrentRefreshes = activeRefreshes;
          }
          await release.future;
          activeRefreshes--;
        },
      );

      final first = sync.invalidate(
        const LearningDomainEvent(
          type: LearningDomainEventType.activityCompleted,
          domains: {LearningDomain.stats},
        ),
      );
      final second = sync.invalidate(
        const LearningDomainEvent(
          type: LearningDomainEventType.lexiconReviewed,
          domains: {LearningDomain.review},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      release.complete();
      final reports = await Future.wait([first, second]);

      expect(refreshes, 1);
      expect(maxConcurrentRefreshes, 1);
      expect(reports[0].event.generation, reports[1].event.generation);
      expect(
        reports[0].event.domains,
        containsAll(<LearningDomain>{
          LearningDomain.stats,
          LearningDomain.review,
        }),
      );
    });

    test('disposed mounted owner is no longer refreshed', () async {
      sync = LearningProgressSyncService(maxRefreshAttempts: 1);
      var refreshes = 0;
      final registration = sync.registerRefresher(
        owner: 'closed-tab',
        domains: const {LearningDomain.stats},
        refresh: (_) async => refreshes++,
      );
      registration.dispose();

      await sync.invalidate(
        const LearningDomainEvent(
          type: LearningDomainEventType.appResumed,
          domains: {LearningDomain.stats},
        ),
      );

      expect(refreshes, 0);
    });

    test('reward boundary emits exactly one sync after repository success',
        () async {
      sync = LearningProgressSyncService(maxRefreshAttempts: 1);
      final repository = _FakeLearningProgressRepository(_result());
      var refreshes = 0;
      sync.registerRefresher(
        owner: 'home',
        domains: const {LearningDomain.stats},
        refresh: (_) async => refreshes++,
      );
      final rewards = LearningRewardService(
        repository: repository,
        syncService: sync,
      );

      final result = await rewards.completeActivity(_submission());

      expect(result.attemptId, 'attempt-1');
      expect(repository.completions, 1);
      expect(refreshes, 1);
    });
  });

  group('learning completion contract fixture', () {
    test('parses server reward, unlock and next-unit fields', () {
      final result = LearningResult.fromMap(const <String, dynamic>{
        'activity_type': 'boss',
        'source_id': 'stage-9',
        'attempt_id': 'boss-attempt-1',
        'passed': true,
        'failed': false,
        'stars': 3,
        'score': 100,
        'accuracy': 1,
        'correct_count': 10,
        'wrong_count': 0,
        'xp_earned': 75,
        'base_xp': 50,
        'bonus_xp': 25,
        'new_total_xp': 1075,
        'current_streak': 4,
        'first_clear': true,
        'perfect': true,
        'unlocked_next': true,
        'next_node_id': 'stage-10',
        'boss_ready': false,
        'unit_completed': true,
        'next_unit_id': 'unit-2',
        'idempotent': false,
      });

      expect(result.xpEarned, 75);
      expect(result.newTotalXp, 1075);
      expect(result.unlockedNext, isTrue);
      expect(result.nextStageId, 'stage-10');
      expect(result.unitCompleted, isTrue);
      expect(result.nextUnitId, 'unit-2');
    });

    test('submission fixture preserves the RPC idempotency key and context',
        () {
      final params = _submission().toRpcParams();

      expect(params['p_attempt_id'], 'attempt-1');
      expect(params['p_unit_id'], 'unit-1');
      expect(params['p_level_id'], 'level-1');
      expect(params['p_activity_type'], 'vocabulary');
    });
  });
}

LearningActivitySubmission _submission() => const LearningActivitySubmission(
      activityType: 'vocabulary',
      sourceType: 'duo_level',
      sourceId: 'game-1:level-1',
      attemptId: 'attempt-1',
      unitId: 'unit-1',
      levelId: 'level-1',
      correctCount: 8,
      wrongCount: 2,
      score: 80,
    );

LearningResult _result() => const LearningResult(
      activityType: 'vocabulary',
      sourceId: 'game-1:level-1',
      attemptId: 'attempt-1',
      passed: true,
      stars: 2,
      score: 80,
      accuracy: .8,
      correctCount: 8,
      wrongCount: 2,
      xpEarned: 20,
      baseXp: 15,
      bonusXp: 5,
      newTotalXp: 120,
      currentStreak: 2,
      firstClear: true,
      perfect: false,
      unlockedNext: true,
      nextNodeId: 'stage-2',
    );

class _FakeLearningProgressRepository implements LearningProgressRepository {
  _FakeLearningProgressRepository(this.result);

  final LearningResult result;
  int completions = 0;

  @override
  Future<LearningResult> completeActivity(
    LearningActivitySubmission submission,
  ) async {
    completions++;
    return result;
  }

  @override
  Future<void> abandonAttempt(
    String attemptId, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<void> migrateGuestProgressToCloud() => throw UnimplementedError();

  @override
  Future<void> startAttempt(LearningActivitySubmission submission) async {}
}
