import 'package:flash_learn_chinese/screen/unit_path/model/unit_learning_node.dart';
import 'package:flash_learn_chinese/screen/unit_path/widget/unit_boss_node.dart';
import 'package:flash_learn_chinese/screen/unit_path/widget/unit_level_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

UnitLearningNode _node({
  required UnitLearningNodeState state,
  bool boss = false,
}) {
  return UnitLearningNode(
    nodeType: boss ? 'boss' : 'learning',
    nodeOrder: boss ? 8 : 1,
    unitId: 'sec_1_unit_1',
    unitTitle: 'Gọi tên món ăn và đồ uống',
    sectionNumber: 1,
    unitNumber: 1,
    levelId: boss ? null : 'level_1',
    levelIndex: boss ? null : 0,
    gameId: boss ? null : 1,
    gameCode: boss ? 'boss_battle' : 'learn_words',
    gameName: boss ? 'Rồng Lửa' : 'Học từ mới',
    gameDescription: boss
        ? 'Đánh bại Rồng Lửa để hoàn thành chương'
        : 'Khám phá từ mới của Unit',
    gameIcon: boss ? '🐉' : '🧠',
    challengeCount: 10,
    attempts: 1,
    bestScore: 80,
    stars: state == UnitLearningNodeState.completed ? 3 : 0,
    rawUnlocked: state != UnitLearningNodeState.locked,
    completed: state == UnitLearningNodeState.completed,
    inProgress: state == UnitLearningNodeState.inProgress,
    currentIndex: state == UnitLearningNodeState.inProgress ? 3 : 0,
    bossStageId: boss ? 1 : null,
    bossName: boss ? 'Rồng Lửa' : null,
    bossHp: boss ? 100 : null,
    playerHp: boss ? 100 : null,
    difficulty: boss ? 2 : null,
    state: state,
  );
}

Future<void> _setSize(
  WidgetTester tester,
  Size size,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  for (final width in <double>[320, 440]) {
    testWidgets('available mission fits at ${width.toInt()} px', (tester) async {
      await _setSize(tester, Size(width, 800));

      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitLevelNode(
              node: _node(state: UnitLearningNodeState.available),
              alignLeft: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Học từ mới'), findsOneWidget);
      expect(find.text('Chơi ngay'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Học từ mới'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('in-progress mission fits at ${width.toInt()} px',
        (tester) async {
      await _setSize(tester, Size(width, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitLevelNode(
              node: _node(state: UnitLearningNodeState.inProgress),
              alignLeft: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Đang chơi'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('locked boss renders as a gated final encounter', (tester) async {
    await _setSize(tester, const Size(320, 800));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnitBossNode(
            node: _node(
              state: UnitLearningNodeState.locked,
              boss: true,
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Rồng Lửa'), findsOneWidget);
    expect(
      find.text('Hoàn thành các nhiệm vụ để mở cổng Boss.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
