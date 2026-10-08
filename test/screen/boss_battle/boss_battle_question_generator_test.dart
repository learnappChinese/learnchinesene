import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/screen/boss_battle/domain/boss_battle_question_generator.dart';
import 'package:flash_learn_chinese/screen/boss_battle/model/boss_battle_question.dart';

void main() {
  test('generator preserves correct answer and avoids duplicate question ids',
      () {
    final generator = BossBattleQuestionGenerator(random: Random(7));
    final seeds = List.generate(
      8,
      (index) => BossBattleQuestion(
        id: 'q$index',
        prompt: 'prompt $index',
        answers: <String>['中$index', 'A$index', 'B$index'],
        correctAnswer: '中$index',
      ),
    );

    final questions = generator.build(seeds, count: 6);

    expect(questions, hasLength(6));
    expect(questions.map((q) => q.id).toSet(), hasLength(6));
    for (final question in questions) {
      expect(question.answers, contains(question.correctAnswer));
      expect(question.answers.toSet().length, question.answers.length);
      expect(question.answers.length, lessThanOrEqualTo(4));
      expect(question.answers.length, greaterThanOrEqualTo(2));
    }
  });
}
