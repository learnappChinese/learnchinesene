class BossBattleStage {
  const BossBattleStage({
    required this.id,
    required this.unitId,
    required this.stageOrder,
    required this.sectionNumber,
    required this.unitNumber,
    required this.title,
    required this.questionCount,
    required this.difficulty,
    required this.bossName,
    required this.bossHp,
    required this.playerHp,
    required this.themeCode,
  });

  final int id;
  final String unitId;
  final int stageOrder;
  final int sectionNumber;
  final int unitNumber;
  final String title;
  final int questionCount;
  final int difficulty;
  final String bossName;
  final int bossHp;
  final int playerHp;
  final String themeCode;

  String get label => 'Cửa $stageOrder';

  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Tân thủ';
      case 2:
        return 'Thử thách';
      case 3:
        return 'Khó';
      case 4:
        return 'Rất khó';
      default:
        return 'Huyền thoại';
    }
  }

  factory BossBattleStage.fromMap(Map<String, dynamic> map) {
    int asInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    return BossBattleStage(
      id: asInt(map['id']),
      unitId: '${map['unit_id'] ?? ''}',
      stageOrder: asInt(map['stage_order']),
      sectionNumber: asInt(map['section_number']),
      unitNumber: asInt(map['unit_number']),
      title: '${map['title'] ?? ''}'.trim(),
      questionCount: asInt(map['question_count'], 4),
      difficulty: asInt(map['difficulty'], 1).clamp(1, 5).toInt(),
      bossName: '${map['boss_name'] ?? 'Rồng Lửa'}'.trim(),
      bossHp: asInt(map['boss_hp'], 100),
      playerHp: asInt(map['player_hp'], 100),
      themeCode: '${map['theme_code'] ?? 'sunset'}'.trim(),
    );
  }
}
