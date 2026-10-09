enum UnitCompletionState { inProgress, bossPending, completed }

class UnitMastery {
  const UnitMastery({
    this.vocabulary,
    this.listening,
    this.speaking,
    this.hanzi,
    this.overall = 0,
    this.allRequiredMissionsPassed = false,
    this.masteryThreshold = .70,
    this.bossRequired = false,
    this.bossAvailable = false,
    this.bossWon = false,
    this.state = UnitCompletionState.inProgress,
  });

  final double? vocabulary;
  final double? listening;
  final double? speaking;
  final double? hanzi;
  final double overall;
  final bool allRequiredMissionsPassed;
  final double masteryThreshold;
  final bool bossRequired;
  final bool bossAvailable;
  final bool bossWon;
  final UnitCompletionState state;

  factory UnitMastery.fromMap(Map<String, dynamic> map) {
    double? score(String key) => (map[key] as num?)?.toDouble();

    return UnitMastery(
      vocabulary: score('vocabulary_mastery'),
      listening: score('listening_mastery'),
      speaking: score('speaking_mastery'),
      hanzi: score('hanzi_mastery'),
      overall: score('overall_mastery') ?? 0,
      allRequiredMissionsPassed: map['all_required_missions_passed'] == true,
      masteryThreshold: score('mastery_threshold') ?? .70,
      bossRequired: map['boss_required'] == true,
      bossAvailable: map['boss_available'] == true,
      bossWon: map['boss_won'] == true,
      state: switch ('${map['unit_state'] ?? ''}') {
        'boss_pending' => UnitCompletionState.bossPending,
        'completed' => UnitCompletionState.completed,
        _ => UnitCompletionState.inProgress,
      },
    );
  }
}
