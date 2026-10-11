import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/adventure_node.dart';
import '../../boss_battle/model/boss_battle_stage.dart';
import '../model/chapter_adventure.dart';

abstract interface class ChapterAdventureRepository {
  Future<ChapterAdventure?> loadChapter(String levelId);
}

class SupabaseChapterAdventureRepository implements ChapterAdventureRepository {
  SupabaseChapterAdventureRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ChapterAdventure?> loadChapter(String levelId) async {
    final levelRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_levels')
          .select('id, unit_id, teaching_objective, level_type, level_subtype')
          .eq('id', levelId)
          .limit(1),
    );
    if (levelRows.isEmpty) return null;
    final level = levelRows.first;
    final unitId = '${level['unit_id'] ?? ''}';

    final unitRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_units')
          .select('id, section_id, unit_number, title')
          .eq('id', unitId)
          .limit(1),
    );
    if (unitRows.isEmpty) return null;
    final unit = unitRows.first;

    final sectionRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_sections')
          .select('section_number, title')
          .eq('id', '${unit['section_id'] ?? ''}')
          .limit(1),
    );
    final section =
        sectionRows.isEmpty ? <String, dynamic>{} : sectionRows.first;

    final sessionRows = List<Map<String, dynamic>>.from(
      await _client.from('duo_sessions').select('id').eq('level_id', levelId),
    );
    final sessionIds = sessionRows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false);
    final challengeTypes = <String>{};
    if (sessionIds.isNotEmpty) {
      final challengeRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_challenges')
            .select('type')
            .inFilter('session_id', sessionIds),
      );
      challengeTypes.addAll(challengeRows.map((row) => '${row['type'] ?? ''}'));
    }

    final gameRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_game_definitions')
          .select('id, game_code, game_order, name_vi, description_vi')
          .order('game_order'),
    ).where((game) => _supports(game['game_code'], challengeTypes)).toList();

    final userId = _client.auth.currentUser?.id;
    final progressRows = userId == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _client
                .from('duo_level_progress')
                .select('game_id, attempts, stars, is_unlocked, is_completed')
                .eq('user_id', userId)
                .eq('level_id', levelId),
          );
    final progressByGame = <int, Map<String, dynamic>>{
      for (final row in progressRows)
        if ((row['game_id'] as num?)?.toInt() case final int id) id: row,
    };

    final firstGameId =
        gameRows.isEmpty ? null : (gameRows.first['id'] as num?)?.toInt();
    final firstCompleted = firstGameId != null &&
        progressByGame[firstGameId]?['is_completed'] == true;
    final missions = <ChapterMission>[];
    for (var index = 0; index < gameRows.length; index++) {
      final game = gameRows[index];
      final gameId = (game['id'] as num?)?.toInt() ?? 0;
      final progress = progressByGame[gameId] ?? const <String, dynamic>{};
      final completed = progress['is_completed'] == true;
      final stars = ((progress['stars'] as num?)?.toInt() ?? 0).clamp(0, 3);
      final attempts = (progress['attempts'] as num?)?.toInt() ?? 0;
      final explicitlyUnlocked = progress['is_unlocked'] == true;
      final branchAvailable = index == 1 || index == 2;
      final available = index == 0 ||
          explicitlyUnlocked ||
          (branchAvailable && firstCompleted) ||
          (index >= 3 && missions.every((mission) => mission.isCompleted));

      final state = completed
          ? (stars == 3
              ? AdventureNodeState.perfect
              : AdventureNodeState.completed)
          : attempts > 0
              ? AdventureNodeState.inProgress
              : available
                  ? AdventureNodeState.available
                  : AdventureNodeState.locked;

      missions.add(ChapterMission(
        gameId: gameId,
        gameCode: '${game['game_code'] ?? ''}',
        title: '${game['name_vi'] ?? 'Nhiệm vụ'}',
        description: '${game['description_vi'] ?? ''}',
        type: _nodeType('${game['game_code'] ?? ''}'),
        state: state,
        stars: stars,
      ));
    }

    final bossRows = List<Map<String, dynamic>>.from(
      await _client.from('boss_stages').select().eq('unit_id', unitId).limit(1),
    );

    return ChapterAdventure(
      levelId: levelId,
      unitId: unitId,
      regionNumber: (section['section_number'] as num?)?.toInt() ?? 1,
      chapterNumber: (unit['unit_number'] as num?)?.toInt() ?? 1,
      title: '${unit['title'] ?? 'Chương mới'}',
      objective: '${level['teaching_objective'] ?? unit['title'] ?? ''}',
      missions: missions,
      boss: bossRows.isEmpty ? null : BossBattleStage.fromMap(bossRows.first),
    );
  }

  static bool _supports(dynamic codeValue, Set<String> types) {
    final code = '$codeValue';
    if (types.isEmpty) return false;
    return switch (code) {
      'learn_words' => true,
      'select_answer' => types.contains('select') || types.contains('assist'),
      'listen_select' =>
        types.any((type) => type.toLowerCase().contains('listen')),
      'translate' => types.contains('translate'),
      'gap_fill' => types.any((type) => type.toLowerCase().contains('gap')),
      'tap_complete' => types.contains('tapComplete'),
      'match_pairs' => types.contains('match'),
      'dialogue' =>
        types.any((type) => type.toLowerCase().contains('dialogue')),
      'sentence_order' =>
        types.any((type) => type.toLowerCase().contains('order')),
      'speaking' => types.any((type) => type.toLowerCase().contains('speak')),
      _ => false,
    };
  }

  static AdventureNodeType _nodeType(String code) => switch (code) {
        'learn_words' => AdventureNodeType.learn,
        'listen_select' => AdventureNodeType.listening,
        'select_answer' || 'match_pairs' => AdventureNodeType.select,
        'dialogue' => AdventureNodeType.dialogue,
        'speaking' => AdventureNodeType.speaking,
        _ => AdventureNodeType.game,
      };
}
