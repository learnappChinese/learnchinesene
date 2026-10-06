enum UnitLearningNodeState {
  locked,
  available,
  inProgress,
  completed,
}

class UnitLearningNode {
  const UnitLearningNode({
    required this.nodeType,
    required this.nodeOrder,
    required this.unitId,
    required this.unitTitle,
    required this.sectionNumber,
    required this.unitNumber,
    required this.levelId,
    required this.levelIndex,
    required this.gameId,
    required this.gameCode,
    required this.gameName,
    required this.gameDescription,
    required this.gameIcon,
    required this.challengeCount,
    required this.attempts,
    required this.bestScore,
    required this.stars,
    required this.rawUnlocked,
    required this.completed,
    required this.inProgress,
    required this.currentIndex,
    required this.bossStageId,
    required this.bossName,
    required this.bossHp,
    required this.playerHp,
    required this.difficulty,
    this.state = UnitLearningNodeState.locked,
  });

  final String nodeType;
  final int nodeOrder;
  final String unitId;
  final String unitTitle;
  final int sectionNumber;
  final int unitNumber;
  final String? levelId;
  final int? levelIndex;
  final int? gameId;
  final String gameCode;
  final String gameName;
  final String gameDescription;
  final String gameIcon;
  final int challengeCount;
  final int attempts;
  final int bestScore;
  final int stars;
  final bool rawUnlocked;
  final bool completed;
  final bool inProgress;
  final int currentIndex;
  final int? bossStageId;
  final String? bossName;
  final int? bossHp;
  final int? playerHp;
  final int? difficulty;
  final UnitLearningNodeState state;

  bool get isBoss => nodeType == 'boss';
  bool get isLocked => state == UnitLearningNodeState.locked;
  bool get isPlayable => !isLocked;

  double get sessionProgress {
    if (completed) return 1;
    if (challengeCount <= 0) return 0;
    return ((currentIndex + 1) / challengeCount).clamp(0.0, 1.0);
  }

  factory UnitLearningNode.fromMap(Map<String, dynamic> map) {
    int asInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    return UnitLearningNode(
      nodeType: '${map['node_type'] ?? 'learning'}',
      nodeOrder: asInt(map['node_order']),
      unitId: '${map['unit_id'] ?? ''}',
      unitTitle: '${map['unit_title'] ?? ''}',
      sectionNumber: asInt(map['section_number']),
      unitNumber: asInt(map['unit_number']),
      levelId: map['level_id']?.toString(),
      levelIndex: asNullableInt(map['level_index']),
      gameId: asNullableInt(map['game_id']),
      gameCode: '${map['game_code'] ?? ''}',
      gameName: '${map['game_name'] ?? ''}',
      gameDescription: '${map['game_description'] ?? ''}',
      gameIcon: '${map['game_icon'] ?? '🎯'}',
      challengeCount: asInt(map['challenge_count']),
      attempts: asInt(map['attempts']),
      bestScore: asInt(map['best_score']),
      stars: asInt(map['stars']).clamp(0, 3).toInt(),
      rawUnlocked: map['is_unlocked'] == true,
      completed: map['is_completed'] == true,
      inProgress: map['in_progress'] == true,
      currentIndex: asInt(map['current_index']),
      bossStageId: asNullableInt(map['boss_stage_id']),
      bossName: map['boss_name']?.toString(),
      bossHp: asNullableInt(map['boss_hp']),
      playerHp: asNullableInt(map['player_hp']),
      difficulty: asNullableInt(map['difficulty']),
    );
  }

  UnitLearningNode copyWith({
    UnitLearningNodeState? state,
  }) {
    return UnitLearningNode(
      nodeType: nodeType,
      nodeOrder: nodeOrder,
      unitId: unitId,
      unitTitle: unitTitle,
      sectionNumber: sectionNumber,
      unitNumber: unitNumber,
      levelId: levelId,
      levelIndex: levelIndex,
      gameId: gameId,
      gameCode: gameCode,
      gameName: gameName,
      gameDescription: gameDescription,
      gameIcon: gameIcon,
      challengeCount: challengeCount,
      attempts: attempts,
      bestScore: bestScore,
      stars: stars,
      rawUnlocked: rawUnlocked,
      completed: completed,
      inProgress: inProgress,
      currentIndex: currentIndex,
      bossStageId: bossStageId,
      bossName: bossName,
      bossHp: bossHp,
      playerHp: playerHp,
      difficulty: difficulty,
      state: state ?? this.state,
    );
  }
}
