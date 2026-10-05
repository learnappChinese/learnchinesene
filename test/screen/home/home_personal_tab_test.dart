import 'dart:io';
import 'dart:ui' as ui;

import 'package:flash_learn_chinese/screen/home/widgets/home_bottom_navigation.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_personal_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(393, 852),
    const Size(440, 956),
    const Size(600, 1024),
  ]) {
    testWidgets(
        'Personal fits ${size.width.toInt()}px and all three cards open',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final previewPath = Platform.environment['PERSONAL_PREVIEW'];
      final capture = previewPath != null && size.width == 440;
      if (capture) {
        await tester.runAsync(() async {
          final font = FontLoader('PreviewArial');
          font.addFont(Future.value(ByteData.sublistView(
              await File('/System/Library/Fonts/Supplemental/Arial.ttf')
                  .readAsBytes())));
          await font.load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }

      final actions = <String>[];
      final destinations = <int>[];
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(440, 956),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: capture ? 'PreviewArial' : null),
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              extendBody: true,
              body: HomePersonalTab(
                onProfile: () => actions.add('profile'),
                onPremium: () => actions.add('premium'),
                onDictionary: () => actions.add('dictionary'),
              ),
              bottomNavigationBar: HomeBottomNavigation(
                  currentIndex: 4, onSelected: destinations.add),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Cá nhân'), findsNWidgets(2));
      expect(find.text('Cài đặt hệ thống'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
      expect(tester.getTopLeft(find.text('Cá nhân').first).dy, greaterThan(62));

      if (capture) {
        final boundary = boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.getBottomLeft(find.text('Từ điển Việt ↔ Trung')).dy,
            lessThan(tester.getTopLeft(find.text('Cá nhân').last).dy));
      }

      for (final title in [
        'Hồ sơ người dùng',
        'Nâng cấp Premium',
        'Từ điển Việt ↔ Trung',
      ]) {
        final card = find
            .ancestor(of: find.text(title), matching: find.byType(Material))
            .first;
        final arrow = find.descendant(
            of: card, matching: find.byIcon(Icons.chevron_right_rounded));
        await tester.ensureVisible(arrow);
        await tester.pumpAndSettle();
        expect(tester.getCenter(arrow).dy,
            closeTo(tester.getRect(card).center.dy, .1));
        await tester.tapAt(tester.getCenter(arrow));
      }
      expect(actions, ['profile', 'premium', 'dictionary']);
      await tester.tap(find.text('Học tập'));
      await tester.tap(find.byTooltip('Trang chủ'));
      expect(destinations, [1, 0]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Personal descriptions stay visible with larger text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final actions = <String>[];
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(440, 956),
      builder: (_, __) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 700), textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: HomePersonalTab(
              onProfile: () => actions.add('profile'),
              onPremium: () => actions.add('premium'),
              onDictionary: () => actions.add('dictionary'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    for (final description in [
      'Xem thông tin cá nhân\nvà xếp hạng',
      'Mở khóa toàn bộ tính\nnăng và bài học HSK',
      'Tra cứu từ bằng AI,\nhỗ trợ giọng nói',
    ]) {
      final finder = find.text(description);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
          paragraph.size.height,
          greaterThanOrEqualTo(
              paragraph.getMaxIntrinsicHeight(paragraph.size.width) - .1));
      await tester.tap(finder);
    }
    expect(actions, ['profile', 'premium', 'dictionary']);
    expect(tester.takeException(), isNull);
  });
}
