import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/learning/data/learning_history_repository.dart';
import 'package:pandarin/core/services/history_service.dart';
import 'package:pandarin/features/history/controller/history_controller.dart';
import 'package:get/get.dart';

class FakeLearningHistoryRepo implements LearningHistoryRepository {
  final List<Map<String, dynamic>> timeline = [
    {
      'title': 'Khiêu chiến Boss',
      'activityType': 'boss',
      'icon': '🐲',
      'score': 100,
      'stars': 3,
      'xpEarned': 30,
      'timestamp': '2026-10-11T10:00:00Z',
    },
    {
      'title': 'Viết Chữ Hán',
      'activityType': 'hanzi',
      'icon': '✍️',
      'score': 95,
      'stars': 3,
      'xpEarned': 15,
      'timestamp': '2026-10-11T09:30:00Z',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchRecentTimeline(
      {int limit = 10}) async {
    return timeline.take(limit).toList();
  }

  @override
  Future<int> fetchTodayXp() async => 45;

  @override
  Future<List<Map<String, dynamic>>> fetch7DayXpActivity() async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({
    int limit = 50,
    String? activityType,
  }) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> fetchFullXpLedger({
    int limit = 50,
    String? filterType,
  }) async =>
      [];
}

class FakeAiHistoryService extends HistoryService {
  List<HistoryItem> items = [
    HistoryItem(
      id: 'ai-1',
      type: 'Dịch thuật',
      timestamp: '2026-10-11T08:00:00Z',
      summary: 'Dịch: Xin chào -> 你好',
      content: {'source_lang': 'vi', 'target_lang': 'zh', 'hanzi': '你好'},
    ),
    HistoryItem(
      id: 'ai-2',
      type: 'Hội thoại',
      timestamp: '2026-10-11T08:15:00Z',
      summary: 'Hội thoại HSK 1: Chào hỏi',
      content: {'level': 1, 'topic': 'Chào hỏi', 'lines': []},
    ),
  ];

  @override
  Future<List<HistoryItem>> getHistory() async => List.unmodifiable(items);

  @override
  Future<void> clearHistory() async {
    items.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  group('HistoryController Two Systems Separation', () {
    test('loads both official learning history and local AI utility history',
        () async {
      final fakeLearningRepo = FakeLearningHistoryRepo();
      final fakeAiHistory = FakeAiHistoryService();

      final controller = HistoryController(
        historyService: fakeAiHistory,
        learningHistoryRepository: fakeLearningRepo,
      );

      await controller.loadHistory();

      // Tab defaults to 0 (Official Learning History)
      expect(controller.selectedTab.value, equals(0));

      // Official learning items loaded from LearningHistoryRepository
      expect(controller.learningItems.length, equals(2));
      expect(controller.learningItems[0]['title'], equals('Khiêu chiến Boss'));
      expect(controller.learningItems[0]['xpEarned'], equals(30));

      // AI utility history items loaded from HistoryService
      expect(controller.aiHistoryItems.length, equals(2));
      expect(controller.aiHistoryItems[0].type, equals('Dịch thuật'));
    });

    test('switchTab toggles between learning history and AI utility history',
        () {
      final controller = HistoryController(
        historyService: FakeAiHistoryService(),
        learningHistoryRepository: FakeLearningHistoryRepo(),
      );

      expect(controller.selectedTab.value, equals(0));
      controller.switchTab(1);
      expect(controller.selectedTab.value, equals(1));
      controller.switchTab(0);
      expect(controller.selectedTab.value, equals(0));
    });

    test(
        'clearAiHistory only clears AI utility items without altering official learning ledger',
        () async {
      final fakeLearningRepo = FakeLearningHistoryRepo();
      final fakeAiHistory = FakeAiHistoryService();

      final controller = HistoryController(
        historyService: fakeAiHistory,
        learningHistoryRepository: fakeLearningRepo,
      );

      await controller.loadHistory();
      expect(controller.aiHistoryItems.length, equals(2));
      expect(controller.learningItems.length, equals(2));

      // Clear AI utility history
      await controller.clearAiHistory();

      // AI items are cleared
      expect(controller.aiHistoryItems.isEmpty, isTrue);
      expect(fakeAiHistory.items.isEmpty, isTrue);

      // CRITICAL: Official learning ledger is preserved untouched!
      expect(controller.learningItems.length, equals(2));
      expect(controller.learningItems[0]['title'], equals('Khiêu chiến Boss'));
    });
  });
}
