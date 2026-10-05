import 'package:flash_learn_chinese/screen/duolingo/widget/duo_word_connect_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Equivalent pair data preserves a selected word across rebuilds',
      (tester) async {
    var completed = 0;
    Widget view() => MaterialApp(
            home: Scaffold(
                body: DuoWordConnectWidget(
          pairs: [
            {'zh': '你好', 'vi': 'Xin chào'}
          ],
          isAnswered: false,
          onCheck: (_) => completed++,
        )));
    await tester.pumpWidget(view());
    await tester.tap(find.text('你好'));
    await tester.pump();
    await tester.pumpWidget(view());
    await tester.tap(find.text('Xin chào'));
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Changed pair data clears matching state and tolerates delayed errors',
      (tester) async {
    var completed = 0;
    Widget view(List<Map<String, String>> pairs) => MaterialApp(
            home: Scaffold(
                body: DuoWordConnectWidget(
          pairs: pairs,
          isAnswered: false,
          onCheck: (_) => completed++,
        )));
    await tester.pumpWidget(view([
      {'zh': '你好', 'vi': 'Xin chào'},
      {'zh': '谢谢', 'vi': 'Cảm ơn'},
    ]));
    await tester.tap(find.text('你好'));
    await tester.tap(find.text('Cảm ơn'));
    await tester.pumpWidget(view([
      {'zh': '再见', 'vi': 'Tạm biệt'}
    ]));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('再见'));
    await tester.tap(find.text('Tạm biệt'));
    expect(completed, 1);
    expect(find.text('你好'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
