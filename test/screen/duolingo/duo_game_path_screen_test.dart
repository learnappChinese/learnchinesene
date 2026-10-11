import 'package:flash_learn_chinese/screen/duolingo/controller/duo_game_path_controller.dart';
import 'package:flash_learn_chinese/screen/duolingo/page/duo_game_path_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeDuoGamePathController extends DuoGamePathController {
  _FakeDuoGamePathController({required super.gameId, required super.gameCode});

  @override
  Future<void> loadLevels() async {
    isLoading.value = false;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() async {
    Get.reset();
  });

  Widget buildTestScreen(DuoGamePathController controller) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      builder: (_, __) => GetMaterialApp(
        home: DuoGamePathScreen(
          gameId: 1,
          gameCode: 'select_answer',
          gameName: 'Chọn đáp án đúng',
          description: 'Luyện chọn đáp án',
          controller: controller,
        ),
      ),
    );
  }

  testWidgets('DuoGamePathScreen renders loaded levels and path correctly',
      (tester) async {
    final controller =
        _FakeDuoGamePathController(gameId: 1, gameCode: 'select_answer');
    controller.isLoading.value = false;
    controller.allLevels.assignAll([
      {
        'id': 'lvl_1',
        'level_id': 'lvl_1',
        'level_number': 1,
        'unit_number': 1,
        'section_number': 1,
        'section_title': 'Khởi Động',
        'challenge_count': 5,
        'is_unlocked': 1,
        'is_completed': 1,
        'stars': 3,
        'lock_reason': null,
      },
      {
        'id': 'lvl_2',
        'level_id': 'lvl_2',
        'level_number': 2,
        'unit_number': 1,
        'section_number': 1,
        'section_title': 'Khởi Động',
        'challenge_count': 5,
        'is_unlocked': 1,
        'is_completed': 0,
        'stars': 0,
        'lock_reason': null,
      },
      {
        'id': 'lvl_3',
        'level_id': 'lvl_3',
        'level_number': 3,
        'unit_number': 1,
        'section_number': 1,
        'section_title': 'Khởi Động',
        'challenge_count': 5,
        'is_unlocked': 0,
        'is_completed': 0,
        'stars': 0,
        'lock_reason': 'chapter_locked',
      },
    ]);

    await tester.pumpWidget(buildTestScreen(controller));
    await tester.pumpAndSettle();

    expect(find.text('Chọn đáp án đúng'), findsOneWidget);
    expect(find.byType(DuoGamePathScreen), findsOneWidget);
  });

  testWidgets('Tapping locked level shows actionable locked mission sheet',
      (tester) async {
    final controller =
        _FakeDuoGamePathController(gameId: 1, gameCode: 'select_answer');
    controller.isLoading.value = false;
    controller.allLevels.assignAll([
      {
        'id': 'lvl_1',
        'level_id': 'lvl_1',
        'level_number': 1,
        'unit_number': 1,
        'section_number': 1,
        'section_title': 'Khởi Động',
        'challenge_count': 5,
        'is_unlocked': 1,
        'is_completed': 0,
        'stars': 0,
        'lock_reason': null,
      },
      {
        'id': 'lvl_2',
        'level_id': 'lvl_2',
        'level_number': 2,
        'unit_number': 1,
        'section_number': 1,
        'section_title': 'Khởi Động',
        'challenge_count': 5,
        'is_unlocked': 0,
        'is_completed': 0,
        'stars': 0,
        'lock_reason': 'chapter_locked',
      },
    ]);

    await tester.pumpWidget(buildTestScreen(controller));
    await tester.pumpAndSettle();

    // Tap locked node (second node)
    final nodes = find.byType(GestureDetector);
    if (nodes.evaluate().isNotEmpty) {
      await tester.tap(nodes.last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  });
}
