import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/ai/model/ai_gateway_exception.dart';
import 'package:flash_learn_chinese/core/services/gemini_service.dart';
import 'package:flash_learn_chinese/core/services/history_service.dart';
import 'package:flash_learn_chinese/core/services/tts_service.dart';
import 'package:flash_learn_chinese/screen/hsk_exam/controller/hsk_exam_controller.dart';

class FakeGeminiExamService extends GeminiService {
  bool shouldFailAnalysis = false;
  int analysisCallCount = 0;

  @override
  Future<List<dynamic>> fetchHskExam(int level) async {
    return [
      {
        'section': 'Đọc hiểu',
        'question_text': 'Nghĩa của "你好" là gì?',
        'options': ['Xin chào', 'Tạm biệt', 'Cảm ơn', 'Xin lỗi'],
        'correct_answer': 'Xin chào',
        'explanation': '"你好" có nghĩa là Xin chào.',
      },
      {
        'section': 'Đọc hiểu',
        'question_text': 'Nghĩa của "再见" là gì?',
        'options': ['Xin chào', 'Tạm biệt', 'Cảm ơn', 'Xin lỗi'],
        'correct_answer': 'Tạm biệt',
        'explanation': '"再见" có nghĩa là Tạm biệt.',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> analyzeHskExamPerformance({
    required int level,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required int score,
    required int totalQuestions,
  }) async {
    analysisCallCount++;
    if (shouldFailAnalysis) {
      throw AiGatewayException(
        code: AiGatewayErrorCode.aiTemporarilyUnavailable,
        message: 'AI Gateway timeout / quota exceeded',
      );
    }
    return {
      'overall_assessment': 'Bạn có phản xạ đọc hiểu HSK $level rất tốt.',
      'strengths': ['Ghi nhớ từ vựng cơ bản vững chắc'],
      'weaknesses': ['Cần luyện thêm phần nghe'],
      'study_suggestions': ['Luyện tập thêm đề thi mẫu'],
    };
  }
}

class FakeExamHistoryService extends HistoryService {
  final List<HistoryItem> items = [];

  @override
  Future<List<HistoryItem>> getHistory() async => List.unmodifiable(items);

  @override
  Future<void> saveHistory(HistoryItem item) async {
    items.insert(0, item);
  }

  @override
  Future<void> updateHistoryContent(
    String id,
    Map<String, dynamic> extraContent,
  ) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final existing = items[index];
      final updatedContent = Map<String, dynamic>.from(existing.content)
        ..addAll(extraContent);
      items[index] = HistoryItem(
        id: existing.id,
        type: existing.type,
        timestamp: existing.timestamp,
        summary: existing.summary,
        content: updatedContent,
      );
    }
  }
}

class FakeTtsService implements TtsService {
  String? lastSpoken;

  @override
  Future<void> speak(
    String text, {
    String language = 'zh-CN',
    double? speechRate,
  }) async {
    lastSpoken = text;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGeminiExamService fakeGemini;
  late FakeExamHistoryService fakeHistory;
  late FakeTtsService fakeTts;
  late HskExamController controller;

  setUp(() {
    fakeGemini = FakeGeminiExamService();
    fakeHistory = FakeExamHistoryService();
    fakeTts = FakeTtsService();
    controller = HskExamController(
      geminiService: fakeGemini,
      historyService: fakeHistory,
      ttsService: fakeTts,
    );
  });

  group('HskExamController Durability & Score Persistence', () {
    test(
        'submits exam, calculates deterministic score, and completes AI analysis',
        () async {
      await controller.generateExam();
      expect(controller.examState.value, equals('started'));
      expect(controller.questions.length, equals(2));

      // Answer 1 correct, 1 wrong
      controller.selectOption(0, 'Xin chào'); // Correct
      controller.selectOption(1, 'Xin lỗi'); // Wrong

      await controller.submitExam();

      expect(controller.examState.value, equals('submitted'));
      expect(controller.score.value, equals(1));
      expect(controller.overallAssessment.value,
          contains('Bạn có phản xạ đọc hiểu'));
      expect(controller.strengths.isNotEmpty, isTrue);

      // Verify history was saved and updated without duplicates
      expect(fakeHistory.items.length, equals(1));
      final saved = fakeHistory.items.first;
      expect(saved.content['score'], equals(1));
      expect(saved.content['total'], equals(2));
      expect(saved.content['has_ai_analysis'], isTrue);
    });

    test('persists raw score even when Gemini analysis throws an exception',
        () async {
      fakeGemini.shouldFailAnalysis = true;

      await controller.generateExam();
      controller.selectOption(0, 'Xin chào'); // Correct
      controller.selectOption(1, 'Tạm biệt'); // Correct

      await controller.submitExam();

      // Score is fully intact
      expect(controller.examState.value, equals('submitted'));
      expect(controller.score.value, equals(2));

      // Analysis error is captured honestly
      expect(controller.analysisError.value, isNotNull);
      expect(controller.analysisError.value,
          contains('AI Gateway timeout / quota exceeded'));
      expect(controller.overallAssessment.value, isEmpty);

      // Raw attempt is still persisted in history!
      expect(fakeHistory.items.length, equals(1));
      final saved = fakeHistory.items.first;
      expect(saved.content['score'], equals(2));
      expect(saved.content['total'], equals(2));
      expect(saved.content['has_ai_analysis'], isFalse);
    });

    test('retryAnalysis retries AI analysis without duplicating history items',
        () async {
      fakeGemini.shouldFailAnalysis = true;

      await controller.generateExam();
      controller.selectOption(0, 'Xin chào');
      controller.selectOption(1, 'Tạm biệt');

      await controller.submitExam();
      expect(fakeHistory.items.length, equals(1));
      expect(controller.overallAssessment.value, isEmpty);

      // Network recovers
      fakeGemini.shouldFailAnalysis = false;

      // Retry analysis
      await controller.retryAnalysis();

      expect(controller.overallAssessment.value, isNotEmpty);
      expect(controller.analysisError.value, isNull);

      // Crucial: No duplicate history items created!
      expect(fakeHistory.items.length, equals(1));
      final updated = fakeHistory.items.first;
      expect(updated.content['has_ai_analysis'], isTrue);
      expect(updated.content['score'], equals(2));
    });
  });
}
