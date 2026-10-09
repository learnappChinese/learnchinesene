import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/presentation/learning_presentation_mapper.dart';
import '../../../core/database/duo_db_helper.dart';
import '../../../core/widgets/adventure_node.dart';
import '../../boss_battle/model/boss_battle_stage.dart';
import '../model/chapter_adventure.dart';

abstract interface class ChapterAdventureRepository {
  Future<ChapterAdventure?> loadChapter(String levelId);
}

class SupabaseChapterAdventureRepository implements ChapterAdventureRepository {
  SupabaseChapterAdventureRepository({
    SupabaseClient? client,
    DuoDbHelper? duoDbHelper,
  })  : _client = client ?? Supabase.instance.client,
        _duoDbHelper = duoDbHelper ?? DuoDbHelper.instance;

  final SupabaseClient _client;
  final DuoDbHelper _duoDbHelper;

  @override
  Future<ChapterAdventure?> loadChapter(String levelId) async {
    final levelRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_levels')
          .select('id, unit_id, teaching_objective')
          .eq('id', levelId)
          .limit(1),
    );
    if (levelRows.isEmpty) return null;

    final level = levelRows.first;
    final unitId = '${level['unit_id'] ?? ''}';
    final rows = await _duoDbHelper.getUnitLearningPath(unitId);
    if (rows.isEmpty) return null;

    final learningRows = rows
        .where((row) => row['node_type'] == 'learning')
        .toList(growable: false);
    final bossRows =
        rows.where((row) => row['node_type'] == 'boss').toList(growable: false);
    if (learningRows.isEmpty) return null;

    final missions = learningRows.map((row) {
      final completed = row['is_completed'] == true;
      final unlocked = row['is_unlocked'] == true;
      final inProgress = row['in_progress'] == true;
      final stars = ((row['stars'] as num?)?.toInt() ?? 0).clamp(0, 3);
      final attempts = (row['attempts'] as num?)?.toInt() ?? 0;
      final state = completed
          ? (stars == 3
              ? AdventureNodeState.perfect
              : AdventureNodeState.completed)
          : inProgress
              ? AdventureNodeState.inProgress
              : !unlocked
                  ? AdventureNodeState.locked
                  : attempts > 0
                      ? AdventureNodeState.failed
                      : AdventureNodeState.available;

      return ChapterMission(
        gameId: (row['game_id'] as num?)?.toInt() ?? 0,
        gameCode: '${row['game_code'] ?? ''}',
        title: LearningPresentationMapper.missionTitle(
          row['game_name'],
          '${row['game_code'] ?? ''}',
          (row['node_order'] as num?)?.toInt() ?? 1,
        ),
        description: LearningPresentationMapper.missionSubtitle(
          row['game_description'],
          '${row['game_code'] ?? ''}',
        ),
        type: _nodeType('${row['game_code'] ?? ''}'),
        state: state,
        stars: stars,
        attempts: attempts,
        bestScore: (row['best_score'] as num?)?.toInt() ?? 0,
        currentIndex: (row['current_index'] as num?)?.toInt() ?? 0,
        currentTotal: (row['current_total'] as num?)?.toInt() ?? 0,
        lockReason: row['lock_reason'] as String?,
        requiredNodeId: row['required_node_id'] as String?,
        requiredMastery: (row['required_mastery'] as num?)?.toDouble(),
      );
    }).toList(growable: false);

    final first = learningRows.first;
    final bossRow = bossRows.isEmpty ? null : bossRows.first;
    final boss = bossRow == null
        ? null
        : BossBattleStage.fromMap(<String, dynamic>{
            'id': bossRow['boss_stage_id'],
            'unit_id': unitId,
            'stage_order': bossRow['node_order'],
            'section_number': bossRow['section_number'],
            'unit_number': bossRow['unit_number'],
            'title': bossRow['game_name'],
            'question_count': bossRow['challenge_count'],
            'difficulty': bossRow['difficulty'],
            'boss_name': bossRow['boss_name'],
            'boss_hp': bossRow['boss_hp'],
            'player_hp': bossRow['player_hp'],
            'theme_code': 'sunset',
          });

    return ChapterAdventure(
      levelId: levelId,
      unitId: unitId,
      regionNumber: (first['section_number'] as num?)?.toInt() ?? 1,
      chapterNumber: (first['unit_number'] as num?)?.toInt() ?? 1,
      title: LearningPresentationMapper.chapterTitle(
        first['unit_title'],
        (first['unit_number'] as num?)?.toInt() ?? 1,
      ),
      objective: '${level['teaching_objective'] ?? first['unit_title'] ?? ''}',
      missions: missions,
      overallMastery: (first['overall_mastery'] as num?)?.toDouble() ?? 0.0,
      bossUnlocked: bossRow?['is_unlocked'] == true,
      bossLockReason: bossRow?['lock_reason'] as String?,
      bossRequiredNodeId: bossRow?['required_node_id'] as String?,
      bossRequiredMastery: (bossRow?['required_mastery'] as num?)?.toDouble(),
      boss: boss,
    );
  }

  static AdventureNodeType _nodeType(String code) => switch (code) {
        'learn_words' => AdventureNodeType.learn,
        'listen_select' => AdventureNodeType.listening,
        'select_answer' ||
        'match_pairs' ||
        'word_connect' =>
          AdventureNodeType.select,
        'dialogue' => AdventureNodeType.dialogue,
        'speaking' => AdventureNodeType.speaking,
        _ => AdventureNodeType.game,
      };
}
