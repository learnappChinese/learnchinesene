import '../../../core/learning/data/learning_journey_repository.dart';
import '../../../core/learning/model/recommended_next_action.dart';
import '../../../core/learning/service/learning_recommendation_service.dart';
import '../../chapter_adventure/data/chapter_adventure_repository.dart';
import '../model/home_journey.dart';

abstract interface class HomeJourneyRepository {
  Future<HomeJourney?> loadJourney();
}

class CloudHomeJourneyRepository implements HomeJourneyRepository {
  CloudHomeJourneyRepository({
    LearningJourneyRepository? journeyRepository,
    ChapterAdventureRepository? chapterRepository,
    LearningRecommendationService? recommendationService,
  })  : _journeyRepository =
            journeyRepository ?? SupabaseLearningJourneyRepository(),
        _chapterRepository =
            chapterRepository ?? SupabaseChapterAdventureRepository(),
        _recommendationService =
            recommendationService ?? SupabaseLearningRecommendationService();

  final LearningJourneyRepository _journeyRepository;
  final ChapterAdventureRepository _chapterRepository;
  final LearningRecommendationService _recommendationService;

  @override
  Future<HomeJourney?> loadJourney() async {
    final unit = await _journeyRepository.getCurrentProgress();
    if (unit == null) return null;

    final chapter = await _chapterRepository.loadChapter(unit.id) ??
        await _journeyRepository.getUnitJourney(unit.id);
    if (chapter == null) return null;

    final completed = chapter.completedMissions;
    final totalMissions = chapter.missions.length;
    final stars = chapter.totalStars;
    final missionIndex =
        chapter.missions.indexWhere((mission) => !mission.isCompleted);
    final currentMission = chapter.missions.isEmpty || missionIndex < 0
        ? null
        : chapter.missions[missionIndex];

    RecommendedNextAction? nextAction;
    try {
      nextAction = await _recommendationService.recommend(
        unitId: chapter.unitId,
        levelId: chapter.levelId,
      );
    } catch (_) {
      // The journey remains usable if an optional recommendation source is
      // temporarily unavailable.
    }

    return HomeJourney(
      gameId: nextAction?.gameId ?? currentMission?.gameId ?? 0,
      gameCode: nextAction?.gameCode ?? currentMission?.gameCode ?? '',
      gameName: 'Hành trình tiếng Trung',
      gameDescription: unit.teachingObjective,
      levelId: nextAction?.levelId ?? chapter.levelId,
      unitId: nextAction?.unitId ?? chapter.unitId,
      worldNumber: chapter.regionNumber,
      chapterNumber: chapter.chapterNumber,
      chapterTitle: chapter.title,
      missionNumber: missionIndex < 0 ? totalMissions : missionIndex + 1,
      missionTitle:
          nextAction?.title ?? currentMission?.title ?? 'Sẵn sàng đánh Boss',
      pathMissionTitle: currentMission?.title ?? 'Sẵn sàng đánh Boss',
      completedMissions: completed,
      totalMissions: totalMissions,
      stars: stars,
      bossProgress: chapter.progress,
      nextRewardXp:
          nextAction?.xpReward ?? (20 + (missionIndex.clamp(0, 4) * 5)),
      recommendation: nextAction?.toLearningRecommendation(),
      nextAction: nextAction,
    );
  }
}
