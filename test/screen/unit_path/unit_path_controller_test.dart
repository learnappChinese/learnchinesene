import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/screen/unit_path/controller/unit_path_controller.dart';
import 'package:flash_learn_chinese/screen/unit_path/data/unit_learning_repository.dart';
import 'package:flash_learn_chinese/screen/unit_path/model/unit_learning_node.dart';

class _FakeUnitLearningSource implements UnitLearningSource {
  _FakeUnitLearningSource(this.nodes);

  final List<UnitLearningNode> nodes;

  @override
  Future<List<UnitLearningNode>> loadUnitPath(String unitId) async => nodes;
}

UnitLearningNode _node({
  required int order,
  bool completed = false,
  bool inProgress = false,
  bool boss = false,
  bool unlocked = false,
}) {
  return UnitLearningNode(
    nodeType: boss ? 'boss' : 'learning',
    nodeOrder: order,
    unitId: 'sec_1_unit_1',
    unitTitle: 'Gọi tên món ăn và đồ uống',
    sectionNumber: 1,
    unitNumber: 1,
    levelId: boss ? null : 'level_1',
    levelIndex: boss ? null : 0,
    gameId: boss ? null : order,
    gameCode: boss ? 'boss_battle' : 'game_$order',
    gameName: boss ? 'Rồng Lửa' : 'Nhiệm vụ $order',
    gameDescription: 'Mô tả',
    gameIcon: boss ? '🐉' : '🎯',
    challengeCount: 10,
    attempts: 0,
    bestScore: 0,
    stars: completed ? 3 : 0,
    rawUnlocked: unlocked,
    completed: completed,
    inProgress: inProgress,
    currentIndex: inProgress ? 3 : 0,
    bossStageId: boss ? 99 : null,
    bossName: boss ? 'Rồng Lửa' : null,
    bossHp: boss ? 100 : null,
    playerHp: boss ? 100 : null,
    difficulty: boss ? 2 : null,
  );
}

void main() {
  test('first mission is available and later missions remain locked', () async {
    final controller = UnitPathController(
      unitId: 'sec_1_unit_1',
      repository: _FakeUnitLearningSource([
        _node(order: 1, unlocked: true),
        _node(order: 2),
        _node(order: 3, boss: true),
      ]),
    );

    await controller.load();

    expect(controller.nodes[0].state, UnitLearningNodeState.available);
    expect(controller.nodes[1].state, UnitLearningNodeState.locked);
    expect(controller.nodes[2].state, UnitLearningNodeState.locked);
  });

  test('server gate keeps the first mission locked for a locked Unit',
      () async {
    final controller = UnitPathController(
      unitId: 'sec_2_unit_1',
      repository: _FakeUnitLearningSource([
        _node(order: 1),
        _node(order: 2),
        _node(order: 3, boss: true),
      ]),
    );

    await controller.load();

    expect(controller.nodes[0].state, UnitLearningNodeState.locked);
    expect(controller.nodes[1].state, UnitLearningNodeState.locked);
    expect(controller.nodes[2].state, UnitLearningNodeState.locked);
  });

  test('active cloud session is shown as in progress', () async {
    final controller = UnitPathController(
      unitId: 'sec_1_unit_1',
      repository: _FakeUnitLearningSource([
        _node(order: 1, completed: true),
        _node(order: 2, inProgress: true),
        _node(order: 3, boss: true),
      ]),
    );

    await controller.load();

    expect(controller.nodes[0].state, UnitLearningNodeState.completed);
    expect(controller.nodes[1].state, UnitLearningNodeState.inProgress);
    expect(controller.nodes[2].state, UnitLearningNodeState.locked);
  });

  test('boss unlocks only after all learning missions complete', () async {
    final controller = UnitPathController(
      unitId: 'sec_1_unit_1',
      repository: _FakeUnitLearningSource([
        _node(order: 1, completed: true),
        _node(order: 2, completed: true),
        _node(order: 3, boss: true),
      ]),
    );

    await controller.load();

    expect(controller.nodes[2].state, UnitLearningNodeState.available);
    expect(controller.completedMissionCount, 2);
    expect(controller.missionCount, 2);
  });

  test('returns the next learning node for completion pipeline', () async {
    final first = _node(order: 1, completed: true);
    final second = _node(order: 2);

    final controller = UnitPathController(
      unitId: 'sec_1_unit_1',
      repository: _FakeUnitLearningSource([
        first,
        second,
        _node(order: 3, boss: true),
      ]),
    );

    await controller.load();

    final next = controller.nextLearningNodeAfter(controller.nodes.first);
    expect(next?.gameId, second.gameId);
    expect(next?.levelId, second.levelId);
  });
}
