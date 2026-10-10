import 'package:flash_learn_chinese/screen/home/model/home_journey.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_practice_tab.dart';
import 'package:flash_learn_chinese/screen/review/model/review_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const journey = HomeJourney(
  gameId: 1,
  gameCode: 'listen_select',
  gameName: 'Luyện nghe',
  gameDescription: 'Nghe và chọn',
  levelId: 'level-1',
  worldNumber: 1,
  chapterNumber: 1,
  chapterTitle: 'Gọi tên món ăn và đồ uống',
  missionNumber: 4,
  missionTitle: 'Nghe và chọn',
  completedMissions: 3,
  totalMissions: 7,
  stars: 6,
  bossProgress: .5,
  nextRewardXp: 30,
);

const summary = ReviewSummary(
  totalDue: 12,
  wordsDue: 8,
  listeningDue: 2,
  speakingDue: 3,
  hanziDue: 5,
);

void main() {
  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('learning hub fits ${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 820);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePracticeTab(
              journey: journey,
              reviewSummary: summary,
              onReview: () {},
              onSpeaking: () {},
              onWriting: () {},
              onFlashcards: () {},
              onLearningPath: () {},
              onQuiz: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BÀI 1'), findsOneWidget);
      expect(find.text('3 / 7 nhiệm vụ'), findsOneWidget);
      expect(find.text('TIẾP TỤC HÀNH TRÌNH'), findsOneWidget);
      expect(find.text('12 mục cần ôn hôm nay'), findsOneWidget);
      expect(find.textContaining('310'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('zero-due actions remain useful instead of showing empty copy',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePracticeTab(
            journey: journey,
            reviewSummary: const ReviewSummary(
              totalDue: 0,
              wordsDue: 0,
              listeningDue: 0,
              speakingDue: 0,
              hanziDue: 0,
            ),
            onSpeaking: () {},
            onWriting: () {},
            onFlashcards: () {},
            onLearningPath: () {},
            onQuiz: () {},
          ),
        ),
      ),
    );

    expect(find.text('Bạn đang theo kịp'), findsOneWidget);
    expect(find.text('Luyện nhanh 3 phút'), findsOneWidget);
    expect(find.text('Khám phá chữ mới'), findsOneWidget);
    expect(find.text('Ôn từ bài hiện tại'), findsOneWidget);
    expect(find.text('Không có mục đến hạn'), findsNothing);
  });
}
