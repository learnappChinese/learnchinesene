import 'package:flutter/foundation.dart';
import '../../widgets/adventure_node.dart';
import '../../../screen/boss_battle/model/boss_battle_stage.dart';

/// Semantic activity type for a learning stage / ải.
enum LearningStageActivityType {
  vocabulary,
  hanzi,
  listening,
  sentence,
  speaking,
  dialogue,
  quiz,
  boss,
}

/// An individual learning item / challenge inside a stage / ải.
@immutable
class LearningStageItemViewModel {
  const LearningStageItemViewModel({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.order,
    required this.prompt,
    this.content = const {},
    this.state = AdventureNodeState.available,
    this.score = 0.0,
    this.mastery = 0.0,
    this.isRequired = true,
  });

  /// Unique item identifier
  final String id;

  /// Source ID in database (word id, character id, challenge id, etc.)
  final String sourceId;

  /// Item type (e.g. 'word', 'character', 'listenTap', 'translate', 'speaking')
  final String type;

  /// Display and execution order (1-based)
  final int order;

  /// Human-readable prompt or target text
  final String prompt;

  /// Structured content payload (pinyin, meaning, sentences, audio, etc.)
  final Map<String, dynamic> content;

  /// Completion state of this specific item
  final AdventureNodeState state;

  /// Score (0.0 to 1.0)
  final double score;

  /// Mastery level (0.0 to 1.0)
  final double mastery;

  /// Whether this item is required to clear the stage
  final bool isRequired;

  bool get isCompleted =>
      state == AdventureNodeState.completed ||
      state == AdventureNodeState.perfect;

  LearningStageItemViewModel copyWith({
    String? id,
    String? sourceId,
    String? type,
    int? order,
    String? prompt,
    Map<String, dynamic>? content,
    AdventureNodeState? state,
    double? score,
    double? mastery,
    bool? isRequired,
  }) {
    return LearningStageItemViewModel(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      order: order ?? this.order,
      prompt: prompt ?? this.prompt,
      content: content ?? this.content,
      state: state ?? this.state,
      score: score ?? this.score,
      mastery: mastery ?? this.mastery,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

/// A stage / ải representing a cohesive learning milestone in a Unit.
/// Rendered as a circular node with a dynamic segmented progress ring.
@immutable
class LearningStageViewModel {
  const LearningStageViewModel({
    required this.id,
    required this.unitId,
    this.sourceLevelIds = const [],
    this.sourceSessionIds = const [],
    this.sourceGameId,
    this.sourceGameCode,
    required this.title,
    required this.subtitle,
    required this.activityType,
    required this.learningObjective,
    required this.items,
    this.completedItems = 0,
    this.state = AdventureNodeState.locked,
    this.mastery = 0.0,
    this.stars = 0,
    this.estimatedMinutes = 5,
    this.rewardPreview = '+20 XP • ⭐',
    this.prerequisiteIds = const [],
    this.lockReason,
    this.requiredStageId,
    this.requiredMastery,
    this.isRequired = true,
    this.bossStage,
  });

  /// Unique stage identifier (e.g. 'stage_sec_1_unit_1_vocab')
  final String id;

  /// Parent Unit ID
  final String unitId;

  /// Linked duo_levels IDs
  final List<String> sourceLevelIds;

  /// Linked duo_sessions IDs
  final List<int> sourceSessionIds;

  /// duo_game_definitions.id used by the unified runner/progress pipeline.
  final int? sourceGameId;

  /// duo_game_definitions.game_code used to resolve the exact gameplay.
  final String? sourceGameCode;

  /// Display title (e.g. 'Ải 1: Từ vựng ẩm thực')
  final String title;

  /// Descriptive subtitle (e.g. 'Học 10 từ vựng cốt lõi')
  final String subtitle;

  /// Semantic activity type
  final LearningStageActivityType activityType;

  /// Educational objective
  final String learningObjective;

  /// The list of items belonging to this stage.
  /// IMPORTANT: totalItems is derived dynamically from items.length!
  final List<LearningStageItemViewModel> items;

  /// Number of completed items in this stage
  final int completedItems;

  /// Progression state of the stage
  final AdventureNodeState state;

  /// Quality/mastery score (0.0 to 1.0)
  final double mastery;

  /// Quality rating in stars (0 to 3), independent from segment count
  final int stars;

  /// Estimated learning time in minutes
  final int estimatedMinutes;

  /// Reward preview badge text
  final String rewardPreview;

  /// Prerequisite stage IDs required to unlock this stage
  final List<String> prerequisiteIds;

  /// Server-provided reason. Presentation code maps it to friendly copy.
  final String? lockReason;

  /// Server-provided dependency node, if the lock is dependency based.
  final String? requiredStageId;

  /// Server-provided mastery threshold, if the lock is mastery based.
  final double? requiredMastery;

  /// Whether clearing this stage is required to reach the Unit Boss
  final bool isRequired;

  /// Boss stage data if this is a Boss stage
  final BossBattleStage? bossStage;

  /// Dynamic total items count - strictly derived from data!
  int get totalItems => items.length;

  /// Number of required items
  int get requiredItemsCount => items.where((i) => i.isRequired).length;

  /// Required items list
  List<LearningStageItemViewModel> get requiredItems =>
      items.where((i) => i.isRequired).toList();

  /// Number of completed required items
  int get completedRequiredCount =>
      items.where((i) => i.isRequired && i.isCompleted).length;

  /// Whether all required items are completed
  bool get areRequiredItemsCompleted =>
      requiredItemsCount == 0 || completedRequiredCount >= requiredItemsCount;

  /// Number of optional items
  int get optionalItemsCount => items.where((i) => !i.isRequired).length;

  /// Optional items list
  List<LearningStageItemViewModel> get optionalItems =>
      items.where((i) => !i.isRequired).toList();

  /// Number of completed optional items
  int get completedOptionalCount =>
      items.where((i) => !i.isRequired && i.isCompleted).length;

  /// Stage progress fraction (0.0 to 1.0) based on required items
  double get progress {
    if (requiredItemsCount == 0) {
      return totalItems == 0
          ? 0.0
          : (completedItems / totalItems).clamp(0.0, 1.0);
    }
    return (completedRequiredCount / requiredItemsCount).clamp(0.0, 1.0);
  }

  /// Whether this stage is completed
  bool get isCompleted =>
      state == AdventureNodeState.completed ||
      state == AdventureNodeState.perfect;

  /// Whether this stage is currently available to start
  bool get isAvailable =>
      state == AdventureNodeState.available ||
      state == AdventureNodeState.inProgress ||
      state == AdventureNodeState.failed;

  /// Whether this stage is locked
  bool get isLocked => state == AdventureNodeState.locked;

  LearningStageViewModel copyWith({
    String? id,
    String? unitId,
    List<String>? sourceLevelIds,
    List<int>? sourceSessionIds,
    int? sourceGameId,
    String? sourceGameCode,
    String? title,
    String? subtitle,
    LearningStageActivityType? activityType,
    String? learningObjective,
    List<LearningStageItemViewModel>? items,
    int? completedItems,
    AdventureNodeState? state,
    double? mastery,
    int? stars,
    int? estimatedMinutes,
    String? rewardPreview,
    List<String>? prerequisiteIds,
    String? lockReason,
    String? requiredStageId,
    double? requiredMastery,
    bool? isRequired,
    BossBattleStage? bossStage,
  }) {
    return LearningStageViewModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      sourceLevelIds: sourceLevelIds ?? this.sourceLevelIds,
      sourceSessionIds: sourceSessionIds ?? this.sourceSessionIds,
      sourceGameId: sourceGameId ?? this.sourceGameId,
      sourceGameCode: sourceGameCode ?? this.sourceGameCode,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      activityType: activityType ?? this.activityType,
      learningObjective: learningObjective ?? this.learningObjective,
      items: items ?? this.items,
      completedItems: completedItems ?? this.completedItems,
      state: state ?? this.state,
      mastery: mastery ?? this.mastery,
      stars: stars ?? this.stars,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      rewardPreview: rewardPreview ?? this.rewardPreview,
      prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
      lockReason: lockReason ?? this.lockReason,
      requiredStageId: requiredStageId ?? this.requiredStageId,
      requiredMastery: requiredMastery ?? this.requiredMastery,
      isRequired: isRequired ?? this.isRequired,
      bossStage: bossStage ?? this.bossStage,
    );
  }
}
