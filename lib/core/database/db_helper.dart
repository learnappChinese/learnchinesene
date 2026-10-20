import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_database.dart';
import '../models/example_sentence.dart';
import '../models/hsk_level.dart';
import '../models/topic.dart';
import '../models/unit_model.dart';
import '../models/word.dart';
import '../learning/service/spaced_repetition_service.dart';
import '../models/speaking_practice_item.dart';
import '../models/hanzi_character.dart';
import '../../features/hanzi_writing/services/hanzi_stroke_cache.dart';

class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }



  Future<dynamic> get database async {
    if (AppDatabase.instance.isOpen) {
      return AppDatabase.instance.database;
    }
    final client = _client;
    if (client != null) {
      try {
        await client.from('lexicon_hsk_levels').select('id').limit(1);
        return client;
      } catch (_) {}
    }
    return null;
  }

  Future<List<HskLevel>> getHskLevels() async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getHskLevels();
      if (rows.isNotEmpty) {
        return rows
            .map(
              (row) => HskLevel.fromMap({
                'id': row['id'],
                'title': row['name'],
                'level_order': row['sort_order'] ?? row['id'],
              }),
            )
            .toList();
      }
    }

    final client = _client;
    if (client == null) return <HskLevel>[];

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_hsk_levels')
          .select('id, name, sort_order')
          .order('sort_order')
          .order('id'),
    );

    return rows
        .map(
          (row) => HskLevel.fromMap({
            'id': row['id'],
            'title': row['name'],
            'level_order': row['sort_order'] ?? row['id'],
          }),
        )
        .toList();
  }

  Future<List<UnitModel>> getUnitsByLevel(int hskLevelId) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getUnitsByHskLevel(hskLevelId);
      if (rows.isNotEmpty) {
        return rows
            .map(
              (row) => UnitModel.fromMap({
                'id': row['id'],
                'title': row['title'],
                'unit_order': row['sort_order'] ?? row['unit_number'] ?? row['id'],
              }),
            )
            .toList();
      }
    }

    final client = _client;
    if (client == null) return <UnitModel>[];

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_units')
          .select('id, title, sort_order, unit_number')
          .eq('hsk_level_id', hskLevelId)
          .order('sort_order')
          .order('unit_number'),
    );

    return rows
        .map(
          (row) => UnitModel.fromMap({
            'id': row['id'],
            'title': row['title'],
            'unit_order': row['sort_order'] ?? row['unit_number'] ?? row['id'],
          }),
        )
        .toList();
  }

  Future<List<Topic>> getTopicsByUnit(int unitId) async {
    final client = _client;
    if (client == null) return <Topic>[];

    final sourceRows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_word_sources')
          .select('topic_id')
          .eq('unit_id', unitId),
    );

    final topicIds = sourceRows
        .map((row) => (row['topic_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet()
        .toList();

    if (topicIds.isEmpty) return <Topic>[];

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_topics')
          .select('id, name_vi, name_en')
          .inFilter('id', topicIds)
          .order('id'),
    );

    return rows
        .map(
          (row) => Topic.fromMap({
            'id': row['id'],
            'title': '${row['name_vi'] ?? row['name_en'] ?? 'Chủ đề'}',
            'topic_order': row['id'],
          }),
        )
        .toList();
  }

  /// Lấy danh sách từ vựng theo cấp độ HSK trong 1 câu truy vấn SQLite nhanh.
  Future<List<Word>> getWordsByHskLevel(int hskLevelId, {int? limit}) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getWordsByHskLevel(
        hskLevelId,
        limit: limit,
      );
      if (rows.isNotEmpty) {
        return rows.map((row) {
          return Word.fromMap(_mapCloudWord(
            row,
            sectionTitle: 'HSK $hskLevelId',
            groupSubtitle: '',
          ));
        }).toList();
      }
    }

    final units = await getUnitsByLevel(hskLevelId);
    final words = <Word>[];
    for (final unit in units) {
      words.addAll(await getWordsByUnit(unit.id));
      if (limit != null && words.length >= limit) break;
    }
    return limit != null ? words.take(limit).toList() : words;
  }

  Future<List<Word>> getWordsByUnit(int unitId) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getWordsByUnit(unitId);
      if (rows.isNotEmpty) {
        return rows.map((row) {
          final levelId = (row['hsk_level_id'] as num?)?.toInt() ?? 1;
          return Word.fromMap(_mapCloudWord(
            row,
            sectionTitle: 'HSK $levelId',
            groupSubtitle: 'Bài $unitId',
          ));
        }).toList();
      }
    }

    final client = _client;
    if (client == null) return <Word>[];

    final linkRows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_word_sources')
          .select('word_id')
          .eq('unit_id', unitId)
          .order('word_id'),
    );

    final wordIds = linkRows
        .map((row) => (row['word_id'] as num?)?.toInt())
        .whereType<int>()
        .toList();

    if (wordIds.isEmpty) return <Word>[];

    final unitRows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_units')
          .select('title, hsk_level_id')
          .eq('id', unitId)
          .limit(1),
    );

    final unitTitle =
        unitRows.isEmpty ? '' : '${unitRows.first['title'] ?? ''}';
    final hskLevelId = unitRows.isEmpty
        ? 0
        : (unitRows.first['hsk_level_id'] as num?)?.toInt() ?? 0;

    final levelTitle = await _levelTitle(hskLevelId);
    final words = await _fetchWordsByIds(wordIds);

    return words
        .map(
          (row) => Word.fromMap(
            _mapCloudWord(
              row,
              sectionTitle: levelTitle,
              groupSubtitle: unitTitle,
            ),
          ),
        )
        .toList();
  }

  Future<List<Word>> getWordsByIds(List<int> ids) async {
    if (ids.isEmpty) return <Word>[];

    if (AppDatabase.instance.isOpen) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final rows = await AppDatabase.instance.database.rawQuery('''
        SELECT * FROM lexicon_words WHERE id IN ($placeholders) ORDER BY id
      ''', ids);

      if (rows.isNotEmpty) {
        return rows.map((r) => Word.fromMap(_mapCloudWord(r))).toList();
      }
    }

    final rows = await _fetchWordsByIds(ids);
    final levelNames = <int, String>{};

    for (final row in rows) {
      final level = (row['hsk_level_id'] as num?)?.toInt() ?? 0;
      levelNames[level] ??= await _levelTitle(level);
    }

    return rows
        .map(
          (row) => Word.fromMap(
            _mapCloudWord(
              row,
              sectionTitle:
                  levelNames[(row['hsk_level_id'] as num?)?.toInt() ?? 0] ?? '',
            ),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchWordsByIds(List<int> ids) async {
    if (ids.isEmpty) return <Map<String, dynamic>>[];
    final client = _client;
    if (client == null) return <Map<String, dynamic>>[];

    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 200) {
      final chunk = ids.sublist(i, min(i + 200, ids.length));
      out.addAll(
        List<Map<String, dynamic>>.from(
          await client
              .from('lexicon_words')
              .select(
                'id, word, pinyin, meaning_vi, meaning_en, tts_url, hsk_level_id, main_character_id',
              )
              .inFilter('id', chunk)
              .order('id'),
        ),
      );
    }
    return out;
  }

  Future<List<ExampleSentence>> getExamplesByWord(int wordId) async {
    final client = _client;
    if (client == null) return <ExampleSentence>[];

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_examples')
          .select(
            'id, word_id, example_order, sentence_cn, sentence_pinyin, sentence_vi',
          )
          .eq('word_id', wordId)
          .order('example_order')
          .order('id'),
    );

    return rows
        .map(
          (row) => ExampleSentence.fromMap({
            'id': row['id'],
            'word_id': row['word_id'],
            'chinese': row['sentence_cn'],
            'pinyin': row['sentence_pinyin'],
            'vietnamese': row['sentence_vi'],
            'order_index': row['example_order'] ?? row['id'],
          }),
        )
        .toList();
  }

  Future<List<ExampleSentence>> getExamplesByUnit(int unitId) async {
    final client = _client;
    if (client == null) return <ExampleSentence>[];

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_examples')
          .select(
            'id, word_id, example_order, sentence_cn, sentence_pinyin, sentence_vi',
          )
          .eq('unit_id', unitId)
          .order('example_order')
          .order('id'),
    );

    return rows
        .map(
          (row) => ExampleSentence.fromMap({
            'id': row['id'],
            'word_id': row['word_id'],
            'chinese': row['sentence_cn'],
            'pinyin': row['sentence_pinyin'],
            'vietnamese': row['sentence_vi'],
            'order_index': row['example_order'] ?? row['id'],
          }),
        )
        .toList();
  }

  Future<List<Word>> getReviewWords({int limit = 30}) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getDueSrsWords(limit: limit);
      final ids = rows
          .map((r) => (r['id'] as num?)?.toInt() ?? (r['word_id'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      if (ids.isNotEmpty) {
        return getWordsByIds(ids);
      }
    }

    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return <Word>[];

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_user_progress')
          .select('word_id, wrong_count, mastered, next_review_at')
          .eq('user_id', userId)
          .eq('mastered', false)
          .order('next_review_at'),
    );

    final now = DateTime.now().toUtc();
    final ids = rows
        .where((row) {
          final wrong = (row['wrong_count'] as num?)?.toInt() ?? 0;
          final due = DateTime.tryParse('${row['next_review_at'] ?? ''}');
          return wrong > 0 || due == null || !due.toUtc().isAfter(now);
        })
        .map((row) => (row['word_id'] as num?)?.toInt())
        .whereType<int>()
        .toList();

    return getWordsByIds(ids);
  }

  Future<void> upsertProgress({
    required int wordId,
    required bool isCorrect,
    int level = 1,
    SrsRating? rating,
  }) async {
    final effectiveRating = rating ?? (isCorrect ? SrsRating.good : SrsRating.hard);
    if (AppDatabase.instance.isOpen) {
      await AppDatabase.instance.recordWordSrsRating(
        wordId: wordId,
        rating: effectiveRating,
      );
    }

    final client = _client;
    if (client?.auth.currentUser != null) {
      try {
        await client!.rpc(
          'record_word_progress',
          params: {
            'p_word_id': wordId,
            'p_is_correct': isCorrect,
            'p_level': level,
          },
        );
      } catch (_) {}
    }
  }

  Future<void> markLearned(int wordId) async {
    await upsertProgress(wordId: wordId, isCorrect: true);
  }

  Future<Map<String, num>> getStats() async {
    if (AppDatabase.instance.isOpen) {
      final totalXp = await AppDatabase.instance.getTotalXp();
      final streak = await AppDatabase.instance.getCurrentStreak();
      final rows = await AppDatabase.instance.database.rawQuery('''
        SELECT COUNT(DISTINCT word_id) AS cnt
        FROM local_word_srs
        WHERE local_id = ? AND srs_stage > 0
      ''', [AppDatabase.instance.activeProfileId]);
      final wordsMastered = (rows.first['cnt'] as num?)?.toInt() ?? 0;

      return {
        'learned': wordsMastered,
        'mastered': wordsMastered,
        'correct': 0,
        'wrong': 0,
        'speakingAttempts': 0,
        'speakingAverage': 0,
        'streak': streak,
        'totalExp': totalXp,
        'favorites': 0,
        'wordsMastered': wordsMastered,
      };
    }

    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return {
        'learned': 0,
        'mastered': 0,
        'correct': 0,
        'wrong': 0,
        'speakingAttempts': 0,
        'speakingAverage': 0,
        'streak': 0,
        'totalExp': 0,
        'favorites': 0,
        'wordsMastered': 0,
      };
    }

    final learningRows = List<Map<String, dynamic>>.from(
      await client.rpc('learning_stats'),
    );
    final learning =
        learningRows.isEmpty ? <String, dynamic>{} : learningRows.first;

    final appRows = List<Map<String, dynamic>>.from(
      await client
          .from('app_user_stats')
          .select(
            'total_exp, current_streak, total_words_mastered, total_favorites',
          )
          .eq('user_id', userId)
          .limit(1),
    );
    final app = appRows.isEmpty ? <String, dynamic>{} : appRows.first;

    return {
      'learned': (learning['learned'] as num?) ?? 0,
      'mastered': (learning['mastered'] as num?) ?? 0,
      'correct': (learning['correct'] as num?) ?? 0,
      'wrong': (learning['wrong'] as num?) ?? 0,
      'speakingAttempts': (learning['speaking_attempts'] as num?) ?? 0,
      'speakingAverage': (learning['speaking_average'] as num?) ?? 0,
      'streak': (app['current_streak'] as num?) ?? 0,
      'totalExp': (app['total_exp'] as num?) ?? 0,
      'favorites': (app['total_favorites'] as num?) ?? 0,
      'wordsMastered': (app['total_words_mastered'] as num?) ?? 0,
    };
  }

  Future<Map<String, int>> getUnitMetrics(int unitId) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getWordsByUnit(unitId);
      final profileId = AppDatabase.instance.activeProfileId;
      final learnedRows = await AppDatabase.instance.database.rawQuery('''
        SELECT COUNT(DISTINCT s.word_id) AS cnt
        FROM local_word_srs s
        INNER JOIN lexicon_word_sources ws ON s.word_id = ws.word_id
        WHERE ws.unit_id = ? AND s.local_id = ? AND s.srs_stage > 0
      ''', [unitId, profileId]);
      final learned = (learnedRows.first['cnt'] as num?)?.toInt() ?? 0;

      return {
        'words': rows.length,
        'learned': learned,
        'examples': 0,
      };
    }

    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return {'words': 0, 'learned': 0, 'examples': 0};
    }

    final rows = List<Map<String, dynamic>>.from(
      await client.rpc(
        'unit_learning_metrics',
        params: {'p_unit_id': unitId},
      ),
    );
    final row = rows.isEmpty ? <String, dynamic>{} : rows.first;

    return {
      'words': (row['words'] as num?)?.toInt() ?? 0,
      'learned': (row['learned'] as num?)?.toInt() ?? 0,
      'examples': (row['examples'] as num?)?.toInt() ?? 0,
    };
  }

  Future<int> getUnitCountForLevel(int levelId) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.getUnitsByHskLevel(levelId);
      return rows.length;
    }
    final client = _client;
    if (client == null) return 0;
    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_units')
          .select('id')
          .eq('hsk_level_id', levelId),
    );
    return rows.length;
  }

  Future<double> getLevelProgress(int levelId) async {
    if (AppDatabase.instance.isOpen) {
      final units = await AppDatabase.instance.getUnitsByHskLevel(levelId);
      if (units.isEmpty) return 0;
      final profileId = AppDatabase.instance.activeProfileId;
      final completed = await AppDatabase.instance.database.rawQuery('''
        SELECT COUNT(DISTINCT level_id) as cnt
        FROM local_stage_progress
        WHERE local_id = ? AND status = 'completed'
      ''', [profileId]);
      final count = (completed.first['cnt'] as num?)?.toInt() ?? 0;
      return (count / units.length).clamp(0.0, 1.0);
    }
    return 0;
  }

  Future<SpeakingPracticeItem?> getSpeakingItemByWordId(int wordId) async {
    final words = await getWordsByIds([wordId]);
    if (words.isEmpty) return null;
    final word = words.first;
    return SpeakingPracticeItem(
      wordId: word.id,
      targetText: word.chinese,
      pinyin: word.pinyin,
      meaning: word.vietnamese,
      audioUrl: word.ttsUrl,
    );
  }

  Future<SpeakingPracticeItem?> getSpeakingItemByExampleId(int exampleId) async {
    return null;
  }

  Future<List<SpeakingPracticeItem>> getSpeakingItemsByUnitId(int unitId) async {
    final words = await getWordsByUnit(unitId);
    return words
        .map(
          (word) => SpeakingPracticeItem(
            wordId: word.id,
            targetText: word.chinese,
            pinyin: word.pinyin,
            meaning: word.vietnamese,
            audioUrl: word.ttsUrl,
          ),
        )
        .toList();
  }

  Future<List<SpeakingPracticeItem>> getRandomSpeakingItems({
    int limit = 20,
  }) async {
    if (AppDatabase.instance.isOpen) {
      final rows = await AppDatabase.instance.database.rawQuery('''
        SELECT * FROM lexicon_words ORDER BY RANDOM() LIMIT ?
      ''', [limit]);
      return rows
          .map(
            (row) => SpeakingPracticeItem.fromMap({
              'word_id': row['id'],
              'word': row['word'],
              'pinyin': row['pinyin'],
              'meaning_vi': row['meaning_vi'],
              'tts_url': row['tts_url'],
            }),
          )
          .toList();
    }
    return [];
  }

  Future<List<HanziCharacter>> getCharactersForWriting({
    String? keyword,
    int? hskLevel,
    int? unitId,
  }) async {
    if (AppDatabase.instance.isOpen) {
      final List<Map<String, dynamic>> rows;
      if (unitId != null) {
        rows = await AppDatabase.instance.getCharactersByUnit(unitId);
      } else {
        rows = await AppDatabase.instance.getCharactersByHskLevel(
          hskLevel: hskLevel,
          keyword: keyword,
        );
      }
      final chars = rows.map((r) => HanziCharacter.fromMap({
        'id': r['id'],
        'character': r['character'],
        'stroke_count': r['stroke_count'],
        'stroke_width': r['stroke_width'],
        'stroke_height': r['stroke_height'],
        'stroke_paths': r['stroke_paths'] ?? '',
        'pinyin': r['pinyin'] ?? '',
        'meaning': r['meaning_vi'] ?? '',
        'hsk_level_id': r['hsk_level_id'],
        'practice_count': r['practice_count'] ?? 0,
        'best_score': (r['best_score'] as num?)?.toDouble() ?? 0.0,
      })).toList();

      // Tải trước vào cache để vẽ và chuyển nét mượt mà
      HanziStrokeCache.instance.prefetch(chars);
      return chars;
    }

    final client = _client;
    if (client == null) return <HanziCharacter>[];

    final characters = List<Map<String, dynamic>>.from(
      await client
          .from('lexicon_characters')
          .select(
            'id, character, stroke_count, stroke_width, stroke_height, stroke_paths',
          )
          .order('id')
          .range(0, 999),
    );
    final words = await _fetchWordCatalog();
    final userId = client.auth.currentUser?.id;
    final progressRows = userId == null
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await client
                .from('lexicon_hanzi_progress')
                .select(
                  'character_id, practice_count, best_score, last_score, next_review_at',
                )
                .eq('user_id', userId),
          );
    final progressByCharacter = <int, Map<String, dynamic>>{
      for (final row in progressRows)
        if (row['character_id'] is num)
          (row['character_id'] as num).toInt(): row,
    };

    final byCharacter = <String, Map<String, dynamic>>{};
    final byMain = <int, Map<String, dynamic>>{};
    for (final word in words) {
      final text = '${word['word'] ?? ''}';
      if (text.isNotEmpty) byCharacter.putIfAbsent(text, () => word);
      final main = (word['main_character_id'] as num?)?.toInt();
      if (main != null) byMain.putIfAbsent(main, () => word);
    }

    final filter = keyword?.trim().toLowerCase();
    final result = <HanziCharacter>[];

    for (final char in characters) {
      final id = (char['id'] as num?)?.toInt();
      if (id == null) continue;
      final character = '${char['character'] ?? ''}';
      final word = byCharacter[character] ?? byMain[id];
      final pinyin = '${word?['pinyin'] ?? ''}';
      final meaning = '${word?['meaning_vi'] ?? ''}';
      final level = (word?['hsk_level_id'] as num?)?.toInt();
      final progress = progressByCharacter[id];

      if (hskLevel != null && level != hskLevel) continue;
      if (filter != null &&
          filter.isNotEmpty &&
          !('$character $pinyin $meaning'.toLowerCase().contains(filter))) {
        continue;
      }

      result.add(
        HanziCharacter.fromMap({
          'id': id,
          'character': character,
          'stroke_count': char['stroke_count'],
          'stroke_width': char['stroke_width'],
          'stroke_height': char['stroke_height'],
          'stroke_paths': char['stroke_paths'] ?? '',
          'pinyin': pinyin,
          'meaning': meaning,
          'hsk_level_id': level,
          'practice_count': progress?['practice_count'],
          'best_score': progress?['best_score'],
          'last_score': progress?['last_score'],
          'next_review_at': progress?['next_review_at'],
        }),
      );
    }

    return result;
  }

  /// Lấy 1 chữ Hán nhanh: Kiểm tra Cache -> Query SQLite 1 dòng -> Fallback.
  Future<HanziCharacter?> getCharacterForWritingById(int characterId) async {
    final cached = HanziStrokeCache.instance.getCharacter(characterId);
    if (cached != null) return cached;

    if (AppDatabase.instance.isOpen) {
      final row = await AppDatabase.instance.getCharacterById(characterId);
      if (row != null) {
        final char = HanziCharacter.fromMap({
          'id': row['id'],
          'character': row['character'],
          'stroke_count': row['stroke_count'],
          'stroke_width': row['stroke_width'],
          'stroke_height': row['stroke_height'],
          'stroke_paths': row['stroke_paths'] ?? '',
          'pinyin': row['pinyin'] ?? '',
          'meaning': row['meaning_vi'] ?? '',
          'hsk_level_id': row['hsk_level_id'],
          'practice_count': row['practice_count'] ?? 0,
          'best_score': (row['best_score'] as num?)?.toDouble() ?? 0.0,
        });
        HanziStrokeCache.instance.putCharacter(char);
        return char;
      }
    }

    final chars = await getCharactersForWriting();
    final matches = chars.where((c) => c.id == characterId);
    return matches.isEmpty ? null : matches.first;
  }

  /// Lấy danh sách chữ Hán theo bài học (Unit).
  Future<List<HanziCharacter>> getCharactersByUnitForWriting(int unitId) async {
    return getCharactersForWriting(unitId: unitId);
  }

  Future<int?> getCharacterIdByCharString(String charStr) async {
    if (charStr.trim().isEmpty) return null;
    final exactChar = charStr.trim();
    final firstChar = exactChar.isNotEmpty ? exactChar[0] : exactChar;

    if (AppDatabase.instance.isOpen) {
      for (final target in [exactChar, if (exactChar != firstChar) firstChar]) {
        final rows = await AppDatabase.instance.database.query(
          'lexicon_characters',
          columns: ['id'],
          where: 'character = ?',
          whereArgs: [target],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          return (rows.first['id'] as num?)?.toInt();
        }
      }
    }

    final client = _client;
    if (client != null) {
      for (final target in [exactChar, if (exactChar != firstChar) firstChar]) {
        try {
          final rows = List<Map<String, dynamic>>.from(
            await client
                .from('lexicon_characters')
                .select('id')
                .eq('character', target)
                .limit(1),
          );
          if (rows.isNotEmpty) {
            return (rows.first['id'] as num?)?.toInt();
          }
        } catch (_) {}
      }
    }

    try {
      final chars = await getCharactersForWriting();
      final exactMatch = chars.where((c) => c.character == exactChar);
      if (exactMatch.isNotEmpty) return exactMatch.first.id;
      final firstMatch = chars.where((c) => c.character == firstChar);
      if (firstMatch.isNotEmpty) return firstMatch.first.id;
    } catch (_) {}

    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchWordCatalog() async {
    final client = _client;
    if (client == null) return <Map<String, dynamic>>[];
    final out = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = List<Map<String, dynamic>>.from(
        await client
            .from('lexicon_words')
            .select(
              'id, word, pinyin, meaning_vi, meaning_en, tts_url, hsk_level_id, main_character_id',
            )
            .order('id')
            .range(from, from + 999),
      );
      out.addAll(page);
      if (page.length < 1000) break;
      from += 1000;
    }

    return out;
  }

  Future<String> _levelTitle(int levelId) async {
    if (levelId <= 0) return '';
    final levels = await getHskLevels();
    final match = levels.where((l) => l.id == levelId);
    return match.isEmpty ? 'HSK $levelId' : match.first.title;
  }

  static Map<String, dynamic> _mapCloudWord(
    Map<String, dynamic> row, {
    String sectionTitle = '',
    String groupSubtitle = '',
  }) {
    return {
      'id': row['id'],
      'chinese': row['word'],
      'pinyin': row['pinyin'],
      'vietnamese': row['meaning_vi'],
      'english': row['meaning_en'],
      'tts_url': row['tts_url'],
      'hsk_level_id': row['hsk_level_id'],
      'section_title': sectionTitle,
      'group_subtitle': groupSubtitle,
    };
  }
}
