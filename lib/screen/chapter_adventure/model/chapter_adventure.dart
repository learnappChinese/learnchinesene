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
    this.overallMastery = 0,
    this.bossUnlocked = false,
    this.bossLockReason,
    this.bossRequiredNodeId,
    this.bossRequiredMastery,
    this.boss,
  });

  final String levelId;
  final String unitId;
  final int regionNumber;
  final int chapterNumber;
  final String title;
  final String objective;
  final List<ChapterMission> missions;
  final double overallMastery;
  final bool bossUnlocked;
  final String? bossLockReason;
  final String? bossRequiredNodeId;
  final double? bossRequiredMastery;
  final BossBattleStage? boss;

  int get completedMissions =>
      missions.where((mission) => mission.isCompleted).length;

  int get totalStars =>
      missions.fold(0, (total, mission) => total + mission.stars);

  double get progress =>
      missions.isEmpty ? 0 : completedMissions / missions.length;
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
    this.attempts = 0,
    this.bestScore = 0,
    this.currentIndex = 0,
    this.currentTotal = 0,
    this.lockReason,
    this.requiredNodeId,
    this.requiredMastery,
  });

  final int gameId;
  final String gameCode;
  final String title;
  final String description;
  final AdventureNodeType type;
  final AdventureNodeState state;
  final int stars;
  final int attempts;
  final int bestScore;
  final int currentIndex;
  final int currentTotal;
  final String? lockReason;
  final String? requiredNodeId;
  final double? requiredMastery;

  bool get isCompleted =>
      state == AdventureNodeState.completed ||
      state == AdventureNodeState.perfect;
}
