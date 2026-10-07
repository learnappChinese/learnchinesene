class HomeJourney {
  const HomeJourney({
    required this.gameId,
    required this.gameCode,
    required this.gameName,
    required this.gameDescription,
    required this.levelId,
    required this.worldNumber,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.missionNumber,
    required this.missionTitle,
    required this.completedMissions,
    required this.totalMissions,
    required this.stars,
    required this.bossProgress,
    required this.nextRewardXp,
  });

  final int gameId;
  final String gameCode;
  final String gameName;
  final String gameDescription;
  final String levelId;
  final int worldNumber;
  final int chapterNumber;
  final String chapterTitle;
  final int missionNumber;
  final String missionTitle;
  final int completedMissions;
  final int totalMissions;
  final int stars;
  final double bossProgress;
  final int nextRewardXp;

  double get chapterProgress =>
      totalMissions == 0 ? 0 : completedMissions / totalMissions;
}
