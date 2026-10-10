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
  MockLearningJourneyRepository({this.stubChapter, this.stubStages = const []});
  final ChapterAdventure? stubChapter;
  final List<LearningStageViewModel> stubStages;

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
      tester.view.physicalSize = Size(width, 800);
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
      expect(find.text('KHIÊU CHIẾN BOSS'), findsOneWidget);
      expect(find.textContaining('Khám phá từ mới'), findsOneWidget);
      expect(find.textContaining('Luyện nghe'), findsOneWidget);

      // Verify no technical strings or 310 levels
      expect(find.textContaining('PATH SECTION 0'), findsNothing);
      expect(find.textContaining('310'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
