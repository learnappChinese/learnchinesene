import 'package:flash_learn_chinese/screen/boss_battle/widget/boss_battle_answer_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Boss Battle answer button accepts taps when enabled',
      (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BossBattleAnswerButton(
            answer: '火',
            index: 0,
            state: BossBattleAnswerVisualState.idle,
            onTap: () => taps += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('火'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('Boss Battle answer button ignores taps when disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BossBattleAnswerButton(
            answer: '水',
            index: 1,
            state: BossBattleAnswerVisualState.disabled,
            onTap: null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('水'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
