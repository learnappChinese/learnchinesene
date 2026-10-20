import 'dart:io';
import 'dart:ui' as ui;

import 'package:pandarin/features/home/widgets/home_bottom_navigation.dart';
import 'package:pandarin/core/config/feature_flags.dart';
import 'package:pandarin/features/home/widgets/home_progress_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(393, 852),
    const Size(440, 874),
    const Size(600, 1024),
  ]) {
    testWidgets(
        'Progress fits ${size.width.toInt()}px and all three cards open',
        (tester) async {
      FeatureFlags.enableAi = true;
      addTearDown(() => FeatureFlags.enableAi = false);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final previewPath = Platform.environment['PROGRESS_PREVIEW'];
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
              body: HomeProgressTab(
                onStats: () => actions.add('stats'),
                onExam: () => actions.add('exam'),
                onHistory: () => actions.add('history'),
              ),
              bottomNavigationBar: HomeBottomNavigation(
                  currentIndex: 3, onSelected: destinations.add),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Tiến độ'), findsWidgets);
      expect(tester.getTopLeft(find.textContaining('Tiến độ').first).dy,
          greaterThan(62));

      if (capture) {
        final boundary = boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(
            tester.getBottomLeft(find.text('Lịch Sử Dịch & Hội Thoại')).dy,
            lessThan(
                tester.getTopLeft(find.textContaining('Tiến độ').first).dy));
      }

      for (final title in [
        'Sổ Lịch Sử Kinh Nghiệm (XP)',
        'Lịch Sử Dịch & Hội Thoại',
        'Thi Thử HSK Với Giáo Viên AI',
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
      expect(actions, ['stats', 'history', 'exam']);
      await tester.tap(find.text('Học tập'));
      await tester.tap(find.byTooltip('Trang chủ'));
      expect(destinations, [1, 0]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Progress descriptions stay visible with larger text',
      (tester) async {
    FeatureFlags.enableAi = true;
      addTearDown(() => FeatureFlags.enableAi = false);
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
            body: HomeProgressTab(
              onStats: () => actions.add('stats'),
              onExam: () => actions.add('exam'),
              onHistory: () => actions.add('history'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    for (final description in [
      'Xem toàn bộ giao dịch XP đã ghi nhận vào hệ thống',
      'Tra cứu các bản dịch và bài hội thoại đã thực hiện',
      'Làm đề kiểm tra năng lực HSK 1-6 chuẩn hóa',
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
    expect(actions, ['stats', 'history', 'exam']);
    expect(tester.takeException(), isNull);
  });
}
