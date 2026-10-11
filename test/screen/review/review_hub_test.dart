import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flash_learn_chinese/screen/review/controller/review_controller.dart';
import 'package:flash_learn_chinese/screen/review/data/review_repository.dart';
import 'package:flash_learn_chinese/screen/review/model/review_item.dart';
import 'package:flash_learn_chinese/screen/review/review_screen.dart';

class FakeReviewRepository implements ReviewRepository {
  @override
  Future<ReviewSummary> loadReviewSummary() async {
    return const ReviewSummary(
      totalDue: 12,
      wordsDue: 5,
      listeningDue: 3,
      speakingDue: 2,
      hanziDue: 2,
    );
  }

  @override
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category) async {
    switch (category) {
      case ReviewCategory.words:
        return const [
          ReviewItem(
            id: 'word_1',
            category: ReviewCategory.words,
            title: '你好',
            subtitle: 'nǐ hǎo',
            translation: 'Xin chào',
            wrongCount: 2,
            score: 60.0,
            isWeak: true,
          ),
          ReviewItem(
            id: 'word_2',
            category: ReviewCategory.words,
            title: '谢谢',
            subtitle: 'xiè xie',
            translation: 'Cảm ơn',
            wrongCount: 0,
            score: 90.0,
            isWeak: false,
          ),
        ];
      case ReviewCategory.listening:
        return const [
          ReviewItem(
            id: 'listen_1',
            category: ReviewCategory.listening,
            title: '你喝茶吗？',
            subtitle: 'Luyện nghe câu hội thoại',
            translation: 'Bạn uống trà không?',
            wrongCount: 1,
            score: 70.0,
            isWeak: true,
          ),
        ];
      case ReviewCategory.speaking:
        return const [
          ReviewItem(
            id: 'speak_1',
            category: ReviewCategory.speaking,
            title: '很高兴认识你',
            subtitle: 'Độ chính xác: 65%',
            translation: 'Nói lại: Rất vui được gặp bạn',
            wrongCount: 2,
            score: 65.0,
            isWeak: true,
          ),
        ];
      case ReviewCategory.hanzi:
        return const [
          ReviewItem(
            id: 'hanzi_10',
            category: ReviewCategory.hanzi,
            title: '水',
            subtitle: 'shuǐ • 4 nét',
            translation: 'Nước',
            wrongCount: 1,
            score: 55.0,
            isWeak: true,
          ),
        ];
    }
  }
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('ReviewController tests', () {
    test('initializes with summary and default words category', () async {
      final repo = FakeReviewRepository();
      final controller = ReviewController(repository: repo);

      await controller.loadInitialData();

      expect(controller.summary.value?.totalDue, 12);
      expect(controller.selectedCategory.value, ReviewCategory.words);
      expect(controller.items.length, 2);
      expect(controller.items.first.title, '你好');
    });

    test('switches category to speaking correctly', () async {
      final repo = FakeReviewRepository();
      final controller = ReviewController(repository: repo);

      await controller.loadInitialData();
      await controller.selectCategory(ReviewCategory.speaking);

      expect(controller.selectedCategory.value, ReviewCategory.speaking);
      expect(controller.items.length, 1);
      expect(controller.items.first.title, '很高兴认识你');
    });
  });

  group('ReviewScreen widget & responsive tests', () {
    Widget buildTestScreen(Size size) {
      final repo = FakeReviewRepository();
      Get.put<ReviewController>(ReviewController(repository: repo));

      return GetMaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ReviewScreen(),
          ),
        ),
      );
    }

    testWidgets('renders hero card, 4 category tabs, and items on 360 width',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Trung Tâm Ôn Luyện'), findsOneWidget);
      expect(find.textContaining('12 MỤC CẦN ÔN HÔM NAY'), findsOneWidget);
      expect(find.text('Từ vựng'), findsOneWidget);
      expect(find.text('Nghe'), findsOneWidget);
      expect(find.text('Nói'), findsOneWidget);
      expect(find.text('Hán tự'), findsOneWidget);

      expect(find.text('Xin chào'), findsOneWidget);
      expect(find.text('Cảm ơn'), findsOneWidget);
      expect(find.text('Bắt Đầu Ôn Từ Vựng'), findsOneWidget);
    });

    testWidgets(
        'responsive test: renders cleanly on compact 320 width without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const Size(320, 640)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Trung Tâm Ôn Luyện'), findsOneWidget);
    });

    testWidgets('switching category updates the item list in UI',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const Size(390, 844)));
      await tester.pumpAndSettle();

      // Tap 'Nói' category
      await tester.tap(find.text('Nói'));
      await tester.pumpAndSettle();

      expect(find.text('很高兴认识你'), findsOneWidget);
      expect(find.text('Bắt Đầu Luyện Nói'), findsOneWidget);
    });
  });
}
