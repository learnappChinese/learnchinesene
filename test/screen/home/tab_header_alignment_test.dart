import 'package:flash_learn_chinese/screen/game_hub/view/game_hub_view.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_learning_tab.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_personal_tab.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_progress_tab.dart';
import 'package:flash_learn_chinese/screen/home/widgets/tab_header.dart';
import 'package:flutter/material.dart';
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
        'All four tabs align headers and cards at ${size.width.toInt()}px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewPadding);

      Future<({Rect header, Rect firstCard, double gap})> measure(
          Widget tab, String firstTitle, String secondTitle) async {
        await tester.pumpWidget(ScreenUtilInit(
          designSize: const Size(440, 956),
          builder: (_, __) => MaterialApp(home: Scaffold(body: tab)),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        Rect cardRect(String title) => tester.getRect(find
            .ancestor(of: find.text(title), matching: find.byType(Material))
            .first);
        final first = cardRect(firstTitle);
        final second = cardRect(secondTitle);
        return (
          header: tester.getRect(find.byType(TabHeader)),
          firstCard: first,
          gap: second.top - first.bottom,
        );
      }

      final learning = await measure(
        HomeLearningTab(
          onPractice: () {},
          onVocabulary: () {},
          onLessons: () {},
          onConversation: () {},
        ),
        'Luyện tập & Thực hành',
        'Kho từ vựng HSK',
      );
      final games = await measure(
        GameHubView(
          onBossBattle: () {},
          onRadicalBuilder: () {},
          onToneNinja: () {},
          onRestaurant: () {},
          onQuickAnswer: () {},
          onStageMap: () {},
        ),
        'Boss Battle',
        'Xây chữ Hán',
      );
      final progress = await measure(
        HomeProgressTab(onStats: () {}, onExam: () {}, onHistory: () {}),
        'Thống kê chi tiết',
        'Thi thử HSK với AI',
      );
      final personal = await measure(
        HomePersonalTab(
            onProfile: () {}, onPremium: () {}, onDictionary: () {}),
        'Hồ sơ người dùng',
        'Nâng cấp Premium',
      );
      for (final tab in [games, progress, personal]) {
        expect(tab.header, learning.header);
        expect(tab.firstCard.top, closeTo(learning.firstCard.top, .1));
        expect(tab.firstCard.left, closeTo(learning.firstCard.left, .1));
        expect(tab.firstCard.width, closeTo(learning.firstCard.width, .1));
        expect(tab.gap, closeTo(learning.gap, .1));
      }
    });
  }
}
