import '../../../core/learning/learning_rules_config.dart';
import '../models/writing_path_models.dart';

enum WritingRecommendationReason {
  overdueReview,
  continuePath,
  strengthenWeakCharacter,
}

class WritingPathRecommendation {
  const WritingPathRecommendation({
    required this.node,
    required this.reason,
  });

  final WritingPathNode node;
  final WritingRecommendationReason reason;

  String get label => switch (reason) {
        WritingRecommendationReason.overdueReview =>
          'Ôn chữ ${node.character}',
        WritingRecommendationReason.continuePath =>
          'Tiếp tục: ${node.character}',
        WritingRecommendationReason.strengthenWeakCharacter =>
          'Củng cố: ${node.character}',
      };

  String get explanation => switch (reason) {
        WritingRecommendationReason.overdueReview =>
          'Chữ này đã đến hạn ôn theo tiến độ đã lưu.',
        WritingRecommendationReason.continuePath =>
          'Đây là chữ tiếp theo đã được mở khóa trong lộ trình.',
        WritingRecommendationReason.strengthenWeakCharacter =>
          'Bạn đã qua bài nhưng chưa đạt mức mastery hoặc chưa đủ số lượt luyện.',
      };
}

WritingPathRecommendation? recommendWritingNode(
  Iterable<WritingHskPath> paths, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();

  final completed = <WritingPathNode>[];
  WritingPathNode? current;
  for (final path in paths) {
    for (final section in path.sections) {
      for (final node in section.nodes) {
        if (node.state == WritingPathNodeState.completed) {
          completed.add(node);
        } else if (current == null &&
            node.state == WritingPathNodeState.current) {
          current = node;
        }
      }
    }
  }

  final overdue = completed.where((node) {
    final due = node.progress.nextReviewAt;
    return due != null && !due.isAfter(currentTime);
  }).toList()
    ..sort((a, b) {
      final aDue = a.progress.nextReviewAt!;
      final bDue = b.progress.nextReviewAt!;
      final byDate = aDue.compareTo(bDue);
      if (byDate != 0) return byDate;
      return a.progress.bestScore.compareTo(b.progress.bestScore);
    });
  if (overdue.isNotEmpty) {
    return WritingPathRecommendation(
      node: overdue.first,
      reason: WritingRecommendationReason.overdueReview,
    );
  }

  if (current != null) {
    return WritingPathRecommendation(
      node: current,
      reason: WritingRecommendationReason.continuePath,
    );
  }

  final weak = completed.where((node) {
    return node.progress.bestScore <
            LearningRulesConfig.hanziMasteryScore * 100 ||
        node.progress.practiceCount <
            LearningRulesConfig.hanziMasteryMinimumPractices;
  }).toList()
    ..sort((a, b) {
      final byScore = a.progress.bestScore.compareTo(b.progress.bestScore);
      if (byScore != 0) return byScore;
      final byPractice =
          a.progress.practiceCount.compareTo(b.progress.practiceCount);
      if (byPractice != 0) return byPractice;
      final bySection = a.sectionOrder.compareTo(b.sectionOrder);
      if (bySection != 0) return bySection;
      return a.nodeOrder.compareTo(b.nodeOrder);
    });

  if (weak.isNotEmpty) {
    return WritingPathRecommendation(
      node: weak.first,
      reason: WritingRecommendationReason.strengthenWeakCharacter,
    );
  }
  return null;
}
