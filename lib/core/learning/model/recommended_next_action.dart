import 'package:flutter/foundation.dart';

import 'learning_journey_models.dart';
import 'learning_recommendation.dart';

enum RecommendedActionType {
  resume,
  startMission,
  fightBoss,
  review,
  practiceWeakness,
  nextUnit,
  explore;

  String get code => switch (this) {
        RecommendedActionType.resume => 'resume',
        RecommendedActionType.startMission => 'start_mission',
        RecommendedActionType.fightBoss => 'fight_boss',
        RecommendedActionType.review => 'review',
        RecommendedActionType.practiceWeakness => 'practice_weakness',
        RecommendedActionType.nextUnit => 'next_unit',
        RecommendedActionType.explore => 'explore',
      };
}

@immutable
class RecommendedNextAction {
  const RecommendedNextAction({
    required this.type,
    String? actionType,
    required this.destination,
    this.unitId,
    this.stageId,
    this.gameId,
    this.gameCode,
    this.levelId,
    this.sectionNumber,
    this.unitNumber,
    required this.reasonCode,
    required this.label,
    required this.title,
    this.subtitle = '',
    this.description = '',
    required this.estimatedMinutes,
    this.dataVersion = 'v1',
    this.xpReward = 20,
    this.currentIndex = 0,
    this.currentTotal = 0,
    this.rewardPreview = '',
    this.canBypass = true,
    this.metadata = const <String, dynamic>{},
  }) : _actionType = actionType;

  final RecommendedActionType type;
  final String? _actionType;
  String get actionType => _actionType ?? type.code;
  final String destination;
  final String? unitId;
  final int? stageId;
  final int? gameId;
  final String? gameCode;
  final String? levelId;
  final int? sectionNumber;
  final int? unitNumber;
  final String reasonCode;
  final String label;
  final String title;
  final String subtitle;
  final String description;
  final int estimatedMinutes;
  final String dataVersion;
  final int xpReward;
  final int currentIndex;
  final int currentTotal;
  final String rewardPreview;
  final bool canBypass;
  final Map<String, dynamic> metadata;

  /// Helper to convert to legacy LearningRecommendation.
  LearningRecommendation toLearningRecommendation() => LearningRecommendation(
        type: switch (type) {
          RecommendedActionType.resume =>
            LearningRecommendationType.activeSession,
          RecommendedActionType.startMission =>
            LearningRecommendationType.chapterProgression,
          RecommendedActionType.fightBoss =>
            LearningRecommendationType.bossReady,
          RecommendedActionType.review =>
            LearningRecommendationType.overdueReview,
          RecommendedActionType.practiceWeakness =>
            LearningRecommendationType.weakSkill,
          RecommendedActionType.nextUnit =>
            LearningRecommendationType.newChapter,
          RecommendedActionType.explore =>
            LearningRecommendationType.newChapter,
        },
        title: title,
        subtitle: subtitle.isNotEmpty ? subtitle : description,
        reason: description.isNotEmpty ? description : reasonCode,
        cta: label,
        targetId: destination,
        estimatedMinutes: estimatedMinutes,
        rewardPreview:
            rewardPreview.isNotEmpty ? rewardPreview : '+$xpReward XP',
        actionType: actionType,
        destination: destination,
        unitId: unitId,
        stageId: stageId,
        reasonCode: reasonCode,
        dataVersion: dataVersion,
      );

  /// Helper to convert to legacy LearningNextAction.
  LearningNextAction toLearningNextAction() => LearningNextAction(
        type: switch (type) {
          RecommendedActionType.resume => LearningActionType.activeSession,
          RecommendedActionType.startMission =>
            LearningActionType.continueMission,
          RecommendedActionType.fightBoss => LearningActionType.fightBoss,
          RecommendedActionType.review => LearningActionType.reviewOverdue,
          RecommendedActionType.nextUnit => LearningActionType.nextUnit,
          _ => LearningActionType.startUnit,
        },
        unitId: unitId ?? '',
        sectionNumber: sectionNumber ?? 1,
        unitNumber: unitNumber ?? 1,
        sectionTitle: metadata['sectionTitle'] as String? ?? 'Lộ trình',
        unitTitle: metadata['unitTitle'] as String? ?? title,
        missionTitle: title,
        gameId: gameId,
        gameCode: gameCode,
        levelId: levelId,
        label: label,
        description: description.isNotEmpty ? description : subtitle,
        xpReward: xpReward,
        currentIndex: currentIndex,
        currentTotal: currentTotal,
      );
}
