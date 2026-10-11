import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_history_repository.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';

class _FakeProgressRepoForHistory implements LearningProgressRepository {
  final List<Map<String, dynamic>> mockXpHistory;
  final List<Map<String, dynamic>> mockAttempts;

  _FakeProgressRepoForHistory({
    required this.mockXpHistory,
    required this.mockAttempts,
  });

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) async {
    return mockXpHistory.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
      {int limit = 50}) async {
    return mockAttempts.take(limit).toList();
  }

  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) async {
    return const UnitMastery();
  }

  @override
  Future<LearningResult> completeActivity(
      LearningActivitySubmission submission) async {
    throw UnimplementedError();
  }

  @override
  Future<void> startAttempt(LearningActivitySubmission submission) async {}

  @override
  Future<void> abandonAttempt(String attemptId,
      {Map<String, dynamic> metadata = const {}}) async {}

  @override
  Future<void> migrateGuestProgressToCloud() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseLearningHistoryRepository (Local fallback mode)', () {
    test('fetchTodayXp correctly sums XP for today', () async {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final yesterdayStr =
          now.subtract(const Duration(days: 1)).toIso8601String();

      final fakeRepo = _FakeProgressRepoForHistory(
        mockXpHistory: [
          {
            'xp_amount': 25,
            'created_at': todayStr,
            'activity_type': 'vocabulary'
          },
          {
            'xp_amount': 15,
            'created_at': todayStr,
            'activity_type': 'listening'
          },
          {
            'xp_amount': 50,
            'created_at': yesterdayStr,
            'activity_type': 'quiz'
          },
        ],
        mockAttempts: [],
      );

      final historyRepo = SupabaseLearningHistoryRepository(
        progressRepository: fakeRepo,
      );

      final todayXp = await historyRepo.fetchTodayXp();
      expect(todayXp, 40);
    });

    test('fetch7DayXpActivity returns 7 day slots with correct weekday labels',
        () async {
      final fakeRepo = _FakeProgressRepoForHistory(
        mockXpHistory: [],
        mockAttempts: [],
      );

      final historyRepo = SupabaseLearningHistoryRepository(
        progressRepository: fakeRepo,
      );

      final weekActivity = await historyRepo.fetch7DayXpActivity();
      expect(weekActivity.length, 7);
      expect(weekActivity.last['is_today'], isTrue);
      expect(weekActivity.first.containsKey('day_label'), isTrue);
      expect(weekActivity.first.containsKey('xp'), isTrue);
    });

    test('fetchRecentTimeline extracts unified milestone events', () async {
      final now = DateTime.now().toIso8601String();
      final fakeRepo = _FakeProgressRepoForHistory(
        mockXpHistory: [
          {
            'activity_type': 'vocabulary',
            'xp_amount': 20,
            'source_id': 'duo_1_1',
            'created_at': now,
          },
          {
            'activity_type': 'boss',
            'xp_amount': 100,
            'source_id': 'boss_1',
            'created_at': now,
          },
        ],
        mockAttempts: [],
      );

      final historyRepo = SupabaseLearningHistoryRepository(
        progressRepository: fakeRepo,
      );

      final timeline = await historyRepo.fetchRecentTimeline(limit: 5);
      expect(timeline.length, 2);
      expect(timeline[0]['activity_type'], 'vocabulary');
      expect(timeline[0]['xp_amount'], 20);
      expect(timeline[1]['activity_type'], 'boss');
      expect(timeline[1]['xp_amount'], 100);
    });
  });
}
