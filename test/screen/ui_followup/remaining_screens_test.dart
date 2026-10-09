import 'dart:async';

import 'package:flash_learn_chinese/core/services/iap_service.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/game_hub/game_hub_screen.dart'
    as preview_hub;
import 'package:flash_learn_chinese/screen/dragon_panda/screens/home/home_screen.dart'
    as preview_home;
import 'package:flash_learn_chinese/screen/game_hub/game_hub_screen.dart';
import 'package:flash_learn_chinese/screen/game_hub/view/game_hub_view.dart';
import 'package:flash_learn_chinese/screen/splash/controller/splash_controller.dart';
import 'package:flash_learn_chinese/screen/splash/splash_screen.dart';
import 'package:flash_learn_chinese/screen/subscription/controller/subscription_controller.dart';
import 'package:flash_learn_chinese/screen/subscription/page/subscription_page.dart';
import 'package:flash_learn_chinese/screen/subscription/widgets/package_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SplashController extends SplashController {
  int starts = 0;

  @override
  Future<void> start() async {
    starts++;
  }
}

class _IapService implements IAPService {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  final bought = <String>[];
  final storeProducts = [
    ProductDetails(
        id: 'premium_package',
        title: 'Premium',
        description: '',
        price: '300.000 đ',
        rawPrice: 300000,
        currencyCode: 'VND'),
    ProductDetails(
        id: 'standard_package',
        title: 'Standard',
        description: '',
        price: '70.000 đ',
        rawPrice: 70000,
        currencyCode: 'VND'),
  ];

  @override
  Future<void> initConnection() async {}

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> ids) async =>
      storeProducts;

  @override
  Future<void> buyProduct(ProductDetails product) async =>
      bought.add(product.id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  testWidgets(
      'Subscription keeps store prices, selection, blocking overlay and borrowed controller',
      (tester) async {
    _viewport(tester, const Size(440, 956));
    SharedPreferences.setMockInitialValues({});
    final service = _IapService();
    addTearDown(service.updates.close);
    final controller = Get.put(SubscriptionController(service));
    await tester.pumpWidget(_app(const SubscriptionPage()));
    await tester.pumpAndSettle();
    expect(find.text('300.000 đ'), findsOneWidget);
    expect(find.text('70.000 đ'), findsOneWidget);
    await tester.ensureVisible(find.text('Gói Tiêu Chuẩn'));
    await tester.tap(find.text('Gói Tiêu Chuẩn'));
    await tester.pumpAndSettle();
    expect(controller.selectedPackageIndex.value, 0);
    await tester.ensureVisible(find.text('Đăng ký ngay'));
    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pump();
    expect(service.bought, ['standard_package']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Gói Cao Cấp'), warnIfMissed: false);
    expect(controller.selectedPackageIndex.value, 0);
    controller.status.value = SubscriptionStatus.loadedProducts;
    controller.activeProductId.value = 'standard_package';
    controller.purchaseDate.value = DateTime.now();
    await tester.pumpAndSettle();
    expect(find.text('Gói đang sử dụng'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.status.value = SubscriptionStatus.purchaseSuccess;
    await tester.pump();
    expect(controller.isClosed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Active subscription card supports long text and enlarged fonts',
      (tester) async {
    _viewport(tester, const Size(360, 640));
    await tester.pumpWidget(_app(
        Scaffold(
            body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PackageCardWidget(
              index: 1,
              title: 'Gói Cao Cấp',
              price: '299.000 đ',
              icon: Icons.workspace_premium_rounded,
              features: const ['Học từ vựng và hội thoại'],
              isSelected: true,
              isActive: true,
              remainingDays: 365,
              onTap: () {},
              onSubscribeTap: () {}),
        )),
        scale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Đang dùng (365 ngày)'), findsOneWidget);
  });
}
