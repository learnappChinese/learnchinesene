import 'package:flash_learn_chinese/core/models/word.dart';
import 'package:flash_learn_chinese/core/theme/app_colors.dart';
import 'package:flash_learn_chinese/core/theme/app_theme.dart';
import 'package:flash_learn_chinese/core/widgets/learning_scaffold.dart';
import 'package:flash_learn_chinese/core/widgets/locked_mission_sheet.dart';
import 'package:flash_learn_chinese/core/widgets/panda_companion.dart';
import 'package:flash_learn_chinese/screen/flashcards/controller/flashcards_controller.dart';
import 'package:flash_learn_chinese/screen/flashcards/flashcards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeFlashcardsController extends FlashcardsController {
  _FakeFlashcardsController(List<Word> mockWords) : super() {
    deck.assignAll(mockWords);
  }

  @override
  Future<void> loadDeck(int level) async {
    // Keep initialized mockWords
  }

  @override
  Future<void> rate(Word word, String rating) async {}
}

const _kMockWords = [
  Word(
    id: 1,
    chinese: '你好',
    pinyin: 'nǐ hǎo',
    vietnamese: 'Xin chào',
    english: 'Hello',
    ttsUrl: '',
    hskLevelId: 1,
    sectionTitle: 'Chào hỏi',
    groupSubtitle: 'Cơ bản',
  ),
  Word(
    id: 2,
    chinese: '谢谢',
    pinyin: 'xièxie',
    vietnamese: 'Cảm ơn',
    english: 'Thank you',
    ttsUrl: '',
    hskLevelId: 1,
    sectionTitle: 'Chào hỏi',
    groupSubtitle: 'Cơ bản',
  ),
];

Widget _buildTestApp({
  required Widget child,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  return ScreenUtilInit(
    designSize: const Size(440, 956),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      theme: theme ?? AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: child,
        ),
      ),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async => Get.reset());

  const testViewports = <String, Size>{
    'Compact (320x568)': Size(320, 568),
    'Small (360x640)': Size(360, 640),
    'Standard (393x852)': Size(393, 852),
    'Large (440x956)': Size(440, 956),
  };

  group('PR 10 Design Tokens & Theme Specification', () {
    test('AppColors provides canonical Chinese Fantasy tokens', () {
      expect(AppColors.jade, const Color(0xFF0F766E));
      expect(AppColors.jadeDark, const Color(0xFF064E3B));
      expect(AppColors.imperialGold, const Color(0xFFF59E0B));
      expect(AppColors.crimson, const Color(0xFFDC2626));
      expect(AppColors.parchment, const Color(0xFFFFFBEB));
      expect(AppColors.cream, const Color(0xFFFFF8ED));
      expect(AppColors.textDark, const Color(0xFF1E1E24));
      expect(AppColors.textMuted, const Color(0xFF64748B));
      expect(AppColors.ink, const Color(0xFF241F20));
      expect(AppColors.jadeGradient.colors.length, 2);
      expect(AppColors.orangeGoldGradient.colors.length, 2);
      expect(AppColors.crimsonGradient.colors.length, 2);
    });

    test('AppTheme light and dark enforce transparent status bars', () {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;

      expect(lightTheme.appBarTheme.backgroundColor, Colors.transparent);
      expect(
        lightTheme.appBarTheme.systemOverlayStyle?.statusBarColor,
        Colors.transparent,
      );
      expect(
        lightTheme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.dark,
      );

      expect(darkTheme.appBarTheme.backgroundColor, Colors.transparent);
      expect(
        darkTheme.appBarTheme.systemOverlayStyle?.statusBarColor,
        Colors.transparent,
      );
      expect(
        darkTheme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );
    });
  });

  group('PR 10 Actionable Locked Stage & Mission Sheet UX', () {
    testWidgets(
        'displays default dismiss button when no action callback is given',
        (tester) async {
      _setViewport(tester, const Size(393, 852));

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showLockedMissionSheet(
                  context,
                  title: 'Ải 4 đang khoá',
                  message: 'Bạn cần hoàn thành các ải trước để mở.',
                ),
                child: const Text('Mở Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Ải 4 đang khoá'), findsOneWidget);
      expect(
        find.text('Bạn cần hoàn thành các ải trước để mở.'),
        findsOneWidget,
      );
      expect(find.text('ĐÃ HIỂU'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('ĐÃ HIỂU'));
      await tester.pumpAndSettle();

      expect(find.text('Ải 4 đang khoá'), findsNothing);
    });

    testWidgets(
        'displays actionable button and triggers onViewRequired callback',
        (tester) async {
      _setViewport(tester, const Size(393, 852));
      var actionTriggered = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showLockedMissionSheet(
                  context,
                  title: 'Ải 5 đang khoá',
                  message: 'Cần vượt qua Ải 4 trước.',
                  requiredTitle: 'Cần làm: Ải 4 - Luyện tập',
                  actionLabel: 'LÀM ẢI TRƯỚC',
                  actionIcon: Icons.play_arrow_rounded,
                  onViewRequired: () {
                    actionTriggered = true;
                  },
                ),
                child: const Text('Mở Sheet Khóa'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Sheet Khóa'));
      await tester.pumpAndSettle();

      expect(find.text('Ải 5 đang khoá'), findsOneWidget);
      expect(find.text('Cần làm: Ải 4 - Luyện tập'), findsOneWidget);
      expect(find.text('LÀM ẢI TRƯỚC'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.text('LÀM ẢI TRƯỚC'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
      expect(find.text('Ải 5 đang khoá'), findsNothing);
    });
  });

  group('PR 10 Accessibility & Reduced Motion UX', () {
    testWidgets('PandaCompanion renders cleanly with disableAnimations: true',
        (tester) async {
      _setViewport(tester, const Size(393, 852));

      await tester.pumpWidget(
        _buildTestApp(
          disableAnimations: true,
          child: const Scaffold(
            body: Center(
              child: PandaCompanion(
                mood: PandaMood.ninja,
                speechText: 'Hãy kiên trì luyện tập!',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(PandaCompanion), findsOneWidget);
      expect(find.text('Hãy kiên trì luyện tập!'), findsOneWidget);
    });

    testWidgets(
        'FlashcardsScreen flips immediately without animation regression',
        (tester) async {
      _setViewport(tester, const Size(393, 852));
      final controller = _FakeFlashcardsController(_kMockWords);

      await tester.pumpWidget(
        _buildTestApp(
          disableAnimations: true,
          child: FlashcardsScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('你好'), findsOneWidget);

      // Tap card to flip
      await tester.tap(find.text('你好'));
      await tester.pumpAndSettle();

      // Card is flipped: shows meaning 'Xin chào'
      expect(find.text('Xin chào'), findsOneWidget);
    });
  });

  group('PR 10 Multi-Resolution Responsive Polish', () {
    for (final entry in testViewports.entries) {
      testWidgets('LearningScaffold renders without overflow on ${entry.key}',
          (tester) async {
        _setViewport(tester, entry.value);

        await tester.pumpWidget(
          _buildTestApp(
            child: LearningScaffold(
              title: 'Càn Khôn Bí Kíp',
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardCreamBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'Thẻ bài ngọc bích',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const PandaCompanion(
                    mood: PandaMood.happy,
                    speechText: 'Tiến độ rất xuất sắc!',
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Càn Khôn Bí Kíp'), findsOneWidget);
        expect(find.text('Thẻ bài ngọc bích'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('LockedMissionSheet does not overflow on ${entry.key}',
          (tester) async {
        _setViewport(tester, entry.value);

        await tester.pumpWidget(
          _buildTestApp(
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLockedMissionSheet(
                    context,
                    title: 'Ải 10 - Đại Ma Vương',
                    message:
                        'Bạn chưa hoàn thành các ải tiên quyết để mở phong ấn này.',
                    requiredTitle: 'Cần làm: Hoàn thành Ải 9 - Lôi Đình',
                    actionLabel: 'CHUYỂN ĐẾN ẢI TIÊN QUYẾT',
                    onViewRequired: () {},
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Ải 10 - Đại Ma Vương'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Dismiss sheet
        await tester.tap(find.text('CHUYỂN ĐẾN ẢI TIÊN QUYẾT'));
        await tester.pumpAndSettle();
      });
    }
  });
}
