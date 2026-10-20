import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandarin/core/widgets/v3_learner_feedback_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'guest_learning_stats_v2': '{"xp":42}',
    });
  });

  test('V3 feedback is separated from existing Guest XP storage', () async {
    await V3LearnerFeedbackStore.save(<String, dynamic>{
      'unit_id': 'sec_1_unit_1',
      'challenge_id': 'question-1',
      'category': 'wrong_translation',
      'notes': 'Bản dịch không đúng ngữ cảnh',
    });

    final results = await V3LearnerFeedbackStore.load();
    expect(results, hasLength(1));
    expect(results.single['challenge_id'], 'question-1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('guest_learning_stats_v2'), '{"xp":42}');
  });

  test('V3 feedback retains only 200 most recent reports', () async {
    for (var i = 0; i < 205; i++) {
      await V3LearnerFeedbackStore.save(<String, dynamic>{
        'unit_id': 'sec_1_unit_1',
        'sequence': i,
      });
    }
    final result = await V3LearnerFeedbackStore.load();
    expect(result.length, 200);
    expect(result.first['sequence'], 5);
    expect(result.last['sequence'], 204);
  });

  testWidgets('learner can report a question in the debug QA sheet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showV3LearnerFeedbackSheet(
                context,
                unitId: 'sec_1_unit_1',
                levelId: 'level-1',
                gameCode: 'translate',
                challengeId: 'question-1',
                screen: 'duo_game_runner',
              ),
              child: const Text('Open QA'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open QA'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra chất lượng bài học'), findsOneWidget);
    expect(find.textContaining('question-1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Thiếu lời giải thích');
    await tester.ensureVisible(find.text('Lưu đánh giá'));
    await tester.tap(find.text('Lưu đánh giá'));
    await tester.pumpAndSettle();

    final entries = await V3LearnerFeedbackStore.load();
    expect(entries, hasLength(1));
    expect(entries.single['unit_id'], 'sec_1_unit_1');
    expect(entries.single['level_id'], 'level-1');
    expect(entries.single['challenge_id'], 'question-1');
    expect(entries.single['notes'], 'Thiếu lời giải thích');
  });

  test('local review queue can be copied as JSON', () async {
    await V3LearnerFeedbackStore.save(<String, dynamic>{
      'unit_id': 'sec_1_unit_1',
      'category': 'locked_progress',
    });
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await V3LearnerFeedbackStore.copyAll();
    expect(copied, contains('locked_progress'));
  });
}
