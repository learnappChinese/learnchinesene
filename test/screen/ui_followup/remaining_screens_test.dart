import 'package:pandarin/features/dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import 'package:pandarin/features/dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart';
import 'package:pandarin/features/dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import 'package:pandarin/features/dragon_panda/screens/game_hub/game_hub_screen.dart'
    as preview_hub;
import 'package:pandarin/features/dragon_panda/screens/home/home_screen.dart'
    as preview_home;
import 'package:pandarin/features/game_hub/game_hub_screen.dart';
import 'package:pandarin/features/game_hub/view/game_hub_view.dart';
import 'package:pandarin/features/splash/controller/splash_controller.dart';
import 'package:pandarin/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _SplashController extends SplashController {
  int starts = 0;

  @override
  Future<void> start() async {
    starts++;
  }
}

Widget _app(Widget screen, {double scale = 1}) => ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => GetMaterialApp(
        theme: ThemeData(fontFamily: 'PinyinFont'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    );

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('PinyinFont')
      ..addFont(rootBundle.load('assets/fonts/Pinyinfont_V2.ttf'));
    await font.load();
  });
  tearDown(() async => Get.reset());

  for (final size in [
    const Size(360, 640),
    const Size(440, 360),
    const Size(1000, 956)
  ]) {
    final scale = size.width == 1000 ? 1.0 : 1.5;
    testWidgets('Boss intro actions remain reachable at $size', (tester) async {
      _viewport(tester, size);
      var starts = 0;
      var backs = 0;
      await tester.pumpWidget(_app(
          BossBattleIntroScreen(
            onStartGame: () => starts++,
            onBack: () => backs++,
          ),
          scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.ensureVisible(find.text('⚔️ Bắt đầu chơi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚔️ Bắt đầu chơi'));
      expect(starts, 1);
      expect(backs, 1);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Boss defeat actions remain reachable at $size',
        (tester) async {
      _viewport(tester, size);
      final actions = <String>[];
      await tester.pumpWidget(_app(
          BossBattleDefeatScreen(
            onRetry: () => actions.add('retry'),
            onBackToHub: () => actions.add('hub'),
          ),
          scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in ['Thử lại', 'Về Game Hub']) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
      }
      expect(actions, ['retry', 'hub']);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Boss victory rewards and actions fit at $size',
        (tester) async {
      _viewport(tester, size);
      final actions = <String>[];
      await tester.pumpWidget(_app(
          BossBattleVictoryScreen(
            xpEarned: 100,
            onContinue: () => actions.add('continue'),
            onBackToHub: () => actions.add('hub'),
          ),
          scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('+100 XP'), findsOneWidget);
      for (final label in ['Tiếp tục', 'Về Game Hub']) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
      }
      expect(actions, ['continue', 'hub']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Preview home keeps tab and learning callbacks', (tester) async {
    _viewport(tester, const Size(440, 956));
    var calls = 0;
    await tester.pumpWidget(
        _app(preview_home.HomeScreen(onNavigateToGameHub: () => calls++)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Trang chủ'));
    expect(calls, 0);
    await tester.tap(find.text('Trò chơi'));
    await tester.tap(find.text('Bắt đầu học'));
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Preview hub keeps every game callback and ignores its current tab',
      (tester) async {
    _viewport(tester, const Size(440, 956));
    final actions = <String>[];
    await tester.pumpWidget(_app(preview_hub.GameHubScreen(
      onSelectBossBattle: () => actions.add('boss'),
      onSelectRadicalBuilder: () => actions.add('radicals'),
      onSelectToneNinja: () => actions.add('tone'),
      onSelectRestaurant: () => actions.add('restaurant'),
      onSelectQuickAnswer: () => actions.add('quick'),
      onBackToHome: () => actions.add('home'),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trò chơi').last);
    expect(actions, isEmpty);
    for (final label in [
      'Boss Battle',
      'Xây chữ Hán',
      'Tone Ninja',
      'Nhà hàng Trung Hoa',
      'Trả lời nhanh'
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
    }
    await tester.tap(find.byTooltip('Trang chủ'));
    expect(
        actions, ['boss', 'radicals', 'tone', 'restaurant', 'quick', 'home']);
  });

  testWidgets('App hub opens boss intro and returns without changing its menu',
      (tester) async {
    _viewport(tester, const Size(440, 956));
    await tester.pumpWidget(_app(const GameHubScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boss Battle'));
    await tester.pumpAndSettle();
    expect(find.byType(BossBattleIntroScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(GameHubView), findsOneWidget);
    expect(find.byType(BossBattleIntroScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 640), const Size(440, 360)]) {
    testWidgets(
        'Splash scrolls a long error, retries and leaves its borrowed controller alive at $size',
        (tester) async {
      _viewport(tester, size);
      final controller = Get.put<SplashController>(_SplashController());
      await tester.pumpWidget(_app(const SplashScreen(), scale: 1.5));
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      controller.error.value = List.filled(
              5, 'Không thể tải học liệu. Hãy kiểm tra kết nối Internet.')
          .join(' ');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      expect((controller as _SplashController).starts, 2);
      await tester.pumpWidget(const SizedBox());
      controller.error.value = 'Changed after disposal';
      await tester.pump();
      expect(controller.isClosed, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
