import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/features/hanzi_writing/models/writing_path_models.dart';
import 'package:pandarin/features/hanzi_writing/services/writing_recommendation_engine.dart';

WritingPathNode node({
  required int id,
  required WritingPathNodeState state,
  required double best,
  required int practices,
  DateTime? due,
}) {
  return WritingPathNode(
    hskLevelId: 1,
    sectionId: 1,
    sectionTitle: 'Đồ ăn và đồ uống',
    sectionOrder: 1,
    nodeOrder: id,
    characterId: id,
    character: '字$id',
    contextWordId: id,
    contextWord: '字$id',
    strokeCount: 1,
    strokeWidth: 110,
    strokeHeight: 110,
    strokePaths: 'M0 0',
    metadataQuality: 'complete',
    progress: WritingCharacterProgress(
      practiceCount: practices,
      bestScore: best,
      lastScore: best,
      nextReviewAt: due,
    ),
    state: state,
  );
}

WritingHskPath path(List<WritingPathNode> nodes) {
  return WritingHskPath(
    catalog: const WritingHskCatalogItem(
      id: 1,
      name: 'HSK 1',
      sortOrder: 1,
      sectionCount: 1,
      mappedCharacterCount: 3,
    ),
    sections: [
      WritingPathSection(
        id: 1,
        title: 'Đồ ăn và đồ uống',
        order: 1,
        nodes: nodes,
        unlocked: true,
      ),
    ],
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 20, 3);

  test('overdue review takes priority over new current node', () {
    final recommendation = recommendWritingNode([
      path([
        node(
          id: 1,
          state: WritingPathNodeState.completed,
          best: 90,
          practices: 4,
          due: now.subtract(const Duration(days: 1)),
        ),
        node(
          id: 2,
          state: WritingPathNodeState.current,
          best: 0,
          practices: 0,
        ),
      ]),
    ], now: now);

    expect(recommendation!.node.characterId, 1);
    expect(recommendation.reason, WritingRecommendationReason.overdueReview);
  });

  test('current node is recommended when no review is due', () {
    final recommendation = recommendWritingNode([
      path([
        node(
          id: 1,
          state: WritingPathNodeState.completed,
          best: 95,
          practices: 4,
          due: now.add(const Duration(days: 2)),
        ),
        node(
          id: 2,
          state: WritingPathNodeState.current,
          best: 0,
          practices: 0,
        ),
      ]),
    ], now: now);

    expect(recommendation!.node.characterId, 2);
    expect(recommendation.reason, WritingRecommendationReason.continuePath);
  });

  test('weak passed character is suggested after path has no current node', () {
    final recommendation = recommendWritingNode([
      path([
        node(
          id: 1,
          state: WritingPathNodeState.completed,
          best: 84,
          practices: 3,
        ),
        node(
          id: 2,
          state: WritingPathNodeState.completed,
          best: 92,
          practices: 4,
        ),
      ]),
    ], now: now);

    expect(recommendation!.node.characterId, 1);
    expect(
      recommendation.reason,
      WritingRecommendationReason.strengthenWeakCharacter,
    );
  });

  test('no recommendation after full mastery with no due review', () {
    final recommendation = recommendWritingNode([
      path([
        node(
          id: 1,
          state: WritingPathNodeState.completed,
          best: 92,
          practices: 3,
        ),
      ]),
    ], now: now);

    expect(recommendation, isNull);
  });
}
