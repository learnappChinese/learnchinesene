import 'package:flash_learn_chinese/core/learning/data/learning_history_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/recommended_next_action.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_mastery_service.dart';
import 'package:flash_learn_chinese/screen/home/controller/home_controller.dart';
import 'package:flash_learn_chinese/screen/home/data/home_journey_repository.dart';
import 'package:flash_learn_chinese/screen/home/model/home_journey.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_dashboard.dart';
import 'package:flash_learn_chinese/screen/review/data/review_repository.dart';
import 'package:flash_learn_chinese/screen/review/model/review_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

const testJourney = HomeJourney(
  gameId: 10,
  gameCode: 'speaking',
  gameName: 'Luyện nói',
  gameDescription: 'Chào hỏi cơ bản',
  levelId: 'lvl_1',
  unitId: 'unit_1',
  worldNumber: 1,
  chapterNumber: 1,
  chapterTitle: 'Bài 1: Làm quen',
  missionNumber: 1,
  missionTitle: 'Luyện phát âm',
  completedMissions: 1,
  totalMissions: 4,
  stars: 3,
  bossProgress: 0.25,
  nextRewardXp: 20,
  nextAction: RecommendedNextAction(
    type: RecommendedActionType.startMission,
    destination: 'mission:10',
    unitId: 'unit_1',
    reasonCode: 'in_progress_mission',
    label: 'TIẾP TỤC',
    title: 'Luyện phát âm',
    estimatedMinutes: 5,
  ),
);

void main() {
  group('Home Smart Recommendation & Resilience Tests', () {
    test(
        'Zero Today/Lifetime XP flipping: When todayXp is 0, HomeController keeps todayXp = 0 and does not substitute lifetimeXp',
        () async {
      final controller = HomeController(
        journeyRepository: _StaticJourneyRepository(journey: testJourney),
        reviewRepository: _StaticReviewRepository(),
        historyRepository: _ZeroTodayXpHistoryRepository(lifetimeXp: 850),
        masteryService: _StaticMasteryService(),
        statsLoader: () async => const <String, num>{
          'totalExp': 850,
          'streak': 12,
          'learned': 25,
        },
      );

      await controller.refreshStats();

      // Today XP must be strictly 0, not substituted by lifetime XP
      expect(controller.todayXp.value, 0);
      expect(controller.lifetimeXp.value, 850);
      expect(controller.streak.value, 12);
      expect(controller.stats['learned'], 25);

      controller.onClose();
    });

    test(
        'Partial failure resilience: Failure of review or history slice preserves journey snapshot and sets journeyError',
        () async {
      final controller = HomeController(
        journeyRepository: _StaticJourneyRepository(journey: testJourney),
        reviewRepository: _FailingReviewRepository(), // Throws error
        historyRepository: _FailingHistoryRepository(), // Throws error
        masteryService: _StaticMasteryService(),
        statsLoader: () async => const <String, num>{
          'totalExp': 200,
          'streak': 3,
        },
      );

      await controller.refreshStats();

      // Journey is preserved and NOT blanked
      expect(controller.journey.value, isNotNull);
      expect(controller.journey.value?.chapterTitle, 'Bài 1: Làm quen');
      expect(controller.journeyError.value, isNotNull);
      expect(controller.isJourneyLoading.value, isFalse);

      controller.onClose();
    });

    testWidgets(
        'Dashboard displays stale notice badge when errorMessage is present without blanking journey',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 850);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        app(
          HomeDashboard(
            journey: testJourney,
            isLoading: false,
            errorMessage: 'Không thể kết nối máy chủ',
            streak: 5,
            lessons: 10,
            xp: 0, // Honest 0 Today XP
            onStartLearning: () {},
            onGrammar: () {},
            onListening: () {},
            onSpeaking: () {},
            onChallenge: () {},
            onProgress: () {},
          ),
        ),
      );
      await tester.pump();

      // Stale notice rendered
      expect(find.textContaining('Dữ liệu ngoại tuyến'), findsOneWidget);
      expect(find.textContaining('Không thể kết nối máy chủ'), findsOneWidget);

      // Journey is STILL completely visible
      expect(find.text('BÀI 1: Bài 1: Làm quen'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // Displays 0 XP
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dashboard renders cleanly with dynamic recommendation CTA',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        app(
          HomeDashboard(
            journey: testJourney,
            isLoading: false,
            streak: 3,
            lessons: 5,
            xp: 25,
            onStartLearning: () {},
            onGrammar: () {},
            onListening: () {},
            onSpeaking: () {},
            onChallenge: () {},
            onProgress: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('你好! 👋'), findsOneWidget);
      expect(find.text('NHIỆM VỤ TIẾP THEO'), findsOneWidget);
      expect(find.text('Luyện phát âm'), findsOneWidget);
      expect(find.text('TIẾP TỤC'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

class _StaticJourneyRepository implements HomeJourneyRepository {
  _StaticJourneyRepository({this.journey});
  final HomeJourney? journey;
  @override
  Future<HomeJourney?> loadJourney() async => journey;
}

class _StaticReviewRepository implements ReviewRepository {
  @override
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category) async => [];
  @override
  Future<ReviewSummary> loadReviewSummary() async =>
      const ReviewSummary(totalDue: 0);
}

class _FailingReviewRepository implements ReviewRepository {
  @override
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category) async =>
      throw StateError('Review service unavailable');
  @override
  Future<ReviewSummary> loadReviewSummary() async =>
      throw StateError('Review summary timed out');
}

class _ZeroTodayXpHistoryRepository implements LearningHistoryRepository {
  _ZeroTodayXpHistoryRepository({required this.lifetimeXp});
  final int lifetimeXp;

  @override
  Future<int> fetchTodayXp() async => 0; // Strictly 0
  @override
  Future<List<Map<String, dynamic>>> fetch7DayXpActivity() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchRecentTimeline(
          {int limit = 10}) async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
          {int limit = 50, String? activityType}) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> fetchFullXpLedger(
          {int limit = 50, String? filterType}) =>
      throw UnimplementedError();
}

class _FailingHistoryRepository implements LearningHistoryRepository {
  @override
  Future<int> fetchTodayXp() async => throw StateError('History DB timeout');
  @override
  Future<List<Map<String, dynamic>>> fetch7DayXpActivity() async =>
      throw StateError('7 day XP unavailable');
  @override
  Future<List<Map<String, dynamic>>> fetchRecentTimeline(
          {int limit = 10}) async =>
      throw StateError('Timeline unavailable');
  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
          {int limit = 50, String? activityType}) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> fetchFullXpLedger(
          {int limit = 50, String? filterType}) =>
      throw UnimplementedError();
}

class _StaticMasteryService implements LearningMasteryService {
  @override
  Future<SkillMasteryProfile> getOverallSkillMastery(
          {String? currentUnitId}) async =>
      const SkillMasteryProfile(overall: 0.75);
}
