import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pandarin/core/learning/data/learning_progress_repository.dart';
import 'package:pandarin/core/learning/learning_rules_config.dart';
import 'package:pandarin/core/learning/model/learning_activity_submission.dart';
import 'package:pandarin/core/learning/model/learning_result.dart';
import 'package:pandarin/core/learning/model/learning_skill_taxonomy.dart';
import 'package:pandarin/core/learning/model/unit_mastery.dart';
import 'package:pandarin/core/learning/service/learning_reward_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PR 02 - Skill Taxonomy & Game Code Mapping', () {
    test('all 11 Duo game codes map to canonical activity types and skills',
        () {
      const expectedMapping =
          <String, ({String activityType, String skillBucket})>{
        'learn_words': (activityType: 'vocabulary', skillBucket: 'vocabulary'),
        'select_answer': (
          activityType: 'vocabulary',
          skillBucket: 'vocabulary'
        ),
        'match_pairs': (activityType: 'vocabulary', skillBucket: 'vocabulary'),
        'word_connect': (activityType: 'vocabulary', skillBucket: 'vocabulary'),
        'translate': (activityType: 'vocabulary', skillBucket: 'vocabulary'),
        'gap_fill': (activityType: 'vocabulary', skillBucket: 'vocabulary'),
        'tap_complete': (activityType: 'vocabulary', skillBucket: 'vocabulary'),
        'sentence_order': (
          activityType: 'vocabulary',
          skillBucket: 'vocabulary'
        ),
        'listen_select': (activityType: 'listening', skillBucket: 'listening'),
        'dialogue': (activityType: 'dialogue', skillBucket: 'listening'),
        'speaking': (activityType: 'speaking', skillBucket: 'speaking'),
      };

      expect(
        LearningSkillTaxonomy.supportedGameCodes.length,
        11,
        reason: 'Curriculum supports exactly 11 distinct Duo game types',
      );

      for (final entry in expectedMapping.entries) {
        final code = entry.key;
        final expected = entry.value;

        expect(
          LearningSkillTaxonomy.activityTypeForGameCode(code),
          expected.activityType,
          reason: '$code should map to activityType ${expected.activityType}',
        );

        expect(
          LearningSkillTaxonomy.skillBucketFor(
            activityType: expected.activityType,
            gameCode: code,
          ),
          expected.skillBucket,
          reason:
              '$code ($expected.activityType) should contribute to ${expected.skillBucket}',
        );
      }
    });

    test('LearningRewardService assigns correct activityType for each gameCode',
        () async {
      final repository = _CapturingRepository();
      final rewards = LearningRewardService(repository: repository);

      for (final code in LearningSkillTaxonomy.supportedGameCodes) {
        await rewards.processDuoGameReward(
          gameId: 1,
          gameCode: code,
          levelId: 'level-$code',
          attemptId: 'att-$code',
          correctCount: 9,
          wrongCount: 1,
          score: 90,
        );

        final expectedActivity =
            LearningSkillTaxonomy.activityTypeForGameCode(code);
        expect(
          repository.lastSubmission?.activityType,
          expectedActivity,
          reason:
              'processDuoGameReward must submit canonical activityType $expectedActivity for $code',
        );
        expect(
          repository.lastSubmission?.metadata['game_code'],
          code,
          reason: 'Raw game_code must be preserved in metadata for provenance',
        );
      }
    });

    test('safely resolves legacy game_mission attempts to proper skill buckets',
        () {
      expect(
        LearningSkillTaxonomy.skillBucketFor(
          activityType: 'game_mission',
          gameCode: 'select_answer',
        ),
        'vocabulary',
      );
      expect(
        LearningSkillTaxonomy.skillBucketFor(
          activityType: 'game_mission',
          gameCode: 'listen_select',
        ),
        'listening',
      );
      expect(
        LearningSkillTaxonomy.skillBucketFor(
          activityType: 'game_mission',
          gameCode: 'speaking',
        ),
        'speaking',
      );
      expect(
        LearningSkillTaxonomy.skillBucketFor(
          activityType: 'game_mission',
          gameCode: 'translate',
        ),
        'vocabulary',
      );
      expect(
        LearningSkillTaxonomy.skillBucketFor(
          activityType: 'game_mission',
          gameCode: 'unknown_future_game',
        ),
        'vocabulary',
        reason:
            'Fallback to vocabulary bucket for unclassified game_mission rows',
      );
    });
  });

  group('PR 02 - Unit Mastery & Boss Readiness Boundaries', () {
    test('calculates normalized unit mastery across present skills', () {
      // Vocab 0.85, Listening 0.75, no speaking, no hanzi
      // Weights: 0.35 + 0.25 = 0.60
      // Weighted: 0.85 * 0.35 + 0.75 * 0.25 = 0.2975 + 0.1875 = 0.485
      // Normalized: 0.485 / 0.60 = 0.808333...
      final mastery = LearningRulesConfig.calculateUnitMastery(
        vocabularyMastery: 0.85,
        listeningMastery: 0.75,
      );
      expect(mastery, closeTo(0.8083, 0.001));
    });

    test(
        'overall mastery < 0.70 keeps unit in_progress and locks Boss with mastery_low',
        () {
      final unitState = LearningRulesConfig.evaluateUnitState(
        allMissionsPassed: true,
        overallMastery: 0.69,
        hasBoss: true,
        bossWon: false,
      );
      expect(
        unitState,
        UnitPassState.inProgress,
        reason: 'Unit cannot be boss_pending if overall mastery is below 70%',
      );
    });

    test('overall mastery >= 0.70 with all required missions unlocks Boss', () {
      final unitState = LearningRulesConfig.evaluateUnitState(
        allMissionsPassed: true,
        overallMastery: 0.70,
        hasBoss: true,
        bossWon: false,
      );
      expect(
        unitState,
        UnitPassState.bossPending,
        reason:
            'Unit transitions to bossPending when all missions pass and mastery >= 70%',
      );
    });

    test('unit completes only after Boss is defeated', () {
      final unitState = LearningRulesConfig.evaluateUnitState(
        allMissionsPassed: true,
        overallMastery: 0.85,
        hasBoss: true,
        bossWon: true,
      );
      expect(unitState, UnitPassState.completed);
    });
  });

  group('PR 02 - Guest Mode Local Mastery Calculation', () {
    late SharedPreferences prefs;
    late SupabaseLearningProgressRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SupabaseLearningProgressRepository();
    });

    test('guest user computes real UnitMastery from local attempts', () async {
      // Simulate guest completing:
      // 1. select_answer (vocabulary): 80% accuracy -> mastery 0.80
      // 2. listen_select (listening): 90% accuracy -> mastery 0.90
      final attempts = <Map<String, dynamic>>[
        {
          'id': 'att-1',
          'unit_id': 'unit-1',
          'activity_type': 'vocabulary',
          'source_type': 'duo_level',
          'source_id': '1:level-1',
          'status': 'passed',
          'score': 80.0,
          'accuracy': 0.80,
          'metadata': {'game_code': 'select_answer'},
        },
        {
          'id': 'att-2',
          'unit_id': 'unit-1',
          'activity_type': 'listening',
          'source_type': 'duo_level',
          'source_id': '2:level-1',
          'status': 'passed',
          'score': 90.0,
          'accuracy': 0.90,
          'metadata': {'game_code': 'listen_select'},
        },
      ];
      await prefs.setStringList(
        'guest_learning_attempts_v2',
        attempts.map(jsonEncode).toList(),
      );

      final mastery = await repository.fetchUnitMastery('unit-1');
      expect(mastery.vocabulary, closeTo(0.80, 0.01));
      expect(mastery.listening, closeTo(0.90, 0.01));
      expect(mastery.speaking, isNull);
      expect(mastery.hanzi, isNull);
      // Normalized: (0.80*0.35 + 0.90*0.25) / (0.35 + 0.25) = (0.28 + 0.225) / 0.60 = 0.505 / 0.60 = 0.8416
      expect(mastery.overall, closeTo(0.8416, 0.01));
      expect(mastery.bossAvailable, isTrue);
      expect(mastery.state, UnitCompletionState.bossPending);
    });

    test('guest user preserves best mastery across retry/replay', () async {
      // Attempt 1: 50% fail
      // Attempt 2 (replay): 85% pass
      final attempts = <Map<String, dynamic>>[
        {
          'id': 'att-fail',
          'unit_id': 'unit-1',
          'activity_type': 'vocabulary',
          'source_type': 'duo_level',
          'source_id': '1:level-1',
          'status': 'failed',
          'score': 50.0,
          'accuracy': 0.50,
          'metadata': {'game_code': 'word_connect'},
        },
        {
          'id': 'att-pass',
          'unit_id': 'unit-1',
          'activity_type': 'vocabulary',
          'source_type': 'duo_level',
          'source_id': '1:level-1',
          'status': 'passed',
          'score': 85.0,
          'accuracy': 0.85,
          'metadata': {'game_code': 'word_connect'},
        },
      ];
      await prefs.setStringList(
        'guest_learning_attempts_v2',
        attempts.map(jsonEncode).toList(),
      );

      final mastery = await repository.fetchUnitMastery('unit-1');
      // Should take MAX score (0.85) for the source, not average with the fail
      expect(mastery.vocabulary, closeTo(0.85, 0.01));
      expect(mastery.overall, closeTo(0.85, 0.01));
    });
  });
}

class _CapturingRepository implements LearningProgressRepository {
  LearningActivitySubmission? lastSubmission;

  @override
  Future<LearningResult> completeActivity(
    LearningActivitySubmission submission,
  ) async {
    lastSubmission = submission;
    return LearningResult(
      activityType: submission.activityType,
      sourceId: submission.sourceId,
      attemptId: submission.attemptId,
      passed: true,
      stars: 3,
      score: 90,
      accuracy: 0.9,
      correctCount: 9,
      wrongCount: 1,
      xpEarned: 20,
      baseXp: 20,
      bonusXp: 0,
      newTotalXp: 20,
      currentStreak: 1,
      firstClear: true,
      perfect: false,
    );
  }

  @override
  Future<void> abandonAttempt(
    String attemptId, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
          {int limit = 50}) async =>
      [];

  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) async =>
      const UnitMastery();

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) async =>
      [];

  @override
  Future<void> migrateGuestProgressToCloud() async {}

  @override
  Future<void> startAttempt(LearningActivitySubmission submission) async {}
}
