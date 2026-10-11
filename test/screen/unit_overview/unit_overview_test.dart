import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_journey_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_journey_models.dart';
import 'package:flash_learn_chinese/core/widgets/adventure_node.dart';
import 'package:flash_learn_chinese/screen/boss_battle/model/boss_battle_stage.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/model/chapter_adventure.dart';
import 'package:flash_learn_chinese/screen/unit_overview/controller/unit_overview_controller.dart';
import 'package:flash_learn_chinese/screen/unit_overview/page/unit_overview_screen.dart';

import 'package:flash_learn_chinese/core/learning/model/learning_stage_models.dart';

class MockLearningJourneyRepository implements LearningJourneyRepository {
  MockLearningJourneyRepository({
    this.stubChapter,
    this.stubStages = const [],
    this.stubNextUnit,
  });
  final ChapterAdventure? stubChapter;
  final List<LearningStageViewModel> stubStages;
  final LearningUnitViewModel? stubNextUnit;

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async => stubChapter;

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async =>
      stubStages;

  @override
  Future<List<LearningSectionViewModel>> getSections() async => const [];

  @override
  Future<List<LearningUnitViewModel>> getUnits(String sectionId) async =>
      const [];

  @override
  Future<LearningUnitViewModel?> getCurrentProgress() async => null;

  @override
  Future<LearningNextAction?> getNextAction() async => null;

  @override
  Future<LearningStageViewModel?> getCurrentStageForActivities(
    Set<LearningStageActivityType> types, {
    String? unitId,
    bool allowCompleted = false,
  }) async {
    final matching = stubStages
        .where((stage) => types.contains(stage.activityType))
        .toList(growable: false);
    if (matching.isEmpty) return null;
    final inProgress = matching
        .where((stage) => stage.state == AdventureNodeState.inProgress)
        .firstOrNull;
    if (inProgress != null) return inProgress;
    final available = matching
        .where((stage) =>
            (stage.state == AdventureNodeState.available ||
                stage.state == AdventureNodeState.failed) &&
            !stage.isLocked)
        .firstOrNull;
    if (available != null) return available;
    if (allowCompleted) {
      return matching.where((stage) => stage.isCompleted).firstOrNull;
    }
    return null;
  }

  @override
  Future<LearningStageViewModel?> getCurrentStageForActivity(
    LearningStageActivityType type, {
    String? unitId,
    bool allowCompleted = false,
  }) =>
      getCurrentStageForActivities(
        {type},
        unitId: unitId,
        allowCompleted: allowCompleted,
      );

  @override
  Future<LearningUnitViewModel?> getNextUnit(String currentUnitId) async =>
      stubNextUnit;
}

void main() {
  const dummyBoss = BossBattleStage(
    id: 1,
    unitId: 'sec_1_unit_1',
    stageOrder: 1,
    sectionNumber: 1,
    unitNumber: 1,
    title: 'Rồng Lửa',
    bossName: 'Rồng Lửa',
    bossHp: 100,
    playerHp: 100,
    difficulty: 1,
    questionCount: 8,
    themeCode: 'sunset',
  );

  const stubChapter = ChapterAdventure(
    levelId: 'lvl-1',
    unitId: 'sec_1_unit_1',
    regionNumber: 1,
    chapterNumber: 1,
    title: 'Gọi tên món ăn và đồ uống',
    objective: 'Nắm vững 18 từ mới và mẫu câu gọi món cơ bản.',
    overallMastery: 0.65,
    bossUnlocked: true,
    boss: dummyBoss,
    missions: [
      ChapterMission(
        gameId: 1,
        gameCode: 'learn_words',
        title: 'Khám phá từ mới',
        description: 'Học và ghi nhớ từ vựng của bài học',
        type: AdventureNodeType.learn,
        state: AdventureNodeState.completed,
        stars: 3,
      ),
      ChapterMission(
        gameId: 2,
        gameCode: 'listen_select',
        title: 'Luyện nghe',
        description: 'Nghe phát âm và chọn đáp án đúng',
        type: AdventureNodeType.listening,
        state: AdventureNodeState.available,
        stars: 0,
      ),
      ChapterMission(
        gameId: 3,
        gameCode: 'select_answer',
        title: 'Chọn đáp án',
        description: 'Chọn nghĩa đúng trong ngữ cảnh',
        type: AdventureNodeType.select,
        state: AdventureNodeState.locked,
        stars: 0,
      ),
    ],
  );

  tearDown(() {
    Get.reset();
  });

  for (final width in [320.0, 360.0, 440.0]) {
    testWidgets('UnitOverviewScreen renders cleanly at ${width.toInt()}px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      Get.put<UnitOverviewController>(
        UnitOverviewController(
          journeyRepository:
              MockLearningJourneyRepository(stubChapter: stubChapter),
        )..unitId = stubChapter.unitId,
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: UnitOverviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('BÀI 1: Gọi tên món ăn và đồ uống'),
          findsOneWidget);
      expect(find.textContaining('PHẦN 1'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget); // 1 completed out of 3
      expect(find.text('65%'), findsOneWidget); // 65% mastery
      await tester.scrollUntilVisible(
        find.text('KHIÊU CHIẾN BOSS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('KHIÊU CHIẾN BOSS'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Khám phá từ mới'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Khám phá từ mới'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Luyện nghe'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Luyện nghe'), findsOneWidget);

      // Verify no technical strings or 310 levels
      expect(find.textContaining('PATH SECTION 0'), findsNothing);
      expect(find.textContaining('310'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'UnitOverviewScreen opens and closes Boss Gate modal when boss is ready',
      (tester) async {
    Get.put<UnitOverviewController>(
      UnitOverviewController(
        journeyRepository:
            MockLearningJourneyRepository(stubChapter: stubChapter),
      )..unitId = stubChapter.unitId,
    );

    await tester.pumpWidget(
      const GetMaterialApp(
        home: UnitOverviewScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify boss ready state on screen
    expect(find.text('CỔNG BOSS ĐÃ MỞ (BOSS GATE)'), findsOneWidget);
    expect(find.text('KHIÊU CHIẾN BOSS'), findsOneWidget);

    // Tap CTA to open boss gate dialog
    await tester.tap(find.text('KHIÊU CHIẾN BOSS'));
    await tester.pumpAndSettle();

    // Verify boss gate modal contents
    expect(find.text('CỔNG KHIÊU CHIẾN BOSS'), findsOneWidget);
    expect(find.text('Rồng Lửa'), findsAtLeastNWidgets(1));
    expect(find.text('100 ❤️'), findsOneWidget);
    expect(find.text('100 🛡️'), findsOneWidget);
    expect(find.text('8 câu hỏi'), findsOneWidget);
    expect(find.text('CHUẨN BỊ THÊM'), findsOneWidget);
    expect(find.text('VÀO CHIẾN ĐẤU'), findsOneWidget);

    // Tap dismiss
    await tester.tap(find.text('CHUẨN BỊ THÊM'));
    await tester.pumpAndSettle();

    expect(find.text('CỔNG KHIÊU CHIẾN BOSS'), findsNothing);
  });

  testWidgets(
      'UnitOverviewScreen displays completed banner and Next Unit CTA when finished',
      (tester) async {
    final completedChapter = ChapterAdventure(
      levelId: 'lvl-1',
      unitId: 'sec_1_unit_1',
      regionNumber: 1,
      chapterNumber: 1,
      title: 'Gọi tên món ăn và đồ uống',
      objective: 'Nắm vững 18 từ mới và mẫu câu gọi món cơ bản.',
      overallMastery: 1.0,
      bossUnlocked: true,
      boss: dummyBoss,
      missions: const [
        ChapterMission(
          gameId: 1,
          gameCode: 'learn_words',
          title: 'Khám phá từ mới',
          description: 'Học và ghi nhớ từ vựng của bài học',
          type: AdventureNodeType.learn,
          state: AdventureNodeState.completed,
          stars: 3,
        ),
        ChapterMission(
          gameId: 2,
          gameCode: 'listen_select',
          title: 'Luyện nghe',
          description: 'Nghe phát âm và chọn đáp án đúng',
          type: AdventureNodeType.listening,
          state: AdventureNodeState.completed,
          stars: 3,
        ),
        ChapterMission(
          gameId: 3,
          gameCode: 'select_answer',
          title: 'Chọn đáp án',
          description: 'Chọn nghĩa đúng trong ngữ cảnh',
          type: AdventureNodeType.select,
          state: AdventureNodeState.completed,
          stars: 3,
        ),
      ],
    );

    const nextUnit = LearningUnitViewModel(
      id: 'sec_1_unit_2',
      sectionId: 'sec_1',
      sectionNumber: 1,
      unitNumber: 2,
      title: 'Hỏi đường và phương tiện',
      subtitle: 'Khám phá từ vựng giao thông',
      missionCount: 3,
      completedMissionCount: 0,
      isUnlocked: true,
    );

    Get.put<UnitOverviewController>(
      UnitOverviewController(
        journeyRepository: MockLearningJourneyRepository(
          stubChapter: completedChapter,
          stubNextUnit: nextUnit,
        ),
      )..unitId = completedChapter.unitId,
    );

    await tester.pumpWidget(
      const GetMaterialApp(
        home: UnitOverviewScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BÀI HỌC ĐÃ HOÀN THÀNH'), findsOneWidget);
    expect(find.textContaining('Hỏi đường và phương tiện'),
        findsAtLeastNWidgets(1));
    expect(
        find.text('BÀI TIẾP THEO: HỎI ĐƯỜNG VÀ PHƯƠNG TIỆN'), findsOneWidget);
  });
}
