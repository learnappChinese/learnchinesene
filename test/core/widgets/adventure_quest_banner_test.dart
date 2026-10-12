import 'package:flash_learn_chinese/core/widgets/adventure_quest_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 440.0]) {
    testWidgets(
      'quest banner is responsive and actionable at ${width.toInt()}px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 700);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: AdventureQuestBanner(
                  eyebrow: 'Nhiệm vụ tiếp theo',
                  title: 'Khám phá làng tre',
                  description:
                      'Cùng Panda hoàn thành bài học đang dở bằng dữ liệu hành trình thật.',
                  progress: .45,
                  progressLabel: '45%',
                  statusLabel: 'Đang học',
                  actionLabel: 'Tiếp tục',
                  onAction: () => tapped = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Khám phá làng tre'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        await tester.tap(find.text('Tiếp tục'));
        expect(tapped, isTrue);
      },
    );
  }

  testWidgets('quest banner exposes a meaningful semantics label',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdventureQuestBanner(
            eyebrow: 'Panda dẫn đường',
            title: 'Bài học hôm nay',
            description: 'Luyện chữ Hán và phát âm.',
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(AdventureQuestBanner));
    expect(node.label, contains('Panda dẫn đường'));
    expect(node.label, contains('Bài học hôm nay'));
    semantics.dispose();
  });
}
