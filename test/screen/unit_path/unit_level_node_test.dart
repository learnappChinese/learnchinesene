import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/screen/unit_path/model/unit_learning_node.dart';
import 'package:flash_learn_chinese/screen/unit_path/widget/unit_level_node.dart';

UnitLearningNode _node(UnitLearningNodeState state) {
  return UnitLearningNode(
    nodeType: 'learning',
    nodeOrder: 1,
    unitId: 'sec_1_unit_1',
    unitTitle: 'Gọi tên món ăn và đồ uống',
    sectionNumber: 1,
    unitNumber: 1,
    levelId: 'level_1',
    levelIndex: 0,
    gameId: 1,
    gameCode: 'learn_words',
    gameName: 'Học từ mới',
    gameDescription: 'Học và ghi nhớ từ vựng trong Chapter này',
    gameIcon: '🧠',
    challengeCount: 10,
    attempts: 2,
    bestScore: 90,
    stars: state == UnitLearningNodeState.completed ? 3 : 0,
    rawUnlocked: state != UnitLearningNodeState.locked,
    completed: state == UnitLearningNodeState.completed,
    inProgress: state == UnitLearningNodeState.inProgress,
    currentIndex: state == UnitLearningNodeState.inProgress ? 4 : 0,
    bossStageId: null,
    bossName: null,
    bossHp: null,
    playerHp: null,
    difficulty: null,
    state: state,
  );
}

Future<void> _pumpNode(
  WidgetTester tester, {
  required double width,
  required UnitLearningNodeState state,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 820));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: UnitLevelNode(
            node: _node(state),
            alignLeft: true,
            onTap: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TestWidgetsFlutterBinding.instance.setSurfaceSize(null);
  });

  testWidgets('mission node renders without overflow at 320 px',
      (tester) async {
    await _pumpNode(
      tester,
      width: 320,
      state: UnitLearningNodeState.inProgress,
    );

    expect(find.text('Học từ mới'), findsOneWidget);
    expect(find.text('Đang chơi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mission node renders completed state at 440 px',
      (tester) async {
    await _pumpNode(
      tester,
      width: 440,
      state: UnitLearningNodeState.completed,
    );

    expect(find.text('Học từ mới'), findsOneWidget);
    expect(find.text('Đã thắng'), findsOneWidget);
    expect(find.text('★★★'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked node communicates lock state', (tester) async {
    await _pumpNode(
      tester,
      width: 320,
      state: UnitLearningNodeState.locked,
    );

    expect(find.text('Khóa'), findsOneWidget);
    expect(find.text('🔒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
