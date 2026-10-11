import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../database/duo_db_helper.dart';
import '../../models/duo_challenge.dart';
import '../../models/duo_flashcard.dart';
import '../model/composed_learning_session.dart';
import '../model/learning_source_context.dart';

/// Exception thrown when a curriculum mission does not have sufficient verified
/// content in the database. Prevents deceptive fallback to random out-of-unit challenges.
class ContentUnavailableException implements Exception {
  const ContentUnavailableException({
    required this.message,
    required this.sourceContext,
  });

  final String message;
  final LearningSourceContext sourceContext;

  @override
  String toString() =>
      'ContentUnavailableException: $message (${sourceContext.duoUnitId}:${sourceContext.levelId})';
}

typedef ChallengeFetcher = Future<List<dynamic>> Function({
  required String levelId,
  required String gameCode,
  required int limit,
});

typedef ActiveSessionGetter = Future<Map<String, dynamic>?> Function(
  int gameId,
  String levelId,
);

/// Domain service responsible for composing curriculum-bounded, adaptive learning sessions.
///
/// Core invariants:
/// 1. Strict Unit Boundary: Challenges must strictly belong to the specified Unit/Level.
/// 2. Bounded Budget: Sessions are 5-10 challenges (matching uses 5-6 pairs).
/// 3. Stable Resume: Resuming preserves the exact question order and progress index.
/// 4. Explicit Unavailable State: Fails gracefully without inventing fake/out-of-unit questions.
class LearningSessionComposer {
  LearningSessionComposer({
    DuoDbHelper? dbHelper,
    ChallengeFetcher? challengeFetcher,
    ActiveSessionGetter? activeSessionGetter,
  })  : _dbHelper = dbHelper ?? DuoDbHelper.instance,
        _challengeFetcher = challengeFetcher,
        _activeSessionGetter = activeSessionGetter;

  final DuoDbHelper _dbHelper;
  final ChallengeFetcher? _challengeFetcher;
  final ActiveSessionGetter? _activeSessionGetter;

  /// Default question budget per session (3-5 minute micro-learning session).
  static const int defaultQuestionBudget = 8;
  static const int minRequiredQuestions = 3;

  /// Compose an authoritative, bounded learning session.
  Future<ComposedLearningSession> composeSession({
    required LearningSourceContext sourceContext,
    required int gameId,
    int targetBudget = defaultQuestionBudget,
    String? forcedAttemptId,
  }) async {
    // 1. Check for existing active session in storage (Cloud for signed-in, Local for guest)
    final activeGetter = _activeSessionGetter;
    final active = activeGetter != null
        ? await activeGetter(gameId, sourceContext.levelId)
        : await _dbHelper.getActiveSession(gameId, sourceContext.levelId);

    if (active != null) {
      final restored = await _restoreSession(
        active: active,
        gameId: gameId,
        sourceContext: sourceContext,
        targetBudget: targetBudget,
      );
      if (restored != null) {
        return restored;
      }
    }

    // 2. Compose a new session bounded strictly to the Unit/Level
    return await _composeNewSession(
      gameId: gameId,
      sourceContext: sourceContext,
      targetBudget: targetBudget,
      attemptId: forcedAttemptId,
    );
  }

  Future<ComposedLearningSession> _composeNewSession({
    required int gameId,
    required LearningSourceContext sourceContext,
    required int targetBudget,
    String? attemptId,
  }) async {
    final rawChallenges = await _fetchUnitChallenges(
      levelId: sourceContext.levelId,
      gameCode: sourceContext.gameCode,
      limit: targetBudget * 2,
    );

    // Verify content sufficiency
    if (rawChallenges.isEmpty || rawChallenges.length < minRequiredQuestions) {
      throw ContentUnavailableException(
        message:
            'Nội dung bài học cho thử thách này chưa sẵn sàng. Vui lòng thử lại sau hoặc chọn thử thách khác.',
        sourceContext: sourceContext,
      );
    }

    // Take bounded budget
    final bounded = rawChallenges.take(targetBudget).toList();
    final items = <ComposedChallengeItem>[];

    for (int i = 0; i < bounded.length; i++) {
      final item = bounded[i];
      final id = _extractId(item, i);
      final type = _extractType(item, sourceContext.gameCode);

      items.add(
        ComposedChallengeItem(
          id: id,
          type: type,
          payload: item,
          unitId: sourceContext.duoUnitId,
          orderIndex: i,
        ),
      );
    }

    final newAttemptId = attemptId ??
        'duo_${gameId}_${sourceContext.levelId}_${DateTime.now().microsecondsSinceEpoch}';

    return ComposedLearningSession(
      sessionId: newAttemptId,
      sourceContext: sourceContext,
      items: items,
      targetBudget: targetBudget,
      currentIndex: 0,
      score: 0,
      correctCount: 0,
      wrongCount: 0,
      isResumed: false,
      startedAt: DateTime.now(),
      metadata: {
        'challenge_ids': items.map((e) => e.id).toList(),
      },
    );
  }

  Future<ComposedLearningSession?> _restoreSession({
    required Map<String, dynamic> active,
    required int gameId,
    required LearningSourceContext sourceContext,
    required int targetBudget,
  }) async {
    try {
      final rawChallenges = await _fetchUnitChallenges(
        levelId: sourceContext.levelId,
        gameCode: sourceContext.gameCode,
        limit: targetBudget * 2,
      );

      if (rawChallenges.isEmpty) return null;

      final savedIds = active['challenge_ids'] is List
          ? (active['challenge_ids'] as List).map((e) => e.toString()).toList()
          : <String>[];

      List<dynamic> ordered;
      if (savedIds.isNotEmpty) {
        // Reconstruct exact saved order
        final Map<String, dynamic> lookup = {};
        for (int i = 0; i < rawChallenges.length; i++) {
          final id = _extractId(rawChallenges[i], i);
          lookup[id] = rawChallenges[i];
        }

        ordered = [];
        for (final id in savedIds) {
          if (lookup.containsKey(id)) {
            ordered.add(lookup[id]);
          }
        }

        // If some challenges were missing, fallback to taking raw bounded
        if (ordered.isEmpty) {
          ordered = rawChallenges.take(targetBudget).toList();
        }
      } else {
        ordered = rawChallenges.take(targetBudget).toList();
      }

      final items = <ComposedChallengeItem>[];
      for (int i = 0; i < ordered.length; i++) {
        final item = ordered[i];
        items.add(
          ComposedChallengeItem(
            id: _extractId(item, i),
            type: _extractType(item, sourceContext.gameCode),
            payload: item,
            unitId: sourceContext.duoUnitId,
            orderIndex: i,
          ),
        );
      }

      final savedIndex = (active['current_index'] as num?)?.toInt() ?? 0;
      final savedScore = (active['score'] as num?)?.toInt() ?? 0;
      final savedCorrect = (active['correct_count'] as num?)?.toInt() ?? 0;
      final savedWrong = (active['wrong_count'] as num?)?.toInt() ?? 0;
      final attemptId = '${active['attempt_id'] ?? ''}'.trim();
      final startedAt =
          DateTime.tryParse('${active['started_at'] ?? ''}') ?? DateTime.now();

      return ComposedLearningSession(
        sessionId: attemptId.isNotEmpty
            ? attemptId
            : 'duo_${gameId}_${sourceContext.levelId}_${DateTime.now().microsecondsSinceEpoch}',
        sourceContext: sourceContext,
        items: items,
        targetBudget: targetBudget,
        currentIndex: min(savedIndex, max(0, items.length - 1)),
        score: savedScore,
        correctCount: savedCorrect,
        wrongCount: savedWrong,
        isResumed: true,
        startedAt: startedAt,
        metadata: {
          'challenge_ids': items.map((e) => e.id).toList(),
        },
      );
    } catch (e) {
      debugPrint('Failed to restore active session cleanly: $e');
      return null;
    }
  }

  Future<List<dynamic>> _fetchUnitChallenges({
    required String levelId,
    required String gameCode,
    required int limit,
  }) async {
    final fetcher = _challengeFetcher;
    if (fetcher != null) {
      return await fetcher(
        levelId: levelId,
        gameCode: gameCode,
        limit: limit,
      );
    }
    try {
      final challenges = await _dbHelper.getChallengesForGameLevel(
        levelId,
        gameCode,
        limit: limit,
      );

      if (gameCode == 'learn_words') {
        // Map learn_words to flashcard representation from the same level
        final wordsSet = <String>{};
        for (var c in challenges) {
          if (c.choicesText != null) {
            final correctIdx = c.choicesCorrect?.indexOf(1) ?? -1;
            if (correctIdx >= 0 && correctIdx < c.choicesText!.length) {
              wordsSet.add(c.choicesText![correctIdx]);
            }
          }
        }

        if (wordsSet.isNotEmpty) {
          final flashcards =
              await _dbHelper.getFlashcardsForWords(wordsSet.toList());
          if (flashcards.isNotEmpty) {
            return flashcards;
          }
        }
      } else if (gameCode == 'word_connect') {
        final wordsSet = <String>{};
        for (var c in challenges) {
          if (c.choicesText != null) {
            final correctIdx = c.choicesCorrect?.indexOf(1) ?? -1;
            if (correctIdx >= 0 && correctIdx < c.choicesText!.length) {
              wordsSet.add(c.choicesText![correctIdx]);
            }
          }
        }

        if (wordsSet.isNotEmpty) {
          final flashcards =
              await _dbHelper.getFlashcardsForWords(wordsSet.toList());
          final pairs = <Map<String, String>>[];
          for (var f in flashcards) {
            if (f.word.isNotEmpty &&
                f.meaning != null &&
                f.meaning!.isNotEmpty) {
              pairs.add({'zh': f.word, 'vi': f.meaning!});
            }
          }
          if (pairs.isNotEmpty) {
            return pairs;
          }
        }
      }

      return challenges;
    } catch (e) {
      debugPrint('Error fetching unit challenges: $e');
      return [];
    }
  }

  String _extractId(dynamic item, int fallbackIndex) {
    if (item is DuoChallenge) return item.id;
    if (item is DuoFlashcard) return item.id.toString();
    if (item is Map) {
      if (item.containsKey('id')) return item['id'].toString();
      if (item.containsKey('zh')) return 'zh_${item['zh']}';
    }
    return 'item_$fallbackIndex';
  }

  String _extractType(dynamic item, String gameCode) {
    if (item is DuoChallenge) return item.type;
    if (item is DuoFlashcard) return 'flashcard';
    if (item is Map) return 'pair';
    return gameCode;
  }
}
