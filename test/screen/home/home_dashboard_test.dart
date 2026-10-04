import 'package:flash_learn_chinese/screen/home/controller/home_controller.dart';
import 'package:flash_learn_chinese/screen/home/home_screen.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_bottom_navigation.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _HomeController extends HomeController {
  @override
  Future<void> refreshStats() async {
    stats.value = {'streak': 9, 'learned': 24, 'correct': 10};
  }
}

Widget _screenUtilApp(Widget home) => ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => GetMaterialApp(home: home),
    );

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(393, 852),
    const Size(600, 1024)
  ]) {
    testWidgets('Dashboard fits ${size.width.toInt()}px and all actions work',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      await tester.pumpWidget(_screenUtilApp(Scaffold(
          body: SafeArea(
              child: HomeDashboard(
        onStartLearning: () => actions.add('learning'),
        onGrammar: () => actions.add('grammar'),
        onListening: () => actions.add('listening'),
        onSpeaking: () => actions.add('speaking'),
        onChallenge: () => actions.add('challenge'),
        onProgress: () => actions.add('progress'),
      )))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          find.image(
              const AssetImage('assets/images/backgrounds/home_garden.png')),
          findsOneWidget);
      await tester.tap(find.text('Bắt đầu học'));
      await tester.tap(find.text('Ngày liên tiếp'));
      for (final entry in {
        'Tiếp tục': 'learning',
        'Từ vựng': 'learning',
        'Ngữ pháp': 'grammar',
        'Luyện nghe': 'listening',
        'Luyện nói': 'speaking',
        'Hoàn thành 10 câu hỏi': 'challenge'
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        expect(actions.last, entry.value);
      }
      expect(
          actions,
          containsAll([
            'learning',
            'grammar',
            'listening',
            'speaking',
            'challenge',
            'progress'
          ]));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Bottom bar has one central home button without a text label',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selected = <int>[];
    await tester.pumpWidget(_screenUtilApp(Scaffold(
        bottomNavigationBar:
            HomeBottomNavigation(currentIndex: 0, onSelected: selected.add))));
    expect(find.text('Trang chủ'), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    await tester.tap(find.text('Học tập'));
    await tester.tap(find.text('Trò chơi'));
    await tester.tap(find.byTooltip('Trang chủ'));
    await tester.tap(find.text('Tiến độ'));
    await tester.tap(find.text('Cá nhân'));
    expect(selected, [1, 2, 0, 3, 4]);
  });

  testWidgets(
      'App home keeps reactive stats and switches learning and progress tabs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    Get.put<HomeController>(_HomeController());
    addTearDown(Get.reset);
    await tester.pumpWidget(_screenUtilApp(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('24'), findsOneWidget);
    expect(find.text('256'), findsOneWidget);
    expect(tester.getTopLeft(find.text('你好! 👋')).dy, greaterThanOrEqualTo(62));
    expect(
        find.image(
            const AssetImage('assets/images/backgrounds/home_garden.png')),
        findsOneWidget);
    await tester.tap(find.text('Học tập'));
    await tester.pumpAndSettle();
    expect(find.text('Học tập chuyên sâu'), findsOneWidget);
    await tester.tap(find.text('Tiến độ'));
    await tester.pumpAndSettle();
    expect(find.text('Tiến độ & Đánh giá'), findsOneWidget);
    await tester.tap(find.byTooltip('Trang chủ'));
    await tester.pumpAndSettle();
    Get.find<HomeController>().stats['learned'] = 25;
    await tester.pump();
    expect(find.text('25'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Xem tất cả').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Học tập chuyên sâu'), findsOneWidget);
    await tester.tap(find.text('Trò chơi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(Get.find<HomeController>().currentIndex.value, 2);
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(Get.find<HomeController>().currentIndex.value, 4);
    expect(find.text('Hồ sơ người dùng'), findsOneWidget);
    expect(find.text('Nâng cấp Premium'), findsOneWidget);
    expect(find.text('Từ điển Việt ↔ Trung'), findsOneWidget);
    expect(find.text('Cài đặt hệ thống'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Trang chủ'));
    await tester.pumpAndSettle();
    expect(Get.find<HomeController>().currentIndex.value, 0);
    expect(tester.takeException(), isNull);
  });
}
