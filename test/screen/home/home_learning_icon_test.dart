import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/features/home/widgets/home_learning_icon.dart';

void main() {
  group('HomeLearningIcon Widget Tests', () {
    testWidgets('Renders all four quick action icons without crash or overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                HomeLearningIcon(label: 'Từ vựng', size: 43),
                HomeLearningIcon(label: 'Luyện viết', size: 43),
                HomeLearningIcon(label: 'Flashcards', size: 43),
                HomeLearningIcon(label: 'Luyện nói', size: 43),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeLearningIcon), findsNWidgets(4));

      // Luyện viết displays Tianzige character '永'
      expect(find.text('永'), findsOneWidget);

      // Flashcards displays character '学' and pinyin 'xué'
      expect(find.text('学'), findsOneWidget);
      expect(find.text('xué'), findsOneWidget);

      // Từ vựng displays '字'
      expect(find.text('字'), findsWidgets);

      // Luyện nói renders CustomPaint with microphone
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Supports alternative English and Vietnamese labels',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HomeLearningIcon(label: 'writing', size: 43),
                HomeLearningIcon(label: 'Hanzi', size: 43),
                HomeLearningIcon(label: 'flashcards', size: 43),
                HomeLearningIcon(label: 'speaking', size: 43),
                HomeLearningIcon(label: 'Thử thách', size: 39),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeLearningIcon), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });
}
