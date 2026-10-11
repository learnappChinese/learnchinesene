import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'verifies every supported Duo game code maps to canonical activityType in PR02',
      () async {
    const currentContract = <String, String>{
      'learn_words': 'vocabulary',
      'select_answer': 'vocabulary',
      'match_pairs': 'vocabulary',
      'word_connect': 'vocabulary',
      'listen_select': 'listening',
      'translate': 'vocabulary',
      'gap_fill': 'vocabulary',
      'tap_complete': 'vocabulary',
      'dialogue': 'dialogue',
      'sentence_order': 'vocabulary',
      'speaking': 'speaking',
    };
    final repository = _CapturingRepository();
    final rewards = LearningRewardService(repository: repository);

    for (final entry in currentContract.entries) {
      await rewards.processDuoGameReward(
        gameId: 1,
        gameCode: entry.key,
        levelId: 'level-1',
        attemptId: 'attempt-${entry.key}',
        correctCount: 8,
        wrongCount: 2,
        score: 80,
      );
      expect(
        repository.lastSubmission?.activityType,
        entry.value,
        reason: '${entry.key} changed; PR02 must verify its mastery semantics',
      );
    }
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
      stars: 2,
      score: 80,
      accuracy: .8,
      correctCount: 8,
      wrongCount: 2,
      xpEarned: 10,
      baseXp: 10,
      bonusXp: 0,
      newTotalXp: 10,
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
