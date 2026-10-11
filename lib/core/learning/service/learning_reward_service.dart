import '../data/learning_progress_repository.dart';
import '../model/learning_activity_submission.dart';
import '../model/learning_result.dart';

/// Coordinates raw learning submissions.
///
/// Signed-in results are evaluated by `complete_learning_activity_v2`.
/// Guest results use the same rule contract through the local repository.
class LearningRewardService {
  LearningRewardService({LearningProgressRepository? repository})
      : _repository = repository ?? SupabaseLearningProgressRepository();

  final LearningProgressRepository _repository;

  Future<void> startAttempt(LearningActivitySubmission submission) =>
      _repository.startAttempt(submission);

  Future<void> abandonAttempt(
    String attemptId, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      _repository.abandonAttempt(attemptId, metadata: metadata);

  Future<LearningResult> completeActivity(
    LearningActivitySubmission submission,
  ) =>
      _repository.completeActivity(submission);

  Future<LearningResult> processVocabularyReward({
    required String levelId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    required int maxCombo,
    int? gameId,
    String? unitId,
    int? totalQuestions,
    int durationSeconds = 0,
  }) {
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'vocabulary',
        sourceType: gameId == null ? 'level' : 'duo_level',
        sourceId: gameId == null ? levelId : '$gameId:$levelId',
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        score: _accuracyPercent(correctCount, wrongCount),
        correctCount: correctCount,
        wrongCount: wrongCount,
        durationSeconds: durationSeconds,
        bestCombo: maxCombo,
        metadata: <String, dynamic>{
          if (gameId != null) 'game_id': gameId,
          'game_code': 'learn_words',
          if (totalQuestions != null) 'required_questions': totalQuestions,
        },
      ),
    );
  }

  Future<LearningResult> processListeningReward({
    required String sourceId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    required int maxCombo,
    String? unitId,
    String? levelId,
    int replayCount = 0,
    int slowAudioCount = 0,
    int durationSeconds = 0,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'listening',
        sourceType: 'listening_challenge',
        sourceId: sourceId,
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        score: _accuracyPercent(correctCount, wrongCount),
        correctCount: correctCount,
        wrongCount: wrongCount,
        durationSeconds: durationSeconds,
        bestCombo: maxCombo,
        metadata: <String, dynamic>{
          ...metadata,
          'replay_count': replayCount,
          'slow_audio_count': slowAudioCount,
        },
      ),
    );
  }

  Future<LearningResult> processSpeakingReward({
    required String sourceId,
    required String attemptId,
    required double accuracyScore,
    required double? pronunciationScore,
    required double? toneScore,
    required double? fluencyScore,
    String? recognizedText,
    int? wordId,
    int? exampleId,
    String? targetText,
    String? unitId,
    String? levelId,
    int durationSeconds = 0,
  }) {
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'speaking',
        sourceType: 'speaking_practice',
        sourceId: sourceId,
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        score: accuracyScore,
        accuracy: (accuracyScore / 100).clamp(0.0, 1.0),
        pronunciation: pronunciationScore,
        tone: toneScore,
        fluency: fluencyScore,
        durationSeconds: durationSeconds,
        metadata: <String, dynamic>{
          'recognized_text': recognizedText,
          'target_text': targetText,
          if (wordId != null) 'word_id': wordId,
          if (exampleId != null) 'example_id': exampleId,
        },
      ),
    );
  }

  Future<void> startSpeakingAttempt({
    required String sourceId,
    required String attemptId,
    int? wordId,
    int? exampleId,
    String? targetText,
    String? unitId,
    String? levelId,
  }) {
    return startAttempt(
      LearningActivitySubmission(
        activityType: 'speaking',
        sourceType: 'speaking_practice',
        sourceId: sourceId,
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        metadata: <String, dynamic>{
          'target_text': targetText,
          if (wordId != null) 'word_id': wordId,
          if (exampleId != null) 'example_id': exampleId,
        },
      ),
    );
  }

  Future<LearningResult> processHanziReward({
    required int characterId,
    required String attemptId,
    required double bestScore,
    required int attempts,
    String? unitId,
    String? levelId,
    int durationSeconds = 0,
  }) {
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'hanzi',
        sourceType: 'character',
        sourceId: '$characterId',
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        score: bestScore,
        hanziScore: bestScore,
        durationSeconds: durationSeconds,
        metadata: <String, dynamic>{
          'character_id': characterId,
          'practice_attempts': attempts,
        },
      ),
    );
  }

  Future<void> startHanziAttempt({
    required int characterId,
    required String attemptId,
    String? unitId,
    String? levelId,
  }) {
    return startAttempt(
      LearningActivitySubmission(
        activityType: 'hanzi',
        sourceType: 'character',
        sourceId: '$characterId',
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        metadata: <String, dynamic>{'character_id': characterId},
      ),
    );
  }

  Future<LearningResult> processBossReward({
    required int stageId,
    required String attemptId,
    required int score,
    required int correctCount,
    required int wrongCount,
    required int bestCombo,
    required int playerHp,
    required int bossHp,
    int durationSeconds = 0,
  }) {
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'boss',
        sourceType: stageId > 0 ? 'boss_stage' : 'boss_practice',
        sourceId: stageId > 0 ? '$stageId' : 'free_battle',
        attemptId: attemptId,
        score: score.toDouble(),
        correctCount: correctCount,
        wrongCount: wrongCount,
        durationSeconds: durationSeconds,
        bestCombo: bestCombo,
        bossHp: bossHp,
        playerHp: playerHp,
        metadata: <String, dynamic>{'stage_id': stageId},
      ),
    );
  }

  Future<void> startBossAttempt({
    required int stageId,
    required String attemptId,
  }) {
    return startAttempt(
      LearningActivitySubmission(
        activityType: 'boss',
        sourceType: stageId > 0 ? 'boss_stage' : 'boss_practice',
        sourceId: stageId > 0 ? '$stageId' : 'free_battle',
        attemptId: attemptId,
        metadata: <String, dynamic>{
          if (stageId > 0) 'stage_id': stageId,
        },
      ),
    );
  }

  Future<LearningResult> processDialogueReward({
    required String dialogueId,
    required String attemptId,
    required int completedObjectives,
    required int totalObjectives,
    int maxCombo = 0,
    String? unitId,
    String? levelId,
    int durationSeconds = 0,
  }) {
    final completion = totalObjectives > 0
        ? (completedObjectives / totalObjectives).clamp(0.0, 1.0)
        : 0.0;
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'dialogue',
        sourceType: 'dialogue_practice',
        sourceId: dialogueId,
        attemptId: attemptId,
        unitId: unitId,
        levelId: levelId,
        score: completion * 100,
        correctCount: completedObjectives,
        wrongCount: totalObjectives - completedObjectives,
        durationSeconds: durationSeconds,
        bestCombo: maxCombo,
        objectiveCompletion: completion,
        metadata: <String, dynamic>{
          'total_objectives': totalObjectives,
          'completed_objectives': completedObjectives,
        },
      ),
    );
  }

  Future<LearningResult> processReviewReward({
    required String sourceId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    int bestCombo = 0,
    int durationSeconds = 0,
  }) {
    return completeActivity(
      LearningActivitySubmission(
        activityType: 'review',
        sourceType: 'review_session',
        sourceId: sourceId,
        attemptId: attemptId,
        score: _accuracyPercent(correctCount, wrongCount),
        correctCount: correctCount,
        wrongCount: wrongCount,
        durationSeconds: durationSeconds,
        bestCombo: bestCombo,
      ),
    );
  }

  Future<void> startReviewAttempt({
    required String sourceId,
    required String attemptId,
  }) {
    return startAttempt(
      LearningActivitySubmission(
        activityType: 'review',
        sourceType: 'review_session',
        sourceId: sourceId,
        attemptId: attemptId,
      ),
    );
  }

  Future<LearningResult> processDuoGameReward({
    required int gameId,
    required String gameCode,
    required String levelId,
    required String attemptId,
    required int correctCount,
    required int wrongCount,
    required int score,
    int maxCombo = 0,
    int durationSeconds = 0,
    double? pronunciationScore,
    double? toneScore,
    double? fluencyScore,
  }) {
    final activityType = _duoActivityType(gameCode);
    return completeActivity(
      LearningActivitySubmission(
        activityType: activityType,
        sourceType: 'duo_level',
        sourceId: '$gameId:$levelId',
        attemptId: attemptId,
        levelId: levelId,
        score: score.toDouble(),
        correctCount: correctCount,
        wrongCount: wrongCount,
        durationSeconds: durationSeconds,
        bestCombo: maxCombo,
        pronunciation: pronunciationScore,
        tone: toneScore,
        fluency: fluencyScore,
        metadata: <String, dynamic>{
          'game_code': gameCode,
          'game_id': gameId,
          'level_id': levelId,
        },
      ),
    );
  }

  Future<void> startDuoGameAttempt({
    required int gameId,
    required String gameCode,
    required String levelId,
    required String attemptId,
  }) {
    return startAttempt(
      LearningActivitySubmission(
        activityType: _duoActivityType(gameCode),
        sourceType: 'duo_level',
        sourceId: '$gameId:$levelId',
        attemptId: attemptId,
        levelId: levelId,
        metadata: <String, dynamic>{
          'game_code': gameCode,
          'game_id': gameId,
          'level_id': levelId,
        },
      ),
    );
  }

  static String _duoActivityType(String gameCode) => switch (gameCode) {
        'speaking' => 'speaking',
        'dialogue' => 'dialogue',
        'listen_select' => 'listening',
        'learn_words' => 'vocabulary',
        _ => 'game_mission',
      };

  static double _accuracyPercent(int correct, int wrong) {
    final total = correct + wrong;
    return total == 0 ? 0 : (correct / total) * 100;
  }
}
