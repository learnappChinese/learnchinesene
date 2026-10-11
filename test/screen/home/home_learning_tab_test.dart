import 'package:flash_learn_chinese/screen/home/widgets/home_bottom_navigation.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_learning_tab.dart';
import 'package:flash_learn_chinese/screen/home/model/home_journey.dart';
import 'package:flash_learn_chinese/screen/review/model/review_item.dart';
import 'package:flash_learn_chinese/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(393, 852),
    const Size(440, 782),
    const Size(600, 1024),
  ]) {
    testWidgets(
        'Learning tab fits ${size.width.toInt()}px and opens all features',
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
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(440, 956),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            extendBody: true,
            body: HomeLearningTab(
              onPractice: () => actions.add('practice'),
              onVocabulary: () => actions.add('vocabulary'),
              onLessons: () => actions.add('lessons'),
              onConversation: () => actions.add('conversation'),
              onSections: () => actions.add('sections'),
            ),
            bottomNavigationBar:
                HomeBottomNavigation(currentIndex: 1, onSelected: (_) {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Học tập'), findsWidgets);
      expect(find.text('Trang chủ'), findsNothing);

      for (final description in [
        'Khám phá thế giới, các vùng đất và bài học HSK',
        'Tự động biên soạn bài học và ngữ pháp',
        'Luyện giao tiếp qua các chủ đề thông minh',
      ]) {
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text(description));
        expect(paragraph.didExceedMaxLines, isFalse);
      }

      // Tap hero CTA
      final heroButton = find.text('VÀO BẢN ĐỒ ẢI');
      expect(heroButton, findsOneWidget);
      await tester.tap(heroButton);
      await tester.pumpAndSettle();

      for (final title in [
        'Bản đồ thế giới & HSK',
        'Bài học chuyên đề AI',
        'Hội thoại tình huống AI',
      ]) {
        final card = find
            .ancestor(of: find.text(title), matching: find.byType(Material))
            .first;
        final arrow = find.descendant(
            of: card, matching: find.byIcon(Icons.chevron_right_rounded));
        await tester.ensureVisible(arrow);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
      }
      expect(actions, ['practice', 'vocabulary', 'lessons', 'conversation']);
      await tester.drag(
          find.byKey(const PageStorageKey('home-learning-scroll')),
          const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'HomeLearningTab renders journey and review summary without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeLearningTab(
            journey: const HomeJourney(
              gameId: 1,
              gameCode: 'world_1',
              gameName: 'Khởi đầu',
              gameDescription: '',
              levelId: 'level_1',
              unitId: 'unit_1',
              worldNumber: 1,
              chapterNumber: 1,
              chapterTitle: 'Khởi đầu học tiếng Trung',
              missionNumber: 1,
              missionTitle: 'Ải 1: Phát âm',
              completedMissions: 1,
              totalMissions: 5,
              stars: 3,
              bossProgress: 0.5,
              nextRewardXp: 50,
            ),
            reviewSummary: const ReviewSummary(
              totalDue: 5,
              wordsDue: 3,
              listeningDue: 2,
            ),
            onPractice: () {},
            onVocabulary: () {},
            onLessons: () {},
            onConversation: () {},
            onSections: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cần ôn tập 5 mục hôm nay'), findsOneWidget);
    expect(find.text('VÀO BẢN ĐỒ ẢI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
