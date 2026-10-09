import 'package:flash_learn_chinese/screen/home/model/home_journey.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const journey = HomeJourney(
  gameId: 1,
  gameCode: 'learn_words',
  gameName: 'Khám phá từ mới',
  gameDescription: 'Bắt đầu hành trình',
  levelId: 'level-1',
  worldNumber: 1,
  chapterNumber: 2,
  chapterTitle: 'Quốc tịch và quê quán',
  missionNumber: 2,
  missionTitle: 'Gọi món cùng Panda',
  completedMissions: 2,
  totalMissions: 6,
  stars: 6,
  bossProgress: .34,
  nextRewardXp: 25,
);

Widget app(Widget child) => ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

HomeDashboard dashboard({
  HomeJourney? data = journey,
  bool loading = false,
  String? error,
  VoidCallback? onRetry,
  VoidCallback? onStartLearning,
}) =>
    HomeDashboard(
      journey: data,
      isLoading: loading,
      errorMessage: error,
      streak: 7,
      lessons: 4,
      xp: 180,
      onStartLearning: onStartLearning ?? () {},
      onGrammar: () {},
      onListening: () {},
      onSpeaking: () {},
      onChallenge: () {},
      onProgress: () {},
      onRetry: onRetry,
    );

void main() {
  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('Dashboard fits ${width.toInt()}px and displays Chinese Fantasy artwork & metrics',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 956);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(dashboard()));
      await tester.pump();

      expect(find.text('你好! 👋'), findsOneWidget);
      expect(find.text('BÀI HỌC HÔM NAY'), findsOneWidget);
      expect(find.text('Bắt đầu học'), findsOneWidget);
      expect(find.text('Ngày học'), findsOneWidget);
      expect(find.text('Bài học'), findsOneWidget);
      expect(find.text('Điểm XP'), findsOneWidget);
      expect(find.text('BÀI 2: Quốc tịch và quê quán'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(find.text('Từ vựng'), findsOneWidget);
      expect(find.text('Ngữ pháp'), findsOneWidget);
      expect(find.text('Luyện nghe'), findsOneWidget);
      expect(find.text('Luyện nói'), findsOneWidget);
      expect(find.text('Hoàn thành 10 câu hỏi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('displays fallback lesson card when journey is null',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 850);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(dashboard(data: null)));
    await tester.pump();

    expect(find.text('Từ vựng cơ bản'), findsOneWidget);
    expect(find.text('Chủ đề: Gia đình'), findsOneWidget);
    expect(find.text('3/8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action callbacks fire correctly on Start Learning and Continue',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var starts = 0;
    await tester.pumpWidget(app(dashboard(onStartLearning: () => starts++)));
    await tester.pump();

    await tester.tap(find.text('Bắt đầu học'));
    expect(starts, 1);

    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.tap(find.text('Tiếp tục'));
    expect(starts, 2);
  });
}
