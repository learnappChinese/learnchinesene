enum LearningRecommendationType {
  activeSession,
  overdueReview,
  weakSkill,
  chapterProgression,
  bossReady,
  newChapter,
}

class LearningRecommendation {
  const LearningRecommendation({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.cta,
    required this.targetId,
    required this.estimatedMinutes,
    required this.rewardPreview,
    this.actionType,
    this.destination,
    this.unitId,
    this.stageId,
    this.reasonCode,
    this.dataVersion = 'v1',
  });

  final LearningRecommendationType type;
  final String title;
  final String subtitle;
  final String reason;
  final String cta;
  final String targetId;
  final int estimatedMinutes;
  final String rewardPreview;

  final String? actionType;
  final String? destination;
  final String? unitId;
  final int? stageId;
  final String? reasonCode;
  final String dataVersion;

  String get label => cta;
}
