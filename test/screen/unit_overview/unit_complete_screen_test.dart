import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_journey_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_journey_models.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_stage_models.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/model/chapter_adventure.dart';
import 'package:flash_learn_chinese/screen/unit_overview/page/unit_complete_screen.dart';

class _StubJourneyRepo implements LearningJourneyRepository {
  _StubJourneyRepo({this.nextUnit});
  final LearningUnitViewModel? nextUnit;

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async => null;

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async =>
      const [];

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
  }) async =>
      null;

  @override
  Future<LearningStageViewModel?> getCurrentStageForActivity(
    LearningStageActivityType type, {
    String? unitId,
    bool allowCompleted = false,
  }) async =>
      null;

  @override
  Future<LearningUnitViewModel?> getNextUnit(String currentUnitId) async =>
      nextUnit;
}

void main() {
  tearDown(() {
    Get.reset();
  });

  const stubNext = LearningUnitViewModel(
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

  testWidgets('UnitCompleteScreen renders victory UI and next unit action',
      (tester) async {
    final repo = _StubJourneyRepo(nextUnit: stubNext);

    await tester.pumpWidget(
      GetMaterialApp(
        home: UnitCompleteScreen(
          unitId: 'sec_1_unit_1',
          unitTitle: 'Gọi tên món ăn',
          sectionNumber: 1,
          unitNumber: 1,
          bossName: 'Rồng Lửa',
          xpEarned: 50,
          starsEarned: 3,
          journeyRepository: repo,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify celebratory ribbon and text
    expect(find.text('🏆 BÀI HỌC HOÀN THÀNH 🏆'), findsOneWidget);
    expect(find.textContaining('GỌI TÊN MÓN ĂN'), findsOneWidget);
    expect(find.textContaining('Rồng Lửa'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Xuất sắc'), findsOneWidget);

    // Verify primary action button displays next unit title
    expect(find.textContaining('Hỏi đường và phương tiện'), findsOneWidget);

    // Verify secondary action button exists
    expect(find.text('Xem lại bài học vừa hoàn thành'), findsOneWidget);

    // Verify Panda Companion speech
    expect(find.textContaining('Tuyệt đỉnh công phu'), findsOneWidget);
  });
}
