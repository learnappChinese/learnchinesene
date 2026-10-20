import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/writing_path_models.dart';
import 'hanzi_progress_snapshot_service.dart';
import 'writing_path_resolver.dart';

class WritingLearningPathRepository {
  WritingLearningPathRepository({
    SupabaseClient? client,
    HanziProgressSnapshotService? progressService,
  })  : _client = client ?? Supabase.instance.client,
        _progressService = progressService ??
            HanziProgressSnapshotService(
              client: client ?? Supabase.instance.client,
            );

  final SupabaseClient _client;
  final HanziProgressSnapshotService _progressService;

  static const bool previewEnabled = bool.fromEnvironment(
    'V3_HANZI_PATH_PREVIEW',
    defaultValue: false,
  );

  Future<List<WritingHskCatalogItem>> loadHskCatalog() async {
    try {
      final response = await _client.rpc('writing_hsk_catalog_v3');
      if (response is List) {
        final rows = response
            .whereType<Map>()
            .map((row) => WritingHskCatalogItem.fromMap(
                Map<String, dynamic>.from(row)))
            .where((item) => item.id > 0)
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      }
    } catch (_) {
      // Migration is intentionally optional during V3 rollout.
    }

    final levels = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_hsk_levels')
          .select('id,name,sort_order')
          .order('sort_order')
          .order('id'),
    );
    final units = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_units')
          .select('id,hsk_level_id')
          .order('hsk_level_id')
          .order('id'),
    );
    final counts = <int, int>{};
    for (final row in units) {
      final id = (row['hsk_level_id'] as num?)?.toInt();
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return levels
        .map((row) {
          final id = (row['id'] as num?)?.toInt() ?? 0;
          return WritingHskCatalogItem(
            id: id,
            name: '${row['name'] ?? 'HSK'}',
            sortOrder: (row['sort_order'] as num?)?.toInt() ?? id,
            sectionCount: counts[id] ?? 0,
            mappedCharacterCount: 0,
          );
        })
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<WritingHskPath> loadHskPath(
    WritingHskCatalogItem catalog, {
    required bool previousLevelCompleted,
  }) async {
    final rawNodes = await _loadStaticNodes(catalog.id);
    final progress = await _loadProgress(
      rawNodes.map((node) => node.characterId).toSet().toList(),
    );

    final sections = resolveWritingPathSections(
      rawNodes: rawNodes,
      progressByCharacter: progress,
      previousLevelCompleted: previousLevelCompleted,
    );

    return WritingHskPath(
      catalog: catalog,
      sections: sections,
    );
  }

  Future<List<WritingPathNode>> _loadStaticNodes(int hskLevelId) async {
    try {
      final response = await _client.rpc(
        'writing_learning_path_v3',
        params: <String, dynamic>{'p_hsk_level_id': hskLevelId},
      );
      if (response is List) {
        final rows = response
            .whereType<Map>()
            .map((row) => WritingPathNode.fromMap(
                Map<String, dynamic>.from(row)))
            .where((node) => node.characterId > 0)
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      }
    } catch (_) {
      // Use legacy normalized tables until V3 read model is deployed.
    }
    return _loadStaticNodesFallback(hskLevelId);
  }

  Future<List<WritingPathNode>> _loadStaticNodesFallback(
      int hskLevelId) async {
    final units = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_units')
          .select('id,title,unit_number,sort_order')
          .eq('hsk_level_id', hskLevelId)
          .order('sort_order')
          .order('unit_number')
          .order('id'),
    );
    if (units.isEmpty) return const <WritingPathNode>[];

    final unitIds = units
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    final links = await _loadRowsInChunks(
      table: 'lexicon_word_units',
      select: 'word_id,unit_id',
      filterColumn: 'unit_id',
      values: unitIds,
    );
    final sources = await _loadRowsInChunks(
      table: 'lexicon_word_sources',
      select: 'word_id,unit_id,topic_id,source_row',
      filterColumn: 'unit_id',
      values: unitIds,
    );

    final wordIds = links
        .map((row) => (row['word_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet()
        .toList();
    final words = await _loadRowsInChunks(
      table: 'lexicon_words',
      select:
          'id,word,pinyin,meaning_vi,hsk_level_id,main_character_id',
      filterColumn: 'id',
      values: wordIds,
    );

    final wordsById = <int, Map<String, dynamic>>{
      for (final row in words)
        if (row['id'] is num) (row['id'] as num).toInt(): row,
    };
    final minSource = <String, int>{};
    final topicIds = <int>{};
    final topicStats = <String, _TopicStat>{};
    for (final row in sources) {
      final unitId = (row['unit_id'] as num?)?.toInt();
      final wordId = (row['word_id'] as num?)?.toInt();
      final topicId = (row['topic_id'] as num?)?.toInt();
      final sourceRow = (row['source_row'] as num?)?.toInt();
      if (unitId != null && wordId != null && sourceRow != null) {
        final key = '$unitId:$wordId';
        final current = minSource[key];
        if (current == null || sourceRow < current) minSource[key] = sourceRow;
      }
      if (unitId != null && topicId != null) {
        topicIds.add(topicId);
        final key = '$unitId:$topicId';
        final current = topicStats[key];
        topicStats[key] = _TopicStat(
          unitId: unitId,
          topicId: topicId,
          count: (current?.count ?? 0) + 1,
          firstSourceRow: current == null
              ? (sourceRow ?? 1 << 30)
              : (sourceRow != null && sourceRow < current.firstSourceRow
                  ? sourceRow
                  : current.firstSourceRow),
        );
      }
    }

    final topicRows = await _loadRowsInChunks(
      table: 'lexicon_topics',
      select: 'id,name_vi',
      filterColumn: 'id',
      values: topicIds.toList(),
    );
    final topicNames = <int, String>{
      for (final row in topicRows)
        if (row['id'] is num && '${row['name_vi'] ?? ''}'.trim().isNotEmpty)
          (row['id'] as num).toInt(): '${row['name_vi']}',
    };
    final semanticTitleByUnit = <int, String>{};
    final bestStatByUnit = <int, _TopicStat>{};
    for (final stat in topicStats.values) {
      final existing = bestStatByUnit[stat.unitId];
      final better = existing == null ||
          stat.count > existing.count ||
          (stat.count == existing.count &&
              stat.firstSourceRow < existing.firstSourceRow) ||
          (stat.count == existing.count &&
              stat.firstSourceRow == existing.firstSourceRow &&
              stat.topicId < existing.topicId);
      if (better && topicNames.containsKey(stat.topicId)) {
        bestStatByUnit[stat.unitId] = stat;
        semanticTitleByUnit[stat.unitId] = topicNames[stat.topicId]!;
      }
    }

    final unitById = <int, Map<String, dynamic>>{
      for (final row in units)
        if (row['id'] is num) (row['id'] as num).toInt(): row,
    };

    final candidates = <_CharacterCandidate>[];
    final characterStrings = <String>{};
    for (final link in links) {
      final unitId = (link['unit_id'] as num?)?.toInt();
      final wordId = (link['word_id'] as num?)?.toInt();
      if (unitId == null || wordId == null) continue;
      final word = wordsById[wordId];
      final unit = unitById[unitId];
      if (word == null || unit == null) continue;
      final text = '${word['word'] ?? ''}';
      var charPosition = 0;
      for (final rune in text.runes) {
        charPosition++;
        final char = String.fromCharCode(rune);
        characterStrings.add(char);
        candidates.add(_CharacterCandidate(
          unitId: unitId,
          unitTitle: semanticTitleByUnit[unitId] ??
              '${unit['title'] ?? 'Section'}',
          unitOrder: (unit['sort_order'] as num?)?.toInt() ??
              (unit['unit_number'] as num?)?.toInt() ??
              unitId,
          wordId: wordId,
          word: text,
          wordPinyin: word['pinyin']?.toString(),
          wordMeaning: word['meaning_vi']?.toString(),
          sourceRow: minSource['$unitId:$wordId'] ?? wordId,
          charPosition: charPosition,
          character: char,
        ));
      }
    }

    final characters = await _loadRowsInChunks(
      table: 'lexicon_characters',
      select:
          'id,character,stroke_count,stroke_width,stroke_height,stroke_paths',
      filterColumn: 'character',
      values: characterStrings.toList(),
    );
    final charByText = <String, Map<String, dynamic>>{
      for (final row in characters) '${row['character'] ?? ''}': row,
    };

    final exactWords = await _loadRowsInChunks(
      table: 'lexicon_words',
      select: 'id,word,pinyin,meaning_vi,hsk_level_id',
      filterColumn: 'word',
      values: charByText.keys.toList(),
    );
    final exactByText = <String, Map<String, dynamic>>{};
    for (final row in exactWords) {
      final text = '${row['word'] ?? ''}';
      final existing = exactByText[text];
      if (existing == null ||
          (row['hsk_level_id'] as num?)?.toInt() == hskLevelId) {
        exactByText[text] = row;
      }
    }

    candidates.sort((a, b) {
      final byUnit = a.unitOrder.compareTo(b.unitOrder);
      if (byUnit != 0) return byUnit;
      final bySource = a.sourceRow.compareTo(b.sourceRow);
      if (bySource != 0) return bySource;
      final byWord = a.wordId.compareTo(b.wordId);
      if (byWord != 0) return byWord;
      return a.charPosition.compareTo(b.charPosition);
    });

    final seen = <String>{};
    final nodeCounter = <int, int>{};
    final nodes = <WritingPathNode>[];
    for (final candidate in candidates) {
      final char = charByText[candidate.character];
      if (char == null) continue;
      final charId = (char['id'] as num?)?.toInt();
      if (charId == null) continue;
      final dedupeKey = '${candidate.unitId}:$charId';
      if (!seen.add(dedupeKey)) continue;
      final exact = exactByText[candidate.character];
      final order = (nodeCounter[candidate.unitId] ?? 0) + 1;
      nodeCounter[candidate.unitId] = order;
      final strokeCount = (char['stroke_count'] as num?)?.toInt() ?? 0;
      final strokePaths = '${char['stroke_paths'] ?? ''}';
      final pinyin = exact?['pinyin']?.toString();
      final meaning = exact?['meaning_vi']?.toString();
      final quality = strokeCount <= 0 || strokePaths.trim().isEmpty
          ? 'missing_strokes'
          : pinyin == null || pinyin.trim().isEmpty
              ? 'context_only_pinyin'
              : meaning == null || meaning.trim().isEmpty
                  ? 'context_only_meaning'
                  : 'complete';

      nodes.add(WritingPathNode(
        hskLevelId: hskLevelId,
        sectionId: candidate.unitId,
        sectionTitle: candidate.unitTitle,
        sectionOrder: candidate.unitOrder,
        nodeOrder: order,
        characterId: charId,
        character: candidate.character,
        characterPinyin: pinyin,
        characterMeaningVi: meaning,
        contextWordId: candidate.wordId,
        contextWord: candidate.word,
        contextPinyin: candidate.wordPinyin,
        contextMeaningVi: candidate.wordMeaning,
        sourceRow: candidate.sourceRow,
        strokeCount: strokeCount,
        strokeWidth: (char['stroke_width'] as num?)?.toDouble() ?? 110,
        strokeHeight: (char['stroke_height'] as num?)?.toDouble() ?? 110,
        strokePaths: strokePaths,
        metadataQuality: quality,
      ));
    }
    return nodes;
  }

  Future<List<Map<String, dynamic>>> _loadRowsInChunks({
    required String table,
    required String select,
    required String filterColumn,
    required List<dynamic> values,
  }) async {
    if (values.isEmpty) return const <Map<String, dynamic>>[];
    final result = <Map<String, dynamic>>[];
    const chunkSize = 150;
    for (var i = 0; i < values.length; i += chunkSize) {
      final end = (i + chunkSize < values.length)
          ? i + chunkSize
          : values.length;
      final chunk = values.sublist(i, end);
      result.addAll(List<Map<String, dynamic>>.from(
        await _client.from(table).select(select).inFilter(filterColumn, chunk),
      ));
    }
    return result;
  }

  Future<Map<int, WritingCharacterProgress>> _loadProgress(
      List<int> characterIds) async {
    final snapshots = await _progressService.loadForCharacters(characterIds);
    return <int, WritingCharacterProgress>{
      for (final entry in snapshots.entries)
        entry.key: WritingCharacterProgress(
          practiceCount: entry.value.practiceCount,
          bestScore: entry.value.bestScore,
          lastScore: entry.value.lastScore,
          nextReviewAt: entry.value.nextReviewAt,
        ),
    };
  }
}

class _CharacterCandidate {
  const _CharacterCandidate({
    required this.unitId,
    required this.unitTitle,
    required this.unitOrder,
    required this.wordId,
    required this.word,
    required this.sourceRow,
    required this.charPosition,
    required this.character,
    this.wordPinyin,
    this.wordMeaning,
  });

  final int unitId;
  final String unitTitle;
  final int unitOrder;
  final int wordId;
  final String word;
  final String? wordPinyin;
  final String? wordMeaning;
  final int sourceRow;
  final int charPosition;
  final String character;
}

class _TopicStat {
  const _TopicStat({
    required this.unitId,
    required this.topicId,
    required this.count,
    required this.firstSourceRow,
  });

  final int unitId;
  final int topicId;
  final int count;
  final int firstSourceRow;
}

class _LastGuestScore {
  const _LastGuestScore({
    required this.completedAt,
    required this.score,
  });

  final DateTime completedAt;
  final double score;
}
