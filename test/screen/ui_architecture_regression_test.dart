import 'package:flash_learn_chinese/core/models/quiz_question.dart';
import 'package:flash_learn_chinese/screen/conversations/widget/conversation_bubble.dart';
import 'package:flash_learn_chinese/screen/hsk/controller/hsk_controller.dart';
import 'package:flash_learn_chinese/screen/hsk/hsk_screen.dart';
import 'package:flash_learn_chinese/screen/hsk_exam/widget/hsk_exam_content.dart';
import 'package:flash_learn_chinese/screen/lessons/widget/lesson_content.dart';
import 'package:flash_learn_chinese/screen/quiz/widget/quiz_content.dart';
import 'package:flash_learn_chinese/screen/speaking/widget/speaking_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const question = QuizQuestion(
  wordId: 1,
  type: QuizType.chineseToVietnamese,
  question: '你好 nghĩa là gì?',
  options: ['Xin chào', 'Cảm ơn', 'Tạm biệt', 'Xin lỗi'],
  correctAnswer: 'Xin chào',
);

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  tearDown(() async => Get.reset());

  testWidgets('Quiz locks answers and keeps feedback and next action',
      (tester) async {
    final answers = <String>[];
    var next = 0;
    Widget view(String? selected) => app(QuizQuestionView(
          q: question,
          index: 0,
          questionCount: 2,
          selected: selected,
          onPlayAudio: () {},
          onChoose: answers.add,
          onNext: () => next++,
        ));
    await tester.pumpWidget(view(null));
    await tester.tap(find.text('Cảm ơn'));
    expect(answers, ['Cảm ơn']);
    await tester.pumpWidget(view('Cảm ơn'));
    expect(find.text('Đáp án đúng là Xin chào.'), findsOneWidget);
    await tester.tap(find.text('Xin chào'));
    expect(answers, ['Cảm ơn']);
    await tester.tap(find.text('Câu tiếp theo'));
    expect(next, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exam question forwards its index and reflects changed answers',
      (tester) async {
    int? selectedIndex;
    String? selectedAnswer;
    Widget view(List<String?> answers) => app(HskExamQuestions(
          selectedLevel: 1,
          questions: const [
            {
              'section': 'Đọc hiểu',
              'question_text': 'Chọn nghĩa',
              'options': ['Xin chào', 'Tạm biệt'],
            }
          ],
          answers: answers,
          onSpeak: (_) {},
          onSelect: (index, answer) {
            selectedIndex = index;
            selectedAnswer = answer;
          },
        ));
    await tester.pumpWidget(view([null]));
    await tester.tap(find.text('Tạm biệt'));
    expect(selectedIndex, 0);
    expect(selectedAnswer, 'Tạm biệt');
    await tester.pumpWidget(view(['Tạm biệt']));
    final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Tạm biệt'));
    final text = tester.widget<Text>(find.text('Tạm biệt'));
    expect(text.style?.fontWeight, FontWeight.bold);
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lesson content renders empty states and forwards spoken text',
      (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(
        app(LessonDialogueTab(lines: const [], onSpeak: spoken.add)));
    expect(find.text('Không có dữ liệu hội thoại.'), findsOneWidget);
    await tester.pumpWidget(app(LessonDialogueTab(
      lines: const [
        {'speaker': 'A', 'zh': '你好', 'vi': 'Xin chào'}
      ],
      onSpeak: spoken.add,
    )));
    await tester.tap(find.text('你好'));
    expect(spoken, ['你好']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Speaking feedback disables actions while recording',
      (tester) async {
    var retry = 0;
    var next = 0;
    Widget view(bool busy) => app(SpeakingResultCard(
          correct: true,
          score: 92,
          recognized: '你好',
          busy: busy,
          showNext: true,
          isLast: true,
          onRetry: () => retry++,
          onNext: () => next++,
        ));
    await tester.pumpWidget(view(true));
    await tester.tap(find.text('Luyện lại'));
    await tester.tap(find.text('Hoàn thành'));
    expect([retry, next], [0, 0]);
    await tester.pumpWidget(view(false));
    await tester.tap(find.text('Luyện lại'));
    await tester.tap(find.text('Hoàn thành'));
    expect([retry, next], [1, 1]);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1000.0]) {
    testWidgets('Conversation supports long text and text scaling at $width',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              size: Size(width, 900), textScaler: const TextScaler.linear(1.5)),
          child: Scaffold(
              body: SingleChildScrollView(
                  child: ConversationBubble(
            chinese: '你好。' * 30,
            vietnamese: 'Đây là đoạn hội thoại dài cần xuống dòng. ' * 12,
            turn: 2,
            onSpeak: () {},
          ))),
        ),
      ));
      expect(find.text('Speaker B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'HSK route retains its controller until pop and recreates on reopen',
      (tester) async {
    Get.testMode = true;
    addTearDown(() => Get.testMode = false);
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () => Get.to(() => const HskScreen()),
                    child: const Text('Open HSK'),
                  ))),
    ));
    await tester.tap(find.text('Open HSK'));
    await tester.pumpAndSettle();
    final first = Get.find<HskController>();
    expect(find.text('Không thể mở bản đồ thế giới'), findsOneWidget);
    await tester.pump();
    expect(Get.find<HskController>(), same(first));
    Get.back();
    await tester.pumpAndSettle();
    expect(first.isClosed, isTrue);
    expect(Get.isRegistered<HskController>(), isFalse);
    await tester.tap(find.text('Open HSK'));
    await tester.pumpAndSettle();
    expect(Get.find<HskController>(), isNot(same(first)));
    expect(tester.takeException(), isNull);
  });
}
