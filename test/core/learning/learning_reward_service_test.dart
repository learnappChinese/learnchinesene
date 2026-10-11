import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/learning_rules_config.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_reward_service.dart';

class FakeLearningProgressRepository implements LearningProgressRepository {
  final List<Map<String, dynamic>> recordedCalls = [];
  final Set<String> processedKeys = {};
  int currentTotalXp = 100;
  int currentStreak = 2;

  @override
  Future<LearningResult> recordReward({
    required String activityType,
    required String sourceType,
    required String sourceId,
    required String attemptId,
    required double score,
    required double accuracy,
    required int correctCount,
    required int wrongCount,
    required int stars,
    required bool passed,
    required int baseXp,
    required int bonusXp,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
  }) async {
    final key = idempotencyKey ?? '$sourceType:$sourceId:$attemptId';
    final isDuplicate = processedKeys.contains(key);

    if (isDuplicate) {
      return LearningResult(
        activityType: activityType,
        sourceId: sourceId,
        attemptId: attemptId,
        passed: passed,
        stars: stars,
        score: score,
        accuracy: accuracy,
        correctCount: correctCount,
        wrongCount: wrongCount,
        xpEarned: 0,
        baseXp: baseXp,
        bonusXp: bonusXp,
        newTotalXp: currentTotalXp,
        newStreak: currentStreak,
        isFirstClear: false,
        isPerfect: accuracy >= 1.0,
      );
    }

    processedKeys.add(key);
    final totalXp = baseXp + bonusXp;
    currentTotalXp += totalXp;
    if (passed) currentStreak += 1;

    final result = LearningResult(
      activityType: activityType,
      sourceId: sourceId,
      attemptId: attemptId,
      passed: passed,
      stars: stars,
      score: score,
      accuracy: accuracy,
      correctCount: correctCount,
      wrongCount: wrongCount,
      xpEarned: totalXp,
      baseXp: baseXp,
      bonusXp: bonusXp,
      newTotalXp: currentTotalXp,
      newStreak: currentStreak,
      isFirstClear: true,
      isPerfect: accuracy >= 1.0,
      metadata: metadata ?? const {},
    );

    recordedCalls.add({
      'key': key,
      'result': result,
    });

    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
          {int limit = 50}) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) async =>
      [];

  @override
  Future<void> migrateGuestProgressToCloud() async {}
}

void main() {
  late FakeLearningProgressRepository fakeRepo;
  late LearningRewardService service;

  setUp(() {
    fakeRepo = FakeLearningProgressRepository();
    service = LearningRewardService(repository: fakeRepo);
  });

  group('LearningRulesConfig tests', () {
    test('star evaluation boundaries', () {
      expect(LearningRulesConfig.evaluateStars(0.69), 0);
      expect(LearningRulesConfig.evaluateStars(0.70), 1);
      expect(LearningRulesConfig.evaluateStars(0.79), 1);
      expect(LearningRulesConfig.evaluateStars(0.80), 2);
      expect(LearningRulesConfig.evaluateStars(0.94), 2);
      expect(LearningRulesConfig.evaluateStars(0.95), 3);
      expect(LearningRulesConfig.evaluateStars(1.0), 3);
    });

    test('speaking weighted score calculation', () {
      final overall = LearningRulesConfig.calculateSpeakingOverall(
        accuracy: 80.0, // 80 * 0.35 = 28
        pronunciation: 70.0, // 70 * 0.30 = 21
        tone: 60.0, // 60 * 0.20 = 12
        fluency: 70.0, // 70 * 0.15 = 10.5
      );
      expect(overall, closeTo(71.5, 0.01));
    });
  });

  group('LearningRewardService tests', () {
    test('vocabulary pass with perfect accuracy and first clear bonus',
        () async {
      final result = await service.processVocabularyReward(
        levelId: 'lvl_101',
        attemptId: 'att_01',
        correctCount: 10,
        wrongCount: 0,
        maxCombo: 10,
        isFirstClear: true,
      );

      expect(result.passed, isTrue);
      expect(result.stars, 3);
      expect(result.accuracy, 1.0);
      expect(result.baseXp, LearningRulesConfig.vocabularyBaseXp);
      expect(
        result.bonusXp,
        LearningRulesConfig.perfectBonusXp +
            LearningRulesConfig.highAccuracyBonusXp +
            LearningRulesConfig.comboBonusXp +
            LearningRulesConfig.firstClearBonusXp,
      );
      expect(result.xpEarned, result.baseXp + result.bonusXp);
      expect(result.isFirstClear, isTrue);
    });

    test('vocabulary fail below 70% receives practice effort XP', () async {
      final result = await service.processVocabularyReward(
        levelId: 'lvl_101',
        attemptId: 'att_02',
        correctCount: 5,
        wrongCount: 5, // 50%
        maxCombo: 2,
        isFirstClear: false,
      );

      expect(result.passed, isFalse);
      expect(result.stars, 0);
      expect(result.baseXp, LearningRulesConfig.practiceEffortXp);
      expect(result.bonusXp, 0);
      expect(result.xpEarned, LearningRulesConfig.practiceEffortXp);
    });

    test('idempotency prevents double XP awarding for same attempt', () async {
      final res1 = await service.processVocabularyReward(
        levelId: 'lvl_102',
        attemptId: 'att_idem_1',
        correctCount: 8,
        wrongCount: 2,
        maxCombo: 6,
        isFirstClear: false,
      );
      expect(res1.xpEarned, greaterThan(0));

      // Retry same attemptId
      final res2 = await service.processVocabularyReward(
        levelId: 'lvl_102',
        attemptId: 'att_idem_1',
        correctCount: 8,
        wrongCount: 2,
        maxCombo: 6,
        isFirstClear: false,
      );
      expect(res2.xpEarned, 0); // No double XP awarded!
    });

    test('speaking pass requires both overall >= 65 and tone >= 50', () async {
      // High accuracy but failing tone (< 50)
      final failedToneResult = await service.processSpeakingReward(
        sourceId: 'spk_1',
        attemptId: 'att_spk_1',
        accuracyScore: 90.0,
        pronunciationScore: 80.0,
        toneScore: 45.0, // Tone too low!
        fluencyScore: 80.0,
      );
      expect(failedToneResult.passed, isFalse);
      expect(failedToneResult.stars, 0);

      // Good tone (>= 50) and good overall (>= 65)
      final passedResult = await service.processSpeakingReward(
        sourceId: 'spk_2',
        attemptId: 'att_spk_2',
        accuracyScore: 85.0,
        pronunciationScore: 80.0,
        toneScore: 70.0,
        fluencyScore: 75.0,
      );
      expect(passedResult.passed, isTrue);
      expect(passedResult.stars, greaterThanOrEqualTo(1));
    });

    test('boss win awards bossBaseXp, stars based on player remaining HP',
        () async {
      final bossWin = await service.processBossReward(
        stageId: 1,
        attemptId: 'att_boss_1',
        won: true,
        score: 500,
        bestCombo: 8,
        playerHp: 85,
        bossHp: 0,
        isFirstClear: true,
      );

      expect(bossWin.passed, isTrue);
      expect(bossWin.stars, 3);
      expect(bossWin.baseXp, LearningRulesConfig.bossBaseXp);
      expect(bossWin.bonusXp, greaterThan(0));
    });

    test('boss loss awards zero stars and partial practice XP', () async {
      final bossLoss = await service.processBossReward(
        stageId: 1,
        attemptId: 'att_boss_2',
        won: false,
        score: 120,
        bestCombo: 2,
        playerHp: 0,
        bossHp: 40,
        isFirstClear: false,
      );

      expect(bossLoss.passed, isFalse);
      expect(bossLoss.stars, 0);
      expect(bossLoss.xpEarned, lessThanOrEqualTo(15));
    });

    test('duo game reward calculates correctly for listening and dialogue',
        () async {
      final listenResult = await service.processDuoGameReward(
        gameId: 4,
        gameCode: 'listen_select',
        levelId: 'lvl_listen_1',
        attemptId: 'att_listen_1',
        correctCount: 8,
        wrongCount: 2,
        score: 80,
        maxCombo: 5,
        isFirstClear: true,
      );

      expect(listenResult.activityType, 'listening');
      expect(listenResult.passed, isTrue);
      expect(listenResult.stars, 2);
      expect(listenResult.baseXp, LearningRulesConfig.listeningBaseXp);

      final dialogueResult = await service.processDuoGameReward(
        gameId: 8,
        gameCode: 'dialogue',
        levelId: 'lvl_diag_1',
        attemptId: 'att_diag_1',
        correctCount: 10,
        wrongCount: 0,
        score: 100,
        maxCombo: 10,
        isFirstClear: true,
      );

      expect(dialogueResult.activityType, 'dialogue');
      expect(dialogueResult.passed, isTrue);
      expect(dialogueResult.stars, 3);
      expect(dialogueResult.baseXp, LearningRulesConfig.dialogueBaseXp);
    });

    test('dialogue objective reward calculates completion and stars', () async {
      final diagReward = await service.processDialogueReward(
        dialogueId: 'diag_123',
        attemptId: 'att_diag_obj_1',
        completedObjectives: 3,
        totalObjectives: 4, // 75% -> pass
      );

      expect(diagReward.passed, isTrue);
      expect(diagReward.stars, 1);
      expect(diagReward.baseXp, LearningRulesConfig.dialogueBaseXp);
    });

    test('hanzi writing reward validates pass and mastery thresholds',
        () async {
      final passedHanzi = await service.processHanziReward(
        characterId: 42,
        attemptId: 'att_hz_1',
        bestScore: 88.0,
        attempts: 2,
      );

      expect(passedHanzi.passed, isTrue);
      expect(passedHanzi.stars, 2);
      expect(passedHanzi.baseXp, LearningRulesConfig.hanziBaseXp);

      final failedHanzi = await service.processHanziReward(
        characterId: 43,
        attemptId: 'att_hz_2',
        bestScore: 65.0, // < 70%
        attempts: 1,
      );

      expect(failedHanzi.passed, isFalse);
      expect(failedHanzi.stars, 0);
      expect(failedHanzi.baseXp, LearningRulesConfig.practiceEffortXp);
    });
  });

  group('Unit Mastery and Level State evaluation tests', () {
    test(
        'calculateUnitMastery normalizes weights correctly when all skills present',
        () {
      final mastery = LearningRulesConfig.calculateUnitMastery(
        vocabularyMastery: 0.80, // 0.80 * 0.35 = 0.28
        listeningMastery: 0.70, // 0.70 * 0.25 = 0.175
        speakingMastery: 0.60, // 0.60 * 0.20 = 0.12
        hanziMastery: 0.90, // 0.90 * 0.20 = 0.18
      );
      // sum = 0.755 / 1.0 = 0.755
      expect(mastery, closeTo(0.755, 0.001));
    });

    test('calculateUnitMastery normalizes weights when some skills are missing',
        () {
      // Only vocab (0.35) and listening (0.25) -> totalWeight = 0.60
      final mastery = LearningRulesConfig.calculateUnitMastery(
        vocabularyMastery: 1.0,
        listeningMastery: 0.5,
      );
      // (1.0*0.35 + 0.5*0.25) / 0.60 = (0.35 + 0.125) / 0.60 = 0.475 / 0.60 ≈ 0.7916
      expect(mastery, closeTo(0.7916, 0.001));
    });

    test('deriveLevelState returns accurate states', () {
      expect(
        LearningRulesConfig.deriveLevelState(
          isUnlocked: false,
          isCompleted: false,
          stars: 0,
          attempts: 0,
        ),
        LearningLevelState.locked,
      );

      expect(
        LearningRulesConfig.deriveLevelState(
          isUnlocked: true,
          isCompleted: false,
          stars: 0,
          attempts: 0,
        ),
        LearningLevelState.available,
      );

      expect(
        LearningRulesConfig.deriveLevelState(
          isUnlocked: true,
          isCompleted: false,
          stars: 0,
          attempts: 1,
        ),
        LearningLevelState.failed,
      );

      expect(
        LearningRulesConfig.deriveLevelState(
          isUnlocked: true,
          isCompleted: true,
          stars: 3,
          attempts: 2,
        ),
        LearningLevelState.perfect,
      );
    });

    test(
        'evaluateUnitState requires all missions, mastery threshold and boss win',
        () {
      // In progress: missions not passed
      expect(
        LearningRulesConfig.evaluateUnitState(
          allMissionsPassed: false,
          overallMastery: 0.85,
          hasBoss: true,
          bossWon: true,
        ),
        UnitPassState.inProgress,
      );

      // In progress: mastery < 70%
      expect(
        LearningRulesConfig.evaluateUnitState(
          allMissionsPassed: true,
          overallMastery: 0.65,
          hasBoss: true,
          bossWon: true,
        ),
        UnitPassState.inProgress,
      );

      // Boss pending: missions passed, mastery >= 70%, but boss not won
      expect(
        LearningRulesConfig.evaluateUnitState(
          allMissionsPassed: true,
          overallMastery: 0.75,
          hasBoss: true,
          bossWon: false,
        ),
        UnitPassState.bossPending,
      );

      // Completed: all passed and boss won
      expect(
        LearningRulesConfig.evaluateUnitState(
          allMissionsPassed: true,
          overallMastery: 0.75,
          hasBoss: true,
          bossWon: true,
        ),
        UnitPassState.completed,
      );
    });
  });
}
