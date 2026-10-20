import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
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
  })  : _client = client ?? _tryGetClient(),
        _duoDatabase = duoDatabase ?? DuoDbHelper.instance,
        _rewardService = rewardService ?? LearningRewardService(),
        _eventBuilder = eventBuilder;

  static SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final SupabaseClient? _client;
  final DuoDbHelper _duoDatabase;
  final LearningRewardService _rewardService;
  final VocabularyEventBuilder _eventBuilder;
  final Map<String, String> _unitIdByLevel = <String, String>{};

  @override
  Future<VocabularyMission?> loadMission({
    required String levelId,
    required int gameId,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final levelRows = List<Map<String, dynamic>>.from(
          await client
            .from('duo_levels')
            .select('unit_id, teaching_objective')
            .eq('id', levelId)
            .limit(1),
      );
      if (levelRows.isNotEmpty) {
        final level = levelRows.first;
        final unitId = '${level['unit_id'] ?? ''}';
        if (unitId.isNotEmpty) {
          _unitIdByLevel[levelId] = unitId;
        }
        final unitRows = List<Map<String, dynamic>>.from(
          await client
              .from('duo_units')
              .select('title')
              .eq('id', unitId)
              .limit(1),
        );

        final sessionRows = List<Map<String, dynamic>>.from(
          await client
              .from('duo_sessions')
              .select('id')
              .eq('level_id', levelId),
        );
        final sessionIds = sessionRows
            .map((row) => (row['id'] as num?)?.toInt())
            .whereType<int>()
            .toList(growable: false);

        if (sessionIds.isNotEmpty) {
          final challengeRows = List<Map<String, dynamic>>.from(
            await client
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

          if (challengeByWord.length >= 2) {
            final wordRows = List<Map<String, dynamic>>.from(
              await client
                  .from('lexicon_words')
                  .select(
                    'id, word, pinyin, meaning_vi, meaning_en, tts_url, hsk_level_id',
                  )
                  .inFilter('word', challengeByWord.keys.toList()),
            )
                .where((row) => '${row['meaning_vi'] ?? ''}'.trim().isNotEmpty)
                .toList();

            if (wordRows.length >= 2) {
              final wordIds = wordRows
                  .map((row) => (row['id'] as num?)?.toInt())
                  .whereType<int>()
                  .toList(growable: false);
              final exampleRows = List<Map<String, dynamic>>.from(
                await client
                    .from('lexicon_examples')
                    .select(
                      'id, word_id, example_order, sentence_cn, sentence_pinyin, sentence_vi',
                    )
                    .inFilter('word_id', wordIds)
                    .order('example_order'),
              );

              final examplesByWord = <int, List<ExampleSentence>>{};
              for (final row in exampleRows) {
                final wordId = (row['word_id'] as num?)?.toInt();
                if (wordId == null) continue;
                final sentence = '${row['sentence_cn'] ?? ''}'.trim();
                if (sentence.isEmpty) continue;
                examplesByWord.putIfAbsent(wordId, () => <ExampleSentence>[]).add(
                      ExampleSentence(
                        id: (row['id'] as num?)?.toInt() ?? 0,
                        wordId: wordId,
                        chinese: sentence,
                        pinyin: '${row['sentence_pinyin'] ?? ''}'.trim(),
                        vietnamese: '${row['sentence_vi'] ?? ''}'.trim(),
                        order: (row['example_order'] as num?)?.toInt() ?? 0,
                      ),
                    );
              }

              final progressByWord = <int, VocabularyWordProgress>{};
              final userId = client.auth.currentUser?.id;
              if (userId != null) {
                final progressRows = List<Map<String, dynamic>>.from(
                  await client
                      .from('user_word_progress')
                      .select(
                        'word_id, correct_count, wrong_count, is_mastered, next_review_at',
                      )
                      .eq('user_id', userId)
                      .inFilter('word_id', wordIds),
                );
                for (final row in progressRows) {
                  final wordId = (row['word_id'] as num?)?.toInt();
                  if (wordId == null) continue;
                  progressByWord[wordId] = VocabularyWordProgress(
                    correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
                    wrongCount: (row['wrong_count'] as num?)?.toInt() ?? 0,
                    mastered: row['is_mastered'] == true,
                    nextReviewAt: DateTime.tryParse(
                      '${row['next_review_at'] ?? ''}',
                    )?.toUtc(),
                  );
                }
              }

              final now = DateTime.now().toUtc();
              final candidates = wordRows.map((row) {
                final id = (row['id'] as num).toInt();
                final chinese = '${row['word'] ?? ''}';
                return VocabularyMissionWord(
                  word: Word.fromMap({
                    'id': id,
                    'word': chinese,
                    'chinese': chinese,
                    'pinyin': '${row['pinyin'] ?? ''}',
                    'meaning': '${row['meaning_vi'] ?? row['meaning_en'] ?? ''}',
                    'vietnamese':
                        '${row['meaning_vi'] ?? row['meaning_en'] ?? ''}',
                    'meaning_vi': row['meaning_vi'],
                    'meaning_en': row['meaning_en'],
                    'tts_url': row['tts_url'],
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
                  final mistakes =
                      b.progress.wrongCount.compareTo(a.progress.wrongCount);
                  if (mistakes != 0) return mistakes;
                  final exposure =
                      a.progress.correctCount.compareTo(b.progress.correctCount);
                  if (exposure != 0) return exposure;
                  return (sourceOrder[a.word.chinese] ?? 0)
                      .compareTo(sourceOrder[b.word.chinese] ?? 0);
                });

              final words =
                  candidates.take(math.min(4, candidates.length)).toList();
              final events = _eventBuilder.build(words);
              if (events.isNotEmpty) {
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
            }
          }
        }
      }
    } catch (_) {}
  }

  // Offline Local Fallback
  return await _loadLocalMission(levelId: levelId, gameId: gameId);
}

  Future<VocabularyMission?> _loadLocalMission({
    required String levelId,
    required int gameId,
  }) async {
    if (!AppDatabase.instance.isOpen) return null;
    try {
      final unitId =
          int.tryParse(levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      _unitIdByLevel[levelId] = '$unitId';
      final wordRows = await AppDatabase.instance.getWordsByUnit(unitId);
      if (wordRows.length < 2) return null;

      final words = <VocabularyMissionWord>[];
      for (final row in wordRows) {
        final id = (row['id'] as num).toInt();
        final zh = '${row['word'] ?? ''}';
        final pinyin = '${row['pinyin'] ?? ''}';
        final vi = '${row['meaning_vi'] ?? ''}';
        final tts = '${row['tts_url'] ?? ''}';

        final word = Word.fromMap({
          'id': id,
          'word': zh,
          'chinese': zh,
          'pinyin': pinyin,
          'vietnamese': vi,
          'meaning_vi': vi,
          'tts_url': tts,
        });

        final challenge = DuoChallenge(
          id: 'vocab_ch_$id',
          type: 'select',
          prompt: zh,
          tts: zh,
          choicesText: [zh],
          choicesCorrect: [1],
          solutions: zh,
        );

        words.add(VocabularyMissionWord(
          word: word,
          sourceChallenge: challenge,
          examples: const [],
          progress: const VocabularyWordProgress(),
        ));
      }

      final candidates = words.take(math.min(4, words.length)).toList();
      final events = _eventBuilder.build(candidates);
      if (events.isEmpty) return null;

      return VocabularyMission(
        levelId: levelId,
        gameId: gameId,
        title: 'Học từ vựng Bài $unitId',
        objective: 'Khám phá và làm quen từ vựng trong bài học.',
        words: candidates,
        events: events,
      );
    } catch (e) {
      debugPrint('[VocabularyAdventureRepository] _loadLocalMission failed: $e');
      return null;
    }
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
  }) async {
    var unitId = _unitIdByLevel[levelId];
    if (unitId == null || unitId.isEmpty) {
      unitId = await _fetchUnitId(levelId);
    }
    unitId ??= levelId.replaceAll(RegExp(r'[^0-9]'), '');
    return _rewardService.startDuoGameAttempt(
      gameId: gameId,
      gameCode: 'learn_words',
      levelId: levelId,
      unitId: unitId,
      attemptId: attemptId,
    );
  }

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
    final client = _client;
    if (client?.auth.currentUser != null) {
      try {
        final response = await client!.rpc(
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
        if (row != null) {
          return VocabularyMasteryUpdate(mastered: row['mastered'] == true);
        }
      } catch (_) {}
    }

    if (AppDatabase.instance.isOpen) {
      try {
        final profileId = AppDatabase.instance.activeProfileId;
        final db = AppDatabase.instance.database;
        await db.rawInsert('''
          INSERT INTO local_word_srs (
            local_id, word_id, srs_stage, next_review_at_utc, last_reviewed_at_utc,
            correct_count, wrong_count
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(local_id, word_id) DO UPDATE SET
            srs_stage = CASE WHEN ? THEN srs_stage + 1 ELSE MAX(1, srs_stage - 1) END,
            correct_count = correct_count + CASE WHEN ? THEN 1 ELSE 0 END,
            wrong_count = wrong_count + CASE WHEN ? THEN 0 ELSE 1 END,
            last_reviewed_at_utc = excluded.last_reviewed_at_utc;
        ''', [
          profileId,
          wordId,
          isCorrect ? 1 : 0,
          DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
          DateTime.now().toUtc().toIso8601String(),
          isCorrect ? 1 : 0,
          isCorrect ? 0 : 1,
          isCorrect ? 1 : 0,
          isCorrect ? 1 : 0,
          isCorrect ? 1 : 0,
        ]);
        return VocabularyMasteryUpdate(mastered: isCorrect && masteryLevel >= 3);
      } catch (e) {
        debugPrint(
            '[VocabularyAdventureRepository] local recordWordOutcome warning: $e');
      }
    }

    return null;
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
    var unitId = _unitIdByLevel[levelId];
    if (unitId == null || unitId.isEmpty) {
      unitId = await _fetchUnitId(levelId);
    }
    unitId ??= levelId.replaceAll(RegExp(r'[^0-9]'), '');
    final reward = await _rewardService.processVocabularyReward(
      levelId: levelId,
      unitId: unitId,
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
        unitId: unitId,
      );
      if (reward.passed) {
        await _unlockNextPlayableLevel(gameId, levelId, reward, unitId);
      }
      await _duoDatabase.clearActiveSession(gameId, levelId);
    }
    return reward;
  }

  Future<void> _unlockNextPlayableLevel(
    int gameId,
    String levelId,
    LearningResult reward,
    String? unitId,
  ) async {
    if (reward.nextNodeId != null && reward.nextNodeId!.isNotEmpty) {
      final parts = reward.nextNodeId!.split(':');
      final nextGameId = parts.length >= 2 ? int.tryParse(parts[0]) : null;
      final nextLevelId = parts.length >= 2 ? parts[1] : reward.nextNodeId!;
      if (nextGameId != null && nextLevelId.isNotEmpty) {
        await _duoDatabase.unlockLevel(nextGameId, nextLevelId);
        return;
      }
    }

    if (unitId != null && unitId.isNotEmpty) {
      final unitPath = await _duoDatabase.getUnitLearningPath(unitId);
      final idx = unitPath.indexWhere((r) =>
          (r['game_id'] as num?)?.toInt() == gameId &&
          '${r['level_id'] ?? ''}' == levelId);
      if (idx != -1 && idx + 1 < unitPath.length) {
        final nextNode = unitPath[idx + 1];
        if (nextNode['node_type'] == 'learning') {
          final nextGId = (nextNode['game_id'] as num?)?.toInt() ?? gameId;
          final nextLId = '${nextNode['level_id'] ?? ''}';
          if (nextLId.isNotEmpty) {
            await _duoDatabase.unlockLevel(nextGId, nextLId);
            return;
          }
        }
      }
    }

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

  Future<String?> _fetchUnitId(String levelId) async {
    final client = _client;
    if (client != null) {
      try {
        final levelRows = List<Map<String, dynamic>>.from(
          await client
              .from('duo_levels')
              .select('unit_id')
              .eq('id', levelId)
              .limit(1),
        );
        if (levelRows.isNotEmpty) {
          final uId = '${levelRows.first['unit_id'] ?? ''}';
          if (uId.isNotEmpty) {
            _unitIdByLevel[levelId] = uId;
            return uId;
          }
        }
      } catch (_) {}
    }
    return null;
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
