import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/example_sentence.dart';
import '../models/hsk_level.dart';
import '../models/topic.dart';
import '../models/unit_model.dart';
import '../models/word.dart';
import '../models/speaking_practice_item.dart';
import '../models/hanzi_character.dart';

class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<SupabaseClient> get database async {
    await _client.from('lexicon_hsk_levels').select('id').limit(1);
    return _client;
  }

  Future<List<HskLevel>> getHskLevels() async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
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
    final rows = List<Map<String, dynamic>>.from(
      await _client
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
    final sourceRows = List<Map<String, dynamic>>.from(
      await _client
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
      await _client
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

  Future<List<Word>> getWordsByUnit(int unitId) async {
    final linkRows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_word_units')
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
      await _client
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

    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 200) {
      final chunk = ids.sublist(i, min(i + 200, ids.length));
      out.addAll(
        List<Map<String, dynamic>>.from(
          await _client
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
    final rows = List<Map<String, dynamic>>.from(
      await _client
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

  Future<List<Word>> getReviewWords() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return <Word>[];
    final rows = List<Map<String, dynamic>>.from(
      await _client
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
  }) async {
    if (_client.auth.currentUser == null) return;
    await _client.rpc(
      'record_word_progress',
      params: {
        'p_word_id': wordId,
        'p_is_correct': isCorrect,
        'p_level': level,
      },
    );
  }

  Future<void> markLearned(int wordId) async {
    if (_client.auth.currentUser == null) return;
    await _client.rpc(
      'mark_word_learned',
      params: {'p_word_id': wordId},
    );
  }

  Future<Map<String, num>> getStats() async {
    if (_client.auth.currentUser == null) {
      return {
        'learned': 0,
        'mastered': 0,
        'correct': 0,
        'wrong': 0,
        'speakingAttempts': 0,
        'speakingAverage': 0,
      };
    }
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc('learning_stats'),
    );
    final row = rows.isEmpty ? <String, dynamic>{} : rows.first;

    return {
      'learned': (row['learned'] as num?) ?? 0,
      'mastered': (row['mastered'] as num?) ?? 0,
      'correct': (row['correct'] as num?) ?? 0,
      'wrong': (row['wrong'] as num?) ?? 0,
      'speakingAttempts': (row['speaking_attempts'] as num?) ?? 0,
      'speakingAverage': (row['speaking_average'] as num?) ?? 0,
    };
  }

  Future<Map<String, int>> getUnitMetrics(int unitId) async {
    if (_client.auth.currentUser == null) {
      final wordRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_word_units')
            .select('word_id')
            .eq('unit_id', unitId),
      );
      final exampleRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_examples')
            .select('id')
            .eq('unit_id', unitId),
      );
      return {
        'words': wordRows.length,
        'learned': 0,
        'examples': exampleRows.length,
      };
    }
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
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
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_units')
          .select('id')
          .eq('hsk_level_id', levelId),
    );
    return rows.length;
  }

  Future<double> getLevelProgress(int levelId) async {
    if (_client.auth.currentUser == null) return 0;
    final value = await _client.rpc(
      'level_learning_progress',
      params: {'p_level_id': levelId},
    );
    return (value as num?)?.toDouble() ?? 0;
  }

  Future<SpeakingPracticeItem?> getSpeakingItemByWordId(int wordId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_words')
          .select('id, word, pinyin, meaning_vi, tts_url')
          .eq('id', wordId)
          .limit(1),
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return SpeakingPracticeItem.fromMap({
      'word_id': row['id'],
      'word': row['word'],
      'pinyin': row['pinyin'],
      'meaning_vi': row['meaning_vi'],
      'tts_url': row['tts_url'],
    });
  }

  Future<SpeakingPracticeItem?> getSpeakingItemByExampleId(
    int exampleId,
  ) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_examples')
          .select('id, word_id, sentence_cn, sentence_pinyin, sentence_vi')
          .eq('id', exampleId)
          .limit(1),
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final wordId = (row['word_id'] as num?)?.toInt();
    final word = wordId == null ? null : await getSpeakingItemByWordId(wordId);

    return SpeakingPracticeItem.fromMap({
      'example_id': row['id'],
      'word_id': row['word_id'],
      'sentence_cn': row['sentence_cn'],
      'sentence_pinyin': row['sentence_pinyin'],
      'sentence_vi': row['sentence_vi'],
      'tts_url': word?.audioUrl,
    });
  }

  Future<List<SpeakingPracticeItem>> getSpeakingItemsByUnitId(
    int unitId,
  ) async {
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
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc('random_lexicon_words', params: {'p_limit': limit}),
    );
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

  Future<void> saveSpeakingPractice({
    required int wordId,
    int? exampleId,
    required String targetText,
    required String recognizedText,
    required double score,
    required bool isCorrect,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('lexicon_speaking_practice').insert({
      'user_id': userId,
      'word_id': wordId,
      'example_id': exampleId,
      'target_text': targetText,
      'recognized_text': recognizedText,
      'accuracy_score': score,
      'pronunciation_score': score,
    });
  }

  Future<List<HanziCharacter>> getCharactersForWriting({
    String? keyword,
    int? hskLevel,
  }) async {
    final characters = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_characters')
          .select(
            'id, character, stroke_count, stroke_width, stroke_height, stroke_paths',
          )
          .order('id')
          .range(0, 999),
    );
    final words = await _fetchWordCatalog();

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
        }),
      );
    }

    return result;
  }

  Future<HanziCharacter?> getCharacterForWritingById(int characterId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_characters')
          .select(
            'id, character, stroke_count, stroke_width, stroke_height, stroke_paths',
          )
          .eq('id', characterId)
          .limit(1),
    );
    if (rows.isEmpty) return null;

    final char = rows.first;
    final character = '${char['character'] ?? ''}';
    var words = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_words')
          .select('pinyin, meaning_vi, hsk_level_id')
          .eq('word', character)
          .limit(1),
    );
    if (words.isEmpty) {
      words = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_words')
            .select('pinyin, meaning_vi, hsk_level_id')
            .eq('main_character_id', characterId)
            .limit(1),
      );
    }
    final word = words.isEmpty ? null : words.first;

    return HanziCharacter.fromMap({
      'id': char['id'],
      'character': character,
      'stroke_count': char['stroke_count'],
      'stroke_width': char['stroke_width'],
      'stroke_height': char['stroke_height'],
      'stroke_paths': char['stroke_paths'] ?? '',
      'pinyin': word?['pinyin'],
      'meaning': word?['meaning_vi'],
      'hsk_level_id': word?['hsk_level_id'],
    });
  }

  Future<int?> getCharacterIdByCharString(String charStr) async {
    if (charStr.isEmpty) return null;

    Future<int?> lookup(String value) async {
      final rows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_characters')
            .select('id')
            .eq('character', value)
            .gt('stroke_count', 0)
            .limit(1),
      );
      return rows.isEmpty ? null : (rows.first['id'] as num?)?.toInt();
    }

    return await lookup(charStr) ?? await lookup(charStr.substring(0, 1));
  }

  Future<void> saveHanziWritingProgress({
    required int characterId,
    required double score,
    required int attempts,
  }) async {
    if (_client.auth.currentUser == null) return;
    await _client.rpc(
      'record_hanzi_progress',
      params: {
        'p_character_id': characterId,
        'p_score': score,
        'p_attempts': attempts,
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchWordCatalog() async {
    final out = <Map<String, dynamic>>[];
    var from = 0;

    while (true) {
      final page = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_words')
            .select(
              'id, word, pinyin, meaning_vi, hsk_level_id, main_character_id',
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
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_hsk_levels')
          .select('name')
          .eq('id', levelId)
          .limit(1),
    );
    return rows.isEmpty ? '' : '${rows.first['name'] ?? ''}';
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

