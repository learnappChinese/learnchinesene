import 'package:pandarin/core/learning/data/learning_journey_repository.dart';
import 'package:pandarin/core/learning/data/learning_progress_repository.dart';
import 'package:pandarin/core/learning/model/learning_journey_models.dart';
import 'package:pandarin/core/learning/model/learning_stage_models.dart';
import 'package:pandarin/core/learning/model/recommended_next_action.dart';
import 'package:pandarin/core/learning/model/unit_mastery.dart';
import 'package:pandarin/core/learning/service/learning_recommendation_service.dart';
import 'package:pandarin/features/chapter_adventure/model/chapter_adventure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningRecommendationService - Deterministic 7-Tier Priorities', () {
    test(
        'Priority 1: Active session outranks all suggestions and preserves index',
        () async {
      final service = SupabaseLearningRecommendationService(
        activeSessionLoader: ({userId, levelId}) async => [
          {
            'attempt_id': 'att_123',
            'game_id': 101,
            'level_id': 'lvl_1',
            'current_index': 4,
            'status': 'active',
          }
        ],
        overdueCountLoader: () async => 15, // High overdue review present
        pathLoader: (unitId) async => [
          {
            'node_type': 'boss',
            'is_unlocked': true,
            'is_completed': false,
            'boss_stage_id': 999,
          }
        ],
      );

      final action =
          await service.recommend(unitId: 'unit_1', levelId: 'lvl_1');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.resume);
      expect(action.actionType, 'resume');
      expect(action.reasonCode, 'active_session');
      expect(action.gameId, 101);
      expect(action.currentIndex, 4);
      expect(action.destination, 'session:101');
      expect(action.label, 'TIẾP TỤC');
      expect(action.subtitle, contains('câu 5'));
    });

    test(
        'Priority 2: Completed unit recommends next unit; explore if no next unit',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: const LearningUnitViewModel(
          id: 'unit_1',
          sectionId: 'sec_1',
          sectionNumber: 1,
          unitNumber: 1,
          title: 'Bài 1: Chào hỏi',
          subtitle: 'Đã hoàn thành',
          teachingObjective: 'Giao tiếp cơ bản',
          missionCount: 4,
          completedMissionCount: 4,
          mastery: 1.0,
          state: UnitCompletionState.completed,
          isUnlocked: true,
          bossWon: true,
        ),
        nextUnit: const LearningUnitViewModel(
          id: 'unit_2',
          sectionId: 'sec_1',
          sectionNumber: 1,
          unitNumber: 2,
          title: 'Bài 2: Gia đình',
          subtitle: 'Sẵn sàng bắt đầu',
          teachingObjective: 'Từ vựng gia đình',
          missionCount: 4,
          completedMissionCount: 0,
          mastery: 0.0,
          state: UnitCompletionState.inProgress,
          isUnlocked: true,
        ),
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 5,
      );

      final action = await service.recommend(unitId: 'unit_1');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.nextUnit);
      expect(action.actionType, 'next_unit');
      expect(action.reasonCode, 'unit_completed_next_unit');
      expect(action.unitId, 'unit_2');
      expect(action.label, 'BÀI TIẾP THEO');
      expect(action.title, contains('Bài 2: Gia đình'));
    });

    test(
        'Priority 2 fallback: Completed unit with no next unit recommends Explore',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: const LearningUnitViewModel(
          id: 'unit_final',
          sectionId: 'sec_9',
          sectionNumber: 9,
          unitNumber: 10,
          title: 'Bài cuối cùng',
          subtitle: 'Hoàn thành',
          teachingObjective: 'Tổng kết',
          missionCount: 5,
          completedMissionCount: 5,
          mastery: 1.0,
          state: UnitCompletionState.completed,
          isUnlocked: true,
          bossWon: true,
        ),
        nextUnit: null, // No more units
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
      );

      final action = await service.recommend(unitId: 'unit_final');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.explore);
      expect(action.actionType, 'explore');
      expect(action.reasonCode, 'explore_world');
      expect(action.label, 'KHÁM PHÁ');
      expect(action.destination, 'sections');
    });

    test(
        'Priority 3: Boss ready outranks overdue review and path missions when unlocked on server',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: const LearningUnitViewModel(
          id: 'unit_1',
          sectionId: 'sec_1',
          sectionNumber: 1,
          unitNumber: 1,
          title: 'Bài 1: Làm quen',
          subtitle: 'Sẵn sàng đấu Boss',
          teachingObjective: 'Học cơ bản',
          missionCount: 3,
          completedMissionCount: 3,
          mastery: 0.9,
          state: UnitCompletionState.bossPending,
          isUnlocked: true,
          bossAvailable: true,
          bossWon: false,
          bossStageId: 501,
          bossName: 'Hắc Long',
        ),
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 10, // Overdue exists, but Boss is ready
        pathLoader: (unitId) async => [
          {
            'node_type': 'boss',
            'is_unlocked': true,
            'is_completed': false,
            'boss_stage_id': 501,
            'boss_name': 'Hắc Long',
          }
        ],
      );

      final action = await service.recommend(unitId: 'unit_1');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.fightBoss);
      expect(action.actionType, 'fight_boss');
      expect(action.reasonCode, 'boss_ready');
      expect(action.stageId, 501);
      expect(action.label, 'ĐÁNH BOSS');
      expect(action.title, contains('Hắc Long'));
    });

    test(
        'Contradictory boss state: Server locked boss node never guesses boss CTA',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: const LearningUnitViewModel(
          id: 'unit_1',
          sectionId: 'sec_1',
          sectionNumber: 1,
          unitNumber: 1,
          title: 'Bài 1: Làm quen',
          subtitle: 'Đang học',
          teachingObjective: 'Cơ bản',
          missionCount: 3,
          completedMissionCount: 1,
          mastery: 0.4,
          state: UnitCompletionState.inProgress,
          isUnlocked: true,
          bossAvailable: false, // Server says NOT available
        ),
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 0,
        pathLoader: (unitId) async => [
          {
            'node_type': 'learning',
            'is_unlocked': true,
            'is_completed': true,
            'game_id': 10,
          },
          {
            'node_type': 'learning',
            'is_unlocked': true,
            'is_completed': false,
            'game_id': 20,
            'game_name': 'Luyện nghe câu 2',
          },
          {
            'node_type': 'boss',
            'is_unlocked': false, // Locked on server
            'is_completed': false,
          },
        ],
      );

      final action = await service.recommend(unitId: 'unit_1');

      expect(action, isNotNull);
      expect(action!.type, isNot(RecommendedActionType.fightBoss));
      expect(action.type, RecommendedActionType.startMission);
      expect(action.gameId, 20);
      expect(action.title, 'Luyện nghe câu 2');
    });

    test(
        'Priority 4: Overdue review suggested with canBypass: true (does not lock path)',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: const LearningUnitViewModel(
          id: 'unit_1',
          sectionId: 'sec_1',
          sectionNumber: 1,
          unitNumber: 1,
          title: 'Bài 1: Làm quen',
          subtitle: 'Đang học',
          teachingObjective: 'Cơ bản',
          missionCount: 4,
          completedMissionCount: 1,
          mastery: 0.5,
          state: UnitCompletionState.inProgress,
          isUnlocked: true,
          bossAvailable: false,
        ),
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 8,
        pathLoader: (unitId) async => [
          {
            'node_type': 'learning',
            'is_unlocked': true,
            'is_completed': false,
            'game_id': 12,
            'game_name': 'Nhiệm vụ 2',
          }
        ],
      );

      final action = await service.recommend(unitId: 'unit_1');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.review);
      expect(action.actionType, 'review');
      expect(action.reasonCode, 'overdue_review');
      expect(action.canBypass, isTrue);
      expect(action.label, 'ÔN NGAY');
      expect(action.title, contains('8 mục'));
    });

    test(
        'Priority 5: In-progress mission returned with appropriate label for failed node',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: const LearningUnitViewModel(
          id: 'unit_1',
          sectionId: 'sec_1',
          sectionNumber: 1,
          unitNumber: 1,
          title: 'Bài 1: Làm quen',
          subtitle: 'Đang học',
          teachingObjective: 'Cơ bản',
          missionCount: 4,
          completedMissionCount: 1,
          mastery: 0.5,
          state: UnitCompletionState.inProgress,
          isUnlocked: true,
        ),
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 0,
        pathLoader: (unitId) async => [
          {
            'node_type': 'learning',
            'is_unlocked': true,
            'is_completed': false,
            'is_failed': true,
            'game_id': 15,
            'game_name': 'Phát âm thanh mẫu',
          }
        ],
      );

      final action = await service.recommend(unitId: 'unit_1');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.startMission);
      expect(action.gameId, 15);
      expect(action.label, 'THỬ LẠI');
    });

    test('Priority 6: Weak-skill practice suggested from UnitMastery evidence',
        () async {
      final mockProgress = _MockProgressRepository(
        mastery: const UnitMastery(
          overall: 0.65,
          vocabulary: 0.85,
          listening: 0.90,
          speaking: 0.40, // Lowest skill
          hanzi: 0.70,
          masteryThreshold: 0.80,
        ),
      );

      final service = SupabaseLearningRecommendationService(
        progressRepository: mockProgress,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 0,
        pathLoader: (unitId) async => [], // All path missions completed
      );

      final action = await service.recommend(unitId: 'unit_1');

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.practiceWeakness);
      expect(action.reasonCode, 'weak_skill');
      expect(action.destination, contains('speaking'));
      expect(action.title, 'Củng cố Phát âm');
      expect(action.label, 'LUYỆN NGAY');
      expect(action.subtitle, contains('40%'));
    });

    test('New user with zero prior activity gets valid first CTA under 5 min',
        () async {
      final mockJourney = _MockJourneyRepository(
        currentProgress: null,
        sections: [
          const LearningSectionViewModel(
            id: 'sec_1',
            sectionNumber: 1,
            title: 'Khởi đầu',
            subtitle: 'Bước đầu học tiếng Trung',
            unitCount: 3,
            completedUnitCount: 0,
            isUnlocked: true,
          )
        ],
        units: [
          const LearningUnitViewModel(
            id: 'unit_1',
            sectionId: 'sec_1',
            sectionNumber: 1,
            unitNumber: 1,
            title: 'Bài 1: Xin chào',
            subtitle: 'Bắt đầu',
            teachingObjective: 'Học chào hỏi cơ bản',
            missionCount: 3,
            completedMissionCount: 0,
            mastery: 0.0,
            state: UnitCompletionState.inProgress,
            isUnlocked: true,
            estimatedMinutes: 5,
          )
        ],
      );

      final service = SupabaseLearningRecommendationService(
        journeyRepository: mockJourney,
        activeSessionLoader: ({userId, levelId}) async => [],
        overdueCountLoader: () async => 0,
        pathLoader: (unitId) async => [
          {
            'node_type': 'learning',
            'is_unlocked': true,
            'is_completed': false,
            'game_id': 1,
            'game_name': 'Bài 1: Làm quen âm tiết',
          }
        ],
      );

      final action = await service.recommend();

      expect(action, isNotNull);
      expect(action!.type, RecommendedActionType.startMission);
      expect(action.estimatedMinutes, lessThanOrEqualTo(5));
      expect(action.unitId, 'unit_1');
      expect(action.title, 'Bài 1: Làm quen âm tiết');
    });
  });
}

class _MockJourneyRepository implements LearningJourneyRepository {
  _MockJourneyRepository({
    this.currentProgress,
    this.nextUnit,
    this.sections = const [],
    this.units = const [],
  });

  final LearningUnitViewModel? currentProgress;
  final LearningUnitViewModel? nextUnit;
  final List<LearningSectionViewModel> sections;
  final List<LearningUnitViewModel> units;

  @override
  Future<LearningUnitViewModel?> getCurrentProgress() async => currentProgress;

  @override
  Future<LearningUnitViewModel?> getNextUnit(String currentUnitId) async =>
      nextUnit;

  @override
  Future<List<LearningSectionViewModel>> getSections() async => sections;

  @override
  Future<List<LearningUnitViewModel>> getUnits(String sectionId) async => units;

  @override
  Future<LearningNextAction?> getNextAction() async => null;

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async => null;

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockProgressRepository implements LearningProgressRepository {
  _MockProgressRepository({required this.mastery});

  final UnitMastery mastery;

  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) async => mastery;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
