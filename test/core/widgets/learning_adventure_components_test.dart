import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/theme/learning_theme.dart';
import 'package:flash_learn_chinese/core/widgets/learning_scaffold.dart';
import 'package:flash_learn_chinese/core/widgets/mission_complete_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LearningResult result({required bool passed}) => LearningResult(
      activityType: 'listening',
      sourceId: 'level-1',
      attemptId: 'attempt-1',
      passed: passed,
      stars: passed ? 2 : 0,
      score: passed ? 92 : 62,
      accuracy: passed ? .92 : .62,
      correctCount: passed ? 9 : 6,
      wrongCount: passed ? 1 : 4,
      xpEarned: passed ? 42 : 4,
      baseXp: passed ? 30 : 0,
      bonusXp: passed ? 12 : 4,
      newTotalXp: 142,
      currentStreak: 3,
      masteryBefore: .4,
      masteryAfter: passed ? .45 : .4,
      bestCombo: 7,
      firstClear: passed,
      perfect: false,
      unlockedNext: passed,
      nextNodeId: passed ? 'level-2' : null,
      reason: passed ? 'passed' : 'accuracy_below_threshold',
    );

void main() {
  testWidgets('LearningScaffold keeps the learning system chrome',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningScaffold(
          title: 'Nhiệm vụ',
          body: SizedBox.expand(),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(appBar.backgroundColor, LearningColors.background);
    expect(appBar.elevation, 0);
    expect(scaffold.backgroundColor, LearningColors.background);
  });

  for (final passed in [true, false]) {
    testWidgets('mission result ${passed ? 'pass' : 'fail'} fits 320px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 760);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var primaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissionCompleteOverlay(
              result: result(passed: passed),
              onNextMission: () => primaryTapped = true,
              onBackToMap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(passed ? 'HOÀN THÀNH NHIỆM VỤ' : 'CHƯA ĐẠT'),
        findsOneWidget,
      );
      expect(find.text(passed ? 'NHIỆM VỤ TIẾP THEO' : 'THỬ LẠI'),
          findsOneWidget);
      await tester.tap(
        find.text(passed ? 'NHIỆM VỤ TIẾP THEO' : 'THỬ LẠI'),
      );
      expect(primaryTapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
