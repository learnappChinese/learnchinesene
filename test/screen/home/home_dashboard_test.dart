import 'package:flash_learn_chinese/screen/home/model/home_journey.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const journey = HomeJourney(
  gameId: 1,
  gameCode: 'learn_words',
  gameName: 'Khám phá từ mới',
  gameDescription: 'Bắt đầu hành trình',
  levelId: 'level-1',
  worldNumber: 1,
  chapterNumber: 5,
  chapterTitle: '餐厅奇遇 • Phiêu lưu ở nhà hàng',
  missionNumber: 2,
  missionTitle: 'Gọi món cùng Panda',
  completedMissions: 2,
  totalMissions: 6,
  stars: 6,
  bossProgress: .34,
  nextRewardXp: 25,
);

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

HomeDashboard dashboard({
  HomeJourney? data = journey,
  bool loading = false,
  String? error,
  VoidCallback? onRetry,
}) =>
    HomeDashboard(
      journey: data,
      isLoading: loading,
      errorMessage: error,
      streak: 7,
      lessons: 4,
      xp: 180,
      onStartLearning: () {},
      onGrammar: () {},
      onListening: () {},
      onSpeaking: () {},
      onChallenge: () {},
      onProgress: () {},
      onRetry: onRetry,
    );

void main() {
  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('Journey Hero fits ${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 820);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(dashboard()));
      await tester.pump();

      expect(find.text('TIẾP TỤC HÀNH TRÌNH'), findsOneWidget);
      expect(find.text('THẾ GIỚI 1  •  CHƯƠNG 5'), findsOneWidget);
      expect(find.text('NHIỆM VỤ 2'), findsOneWidget);
      expect(find.text('Phần thưởng tiếp theo: +25 XP'), findsOneWidget);
      expect(find.text('Cổng Boss'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('supports loading, empty, error, and retry states',
      (tester) async {
    await tester.pumpWidget(app(dashboard(loading: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(app(dashboard(data: null)));
    await tester.pump();
    expect(find.text('Hành trình mới đang chờ bạn'), findsOneWidget);

    var retried = false;
    await tester.pumpWidget(app(dashboard(
      data: null,
      error: 'Không thể mở bản đồ hành trình.',
      onRetry: () => retried = true,
    )));
    await tester.tap(find.text('THỬ LẠI'));
    expect(retried, isTrue);
  });
}
