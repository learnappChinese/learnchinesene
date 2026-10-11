import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/learning_reward_config.dart';
import 'package:flash_learn_chinese/core/learning/learning_rules_config.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_reward_service.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_rules_service.dart';

void main() {
  const rules = LearningRulesService();

  group('central pass and star rules', () {
    for (final boundary in <(double, int)>[
      (0.69, 0),
      (0.70, 1),
      (0.79, 1),
      (0.80, 2),
      (0.94, 2),
      (0.95, 3),
    ]) {
      test('${(boundary.$1 * 100).round()}% gives ${boundary.$2} star(s)', () {
        expect(rules.evaluateStars(boundary.$1), boundary.$2);
        final result = rules.evaluate(
          _submission(
            attemptId: 'boundary-${boundary.$1}',
            correct: (boundary.$1 * 100).round(),
            wrong: 100 - (boundary.$1 * 100).round(),
          ),
          firstClear: true,
        );
        expect(result.passed, boundary.$1 >= .70);
        expect(result.stars, boundary.$2);
      });
    }

    test('unit mastery normalizes missing skill weights', () {
      expect(
        LearningRulesConfig.calculateUnitMastery(
          vocabularyMastery: .8,
          listeningMastery: .6,
        ),
        closeTo(.716666, .00001),
      );
    });

    test('unit remains boss pending until boss is won', () {
      expect(
        LearningRulesConfig.evaluateUnitState(
          allMissionsPassed: true,
          overallMastery: .75,
          hasBoss: true,
          bossWon: false,
        ),
        UnitPassState.bossPending,
      );
      expect(
        LearningRulesConfig.evaluateUnitState(
          allMissionsPassed: true,
          overallMastery: .75,
          hasBoss: true,
          bossWon: true,
        ),
        UnitPassState.completed,
      );
    });

    test('UnitMastery maps server mastery and completion state', () {
      final mastery = UnitMastery.fromMap(<String, dynamic>{
        'vocabulary_mastery': .9,
        'listening_mastery': .8,
        'overall_mastery': .85,
        'all_required_missions_passed': true,
        'boss_required': true,
        'boss_available': true,
        'boss_won': false,
        'unit_state': 'boss_pending',
      });
      expect(mastery.vocabulary, .9);
      expect(mastery.overall, .85);
      expect(mastery.bossAvailable, isTrue);
      expect(mastery.state, UnitCompletionState.bossPending);
    });
  });

  group('skill-specific rules', () {
    test('speaking fails when overall passes but pronunciation is below 60',
        () {
      final result = rules.evaluate(
        _submission(
          activityType: 'speaking',
          attemptId: 'speaking-pronunciation',
          accuracy: 1,
          pronunciation: 59,
          tone: 100,
          fluency: 100,
        ),
        firstClear: true,
      );
      expect(result.score, greaterThanOrEqualTo(65));
      expect(result.passed, isFalse);
      expect(result.reason, 'pronunciation_below_threshold');
    });

    test('speaking fails when tone is below 50', () {
      final result = rules.evaluate(
        _submission(
          activityType: 'speaking',
          attemptId: 'speaking-tone',
          accuracy: 1,
          pronunciation: 100,
          tone: 49,
          fluency: 100,
        ),
        firstClear: true,
      );
      expect(result.score, greaterThanOrEqualTo(65));
      expect(result.passed, isFalse);
      expect(result.reason, 'tone_below_threshold');
    });

    test('speaking weighted score uses 35/30/20/15 weights', () {
      expect(
        rules.calculateSpeakingOverall(
          accuracy: 80,
          pronunciation: 70,
          tone: 60,
          fluency: 50,
        ),
        68.5,
      );
    });

    test('Hanzi requires score 85 and minimum practice count for mastery', () {
      expect(rules.isHanziMastered(bestScore: 84, practiceCount: 3), isFalse);
      expect(rules.isHanziMastered(bestScore: 85, practiceCount: 2), isFalse);
      expect(rules.isHanziMastered(bestScore: 85, practiceCount: 3), isTrue);

      final score84 = rules.evaluate(
        _submission(
          activityType: 'hanzi',
          attemptId: 'hanzi-84',
          hanziScore: 84,
          metadata: const {'practice_attempts': 1},
        ),
        firstClear: true,
        previousHanziPracticeCount: 2,
      );
      final score85Early = rules.evaluate(
        _submission(
          activityType: 'hanzi',
          attemptId: 'hanzi-85-early',
          hanziScore: 85,
          metadata: const {'practice_attempts': 1},
        ),
        firstClear: true,
      );
      final score85Enough = rules.evaluate(
        _submission(
          activityType: 'hanzi',
          attemptId: 'hanzi-85-enough',
          hanziScore: 85,
          metadata: const {'practice_attempts': 1},
        ),
        firstClear: true,
        previousHanziPracticeCount: 2,
      );
      expect(score84.hanziMastered, isFalse);
      expect(score85Early.hanziMastered, isFalse);
      expect(score85Enough.hanziMastered, isTrue);
    });

    test('Boss result is derived only from raw HP', () {
      final win = rules.evaluate(
        _submission(
          activityType: 'boss',
          sourceType: 'boss_stage',
          attemptId: 'boss-win',
          bossHp: 0,
          playerHp: 1,
        ),
        firstClear: true,
      );
      final loss = rules.evaluate(
        _submission(
          activityType: 'boss',
          sourceType: 'boss_stage',
          attemptId: 'boss-loss',
          bossHp: 0,
          playerHp: 0,
        ),
        firstClear: true,
      );
      expect(win.passed, isTrue);
      expect(loss.passed, isFalse);
    });
  });

  group('guest authoritative fallback', () {
    late DateTime now;
    late SupabaseLearningProgressRepository repository;
    late LearningRewardService rewards;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      now = DateTime(2026, 10, 9, 9);
      repository = SupabaseLearningProgressRepository(
        prefs: prefs,
        nowProvider: () => now,
      );
      rewards = LearningRewardService(repository: repository);
    });

    test('first pass gets first-clear bonus and replay does not', () async {
      final first = _submission(attemptId: 'first-pass', correct: 8, wrong: 2);
      await rewards.startAttempt(first);
      final firstResult = await rewards.completeActivity(first);

      final replay = _submission(attemptId: 'replay', correct: 8, wrong: 2);
      await rewards.startAttempt(replay);
      final replayResult = await rewards.completeActivity(replay);

      expect(firstResult.firstClear, isTrue);
      expect(replayResult.firstClear, isFalse);
      expect(firstResult.bonusXp, greaterThan(replayResult.bonusXp));
      expect(replayResult.baseXp, LearningRewardConfig.replayXpCap);
    });

    test('same event and concurrent retry never duplicate XP', () async {
      final submission = _submission(
        attemptId: 'network-retry',
        correct: 10,
        wrong: 0,
      );
      await rewards.startAttempt(submission);
      final results = await Future.wait(<Future<dynamic>>[
        rewards.completeActivity(submission),
        rewards.completeActivity(submission),
      ]);
      final afterRetry = await rewards.completeActivity(submission);
      final history = await repository.fetchXpHistory();

      expect(results[0].xpEarned, results[1].xpEarned);
      expect(afterRetry.idempotent, isTrue);
      expect(history, hasLength(1));
    });

    test('zero-XP Boss loss is still idempotent', () async {
      final loss = _submission(
        activityType: 'boss',
        sourceType: 'boss_stage',
        sourceId: '1',
        attemptId: 'boss-zero',
        bossHp: 100,
        playerHp: 0,
      );
      final first = await rewards.completeActivity(loss);
      final retry = await rewards.completeActivity(loss);
      expect(first.xpEarned, 0);
      expect(retry.idempotent, isTrue);
      expect(await repository.fetchXpHistory(), hasLength(1));
    });

    test('started attempts can transition to abandoned without XP', () async {
      final submission = _submission(
        attemptId: 'abandoned-attempt',
        correct: 0,
        wrong: 0,
      );
      await rewards.startAttempt(submission);
      await rewards.abandonAttempt(
        submission.attemptId,
        metadata: const <String, dynamic>{'reason': 'test_closed'},
      );

      final attempts = await repository.fetchAttemptHistory();
      expect(attempts.single['status'], 'abandoned');
      expect(await repository.fetchXpHistory(), isEmpty);
    });

    test('streak stays same day, increments next day and resets after gap',
        () async {
      Future<int> complete(String id) async {
        final submission = _submission(
          sourceId: id,
          attemptId: id,
          correct: 8,
          wrong: 2,
        );
        return (await rewards.completeActivity(submission)).currentStreak;
      }

      expect(await complete('day-1-a'), 1);
      expect(await complete('day-1-b'), 1);
      now = DateTime(2026, 10, 10, 8);
      expect(await complete('day-2'), 2);
      now = DateTime(2026, 10, 13, 8);
      expect(await complete('day-5'), 1);
    });
  });
}

LearningActivitySubmission _submission({
  String activityType = 'vocabulary',
  String sourceType = 'level',
  String sourceId = 'level-1',
  required String attemptId,
  int correct = 0,
  int wrong = 0,
  double? accuracy,
  double? pronunciation,
  double? tone,
  double? fluency,
  double? hanziScore,
  int? bossHp,
  int? playerHp,
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  return LearningActivitySubmission(
    activityType: activityType,
    sourceType: sourceType,
    sourceId: sourceId,
    attemptId: attemptId,
    score: hanziScore ?? 0,
    correctCount: correct,
    wrongCount: wrong,
    accuracy: accuracy,
    pronunciation: pronunciation,
    tone: tone,
    fluency: fluency,
    hanziScore: hanziScore,
    bossHp: bossHp,
    playerHp: playerHp,
    metadata: metadata,
  );
}
