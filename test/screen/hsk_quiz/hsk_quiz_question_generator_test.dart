import 'package:flash_learn_chinese/screen/hsk_quiz/domain/hsk_quiz_question_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generation preserves the vocabulary and produces playable questions',
      () {
    final vocabulary = List.generate(
        40,
        (i) => {
              'hanzi': '字$i',
              'meaning_vi': 'Nghĩa $i',
              'pinyin': 'pinyin $i',
            });
    final original = List.of(vocabulary);
    final questions = HskQuizQuestionGenerator.generate(vocabulary);
    expect(vocabulary, orderedEquals(original));
    expect(questions, hasLength(10));
    for (final question in questions) {
      expect(question['options'], hasLength(4));
      expect(question['options'], contains(question['correctAnswer']));
      expect(question['questionText'], isNotEmpty);
    }
  });

  test('Insufficient vocabulary cannot start a session', () {
    expect(() => HskQuizQuestionGenerator.generate([]), throwsException);
  });
}
