import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/learning/model/composed_learning_session.dart';
import 'package:pandarin/core/learning/model/learning_source_context.dart';
import 'package:pandarin/core/learning/service/learning_session_composer.dart';
import 'package:pandarin/core/learning/service/unit_bridge_resolver.dart';
import 'package:pandarin/core/models/duo_challenge.dart';

void main() {
  group('LearningSourceContext Tests', () {
    test('creates and serializes LearningSourceContext correctly', () {
      final context = LearningSourceContext(
        courseId: 'duo_chinese_v1',
        sectionId: 'sec_1',
        duoUnitId: 'unit_3',
        lexiconUnitId: 3,
        levelId: 'u3_l2',
        gameCode: 'select_answer',
        mode: LearningMode.duoMission,
        allowedChallengeIds: const ['c1', 'c2', 'c3'],
      );

      expect(context.duoUnitId, 'unit_3');
      expect(context.lexiconUnitId, 3);
      expect(context.levelId, 'u3_l2');
      expect(context.gameCode, 'select_answer');
      expect(context.mode, LearningMode.duoMission);
      expect(context.allowedChallengeIds, ['c1', 'c2', 'c3']);

      final json = context.toJson();
      expect(json['duo_unit_id'], 'unit_3');
      expect(json['lexicon_unit_id'], 3);
      expect(json['level_id'], 'u3_l2');

      final fromJson = LearningSourceContext.fromJson(json);
      expect(fromJson.duoUnitId, 'unit_3');
      expect(fromJson.lexiconUnitId, 3);
      expect(fromJson.levelId, 'u3_l2');
      expect(fromJson.mode, LearningMode.duoMission);
    });

    test('copyWith preserves unmodified fields', () {
      const original = LearningSourceContext(
        courseId: 'duo',
        duoUnitId: 'u1',
        levelId: 'u1_l1',
        gameCode: 'translate',
      );

      final modified = original.copyWith(
        lexiconUnitId: 1,
        mode: LearningMode.reviewSession,
      );

      expect(modified.courseId, 'duo');
      expect(modified.duoUnitId, 'u1');
      expect(modified.lexiconUnitId, 1);
      expect(modified.mode, LearningMode.reviewSession);
    });
  });

  group('UnitBridgeResolver Tests', () {
    final resolver = UnitBridgeResolver();

    test('resolves plain integer strings', () {
      expect(resolver.resolveLexiconUnitId('5'), 5);
      expect(resolver.resolveLexiconUnitId('12'), 12);
    });

    test('resolves prefixed unit strings', () {
      expect(resolver.resolveLexiconUnitId('unit_1'), 1);
      expect(resolver.resolveLexiconUnitId('unit_04'), 4);
      expect(resolver.resolveLexiconUnitId('u7'), 7);
      expect(resolver.resolveLexiconUnitId('u_9'), 9);
      expect(resolver.resolveLexiconUnitId('chapter_3'), 3);
    });

    test('supports explicit custom mappings', () {
      resolver.registerMapping('bonus_hsk1', 99);
      expect(resolver.resolveLexiconUnitId('bonus_hsk1'), 99);
      expect(resolver.resolveDuoUnitId(99), 'bonus_hsk1');
    });

    test('returns null gracefully on non-numeric unmapped IDs without throwing',
        () {
      expect(resolver.resolveLexiconUnitId('arbitrary_non_numeric'), isNull);
      expect(resolver.resolveLexiconUnitId(''), isNull);
    });

    test('buildBridgeContext correctly populates duo and lexicon IDs', () {
      final context = resolver.buildBridgeContext(
        duoUnitId: 'unit_6',
        levelId: 'u6_l1',
        gameCode: 'gap_fill',
        mode: LearningMode.duoMission,
      );

      expect(context.duoUnitId, 'unit_6');
      expect(context.lexiconUnitId, 6);
      expect(context.levelId, 'u6_l1');
    });
  });

  group('ComposedLearningSession Model Tests', () {
    test('snapshots and restores correctly', () {
      final now = DateTime.now();
      final session = ComposedLearningSession(
        sessionId: 'session_123',
        sourceContext: const LearningSourceContext(
          courseId: 'duo',
          duoUnitId: 'unit_2',
          levelId: 'u2_l1',
          gameCode: 'select_answer',
        ),
        items: [
          const ComposedChallengeItem(
            id: 'c_1',
            type: 'multiple_choice',
            payload: {'question': 'Q1'},
            unitId: 'unit_2',
            orderIndex: 0,
          ),
          const ComposedChallengeItem(
            id: 'c_2',
            type: 'multiple_choice',
            payload: {'question': 'Q2'},
            unitId: 'unit_2',
            orderIndex: 1,
          ),
        ],
        targetBudget: 5,
        currentIndex: 1,
        score: 20,
        correctCount: 2,
        wrongCount: 0,
        isResumed: true,
        startedAt: now,
      );

      final json = session.toJson();
      expect(json['session_id'], 'session_123');
      expect(json['current_index'], 1);
      expect(json['score'], 20);
      expect(json['is_resumed'], isTrue);
      expect(json['items'], hasLength(2));

      final restored = ComposedLearningSession.fromJson(json);
      expect(restored.sessionId, 'session_123');
      expect(restored.currentIndex, 1);
      expect(restored.score, 20);
      expect(restored.isResumed, isTrue);
      expect(restored.items.length, 2);
      expect(restored.items.first.id, 'c_1');
    });
  });

  group('LearningSessionComposer Tests', () {
    DuoChallenge makeChallenge(String id, String levelId) {
      return DuoChallenge(
        id: id,
        type: 'select_answer',
        prompt: 'Prompt_$id',
      );
    }

    test('throws ContentUnavailableException when unit has 0 challenges',
        () async {
      final composer = LearningSessionComposer(
        challengeFetcher:
            ({required levelId, required gameCode, required limit}) async => [],
        activeSessionGetter: (gameId, levelId) async => null,
      );

      const context = LearningSourceContext(
        courseId: 'duo',
        duoUnitId: 'unit_9',
        levelId: 'u9_empty',
        gameCode: 'select_answer',
      );

      expect(
        () => composer.composeSession(sourceContext: context, gameId: 1),
        throwsA(isA<ContentUnavailableException>().having(
          (ContentUnavailableException e) => e.message,
          'message',
          contains('chưa sẵn sàng'),
        )),
      );
    });

    test(
        'throws ContentUnavailableException when unit content is below minimum threshold',
        () async {
      final composer = LearningSessionComposer(
        challengeFetcher:
            ({required levelId, required gameCode, required limit}) async => [
          makeChallenge('c1', levelId),
          makeChallenge('c2', levelId),
        ], // Only 2 items, below minRequiredQuestions (3)
        activeSessionGetter: (gameId, levelId) async => null,
      );

      const context = LearningSourceContext(
        courseId: 'duo',
        duoUnitId: 'unit_1',
        levelId: 'u1_l1',
        gameCode: 'select_answer',
      );

      expect(
        () => composer.composeSession(sourceContext: context, gameId: 1),
        throwsA(isA<ContentUnavailableException>()),
      );
    });

    test('enforces bounded question budget and strict unit bounding', () async {
      final allRaw = List.generate(
        12,
        (i) => makeChallenge('ch_$i', 'u2_l1'),
      );

      final composer = LearningSessionComposer(
        challengeFetcher: (
                {required levelId, required gameCode, required limit}) async =>
            allRaw,
        activeSessionGetter: (gameId, levelId) async => null,
      );

      const context = LearningSourceContext(
        courseId: 'duo',
        duoUnitId: 'unit_2',
        levelId: 'u2_l1',
        gameCode: 'select_answer',
      );

      final session = await composer.composeSession(
        sourceContext: context,
        gameId: 1,
        targetBudget: 6, // Budget is capped at 6
      );

      expect(session.isResumed, isFalse);
      expect(session.items.length, 6);
      expect(session.currentIndex, 0);
      expect(session.items.map((i) => i.id).toList(), [
        'ch_0',
        'ch_1',
        'ch_2',
        'ch_3',
        'ch_4',
        'ch_5',
      ]);
    });

    test(
        'restores exact question sequence without re-shuffling when resuming session',
        () async {
      final allRaw = [
        makeChallenge('id_alpha', 'u3_l1'),
        makeChallenge('id_beta', 'u3_l1'),
        makeChallenge('id_gamma', 'u3_l1'),
        makeChallenge('id_delta', 'u3_l1'),
        makeChallenge('id_epsilon', 'u3_l1'),
      ];

      // Active session had a specific challenge order: gamma -> alpha -> delta
      final activeSaved = {
        'attempt_id': 'saved_attempt_456',
        'current_index': 2,
        'score': 25,
        'correct_count': 2,
        'wrong_count': 1,
        'challenge_ids': ['id_gamma', 'id_alpha', 'id_delta'],
        'started_at': DateTime.now().toIso8601String(),
      };

      final composer = LearningSessionComposer(
        challengeFetcher: (
                {required levelId, required gameCode, required limit}) async =>
            allRaw,
        activeSessionGetter: (gameId, levelId) async => activeSaved,
      );

      const context = LearningSourceContext(
        courseId: 'duo',
        duoUnitId: 'unit_3',
        levelId: 'u3_l1',
        gameCode: 'select_answer',
      );

      final session = await composer.composeSession(
        sourceContext: context,
        gameId: 1,
      );

      expect(session.isResumed, isTrue);
      expect(session.sessionId, 'saved_attempt_456');
      expect(session.currentIndex, 2);
      expect(session.score, 25);
      expect(session.correctCount, 2);
      expect(session.wrongCount, 1);
      // Verify exact sequence order preserved
      expect(session.items.map((i) => i.id).toList(), [
        'id_gamma',
        'id_alpha',
        'id_delta',
      ]);
    });
  });
}
