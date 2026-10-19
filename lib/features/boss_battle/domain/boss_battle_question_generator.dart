import 'dart:math';

import '../model/boss_battle_question.dart';

class BossBattleQuestionGenerator {
  BossBattleQuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<BossBattleQuestion> build(
    List<BossBattleQuestion> seeds, {
    int count = 12,
  }) {
    if (seeds.isEmpty) return const [];

    final uniqueById = <String, BossBattleQuestion>{
      for (final seed in seeds) seed.id: seed,
    };

    final shuffled = uniqueById.values.toList()..shuffle(_random);
    final answerPool = shuffled
        .expand((question) => question.answers)
        .map((answer) => answer.trim())
        .where((answer) => answer.isNotEmpty)
        .toSet()
        .toList()
      ..shuffle(_random);

    final result = <BossBattleQuestion>[];

    for (final seed in shuffled) {
      final answers = <String>[seed.correctAnswer];

      final localDistractors = seed.answers
          .where((answer) => answer != seed.correctAnswer)
          .toList()
        ..shuffle(_random);

      for (final candidate in localDistractors) {
        if (answers.length >= 4) break;
        if (candidate.trim().isNotEmpty && !answers.contains(candidate)) {
          answers.add(candidate);
        }
      }

      for (final candidate in answerPool) {
        if (answers.length >= 4) break;
        if (candidate != seed.correctAnswer && !answers.contains(candidate)) {
          answers.add(candidate);
        }
      }

      if (answers.length < 2) continue;

      answers.shuffle(_random);
      result.add(seed.copyWith(answers: answers.take(4).toList()));

      if (result.length >= count) break;
    }

    return result;
  }
}
