import 'package:flash_learn_chinese/screen/home/widgets/home_bottom_navigation.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_learning_tab.dart';
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
          home: Scaffold(
            extendBody: true,
            body: HomeLearningTab(
              onPractice: () => actions.add('practice'),
              onVocabulary: () => actions.add('vocabulary'),
              onLessons: () => actions.add('lessons'),
              onConversation: () => actions.add('conversation'),
            ),
            bottomNavigationBar:
                HomeBottomNavigation(currentIndex: 1, onSelected: (_) {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Học tập chuyên sâu'), findsOneWidget);
      expect(find.text('Trang chủ'), findsNothing);
      expect(tester.getTopLeft(find.text('Học tập chuyên sâu')).dy,
          greaterThanOrEqualTo(47));
      expect(tester.getTopLeft(find.text('Học tập chuyên sâu')).dy,
          lessThanOrEqualTo(47 + 24.w));
      for (final description in [
        'Luyện viết, phát âm, flashcards và ôn tập HSK',
        'Xem từ theo cấp độ HSK và bài học',
        'Tự động biên soạn bài học và ngữ pháp',
        'Luyện giao tiếp qua các chủ đề thông minh',
      ]) {
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text(description));
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
            paragraph.size.height,
            greaterThanOrEqualTo(
                paragraph.getMaxIntrinsicHeight(paragraph.size.width) - .1));
      }
      for (final title in [
        'Luyện tập & Thực hành',
        'Kho từ vựng HSK',
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
        expect(tester.getCenter(arrow).dy,
            closeTo(tester.getRect(card).center.dy, .1));
        final textGroup = find
            .ancestor(of: find.text(title), matching: find.byType(Column))
            .first;
        expect(tester.getCenter(textGroup).dy,
            closeTo(tester.getRect(card).center.dy, .1));
        await tester.tapAt(tester.getCenter(arrow));
      }
      expect(actions, ['practice', 'vocabulary', 'lessons', 'conversation']);
      await tester.drag(find.byKey(const ValueKey('learning-scroll')),
          const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.text('Hội thoại tình huống AI')).dy,
          lessThan(tester.getTopLeft(find.text('Học tập')).dy));
      expect(tester.takeException(), isNull);
    });
  }
}
