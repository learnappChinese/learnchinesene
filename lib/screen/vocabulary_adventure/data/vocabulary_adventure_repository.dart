import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/duo_db_helper.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/models/example_sentence.dart';
import '../../../core/models/word.dart';
import '../model/vocabulary_adventure.dart';

abstract interface class VocabularyAdventureRepository {
  Future<VocabularyMission?> loadMission({
    required String levelId,
    required int gameId,
  });

  Future<VocabularyRunSnapshot?> loadActiveRun({
    required String levelId,
    required int gameId,
  });

  Future<void> saveActiveRun({
    required String levelId,
    required int gameId,
    required VocabularyRunSnapshot snapshot,
  });

  Future<void> startMission({
    required String levelId,
    required int gameId,
    required String attemptId,
  });

  Future<void> abandonMission({
    required String attemptId,
    required String reason,
  });

  Future<VocabularyMasteryUpdate?> recordWordOutcome({
    required int wordId,
    required bool isCorrect,
    required int masteryLevel,
  });

  Future<LearningResult?> completeMission({
    required String levelId,
    required int gameId,
    required String attemptId,
    required int totalQuestions,
    required int durationSeconds,
    int correctCount = 0,
    int wrongCount = 0,
    int maxCombo = 0,
  });
}

class SupabaseVocabularyAdventureRepository
    implements VocabularyAdventureRepository {
  SupabaseVocabularyAdventureRepository({
    SupabaseClient? client,
    DuoDbHelper? duoDatabase,
    LearningRewardService? rewardService,
    VocabularyEventBuilder eventBuilder = const VocabularyEventBuilder(),
  })  : _client = client ?? Supabase.instance.client,
        _duoDatabase = duoDatabase ?? DuoDbHelper.instance,
        _rewardService = rewardService ?? LearningRewardService(),
        _eventBuilder = eventBuilder;

  final SupabaseClient _client;
  final DuoDbHelper _duoDatabase;
  final LearningRewardService _rewardService;
  final VocabularyEventBuilder _eventBuilder;

  @override
  Future<VocabularyMission?> loadMission({
    required String levelId,
    required int gameId,
  }) async {
    final levelRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_levels')
          .select('unit_id, teaching_objective')
          .eq('id', levelId)
          .limit(1),
    );
    if (levelRows.isEmpty) return null;

    final level = levelRows.first;
    final unitId = '${level['unit_id'] ?? ''}';
    final unitRows = List<Map<String, dynamic>>.from(
      await _client.from('duo_units').select('title').eq('id', unitId).limit(1),
    );

    final sessionRows = List<Map<String, dynamic>>.from(
      await _client.from('duo_sessions').select('id').eq('level_id', levelId),
    );
    final sessionIds = sessionRows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false);
    if (sessionIds.isEmpty) return null;

    final challengeRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_challenges')
          .select(
            'id, session_id, type, prompt, tts, slow_tts, choices_text, '
            'choices_tts, choices_image, choices_correct, tokens_text, '
            'tokens_tts, tokens_hints, solutions',
          )
          .inFilter('session_id', sessionIds)
          .inFilter('type', const ['select', 'assist'])
          .order('session_id')
          .order('id'),
    );

    final challengeByWord = <String, DuoChallenge>{};
    final sourceOrder = <String, int>{};
    final imageByWord = <String, String>{};
    for (var index = 0; index < challengeRows.length; index++) {
      final challenge = DuoChallenge.fromMap(challengeRows[index]);
      final choiceIndex = _correctChoiceIndex(challenge);
      if (choiceIndex == null) continue;
      final word = challenge.choicesText![choiceIndex].trim();
      if (word.isEmpty) continue;
      challengeByWord.putIfAbsent(word, () => challenge);
      sourceOrder.putIfAbsent(word, () => index);
      final images = challenge.choicesImage;
      if (images != null && choiceIndex < images.length) {
        final image = images[choiceIndex].trim();
        if (image.isNotEmpty) imageByWord.putIfAbsent(word, () => image);
      }
    }
    if (challengeByWord.length < 2) return null;

    final wordRows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_words')
          .select(
            'id, word, pinyin, meaning_vi, meaning_en, tts_url, hsk_level_id',
          )
          .inFilter('word', challengeByWord.keys.toList()),
    ).where((row) => '${row['meaning_vi'] ?? ''}'.trim().isNotEmpty).toList();
    if (wordRows.length < 2) return null;

    final wordIds = wordRows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false);
    final exampleRows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_examples')
          .select(
            'id, word_id, example_order, sentence_cn, sentence_pinyin, sentence_vi',
          )
          .inFilter('word_id', wordIds)
          .order('example_order')
          .order('id'),
    );
    final examplesByWord = <int, List<ExampleSentence>>{};
    for (final row in exampleRows) {
      final wordId = (row['word_id'] as num?)?.toInt();
      if (wordId == null) continue;
      examplesByWord.putIfAbsent(wordId, () => []).add(
            ExampleSentence.fromMap({
              'id': row['id'],
              'word_id': row['word_id'],
              'chinese': row['sentence_cn'],
              'pinyin': row['sentence_pinyin'],
              'vietnamese': row['sentence_vi'],
              'order_index': row['example_order'] ?? row['id'],
            }),
          );
    }

    final userId = _client.auth.currentUser?.id;
    final progressRows = userId == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _client
                .from('lexicon_user_progress')
                .select(
                  'word_id, correct_count, wrong_count, mastered, next_review_at',
                )
                .eq('user_id', userId)
                .inFilter('word_id', wordIds),
          );
    final progressByWord = <int, VocabularyWordProgress>{
      for (final row in progressRows)
        if ((row['word_id'] as num?)?.toInt() case final int id)
          id: VocabularyWordProgress(
            correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
            wrongCount: (row['wrong_count'] as num?)?.toInt() ?? 0,
            mastered: row['mastered'] == true,
            nextReviewAt: DateTime.tryParse('${row['next_review_at'] ?? ''}'),
          ),
    };

    final now = DateTime.now().toUtc();
    final candidates = wordRows.map((row) {
      final id = (row['id'] as num?)?.toInt() ?? 0;
      final chinese = '${row['word'] ?? ''}';
      return VocabularyMissionWord(
        word: Word.fromMap({
          'id': id,
          'chinese': chinese,
          'pinyin': row['pinyin'],
          'vietnamese': row['meaning_vi'],
          'english': row['meaning_en'],
          'tts_url': row['tts_url'],
          'hsk_level_id': row['hsk_level_id'],
          'section_title': unitRows.isEmpty ? '' : unitRows.first['title'],
          'group_subtitle': level['teaching_objective'],
          'wrong_count': progressByWord[id]?.wrongCount ?? 0,
          'correct_count': progressByWord[id]?.correctCount ?? 0,
        }),
        sourceChallenge: challengeByWord[chinese]!,
        examples: examplesByWord[id] ?? const [],
        progress: progressByWord[id] ?? const VocabularyWordProgress(),
        imageUrl: imageByWord[chinese],
      );
    }).toList()
      ..sort((a, b) {
        final mastered = (a.progress.mastered ? 1 : 0)
            .compareTo(b.progress.mastered ? 1 : 0);
        if (mastered != 0) return mastered;
        final aDue = a.progress.nextReviewAt == null ||
                !a.progress.nextReviewAt!.toUtc().isAfter(now)
            ? 0
            : 1;
        final bDue = b.progress.nextReviewAt == null ||
                !b.progress.nextReviewAt!.toUtc().isAfter(now)
            ? 0
            : 1;
        final reviewPriority = aDue.compareTo(bDue);
        if (reviewPriority != 0) return reviewPriority;
        final mistakes = b.progress.wrongCount.compareTo(a.progress.wrongCount);
        if (mistakes != 0) return mistakes;
        final exposure =
            a.progress.correctCount.compareTo(b.progress.correctCount);
        if (exposure != 0) return exposure;
        return (sourceOrder[a.word.chinese] ?? 0)
            .compareTo(sourceOrder[b.word.chinese] ?? 0);
      });

    final words = candidates.take(math.min(4, candidates.length)).toList();
    final events = _eventBuilder.build(words);
    if (events.isEmpty) return null;

    return VocabularyMission(
      levelId: levelId,
      gameId: gameId,
      title: unitRows.isEmpty
          ? 'Hành trình từ vựng'
          : '${unitRows.first['title'] ?? 'Hành trình từ vựng'}',
      objective: '${level['teaching_objective'] ?? ''}',
      words: words,
      events: events,
    );
  }

  @override
  Future<VocabularyRunSnapshot?> loadActiveRun({
    required String levelId,
    required int gameId,
  }) async {
    final row = await _duoDatabase.getActiveSession(gameId, levelId);
    if (row == null) return null;
    return VocabularyRunSnapshot(
      attemptId: '${row['attempt_id'] ?? ''}',
      startedAt: DateTime.tryParse('${row['started_at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      currentIndex: (row['current_index'] as num?)?.toInt() ?? 0,
      score: (row['score'] as num?)?.toInt() ?? 0,
      correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (row['wrong_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> saveActiveRun({
    required String levelId,
    required int gameId,
    required VocabularyRunSnapshot snapshot,
  }) =>
      _duoDatabase.saveActiveSession(
        gameId,
        levelId,
        snapshot.currentIndex,
        snapshot.score,
        snapshot.correctCount,
        snapshot.wrongCount,
        snapshot.attemptId,
      );

  @override
  Future<void> startMission({
    required String levelId,
    required int gameId,
    required String attemptId,
  }) =>
      _rewardService.startDuoGameAttempt(
        gameId: gameId,
        gameCode: 'learn_words',
        levelId: levelId,
        attemptId: attemptId,
      );

  @override
  Future<void> abandonMission({
    required String attemptId,
    required String reason,
  }) =>
      _rewardService.abandonAttempt(
        attemptId,
        metadata: <String, dynamic>{'reason': reason},
      );

  @override
  Future<VocabularyMasteryUpdate?> recordWordOutcome({
    required int wordId,
    required bool isCorrect,
    required int masteryLevel,
  }) async {
    if (_client.auth.currentUser == null) return null;
    final response = await _client.rpc(
      'record_word_progress',
      params: {
        'p_word_id': wordId,
        'p_is_correct': isCorrect,
        'p_level': masteryLevel,
      },
    );
    final row = switch (response) {
      Map value => Map<String, dynamic>.from(value),
      List value when value.isNotEmpty =>
        Map<String, dynamic>.from(value.first as Map),
      _ => null,
    };
    return row == null
        ? null
        : VocabularyMasteryUpdate(mastered: row['mastered'] == true);
  }

  @override
  Future<LearningResult?> completeMission({
    required String levelId,
    required int gameId,
    required String attemptId,
    required int totalQuestions,
    required int durationSeconds,
    int correctCount = 0,
    int wrongCount = 0,
    int maxCombo = 0,
  }) async {
    final reward = await _rewardService.processVocabularyReward(
      levelId: levelId,
      attemptId: attemptId,
      gameId: gameId,
      correctCount: correctCount,
      wrongCount: wrongCount,
      maxCombo: maxCombo,
      totalQuestions: totalQuestions,
      durationSeconds: durationSeconds,
    );

    if (!_duoDatabase.isSignedIn) {
      await _duoDatabase.saveLevelProgress(
        gameId,
        levelId,
        reward.score.toInt(),
        reward.stars,
        reward.passed,
      );
      if (reward.passed) {
        await _unlockNextPlayableLevel(gameId, levelId);
      }
      await _duoDatabase.clearActiveSession(gameId, levelId);
    }
    return reward;
  }

  Future<void> _unlockNextPlayableLevel(int gameId, String levelId) async {
    final levels = await _duoDatabase.getGamePath(gameId, 'learn_words');
    var foundCurrent = false;
    for (final level in levels) {
      final id = '${level['level_id'] ?? ''}';
      if (foundCurrent &&
          ((level['challenge_count'] as num?)?.toInt() ?? 0) > 0) {
        await _duoDatabase.unlockLevel(gameId, id);
        return;
      }
      if (id == levelId) foundCurrent = true;
    }
  }

  static int? _correctChoiceIndex(DuoChallenge challenge) {
    final choices = challenge.choicesText;
    final correct = challenge.choicesCorrect;
    if (choices == null || choices.isEmpty || correct == null) return null;

    if (correct.length == choices.length) {
      final index = correct.indexWhere((value) => value == 1);
      return index >= 0 ? index : null;
    }
    if (correct.length == 1) {
      final index = correct.first;
      return index >= 0 && index < choices.length ? index : null;
    }
    return null;
  }
}
