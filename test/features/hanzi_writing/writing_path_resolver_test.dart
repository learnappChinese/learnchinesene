import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/features/hanzi_writing/models/writing_path_models.dart';
import 'package:pandarin/features/hanzi_writing/services/writing_path_resolver.dart';

WritingPathNode node({
  required int characterId,
  required int sectionId,
  required int sectionOrder,
  required int nodeOrder,
  String character = '你',
  bool strokes = true,
}) {
  return WritingPathNode(
    hskLevelId: 1,
    sectionId: sectionId,
    sectionTitle: 'Section $sectionOrder',
    sectionOrder: sectionOrder,
    nodeOrder: nodeOrder,
    characterId: characterId,
    character: character,
    contextWordId: characterId,
    contextWord: character,
    strokeCount: strokes ? 5 : 0,
    strokeWidth: 110,
    strokeHeight: 110,
    strokePaths: strokes ? 'M 0,0 L 1,1' : '',
    metadataQuality: strokes ? 'complete' : 'missing_strokes',
  );
}

void main() {
  test('first valid node is current and later nodes are locked', () {
    final sections = resolveWritingPathSections(
      rawNodes: [
        node(characterId: 1, sectionId: 10, sectionOrder: 1, nodeOrder: 1),
        node(characterId: 2, sectionId: 10, sectionOrder: 1, nodeOrder: 2),
      ],
      progressByCharacter: const {},
      previousLevelCompleted: true,
    );

    expect(sections.single.nodes[0].state, WritingPathNodeState.current);
    expect(sections.single.nodes[1].state, WritingPathNodeState.locked);
  });

  test('existing Hanzi pass threshold unlocks exactly the next node', () {
    final sections = resolveWritingPathSections(
      rawNodes: [
        node(characterId: 1, sectionId: 10, sectionOrder: 1, nodeOrder: 1),
        node(characterId: 2, sectionId: 10, sectionOrder: 1, nodeOrder: 2),
      ],
      progressByCharacter: const {
        1: WritingCharacterProgress(practiceCount: 1, bestScore: 70),
      },
      previousLevelCompleted: true,
    );

    expect(sections.single.nodes[0].state, WritingPathNodeState.completed);
    expect(sections.single.nodes[1].state, WritingPathNodeState.current);
  });

  test('score below pass threshold does not unlock next character', () {
    final sections = resolveWritingPathSections(
      rawNodes: [
        node(characterId: 1, sectionId: 10, sectionOrder: 1, nodeOrder: 1),
        node(characterId: 2, sectionId: 10, sectionOrder: 1, nodeOrder: 2),
      ],
      progressByCharacter: const {
        1: WritingCharacterProgress(practiceCount: 3, bestScore: 69.9),
      },
      previousLevelCompleted: true,
    );

    expect(sections.single.nodes[0].state, WritingPathNodeState.current);
    expect(sections.single.nodes[1].state, WritingPathNodeState.locked);
  });

  test('missing stroke data is unavailable but does not create fake blocker', () {
    final sections = resolveWritingPathSections(
      rawNodes: [
        node(
          characterId: 1,
          sectionId: 10,
          sectionOrder: 1,
          nodeOrder: 1,
          strokes: false,
        ),
        node(characterId: 2, sectionId: 10, sectionOrder: 1, nodeOrder: 2),
      ],
      progressByCharacter: const {},
      previousLevelCompleted: true,
    );

    expect(sections.single.nodes[0].state, WritingPathNodeState.unavailable);
    expect(sections.single.nodes[1].state, WritingPathNodeState.current);
    expect(sections.single.requiredCount, 1);
  });

  test('next section stays locked until all required previous nodes pass', () {
    final raw = [
      node(characterId: 1, sectionId: 10, sectionOrder: 1, nodeOrder: 1),
      node(characterId: 2, sectionId: 10, sectionOrder: 1, nodeOrder: 2),
      node(characterId: 3, sectionId: 20, sectionOrder: 2, nodeOrder: 1),
    ];

    final incomplete = resolveWritingPathSections(
      rawNodes: raw,
      progressByCharacter: const {
        1: WritingCharacterProgress(practiceCount: 1, bestScore: 80),
      },
      previousLevelCompleted: true,
    );
    expect(incomplete[1].unlocked, isFalse);
    expect(incomplete[1].nodes.single.state, WritingPathNodeState.locked);

    final complete = resolveWritingPathSections(
      rawNodes: raw,
      progressByCharacter: const {
        1: WritingCharacterProgress(practiceCount: 1, bestScore: 80),
        2: WritingCharacterProgress(practiceCount: 1, bestScore: 75),
      },
      previousLevelCompleted: true,
    );
    expect(complete[0].completed, isTrue);
    expect(complete[1].unlocked, isTrue);
    expect(complete[1].nodes.single.state, WritingPathNodeState.current);
  });

  test('global character progress is reused when a Hanzi appears again', () {
    final sections = resolveWritingPathSections(
      rawNodes: [
        node(characterId: 9, sectionId: 10, sectionOrder: 1, nodeOrder: 1),
        node(characterId: 9, sectionId: 20, sectionOrder: 2, nodeOrder: 1),
      ],
      progressByCharacter: const {
        9: WritingCharacterProgress(practiceCount: 1, bestScore: 91),
      },
      previousLevelCompleted: true,
    );

    expect(sections[0].nodes.single.state, WritingPathNodeState.completed);
    expect(sections[1].nodes.single.state, WritingPathNodeState.completed);
  });
}
