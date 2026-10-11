import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/services/history_service.dart';
import 'package:flash_learn_chinese/screen/hsk_quiz/controller/hsk_quiz_controller.dart';
import 'package:flash_learn_chinese/screen/hsk_quiz/data/hsk_quiz_repository.dart';
import 'package:flash_learn_chinese/screen/hsk_quiz/domain/hsk_quiz_question_generator.dart';

class MockHskQuizRepository implements HskQuizRepository {
  MockHskQuizRepository({this.vocabulary});
  final List<Map<String, dynamic>>? vocabulary;

  @override
  Future<List<Map<String, dynamic>>> loadHskVocabulary(int level) async {
    return vocabulary ?? HskSeedVocabulary.getWordsForLevel(level);
  }
}

class FakeHistoryService extends HistoryService {
  final List<HistoryItem> saved = [];

  @override
  Future<List<HistoryItem>> getHistory() async => List.unmodifiable(saved);

  @override
  Future<void> saveHistory(HistoryItem item) async {
    saved.insert(0, item);
  }
}

void main() {
  group('HskSeedVocabulary & Curriculum Grounding', () {
    test('provides curated canonical vocabulary for levels 1 to 6', () {
      for (var lvl = 1; lvl <= 6; lvl++) {
        final words = HskSeedVocabulary.getWordsForLevel(lvl);
        expect(words.length, greaterThanOrEqualTo(10),
            reason: 'Level $lvl must have at least 10 curriculum words');
        for (final w in words) {
          expect(w['id'], isNotNull);
          expect(w['word'], isNotEmpty);
          expect(w['pinyin'], isNotEmpty);
          expect(w['meaning_vi'], isNotEmpty);
          expect(w['hsk_level'], equals(lvl));
          expect(w['source'], equals('curriculum_seed'));
        }
      }
    });

    test('CloudHskQuizRepository falls back safely to seed data when offline',
        () async {
      final repo = CloudHskQuizRepository(client: null);
      final words = await repo.loadHskVocabulary(1);
      expect(words.length, greaterThanOrEqualTo(10));
      expect(words.first['hsk_level'], equals(1));
    });
  });

  group('HskQuizQuestionGenerator', () {
    test('generates questions grounded in provided vocabulary pool', () {
      final vocab = HskSeedVocabulary.getWordsForLevel(1);
      final questions = HskQuizQuestionGenerator.generate(
        vocab,
        questionCount: 10,
        random: math.Random(42),
      );

      expect(questions.length, equals(10));

      final allWords = vocab.map((w) => w['hanzi']).toSet();

      for (final q in questions) {
        // Target word belongs to curriculum
        expect(allWords.contains(q['word']['hanzi']), isTrue);

        // Options contain 4 choices including the correct answer
        final options = List<String>.from(q['options']);
        expect(options.length, equals(4));
        expect(options.contains(q['correctAnswer']), isTrue);

        // Provenance attached
        expect(q['source_word_id'], isNotNull);
        expect(q['hsk_level'], equals(1));
        expect(q['explanation'], isNotEmpty);
      }
    });

    test('throws when vocabulary pool has fewer than 4 items', () {
      expect(
        () => HskQuizQuestionGenerator.generate([
          {'hanzi': '你', 'pinyin': 'nǐ', 'meaning_vi': 'bạn'},
          {'hanzi': '好', 'pinyin': 'hǎo', 'meaning_vi': 'tốt'},
        ]),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('HskQuizController', () {
    test('loads questions, updates score on correct answer, and finishes',
        () async {
      final mockRepo = MockHskQuizRepository();
      final fakeHistory = FakeHistoryService();
      final controller = HskQuizController(
        repository: mockRepo,
        historyService: fakeHistory,
      );

      expect(controller.state.value, equals(QuizState.setup));

      await controller.generate(1);

      expect(controller.state.value, equals(QuizState.playing));
      expect(controller.questions.length, equals(10));
      expect(controller.currentIndex.value, equals(0));
      expect(controller.score.value, equals(0));

      // Answer first question correctly
      final firstCorrect = controller.questions[0]['correctAnswer'];
      controller.answer(firstCorrect);
      expect(controller.score.value, equals(1));
      expect(controller.selectedAnswer.value, equals(firstCorrect));

      // Navigate through all remaining questions
      for (var i = 1; i < controller.questions.length; i++) {
        controller.nextQuestion();
        expect(controller.currentIndex.value, equals(i));
        final correctAns = controller.questions[i]['correctAnswer'];
        controller.answer(correctAns);
      }

      // Finish quiz
      controller.nextQuestion();
      expect(controller.state.value, equals(QuizState.finished));
      expect(controller.score.value, equals(10));

      // Verify practice attempt was saved to history with mode 'practice'
      expect(fakeHistory.saved.length, equals(1));
      final savedItem = fakeHistory.saved.first;
      expect(savedItem.type, equals('Trắc nghiệm HSK'));
      expect(savedItem.content['level'], equals(1));
      expect(savedItem.content['score'], equals(10));
      expect(savedItem.content['mode'], equals('practice'));
    });
  });
}
