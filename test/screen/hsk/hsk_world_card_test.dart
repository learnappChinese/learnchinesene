import 'package:flash_learn_chinese/core/models/hsk_level.dart';
import 'package:flash_learn_chinese/screen/hsk/widget/hsk_level_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('world card fits ${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 218,
              child: HskLevelCard(
                level: const HskLevel(id: 1, title: 'HSK 1', order: 1),
                index: 0,
                count: 20,
                progress: .4,
                isUnlocked: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bamboo Village'), findsOneWidget);
      expect(find.text('Làng Trúc Xanh'), findsOneWidget);
      expect(find.text('8/20 chương hoàn thành'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      await tester.tap(find.byType(HskLevelCard));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('locked world exposes lock state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 218,
          child: HskLevelCard(
            level: const HskLevel(id: 6, title: 'HSK 6', order: 6),
            index: 5,
            count: 30,
            progress: 0,
            isUnlocked: false,
            onTap: () {},
          ),
        ),
      ),
    ));
    expect(find.text('Dragon Realm'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });
}
