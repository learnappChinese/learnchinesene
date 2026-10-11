import 'package:flutter/foundation.dart';
import 'learning_result.dart';

/// Actions that a learner can take after finishing, failing, or pausing a learning session.
enum LearningNavigationAction {
  completed,
  failed,
  paused,
  abandoned,
  cancelled,
  retry,
  nextMission,
  fightBoss,
  nextUnit,
}

/// A typed navigation result returned when leaving a learning screen
/// (Duo game, Boss battle, Writing, Speaking, Unit complete).
@immutable
class LearningNavigationOutcome {
  const LearningNavigationOutcome({
    required this.action,
    this.result,
    this.nextNodeId,
    this.nextUnitId,
    this.metadata = const <String, dynamic>{},
  });

  /// The outcome action.
  final LearningNavigationAction action;

  /// The authoritative [LearningResult] if completion/evaluation was performed.
  final LearningResult? result;

  /// Identifier for the next stage/challenge/node (e.g., 'gameId:levelId' or 'boss:stageId').
  final String? nextNodeId;

  /// Identifier for the next Unit if the current unit was completed.
  final String? nextUnitId;

  /// Additional payload metadata.
  final Map<String, dynamic> metadata;

  /// Whether this outcome represents a successful completion or positive forward movement.
  bool get isSuccess =>
      action == LearningNavigationAction.completed ||
      action == LearningNavigationAction.nextMission ||
      action == LearningNavigationAction.fightBoss ||
      action == LearningNavigationAction.nextUnit ||
      (result != null && result!.passed);

  bool get isFailed =>
      action == LearningNavigationAction.failed ||
      (result != null && result!.failed);

  bool get isRetry => action == LearningNavigationAction.retry;
  bool get isPaused => action == LearningNavigationAction.paused;
  bool get isAbandoned => action == LearningNavigationAction.abandoned;
  bool get isCancelled => action == LearningNavigationAction.cancelled;
  bool get isFightBoss => action == LearningNavigationAction.fightBoss;
  bool get isNextUnit => action == LearningNavigationAction.nextUnit;

  /// Convenience factory for a successful completion.
  factory LearningNavigationOutcome.completed({
    LearningResult? result,
    String? nextNodeId,
    String? nextUnitId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.completed,
        result: result,
        nextNodeId: nextNodeId ?? result?.nextNodeId,
        nextUnitId: nextUnitId ?? result?.nextUnitId,
        metadata: metadata,
      );

  /// Convenience factory for a failed attempt.
  factory LearningNavigationOutcome.failed({
    LearningResult? result,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.failed,
        result: result,
        metadata: metadata,
      );

  /// Convenience factory for a retry action.
  factory LearningNavigationOutcome.retry({
    LearningResult? result,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.retry,
        result: result,
        metadata: metadata,
      );

  /// Convenience factory for moving to the next mission.
  factory LearningNavigationOutcome.nextMission({
    LearningResult? result,
    String? nextNodeId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.nextMission,
        result: result,
        nextNodeId: nextNodeId ?? result?.nextNodeId,
        metadata: metadata,
      );

  /// Convenience factory for engaging the Unit Boss.
  factory LearningNavigationOutcome.fightBoss({
    LearningResult? result,
    String? bossStageId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.fightBoss,
        result: result,
        nextNodeId: bossStageId ?? result?.nextNodeId,
        metadata: metadata,
      );

  /// Convenience factory for proceeding to the next Unit.
  factory LearningNavigationOutcome.nextUnit({
    LearningResult? result,
    String? nextUnitId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.nextUnit,
        result: result,
        nextUnitId: nextUnitId ?? result?.nextUnitId,
        metadata: metadata,
      );

  /// Convenience factory for pausing the session.
  factory LearningNavigationOutcome.paused({
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.paused,
        metadata: metadata,
      );

  /// Convenience factory for abandoning the attempt.
  factory LearningNavigationOutcome.abandoned({
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.abandoned,
        metadata: metadata,
      );

  /// Convenience factory for cancelling out of the screen.
  factory LearningNavigationOutcome.cancelled({
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      LearningNavigationOutcome(
        action: LearningNavigationAction.cancelled,
        metadata: metadata,
      );

  @override
  String toString() =>
      'LearningNavigationOutcome(action: $action, isSuccess: $isSuccess, nextNode: $nextNodeId, nextUnit: $nextUnitId)';
}
