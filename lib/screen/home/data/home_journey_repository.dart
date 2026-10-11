import '../../chapter_adventure/data/chapter_adventure_repository.dart';
import '../../duolingo/controller/duo_game_repository.dart';
import '../model/home_journey.dart';

abstract interface class HomeJourneyRepository {
  Future<HomeJourney?> loadJourney();
}

class CloudHomeJourneyRepository implements HomeJourneyRepository {
  CloudHomeJourneyRepository({
    DuoGameRepository? gameRepository,
    ChapterAdventureRepository? chapterRepository,
  })  : _gameRepository = gameRepository ?? DuoGameRepository.instance,
        _chapterRepository =
            chapterRepository ?? SupabaseChapterAdventureRepository();

  final DuoGameRepository _gameRepository;
  final ChapterAdventureRepository _chapterRepository;

  @override
  Future<HomeJourney?> loadJourney() async {
    final games = await _gameRepository.getGames();
    if (games.isEmpty) return null;

    final game = games.first;
    final gameId = (game['id'] as num?)?.toInt() ?? 0;
    final gameCode = '${game['game_code'] ?? ''}';
    final levels = await _gameRepository.getGameLevels(gameId, gameCode);
    final playable = levels.where(_isPlayable).toList();
    if (playable.isEmpty) return null;

    final activeIndex = playable.indexWhere(
      (level) => level['is_unlocked'] == 1 && level['is_completed'] != 1,
    );
    final index = activeIndex < 0 ? playable.length - 1 : activeIndex;
    final active = playable[index];
    final levelId = '${active['level_id'] ?? ''}';
    final chapter = await _chapterRepository.loadChapter(levelId);
    final completed = chapter?.completedMissions ?? 0;
    final totalMissions = chapter?.missions.length ?? 1;
    final stars = chapter?.totalStars ?? 0;
    final missionIndex =
        chapter?.missions.indexWhere((mission) => !mission.isCompleted) ?? 0;
    final currentMission =
        chapter == null || chapter.missions.isEmpty || missionIndex < 0
            ? null
            : chapter.missions[missionIndex];

    return HomeJourney(
      gameId: gameId,
      gameCode: gameCode,
      gameName: '${game['name_vi'] ?? 'Hành trình tiếng Trung'}',
      gameDescription: '${game['description_vi'] ?? ''}',
      levelId: levelId,
      worldNumber: (active['section_number'] as num?)?.toInt() ?? 1,
      chapterNumber: chapter?.chapterNumber ??
          (active['unit_number'] as num?)?.toInt() ??
          1,
      chapterTitle: chapter?.title ?? '${active['unit_title'] ?? 'Chương mới'}',
      missionNumber: missionIndex < 0 ? totalMissions : missionIndex + 1,
      missionTitle: currentMission?.title ?? 'Sẵn sàng đánh Boss',
      completedMissions: completed,
      totalMissions: totalMissions,
      stars: stars,
      bossProgress: chapter?.progress ?? 0,
      nextRewardXp: 20 + (missionIndex.clamp(0, 4) * 5),
    );
  }

  bool _isPlayable(Map<String, dynamic> level) =>
      ((level['challenge_count'] as num?)?.toInt() ?? 0) > 0;
}
