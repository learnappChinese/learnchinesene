import '../../../core/widgets/adventure_node.dart';
import '../../boss_battle/model/boss_battle_stage.dart';

class ChapterAdventure {
  const ChapterAdventure({
    required this.levelId,
    required this.unitId,
    required this.regionNumber,
    required this.chapterNumber,
    required this.title,
    required this.objective,
    required this.missions,
    this.boss,
  });

  final String levelId;
  final String unitId;
  final int regionNumber;
  final int chapterNumber;
  final String title;
  final String objective;
  final List<ChapterMission> missions;
  final BossBattleStage? boss;

  int get completedMissions =>
      missions.where((mission) => mission.isCompleted).length;

  int get totalStars =>
      missions.fold(0, (total, mission) => total + mission.stars);

  double get progress =>
      missions.isEmpty ? 0 : completedMissions / missions.length;

  bool get bossUnlocked =>
      missions.isNotEmpty && completedMissions == missions.length;
}

class ChapterMission {
  const ChapterMission({
    required this.gameId,
    required this.gameCode,
    required this.title,
    required this.description,
    required this.type,
    required this.state,
    required this.stars,
  });

  final int gameId;
  final String gameCode;
  final String title;
  final String description;
  final AdventureNodeType type;
  final AdventureNodeState state;
  final int stars;

  bool get isCompleted =>
      state == AdventureNodeState.completed ||
      state == AdventureNodeState.perfect;
}
