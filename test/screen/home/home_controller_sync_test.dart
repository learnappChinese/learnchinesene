import 'package:flash_learn_chinese/core/learning/data/learning_history_repository.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_mastery_service.dart';
import 'package:flash_learn_chinese/screen/home/controller/home_controller.dart';
import 'package:flash_learn_chinese/screen/home/data/home_journey_repository.dart';
import 'package:flash_learn_chinese/screen/home/model/home_journey.dart';
import 'package:flash_learn_chinese/screen/review/data/review_repository.dart';
import 'package:flash_learn_chinese/screen/review/model/review_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one failed Home endpoint preserves every successful slice', () async {
    final controller = HomeController(
      journeyRepository: _FailingJourneyRepository(),
      reviewRepository: _ReviewRepository(),
      historyRepository: _HistoryRepository(),
      masteryService: _MasteryService(),
      statsLoader: () async => const <String, num>{
        'totalExp': 321,
        'streak': 7,
        'learned': 12,
      },
    );

    await controller.refreshStats();

    expect(controller.stats['learned'], 12);
    expect(controller.lifetimeXp.value, 321);
    expect(controller.streak.value, 7);
    expect(controller.todayXp.value, 25);
    expect(controller.sevenDayXp, hasLength(1));
    expect(controller.recentTimeline, hasLength(1));
    expect(controller.reviewSummary.value?.totalDue, 3);
    expect(controller.masteryProfile.value.overall, .8);
    expect(controller.journey.value, isNull);
    expect(controller.journeyError.value, isNotNull);
    expect(controller.isJourneyLoading.value, isFalse);

    controller.onClose();
  });
}

class _FailingJourneyRepository implements HomeJourneyRepository {
  @override
  Future<HomeJourney?> loadJourney() =>
      Future<HomeJourney?>.error(StateError('journey unavailable'));
}

class _ReviewRepository implements ReviewRepository {
  @override
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category) async =>
      const <ReviewItem>[];

  @override
  Future<ReviewSummary> loadReviewSummary() async =>
      const ReviewSummary(totalDue: 3, wordsDue: 3);
}

class _HistoryRepository implements LearningHistoryRepository {
  @override
  Future<List<Map<String, dynamic>>> fetch7DayXpActivity() async =>
      <Map<String, dynamic>>[
        <String, dynamic>{'dayLabel': 'T2', 'xpEarned': 25},
      ];

  @override
  Future<List<Map<String, dynamic>>> fetchRecentTimeline({
    int limit = 10,
  }) async =>
      <Map<String, dynamic>>[
        <String, dynamic>{'activity_type': 'vocabulary', 'xp_earned': 25},
      ];

  @override
  Future<int> fetchTodayXp() async => 25;

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({
    int limit = 50,
    String? activityType,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchFullXpLedger({
    int limit = 50,
    String? filterType,
  }) =>
      throw UnimplementedError();
}

class _MasteryService implements LearningMasteryService {
  @override
  Future<SkillMasteryProfile> getOverallSkillMastery({
    String? currentUnitId,
  }) async =>
      const SkillMasteryProfile(overall: .8, vocabulary: .9);
}
