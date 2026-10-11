import 'package:flutter/foundation.dart';
import '../../widgets/adventure_node.dart';

/// Context used by [MissionStateMachine] to evaluate state transitions.
@immutable
class MissionTransitionContext {
  const MissionTransitionContext({
    this.isPrerequisiteMet = true,
    this.previousState = AdventureNodeState.locked,
    this.passed = false,
    this.score = 0.0,
    this.stars = 0,
    this.isReplay = false,
    this.isFirstClear = true,
    this.mastery = 0.0,
    this.requiredMastery = 0.70,
    this.lockReason,
  });

  final bool isPrerequisiteMet;
  final AdventureNodeState previousState;
  final bool passed;
  final double score;
  final int stars;
  final bool isReplay;
  final bool isFirstClear;
  final double mastery;
  final double requiredMastery;
  final String? lockReason;
}

/// Result of evaluating a state transition.
@immutable
class MissionTransitionResult {
  const MissionTransitionResult({
    required this.allowed,
    required this.newState,
    this.reason,
    this.preservedPrevious = false,
    this.awardFirstClearXp = false,
  });

  final bool allowed;
  final AdventureNodeState newState;
  final String? reason;
  final bool preservedPrevious;
  final bool awardFirstClearXp;

  factory MissionTransitionResult.rejected(
          String reason, AdventureNodeState currentState) =>
      MissionTransitionResult(
        allowed: false,
        newState: currentState,
        reason: reason,
      );

  factory MissionTransitionResult.ok(
    AdventureNodeState newState, {
    String? reason,
    bool preservedPrevious = false,
    bool awardFirstClearXp = false,
  }) =>
      MissionTransitionResult(
        allowed: true,
        newState: newState,
        reason: reason,
        preservedPrevious: preservedPrevious,
        awardFirstClearXp: awardFirstClearXp,
      );
}

/// Standardized Mission State Machine for learning nodes in Chinese Learning Adventure.
///
/// States:
/// - [AdventureNodeState.locked]
/// - [AdventureNodeState.available]
/// - [AdventureNodeState.inProgress]
/// - [AdventureNodeState.paused]
/// - [AdventureNodeState.failed]
/// - [AdventureNodeState.completed]
/// - [AdventureNodeState.perfect]
class MissionStateMachine {
  const MissionStateMachine._();

  /// Evaluates transitioning from [current] to [target] with [context].
  static MissionTransitionResult transition({
    required AdventureNodeState current,
    required AdventureNodeState target,
    required MissionTransitionContext context,
  }) {
    switch (target) {
      case AdventureNodeState.locked:
        if (!context.isPrerequisiteMet) {
          return MissionTransitionResult.ok(
            AdventureNodeState.locked,
            reason:
                context.lockReason ?? 'Chưa hoàn thành điều kiện tiên quyết.',
          );
        }
        return MissionTransitionResult.rejected(
            'Không thể khóa lại màn đã mở khi điều kiện tiên quyết vẫn thỏa.',
            current);

      case AdventureNodeState.available:
        if (!context.isPrerequisiteMet) {
          return MissionTransitionResult.rejected(
              'Không thể mở màn khi điều kiện tiên quyết chưa đạt.', current);
        }
        if (current == AdventureNodeState.completed ||
            current == AdventureNodeState.perfect) {
          return MissionTransitionResult.rejected(
              'Màn đã hoàn thành không hạ cấp về available.', current);
        }
        return MissionTransitionResult.ok(AdventureNodeState.available);

      case AdventureNodeState.inProgress:
        if (current == AdventureNodeState.locked) {
          return MissionTransitionResult.rejected(
              'Màn đang bị khóa, không thể bắt đầu học.', current);
        }
        // Allowed from available, failed (retry), completed/perfect (replay), paused (resume)
        return MissionTransitionResult.ok(
          AdventureNodeState.inProgress,
          preservedPrevious: current == AdventureNodeState.completed ||
              current == AdventureNodeState.perfect,
        );

      case AdventureNodeState.paused:
        if (current != AdventureNodeState.inProgress) {
          return MissionTransitionResult.rejected(
              'Chỉ có thể tạm dừng khi đang học (inProgress).', current);
        }
        return MissionTransitionResult.ok(AdventureNodeState.paused);

      case AdventureNodeState.failed:
        if (current == AdventureNodeState.completed ||
            current == AdventureNodeState.perfect) {
          // Rule: Completed/perfect is NOT lost when replay fails!
          return MissionTransitionResult.ok(
            current, // PRESERVE COMPLETED STATE
            reason:
                'Lần học lại chưa đạt nhưng tiến độ hoàn thành trước đó vẫn được bảo lưu.',
            preservedPrevious: true,
            awardFirstClearXp: false,
          );
        }
        return MissionTransitionResult.ok(
          AdventureNodeState.failed,
          reason: 'Chưa đạt điểm yêu cầu (70%). Hãy thử lại!',
          awardFirstClearXp: false,
        );

      case AdventureNodeState.completed:
        if (!context.passed) {
          return MissionTransitionResult.rejected(
              'Chưa vượt qua thử thách, không thể chuyển thành completed.',
              current);
        }
        final isPerfect = context.stars >= 3 && context.score >= 95.0;
        final finalState = isPerfect
            ? AdventureNodeState.perfect
            : AdventureNodeState.completed;
        final shouldAwardFirstClear = context.isFirstClear &&
            current != AdventureNodeState.completed &&
            current != AdventureNodeState.perfect;
        return MissionTransitionResult.ok(
          finalState,
          awardFirstClearXp: shouldAwardFirstClear,
          reason: isPerfect
              ? 'Xuất sắc! Đạt kỷ lục 3 sao hoàn hảo!'
              : 'Vượt ải thành công!',
        );

      case AdventureNodeState.perfect:
        if (!context.passed || context.stars < 3) {
          return MissionTransitionResult.rejected(
              'Cần đạt 3 sao để chuyển thành perfect.', current);
        }
        final shouldAwardFirstClear = context.isFirstClear &&
            current != AdventureNodeState.completed &&
            current != AdventureNodeState.perfect;
        return MissionTransitionResult.ok(
          AdventureNodeState.perfect,
          awardFirstClearXp: shouldAwardFirstClear,
          reason: 'Kỷ lục hoàn hảo! 3 sao!',
        );
    }
  }

  /// Whether a failed node can be retried.
  static bool canRetry({
    required AdventureNodeState state,
    required bool isPrerequisiteMet,
  }) {
    return (state == AdventureNodeState.failed ||
            state == AdventureNodeState.inProgress) &&
        isPrerequisiteMet;
  }

  /// Whether a node is playable (either new attempt, resume, retry, or replay).
  static bool isPlayable(AdventureNodeState state) {
    return state != AdventureNodeState.locked;
  }
}
