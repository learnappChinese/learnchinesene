import 'package:pandarin/core/widgets/learning_scaffold.dart';
import 'package:pandarin/core/widgets/learning_scene_background.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scene background reaches the screen bottom under SafeArea',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    const contentKey = Key('content');
    await tester.pumpWidget(const MaterialApp(
      home: LearningScaffold(
        title: 'Test',
        body: LearningSceneBackground(
          child: SizedBox.expand(key: contentKey),
        ),
      ),
    ));

    final background = find
        .descendant(
          of: find.byType(LearningSceneBackground),
          matching: find.byType(DecoratedBox),
        )
        .first;
    // Nền phủ tới mép dưới màn hình...
    expect(tester.getRect(background).bottom, 800);
    // ...còn nội dung vẫn nằm trên vạch home indicator.
    expect(tester.getRect(find.byKey(contentKey)).bottom, 800 - 34);
  });

  testWidgets('Scene background is actually painted below the safe area',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey,
      child: const MaterialApp(
        home: LearningScaffold(
          title: 'Test',
          body: LearningSceneBackground(
            theme: LearningSceneTheme.dragonRealm,
            showMountains: false,
            child: SizedBox.expand(),
          ),
        ),
      ),
    ));

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    late ByteData bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      image.dispose();
    });
    // Pixel nằm trong vùng home indicator (y = 790) phải là nền tối của
    // scene, không phải màu kem của Scaffold.
    final offset = (790 * 400 + 200) * 4;
    final r = bytes.getUint8(offset);
    final g = bytes.getUint8(offset + 1);
    final b = bytes.getUint8(offset + 2);
    expect(r + g + b, lessThan(200), reason: 'rgb($r,$g,$b)');
  });
}
