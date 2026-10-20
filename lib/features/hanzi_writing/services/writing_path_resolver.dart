import '../../../core/learning/learning_rules_config.dart';
import '../models/writing_path_models.dart';

List<WritingPathSection> resolveWritingPathSections({
  required List<WritingPathNode> rawNodes,
  required Map<int, WritingCharacterProgress> progressByCharacter,
  required bool previousLevelCompleted,
}) {
  final grouped = <int, List<WritingPathNode>>{};
  final sectionTitles = <int, String>{};
  final sectionOrders = <int, int>{};
  for (final node in rawNodes) {
    grouped.putIfAbsent(node.sectionId, () => <WritingPathNode>[]).add(node);
    sectionTitles[node.sectionId] = node.sectionTitle;
    sectionOrders[node.sectionId] = node.sectionOrder;
  }

  final sectionIds = grouped.keys.toList()
    ..sort((a, b) =>
        (sectionOrders[a] ?? a).compareTo(sectionOrders[b] ?? b));

  var sectionUnlocked = previousLevelCompleted;
  final sections = <WritingPathSection>[];
  for (final sectionId in sectionIds) {
    final nodes = grouped[sectionId]!
      ..sort((a, b) => a.nodeOrder.compareTo(b.nodeOrder));
    var canReachNextNode = sectionUnlocked;
    final resolved = <WritingPathNode>[];

    for (final node in nodes) {
      final nodeProgress =
          progressByCharacter[node.characterId] ??
              const WritingCharacterProgress();
      final passed = nodeProgress.bestScore >=
          LearningRulesConfig.hanziPassScore * 100;

      WritingPathNodeState state;
      String? lockReason;
      if (!node.hasStrokeData) {
        state = WritingPathNodeState.unavailable;
        lockReason = 'Chữ này chưa có dữ liệu nét viết hợp lệ.';
      } else if (passed) {
        state = WritingPathNodeState.completed;
      } else if (canReachNextNode) {
        state = WritingPathNodeState.current;
        canReachNextNode = false;
      } else {
        state = WritingPathNodeState.locked;
        lockReason = sectionUnlocked
            ? 'Hoàn thành chữ trước để mở khóa.'
            : 'Hoàn thành Section trước để mở khóa.';
      }

      resolved.add(node.copyWith(
        progress: nodeProgress,
        state: state,
        lockReason: lockReason,
      ));
    }

    final required = resolved.where((node) => node.hasStrokeData).toList();
    final completed = required.where((node) =>
        node.progress.bestScore >=
        LearningRulesConfig.hanziPassScore * 100);
    final isCompleted =
        required.isNotEmpty && completed.length == required.length;

    sections.add(WritingPathSection(
      id: sectionId,
      title: sectionTitles[sectionId] ?? 'Section',
      order: sectionOrders[sectionId] ?? sectionId,
      nodes: List.unmodifiable(resolved),
      unlocked: sectionUnlocked,
    ));
    sectionUnlocked = sectionUnlocked && isCompleted;
  }
  return List.unmodifiable(sections);
}
