import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/widgets/adventure_node.dart';
import 'package:flash_learn_chinese/core/widgets/segmented_progress_node.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('SegmentedProgressNode Dynamic Ring & Presentation Tests', () {
    testWidgets('Renders cleanly with 3 segments (small stage)', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SegmentedProgressNode(
            totalSegments: 3,
            completedSegments: 1,
            state: AdventureNodeState.inProgress,
            icon: Icons.menu_book_rounded,
          ),
        ),
      );

      expect(find.byType(SegmentedProgressNode), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('Renders cleanly with 5 segments (medium stage)', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SegmentedProgressNode(
            totalSegments: 5,
            completedSegments: 3,
            state: AdventureNodeState.inProgress,
            icon: Icons.edit_note_rounded,
          ),
        ),
      );

      expect(find.byType(SegmentedProgressNode), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });

    testWidgets('Renders cleanly with 8 segments', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SegmentedProgressNode(
            totalSegments: 8,
            completedSegments: 8,
            state: AdventureNodeState.completed,
            icon: Icons.headphones_rounded,
            stars: 2,
          ),
        ),
      );

      expect(find.byType(SegmentedProgressNode), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
      // Completed node shows checkmark badge
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Shows 2 filled stars and 1 outlined star
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('Transitions cleanly to continuous ring when totalSegments > continuousThreshold (e.g. 15 segments)', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SegmentedProgressNode(
            totalSegments: 15,
            completedSegments: 10,
            state: AdventureNodeState.inProgress,
            continuousThreshold: 12,
            icon: Icons.translate_rounded,
          ),
        ),
      );

      expect(find.byType(SegmentedProgressNode), findsOneWidget);
      expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    });

    testWidgets('Renders single segment (totalSegments == 1)', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SegmentedProgressNode(
            totalSegments: 1,
            completedSegments: 1,
            state: AdventureNodeState.completed,
            icon: Icons.shield_rounded,
          ),
        ),
      );

      expect(find.byType(SegmentedProgressNode), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('Locked state renders lock badge and muted styling', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SegmentedProgressNode(
            totalSegments: 4,
            completedSegments: 0,
            state: AdventureNodeState.locked,
            icon: Icons.mic_rounded,
          ),
        ),
      );

      expect(find.byType(SegmentedProgressNode), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('Tapping node triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWidget(
          SegmentedProgressNode(
            totalSegments: 5,
            completedSegments: 2,
            state: AdventureNodeState.available,
            icon: Icons.menu_book_rounded,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(SegmentedProgressNode));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
