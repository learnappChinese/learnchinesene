import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flash_learn_chinese/core/learning/data/learning_journey_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_journey_models.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_stage_models.dart';
import 'package:flash_learn_chinese/core/widgets/adventure_node.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/model/chapter_adventure.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/quick_answer/quick_answer_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/radical_builder/radical_builder_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/tone_ninja/tone_ninja_screen.dart';
import 'package:flash_learn_chinese/screen/game_hub/game_hub_screen.dart';
import 'package:flash_learn_chinese/screen/hanzi_writing/screens/hanzi_writing_home_screen.dart';

class StubLearningJourneyRepository implements LearningJourneyRepository {
  StubLearningJourneyRepository({
    this.currentUnit,
    this.unitStages = const [],
  });

  LearningUnitViewModel? currentUnit;
  List<LearningStageViewModel> unitStages;

  @override
  Future<List<LearningSectionViewModel>> getSections() async => const [];

  @override
  Future<List<LearningUnitViewModel>> getUnits(String sectionId) async =>
      const [];

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async => null;

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async =>
      unitStages;

  @override
  Future<LearningUnitViewModel?> getCurrentProgress() async => currentUnit;

  @override
  Future<LearningNextAction?> getNextAction() async => null;

  @override
  Future<LearningStageViewModel?> getCurrentStageForActivities(
    Set<LearningStageActivityType> types, {
    String? unitId,
    bool allowCompleted = false,
  }) async {
    final matching = unitStages
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
      null;
}

LearningStageViewModel _buildTestStage({
  required String id,
  required String title,
  required LearningStageActivityType activityType,
  AdventureNodeState state = AdventureNodeState.available,
  String? sourceGameCode,
  int? sourceGameId,
  String? lockReason,
}) {
  return LearningStageViewModel(
    id: id,
    unitId: 'unit-1',
    title: title,
    subtitle: 'Mô tả bài học',
    activityType: activityType,
    learningObjective: 'Mục tiêu học',
    sourceGameId: sourceGameId ?? 1,
    sourceGameCode: sourceGameCode ?? 'test_game',
    sourceLevelIds: const ['lvl-1'],
    state: state,
    lockReason: lockReason,
    items: const [],
  );
}

Widget _wrapWithApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(440, 956),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => GetMaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Repository stage resolution logic', () {
    test('prioritizes inProgress over available stage of same activity',
        () async {
      final inProgressHanzi = _buildTestStage(
        id: 'hanzi-2',
        title: 'Chữ Hán đang học',
        activityType: LearningStageActivityType.hanzi,
        state: AdventureNodeState.inProgress,
      );
      final availableHanzi = _buildTestStage(
        id: 'hanzi-1',
        title: 'Chữ Hán 1',
        activityType: LearningStageActivityType.hanzi,
        state: AdventureNodeState.available,
      );

      final repo = StubLearningJourneyRepository(
        unitStages: [availableHanzi, inProgressHanzi],
      );

      final resolved = await repo.getCurrentStageForActivities(
        {LearningStageActivityType.hanzi},
      );
      expect(resolved?.id, 'hanzi-2');
    });

    test('ignores locked stages and returns null if none available', () async {
      final lockedListening = _buildTestStage(
        id: 'listen-1',
        title: 'Luyện nghe khóa',
        activityType: LearningStageActivityType.listening,
        state: AdventureNodeState.locked,
        lockReason: 'chapter_locked',
      );

      final repo = StubLearningJourneyRepository(
        unitStages: [lockedListening],
      );

      final resolved = await repo.getCurrentStageForActivities(
        {LearningStageActivityType.listening},
      );
      expect(resolved, isNull);
    });

    test('ignores completed stages unless allowCompleted is true', () async {
      final completedSentence = _buildTestStage(
        id: 'sent-1',
        title: 'Đặt câu hoàn thành',
        activityType: LearningStageActivityType.sentence,
        state: AdventureNodeState.completed,
      );

      final repo = StubLearningJourneyRepository(
        unitStages: [completedSentence],
      );

      final withoutCompleted = await repo.getCurrentStageForActivities(
        {LearningStageActivityType.sentence},
        allowCompleted: false,
      );
      expect(withoutCompleted, isNull);

      final withCompleted = await repo.getCurrentStageForActivities(
        {LearningStageActivityType.sentence},
        allowCompleted: true,
      );
      expect(withCompleted?.id, 'sent-1');
    });
  });

  group('GameHub programmatic stage launch vs fallback', () {
    test('routes to curriculum when stage is available', () async {
      final repo = StubLearningJourneyRepository(
        unitStages: [
          _buildTestStage(
            id: 'h1',
            title: 'Chữ Hán cơ bản',
            activityType: LearningStageActivityType.hanzi,
            state: AdventureNodeState.available,
          ),
          _buildTestStage(
            id: 'l1',
            title: 'Luyện nghe cơ bản',
            activityType: LearningStageActivityType.listening,
            state: AdventureNodeState.available,
            sourceGameCode: 'listen_select',
          ),
          _buildTestStage(
            id: 's1',
            title: 'Mẫu câu cơ bản',
            activityType: LearningStageActivityType.sentence,
            state: AdventureNodeState.available,
            sourceGameCode: 'translate',
          ),
          _buildTestStage(
            id: 'sp1',
            title: 'Luyện nói cơ bản',
            activityType: LearningStageActivityType.speaking,
            state: AdventureNodeState.available,
          ),
        ],
      );

      final hub = GameHubScreen(journeyRepository: repo);

      expect(await hub.openHanziStage(), isTrue);
      expect(await hub.openListeningStage(), isTrue);
      expect(await hub.openSentenceStage(), isTrue);
      expect(await hub.openSpeakingStage(), isTrue);
      expect(await hub.openQuickAnswerStage(), isTrue);
    });

    test('falls back to Quick Practice when stage is locked or missing',
        () async {
      final repo = StubLearningJourneyRepository(
        unitStages: [
          _buildTestStage(
            id: 'h1',
            title: 'Chữ Hán bị khóa',
            activityType: LearningStageActivityType.hanzi,
            state: AdventureNodeState.locked,
          ),
        ],
      );

      final hub = GameHubScreen(journeyRepository: repo);

      // Hanzi stage is locked -> false (fallback)
      expect(await hub.openHanziStage(), isFalse);
      // Listening stage is missing -> false (fallback)
      expect(await hub.openListeningStage(), isFalse);
      // Sentence stage is missing -> false (fallback)
      expect(await hub.openSentenceStage(), isFalse);
      // Speaking stage is missing -> false (fallback)
      expect(await hub.openSpeakingStage(), isFalse);
      expect(await hub.openQuickAnswerStage(), isFalse);
    });
  });

  group('GameHub widget interaction navigation', () {
    testWidgets(
        'tapping cards navigates to curriculum screens when stages exist',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(440, 956);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StubLearningJourneyRepository(
        unitStages: [
          _buildTestStage(
            id: 'h1',
            title: 'Xây chữ Hán',
            activityType: LearningStageActivityType.hanzi,
            state: AdventureNodeState.available,
          ),
        ],
      );

      await tester
          .pumpWidget(_wrapWithApp(GameHubScreen(journeyRepository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xây chữ Hán'));
      await tester.pumpAndSettle();

      expect(find.byType(HanziWritingHomeScreen), findsOneWidget);
    });

    testWidgets(
        'tapping cards falls back to quick practice when stages missing',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(440, 956);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StubLearningJourneyRepository(unitStages: const []);

      await tester
          .pumpWidget(_wrapWithApp(GameHubScreen(journeyRepository: repo)));
      await tester.pumpAndSettle();

      // Tap Radical Builder card when no curriculum stage exists
      await tester.tap(find.text('Xây chữ Hán'));
      await tester.pumpAndSettle();
      expect(find.byType(RadicalBuilderScreen), findsOneWidget);

      // Go back to hub
      Get.back();
      await tester.pumpAndSettle();

      // Tap Tone Ninja card when no curriculum stage exists
      await tester.tap(find.text('Tone Ninja'));
      await tester.pumpAndSettle();
      expect(find.byType(ToneNinjaScreen), findsOneWidget);

      // Go back to hub
      Get.back();
      await tester.pumpAndSettle();

      // Tap Chinese Restaurant card when no curriculum stage exists
      await tester.tap(find.text('Nhà hàng Trung Hoa'));
      await tester.pumpAndSettle();
      expect(find.byType(ChineseRestaurantScreen), findsOneWidget);

      // Go back to hub
      Get.back();
      await tester.pumpAndSettle();

      // Tap Quick Answer card when no curriculum stage exists
      await tester.tap(find.text('Trả lời nhanh'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickAnswerScreen), findsOneWidget);
    });
  });
}
