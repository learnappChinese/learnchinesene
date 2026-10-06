import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/screen/boss_battle/controller/boss_battle_controller.dart';
import 'package:flash_learn_chinese/screen/boss_battle/data/boss_battle_repository.dart';
import 'package:flash_learn_chinese/screen/boss_battle/domain/boss_battle_question_generator.dart';
import 'package:flash_learn_chinese/screen/boss_battle/model/boss_battle_question.dart';
import 'package:flash_learn_chinese/screen/boss_battle/model/boss_battle_stage.dart';

class _FakeProgressSink implements BossBattleProgressSink {
  int calls = 0;
  int? stageId;
  int? score;
  int? stars;
  int? bestCombo;
  bool? won;

  @override
  Future<void> recordResult({
    required int stageId,
    required int score,
    required int stars,
    required int bestCombo,
    required bool won,
  }) async {
    calls += 1;
    this.stageId = stageId;
    this.score = score;
    this.stars = stars;
    this.bestCombo = bestCombo;
    this.won = won;
  }
}

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

BossBattleController _controller({
  BossBattleStage? stage,
  BossBattleProgressSink? progressSink,
}) {
  return BossBattleController(
    source: _FakeQuestionSource(_questions()),
    progressSink: progressSink,
    generator: BossBattleQuestionGenerator(),
    stage: stage,
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
    expect(controller.playerHp.value, lessThan(BossBattleController.maxPlayerHp));
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


  test('boss win persists stage score stars and combo once', () async {
    final sink = _FakeProgressSink();
    final controller = BossBattleController(
      source: _FakeQuestionSource(_questions()),
      progressSink: sink,
      stage: _stage,
      generator: BossBattleQuestionGenerator(),
      resolveDelay: Duration.zero,
      attackDelay: Duration.zero,
      transitionDelay: Duration.zero,
    );
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();

    var guard = 0;
    while (controller.phase.value != BossBattlePhase.result && guard < 12) {
      final question = controller.currentQuestion;
      if (question == null) break;
      await controller.answer(question.correctAnswer);
      guard += 1;
    }

    expect(sink.calls, 1);
    expect(sink.stageId, _stage.id);
    expect(sink.won, isTrue);
    expect(sink.score, greaterThan(0));
    expect(sink.stars, inInclusiveRange(1, 3));
    expect(sink.bestCombo, greaterThan(0));
  });

  test('boss loss persists attempt without victory stars', () async {
    final sink = _FakeProgressSink();
    const fragileStage = BossBattleStage(
      id: 78,
      unitId: 'sec_1_unit_2',
      stageOrder: 2,
      sectionNumber: 1,
      unitNumber: 2,
      title: 'Boss Unit 2',
      questionCount: 12,
      difficulty: 3,
      bossName: 'Rồng Lửa',
      bossHp: 100,
      playerHp: 20,
      themeCode: 'sunset',
    );
    final controller = BossBattleController(
      source: _FakeQuestionSource(_questions()),
      progressSink: sink,
      stage: fragileStage,
      generator: BossBattleQuestionGenerator(),
      resolveDelay: Duration.zero,
      attackDelay: Duration.zero,
      transitionDelay: Duration.zero,
    );
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();
    final question = controller.currentQuestion!;
    final wrong = question.answers.firstWhere(
      (answer) => answer != question.correctAnswer,
    );
    await controller.answer(wrong);

    expect(controller.phase.value, BossBattlePhase.result);
    expect(sink.calls, 1);
    expect(sink.stageId, fragileStage.id);
    expect(sink.won, isFalse);
    expect(sink.stars, 0);
  });


  test('stage victory persists boss progress exactly once', () async {
    final sink = _FakeProgressSink();
    const stage = BossBattleStage(
      id: 77,
      unitId: 'sec_1_unit_1',
      stageOrder: 1,
      sectionNumber: 1,
      unitNumber: 1,
      title: 'Boss Unit 1',
      questionCount: 4,
      difficulty: 1,
      bossName: 'Rồng Lửa',
      bossHp: 20,
      playerHp: 100,
      themeCode: 'sunset',
    );
    final controller = _controller(
      stage: stage,
      progressSink: sink,
    );
    addTearDown(controller.onClose);

    await controller.startBattle();
    controller.beginBattle();
    await controller.answer(controller.currentQuestion!.correctAnswer);

    expect(controller.phase.value, BossBattlePhase.result);
    expect(sink.calls, 1);
    expect(sink.stageId, stage.id);
    expect(sink.won, isTrue);
    expect(sink.score, greaterThan(0));
    expect(sink.stars, inInclusiveRange(1, 3));
    expect(sink.bestCombo, 1);
  });
}
