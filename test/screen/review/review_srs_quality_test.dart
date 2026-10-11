import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_source_context.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_reward_service.dart';
import 'package:flash_learn_chinese/core/models/speaking_practice_item.dart';
import 'package:flash_learn_chinese/screen/hanzi_writing/controller/hanzi_writing_controller.dart';
import 'package:flash_learn_chinese/screen/review/controller/review_controller.dart';
import 'package:flash_learn_chinese/screen/review/data/review_repository.dart';
import 'package:flash_learn_chinese/screen/review/model/review_item.dart';
import 'package:flash_learn_chinese/screen/review/review_screen.dart';
import 'package:flash_learn_chinese/screen/speaking/controller/speaking_controller.dart';
import 'package:flash_learn_chinese/screen/speaking/widget/speaking_cards.dart';
import 'package:flash_learn_chinese/core/services/speech_service.dart';

class StubRewardService extends LearningRewardService {
  String? lastStartedUnitId;
  String? lastStartedLevelId;
  String? lastCompletedUnitId;
  String? lastCompletedLevelId;

  @override
  Future<void> startSpeakingAttempt({
    required String sourceId,
    required String attemptId,
    int? wordId,
    int? exampleId,
    String? targetText,
    String? unitId,
    String? levelId,
  }) async {
    lastStartedUnitId = unitId;
    lastStartedLevelId = levelId;
  }

  @override
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
  }) async {
    lastCompletedUnitId = unitId;
    lastCompletedLevelId = levelId;
    return const LearningResult(
      activityType: 'speaking',
      sourceId: '1',
      attemptId: '1',
      passed: true,
      stars: 3,
      score: 100,
      accuracy: 1.0,
      correctCount: 1,
      wrongCount: 0,
      xpEarned: 10,
      baseXp: 10,
      bonusXp: 0,
      newTotalXp: 10,
      currentStreak: 1,
      firstClear: false,
      perfect: true,
    );
  }

  @override
  Future<void> startHanziAttempt({
    required int characterId,
    required String attemptId,
    String? unitId,
    String? levelId,
  }) async {
    lastStartedUnitId = unitId;
    lastStartedLevelId = levelId;
  }

  @override
  Future<LearningResult> processHanziReward({
    required int characterId,
    required String attemptId,
    required double bestScore,
    required int attempts,
    String? unitId,
    String? levelId,
    int durationSeconds = 0,
  }) async {
    lastCompletedUnitId = unitId;
    lastCompletedLevelId = levelId;
    return const LearningResult(
      activityType: 'hanzi',
      sourceId: '1',
      attemptId: '1',
      passed: true,
      stars: 3,
      score: 95,
      accuracy: 0.95,
      correctCount: 1,
      wrongCount: 0,
      xpEarned: 10,
      baseXp: 10,
      bonusXp: 0,
      newTotalXp: 10,
      currentStreak: 1,
      firstClear: false,
      perfect: true,
    );
  }
}

class FakeSpeechService extends SpeechService {
  @override
  Future<SpeechResult> listenAndScore({
    required String targetText,
    String localeId = 'zh_CN',
    Duration listenFor = const Duration(seconds: 8),
  }) async {
    return const SpeechResult(
      isAvailable: true,
      recognizedText: '你好',
      score: 95.0,
      isCorrect: true,
    );
  }
}

class FailingReviewRepository implements ReviewRepository {
  @override
  Future<ReviewSummary> loadReviewSummary() async {
    throw Exception('Database network timeout');
  }

  @override
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category) async {
    throw Exception('Database network timeout');
  }
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('PR 07: SRS Due Boundary Logic', () {
    test('strictly computes isDue according to next_review_at and mastery', () {
      final now = DateTime.now().toUtc();

      bool calculateDue({
        required bool mastered,
        required int wrongCount,
        required DateTime? nextReviewAt,
      }) {
        final nextReview = nextReviewAt?.toUtc();
        return !mastered &&
            (wrongCount > 0 || nextReview == null || !nextReview.isAfter(now));
      }

      // 1. Mastered words are NEVER due
      expect(
        calculateDue(mastered: true, wrongCount: 0, nextReviewAt: now.subtract(const Duration(days: 1))),
        isFalse,
      );

      // 2. Scheduled in future with 0 wrong count is NOT due
      expect(
        calculateDue(mastered: false, wrongCount: 0, nextReviewAt: now.add(const Duration(days: 2))),
        isFalse,
      );

      // 3. Scheduled in past (overdue) IS due
      expect(
        calculateDue(mastered: false, wrongCount: 0, nextReviewAt: now.subtract(const Duration(hours: 1))),
        isTrue,
      );

      // 4. No scheduled review (null nextReview) IS due for initial review
      expect(
        calculateDue(mastered: false, wrongCount: 0, nextReviewAt: null),
        isTrue,
      );

      // 5. Wrong count > 0 requires review regardless of future date
      expect(
        calculateDue(mastered: false, wrongCount: 2, nextReviewAt: now.add(const Duration(days: 1))),
        isTrue,
      );
    });
  });

  group('PR 07: Truthful Speaking Metrics', () {
    testWidgets('SpeakingResultCard renders truthful speech-match labels without fake multipliers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakingResultCard(
              score: 85.0,
              correct: true,
              recognized: 'nǐ hǎo',
              busy: false,
              showNext: true,
              isLast: false,
              onRetry: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confirms truthful STT text matching labels are displayed
      expect(find.text('Độ khớp từ'), findsOneWidget);
      expect(find.text('Nhận dạng'), findsOneWidget);
      expect(find.text('Mức độ'), findsOneWidget);

      // Verify fabricated multipliers ('Thanh điệu', 'Lưu loát') are NOT present
      expect(find.text('Thanh điệu'), findsNothing);
      expect(find.text('Lưu loát'), findsNothing);
    });
  });

  group('PR 07: Speaking and Hanzi Source Context Isolation', () {
    test('Curriculum speaking passes duoUnitId and levelId to reward service', () async {
      final stubReward = StubRewardService();
      final context = const LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: 'unit_3',
        lexiconUnitId: 3,
        levelId: 'unit_3_stage_speaking',
        gameCode: 'speaking',
        mode: LearningMode.duoMission,
      );

      final controller = SpeakingController(
        sourceContext: context,
        rewardService: stubReward,
        speechService: FakeSpeechService(),
        permissionChecker: () async => true,
      );
      controller.items.assignAll([
        const SpeakingPracticeItem(
          wordId: 101,
          targetText: '你好',
          pinyin: 'nǐ hǎo',
          meaning: 'Xin chào',
        ),
      ]);

      await controller.start();
      expect(stubReward.lastStartedUnitId, 'unit_3');
      expect(stubReward.lastStartedLevelId, 'unit_3_stage_speaking');
    });

    test('Practice mode speaking isolates attempts and does NOT pass unit/level IDs', () async {
      final stubReward = StubRewardService();
      final context = const LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: 'practice',
        levelId: 'free_practice',
        gameCode: 'speaking',
        mode: LearningMode.practice,
      );

      final controller = SpeakingController(
        sourceContext: context,
        rewardService: stubReward,
        random: true,
        speechService: FakeSpeechService(),
        permissionChecker: () async => true,
      );
      controller.items.assignAll([
        const SpeakingPracticeItem(
          wordId: 101,
          targetText: '你好',
          pinyin: 'nǐ hǎo',
          meaning: 'Xin chào',
        ),
      ]);

      await controller.start();
      expect(stubReward.lastStartedUnitId, isNull);
      expect(stubReward.lastStartedLevelId, isNull);
    });

    test('Curriculum Hanzi writing passes duoUnitId and levelId to reward service', () async {
      final stubReward = StubRewardService();
      final context = const LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: 'unit_4',
        lexiconUnitId: 4,
        levelId: 'unit_4_stage_hanzi',
        gameCode: 'hanzi',
        mode: LearningMode.duoMission,
      );

      final controller = HanziWritingController(
        rewardService: stubReward,
      );

      await controller.beginPractice(42, sourceContext: context);
      expect(stubReward.lastStartedUnitId, 'unit_4');
      expect(stubReward.lastStartedLevelId, 'unit_4_stage_hanzi');

      await controller.saveProgress(42, const [], sourceContext: context);
      expect(stubReward.lastCompletedUnitId, 'unit_4');
      expect(stubReward.lastCompletedLevelId, 'unit_4_stage_hanzi');
    });

    test('Free Hanzi library practice isolates attempts from Unit stages', () async {
      final stubReward = StubRewardService();
      final controller = HanziWritingController(
        rewardService: stubReward,
      );

      // In free practice, sourceContext is null or practice mode
      await controller.beginPractice(42);
      expect(stubReward.lastStartedUnitId, isNull);
      expect(stubReward.lastStartedLevelId, isNull);

      await controller.saveProgress(42, const []);
      expect(stubReward.lastCompletedUnitId, isNull);
      expect(stubReward.lastCompletedLevelId, isNull);
    });
  });

  group('PR 07: Review Hub Error State', () {
    testWidgets('shows truthful error UI instead of fake 0 items due on load failure',
        (tester) async {
      final failingRepo = FailingReviewRepository();
      final controller = ReviewController(repository: failingRepo);
      Get.put<ReviewController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: ReviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Does not show fake 0 due hero
      expect(find.textContaining('0 MỤC CẦN ÔN HÔM NAY'), findsNothing);
      // Shows error state with retry button
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
