import 'dart:io';
import 'dart:ui' as ui;

import 'package:flash_learn_chinese/screen/game_hub/view/game_hub_view.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(393, 852),
    const Size(440, 782),
    const Size(600, 1024),
  ]) {
    testWidgets('Game menu fits ${size.width.toInt()}px and opens every game',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final actions = <String>[];
      final destinations = <int>[];
      final previewPath = Platform.environment['GAME_HUB_PREVIEW'];
      final capture = previewPath != null && size.width == 440;
      if (capture) {
        await tester.runAsync(() async {
          final loader = FontLoader('PreviewArial');
          for (final path in [
            '/System/Library/Fonts/Supplemental/Arial.ttf',
            '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
          ]) {
            loader.addFont(Future.value(
                ByteData.sublistView(await File(path).readAsBytes())));
          }
          await loader.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
        });
      }
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
              body: GameHubView(
                onBossBattle: () => actions.add('boss'),
                onRadicalBuilder: () => actions.add('radicals'),
                onToneNinja: () => actions.add('ninja'),
                onRestaurant: () => actions.add('restaurant'),
                onQuickAnswer: () => actions.add('quick'),
                onStageMap: () => actions.add('map'),
                chapterNumber: 1,
                completedMissions: 3,
                totalMissions: 7,
                stars: 2,
              ),
              bottomNavigationBar: HomeBottomNavigation(
                  currentIndex: 2, onSelected: destinations.add),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('CHAPTER 1  •  3 / 7 nhiệm vụ'), findsNWidgets(5));
      expect(tester.getTopLeft(find.text('Trò chơi').first).dy,
          greaterThanOrEqualTo(47));
      final heading = tester.getRect(find.text('Trò chơi').first);
      final journey = tester.getRect(find.byTooltip('Hành trình Ải'));
      expect(heading.top, lessThanOrEqualTo(47 + 24.w));
      expect(journey.top, greaterThanOrEqualTo(47 - 12.w));
      expect(journey.right, lessThanOrEqualTo(size.width));
      expect(heading.right, lessThan(journey.left));
      final description = tester
          .getRect(find.text('Học tiếng Trung qua những trò chơi thú vị!'));
      expect(description.overlaps(journey), isFalse);
      if (capture) {
        final boundary = boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byTooltip('Hành trình Ải'));
      for (final title in [
        'Boss Battle',
        'Xây chữ Hán',
        'Tone Ninja',
        'Nhà hàng Trung Hoa',
        'Trả lời nhanh',
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
      expect(
          actions, ['map', 'boss', 'radicals', 'ninja', 'restaurant', 'quick']);
      await tester.tap(find.byTooltip('Trang chủ'));
      await tester.tap(find.text('Học tập'));
      expect(destinations, [0, 1]);
      // Larger system text can grow the cards; every game stays reachable.
      final context = tester.element(find.byType(GameHubView));
      final largeTextMedia = MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.5));
      final menu = tester.widget<GameHubView>(find.byType(GameHubView));
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(440, 956),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          home: MediaQuery(
            data: largeTextMedia,
            child: Scaffold(body: menu),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Trả lời nhanh'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
