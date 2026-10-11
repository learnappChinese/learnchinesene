import 'package:flutter/foundation.dart';
import '../../widgets/adventure_node.dart';
import 'unit_mastery.dart';

enum LearningActionType {
  activeSession,
  continueMission,
  reviewOverdue,
  fightBoss,
  nextUnit,
  startUnit,
}

@immutable
class LearningSectionViewModel {
  const LearningSectionViewModel({
    required this.id,
    required this.sectionNumber,
    required this.title,
    required this.subtitle,
    required this.unitCount,
    required this.completedUnitCount,
    required this.isUnlocked,
    this.units = const [],
  });

  final String id;
  final int sectionNumber;
  final String title;
  final String subtitle;
  final int unitCount;
  final int completedUnitCount;
  final bool isUnlocked;
  final List<LearningUnitViewModel> units;

  double get progress =>
      unitCount == 0 ? 0.0 : (completedUnitCount / unitCount).clamp(0.0, 1.0);

  bool get isCompleted => completedUnitCount >= unitCount && unitCount > 0;

  LearningSectionViewModel copyWith({
    String? id,
    int? sectionNumber,
    String? title,
    String? subtitle,
    int? unitCount,
    int? completedUnitCount,
    bool? isUnlocked,
    List<LearningUnitViewModel>? units,
  }) {
    return LearningSectionViewModel(
      id: id ?? this.id,
      sectionNumber: sectionNumber ?? this.sectionNumber,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      unitCount: unitCount ?? this.unitCount,
      completedUnitCount: completedUnitCount ?? this.completedUnitCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      units: units ?? this.units,
    );
  }
}

@immutable
class LearningUnitViewModel {
  const LearningUnitViewModel({
    required this.id,
    required this.sectionId,
    required this.sectionNumber,
    required this.unitNumber,
    required this.title,
    required this.subtitle,
    this.teachingObjective = '',
    required this.missionCount,
    required this.completedMissionCount,
    this.mastery = 0.0,
    this.state = UnitCompletionState.inProgress,
    this.isUnlocked = false,
    this.bossAvailable = false,
    this.bossWon = false,
    this.bossStageId,
    this.bossName,
    this.estimatedMinutes = 15,
    this.lockReason,
  });

  final String id;
  final String sectionId;
  final int sectionNumber;
  final int unitNumber;
  final String title;
  final String subtitle;
  final String teachingObjective;
  final int missionCount;
  final int completedMissionCount;
  final double mastery;
  final UnitCompletionState state;
  final bool isUnlocked;
  final bool bossAvailable;
  final bool bossWon;
  final int? bossStageId;
  final String? bossName;
  final int estimatedMinutes;
  final String? lockReason;

  double get progress => missionCount == 0
      ? 0.0
      : (completedMissionCount / missionCount).clamp(0.0, 1.0);

  bool get isCompleted => state == UnitCompletionState.completed || bossWon;

  bool get inProgress =>
      isUnlocked && !isCompleted && completedMissionCount > 0;

  LearningUnitViewModel copyWith({
    String? id,
    String? sectionId,
    int? sectionNumber,
    int? unitNumber,
    String? title,
    String? subtitle,
    String? teachingObjective,
    int? missionCount,
    int? completedMissionCount,
    double? mastery,
    UnitCompletionState? state,
    bool? isUnlocked,
    bool? bossAvailable,
    bool? bossWon,
    int? bossStageId,
    String? bossName,
    int? estimatedMinutes,
    String? lockReason,
  }) {
    return LearningUnitViewModel(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      sectionNumber: sectionNumber ?? this.sectionNumber,
      unitNumber: unitNumber ?? this.unitNumber,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      teachingObjective: teachingObjective ?? this.teachingObjective,
      missionCount: missionCount ?? this.missionCount,
      completedMissionCount:
          completedMissionCount ?? this.completedMissionCount,
      mastery: mastery ?? this.mastery,
      state: state ?? this.state,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      bossAvailable: bossAvailable ?? this.bossAvailable,
      bossWon: bossWon ?? this.bossWon,
      bossStageId: bossStageId ?? this.bossStageId,
      bossName: bossName ?? this.bossName,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      lockReason: lockReason ?? this.lockReason,
    );
  }
}

@immutable
class LearningMissionViewModel {
  const LearningMissionViewModel({
    required this.gameId,
    required this.gameCode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.state,
    required this.stars,
    this.bestScore = 0,
    this.attempts = 0,
    this.currentIndex = 0,
    this.currentTotal = 0,
    this.challengeCount = 0,
    this.lockReason,
    this.levelId,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.inProgress = false,
  });

  final int gameId;
  final String gameCode;
  final String title;
  final String subtitle;
  final String icon;
  final AdventureNodeType type;
  final AdventureNodeState state;
  final int stars;
  final int bestScore;
  final int attempts;
  final int currentIndex;
  final int currentTotal;
  final int challengeCount;
  final String? lockReason;
  final String? levelId;
  final bool isUnlocked;
  final bool isCompleted;
  final bool inProgress;
}

@immutable
class LearningNextAction {
  const LearningNextAction({
    required this.type,
    required this.unitId,
    required this.sectionNumber,
    required this.unitNumber,
    required this.sectionTitle,
    required this.unitTitle,
    required this.missionTitle,
    this.gameId,
    this.gameCode,
    this.levelId,
    required this.label,
    required this.description,
    this.xpReward = 20,
    this.currentIndex = 0,
    this.currentTotal = 0,
  });

  final LearningActionType type;
  final String unitId;
  final int sectionNumber;
  final int unitNumber;
  final String sectionTitle;
  final String unitTitle;
  final String missionTitle;
  final int? gameId;
  final String? gameCode;
  final String? levelId;
  final String label;
  final String description;
  final int xpReward;
  final int currentIndex;
  final int currentTotal;
}
