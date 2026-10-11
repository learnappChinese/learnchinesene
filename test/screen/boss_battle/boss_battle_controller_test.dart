import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/screen/boss_battle/controller/boss_battle_controller.dart';
import 'package:flash_learn_chinese/screen/boss_battle/data/boss_battle_repository.dart';
import 'package:flash_learn_chinese/screen/boss_battle/domain/boss_battle_question_generator.dart';
import 'package:flash_learn_chinese/screen/boss_battle/model/boss_battle_question.dart';

class _FakeQuestionSource implements BossBattleQuestionSource {
  _FakeQuestionSource(this.questions);

  final List<BossBattleQuestion> questions;

  @override
  Future<List<BossBattleQuestion>> loadQuestionSeeds({
    int limit = 36,
    int? stageId,
  }) async {
    return questions.take(limit).toList();
  }

  @override
  Future<void> recordBossProgress({
    required int stageId,
    required int score,
    required int stars,
    required int bestCombo,
    required bool won,
  }) async {}

  @override
  Future<void> close() async {}
}

List<BossBattleQuestion> _questions() {
  return List.generate(
    12,
    (index) => BossBattleQuestion(
      id: 'q$index',
      prompt: 'nghĩa $index',
      answers: <String>['中$index', 'A$index', 'B$index', 'C$index'],
      correctAnswer: '中$index',
    ),
  );
}

BossBattleController _controller() {
  return BossBattleController(
    source: _FakeQuestionSource(_questions()),
    generator: BossBattleQuestionGenerator(),
    resolveDelay: Duration.zero,
    attackDelay: Duration.zero,
    transitionDelay: Duration.zero,
  );
}

void main() {
  test('correct answer increases combo and damages boss', () async {
    final controller = _controller();
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();
    final correct = controller.currentQuestion!.correctAnswer;
    await controller.answer(correct);

    expect(controller.correctCount.value, 1);
    expect(controller.wrongCount.value, 0);
    expect(controller.combo.value, 1);
    expect(controller.score.value, greaterThan(0));
    expect(controller.bossHp.value, lessThan(BossBattleController.maxBossHp));
    expect(controller.playerHp.value, BossBattleController.maxPlayerHp);
  });

  test('wrong answer resets combo and damages player', () async {
    final controller = _controller();
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();
    final question = controller.currentQuestion!;
    final wrong = question.answers.firstWhere(
      (answer) => answer != question.correctAnswer,
    );
    await controller.answer(wrong);

    expect(controller.correctCount.value, 0);
    expect(controller.wrongCount.value, 1);
    expect(controller.combo.value, 0);
    expect(
        controller.playerHp.value, lessThan(BossBattleController.maxPlayerHp));
    expect(controller.bossHp.value, BossBattleController.maxBossHp);
  });

  test('duplicate answer submission only resolves once', () async {
    final controller = _controller();
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();
    final correct = controller.currentQuestion!.correctAnswer;

    await Future.wait<void>([
      controller.answer(correct),
      controller.answer(correct),
    ]);

    expect(controller.correctCount.value, 1);
  });

  test('repeated correct answers can finish with a win', () async {
    final controller = _controller();
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();

    var guard = 0;
    while (controller.phase.value != BossBattlePhase.result && guard < 10) {
      final question = controller.currentQuestion;
      if (question == null) break;
      await controller.answer(question.correctAnswer);
      guard += 1;
    }

    expect(controller.phase.value, BossBattlePhase.result);
    expect(controller.bossHp.value, 0);
    expect(controller.playerHp.value, greaterThan(0));
  });
}
