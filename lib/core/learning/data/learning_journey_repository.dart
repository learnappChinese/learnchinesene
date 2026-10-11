import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/learning_presentation_mapper.dart';
import '../../widgets/adventure_node.dart';
import '../../../screen/chapter_adventure/data/chapter_adventure_repository.dart';
import '../../../screen/chapter_adventure/model/chapter_adventure.dart';
import '../../../screen/review/data/review_repository.dart';
import '../model/learning_journey_models.dart';
import '../model/unit_mastery.dart';

import '../model/learning_stage_models.dart';
import '../service/learning_recommendation_service.dart';
import '../service/learning_stage_grouping_service.dart';

abstract interface class LearningJourneyRepository {
  Future<List<LearningSectionViewModel>> getSections();
  Future<List<LearningUnitViewModel>> getUnits(String sectionId);
  Future<ChapterAdventure?> getUnitJourney(String unitId);
  Future<List<LearningStageViewModel>> getUnitStages(String unitId);
  Future<LearningUnitViewModel?> getCurrentProgress();
  Future<LearningNextAction?> getNextAction();
  Future<LearningStageViewModel?> getCurrentStageForActivities(
    Set<LearningStageActivityType> types, {
    String? unitId,
    bool allowCompleted = false,
  });
  Future<LearningStageViewModel?> getCurrentStageForActivity(
    LearningStageActivityType type, {
    String? unitId,
    bool allowCompleted = false,
  });
  Future<LearningUnitViewModel?> getNextUnit(String currentUnitId);
}

class SupabaseLearningJourneyRepository implements LearningJourneyRepository {
  SupabaseLearningJourneyRepository({
    SupabaseClient? client,
    ChapterAdventureRepository? chapterAdventureRepository,
    ReviewRepository? reviewRepository,
    LearningStageGroupingService? stageGroupingService,
    LearningRecommendationService? recommendationService,
  })  : _client = client ?? Supabase.instance.client,
        _chapterRepo =
            chapterAdventureRepository ?? SupabaseChapterAdventureRepository(),
        _reviewRepo = reviewRepository ?? SupabaseReviewRepository(),
        _stageGroupingService =
            stageGroupingService ?? const LearningStageGroupingService(),
        _recommendationService = recommendationService;

  final SupabaseClient _client;
  final ChapterAdventureRepository _chapterRepo;
  final ReviewRepository _reviewRepo;
  final LearningStageGroupingService _stageGroupingService;
  final LearningRecommendationService? _recommendationService;

  @override
  Future<List<LearningSectionViewModel>> getSections() async {
    try {
      final rows = List<Map<String, dynamic>>.from(
        await _client.rpc('learning_sections_v2'),
      );
      return rows.map((row) {
        final number = (row['section_number'] as num?)?.toInt() ?? 1;
        return LearningSectionViewModel(
          id: '${row['section_id'] ?? ''}',
          sectionNumber: number,
          title: LearningPresentationMapper.sectionHeading(number),
          subtitle: LearningPresentationMapper.sectionName(
            number,
            row['section_title'],
          ),
          unitCount: (row['unit_count'] as num?)?.toInt() ?? 0,
          completedUnitCount:
              (row['completed_unit_count'] as num?)?.toInt() ?? 0,
          isUnlocked: row['is_unlocked'] == true,
          lockReason: row['lock_reason'] as String?,
          requiredSectionNumber:
              (row['required_section_number'] as num?)?.toInt(),
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<LearningUnitViewModel>> getUnits(String sectionId) async {
    try {
      final rows = List<Map<String, dynamic>>.from(
        await _client.rpc(
          'learning_units_v2',
          params: <String, dynamic>{'p_section_id': sectionId},
        ),
      );

      return rows.map((row) {
        final unitNumber = (row['unit_number'] as num?)?.toInt() ?? 1;
        final title = LearningPresentationMapper.unitTitle(
          row['unit_title'],
          unitNumber,
        );
        final requiredUnitId = row['required_unit_id'] as String?;
        final requiredUnitNumber = requiredUnitId == null
            ? null
            : rows
                .where((candidate) => candidate['unit_id'] == requiredUnitId)
                .map((candidate) => (candidate['unit_number'] as num?)?.toInt())
                .whereType<int>()
                .firstOrNull;
        final isUnlocked = row['is_unlocked'] == true;
        final unitState = '${row['unit_state'] ?? ''}';

        return LearningUnitViewModel(
          id: '${row['unit_id'] ?? ''}',
          sectionId: '${row['section_id'] ?? sectionId}',
          sectionNumber: (row['section_number'] as num?)?.toInt() ?? 1,
          unitNumber: unitNumber,
          title: LearningPresentationMapper.unitFullTitle(title, unitNumber),
          subtitle: switch (unitState) {
            'completed' => 'Đã đánh bại Boss của bài học',
            'in_progress' => 'Tiếp tục hành trình đang dở',
            'failed' => 'Sẵn sàng thử lại, tiến độ vẫn được giữ',
            'locked' when requiredUnitNumber != null =>
              'Hoàn thành Bài $requiredUnitNumber để mở',
            'locked' => 'Chưa đủ điều kiện mở bài học',
            _ => 'Sẵn sàng bắt đầu hành trình',
          },
          teachingObjective: '${row['teaching_objective'] ?? title}',
          missionCount: (row['stage_count'] as num?)?.toInt() ?? 0,
          completedMissionCount:
              (row['completed_stage_count'] as num?)?.toInt() ?? 0,
          mastery: (row['overall_mastery'] as num?)?.toDouble() ?? 0.0,
          state: unitState == 'completed'
              ? UnitCompletionState.completed
              : UnitCompletionState.inProgress,
          isUnlocked: isUnlocked,
          bossAvailable: row['boss_available'] == true,
          bossWon: row['boss_won'] == true,
          bossStageId: (row['boss_stage_id'] as num?)?.toInt(),
          bossName: row['boss_name'] as String?,
          estimatedMinutes: (((row['stage_count'] as num?)?.toInt() ?? 1) * 5)
              .clamp(3, 35)
              .toInt(),
          lockReason: isUnlocked
              ? null
              : (requiredUnitNumber == null
                  ? 'Bài học này chưa được mở.'
                  : 'Đánh bại Boss Bài $requiredUnitNumber để mở khóa.'),
          requiredUnitId: requiredUnitId,
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<LearningUnitViewModel?> getNextUnit(String currentUnitId) async {
    try {
      final sections = await getSections();
      if (sections.isEmpty) return null;

      for (int s = 0; s < sections.length; s++) {
        final sec = sections[s];
        final units = await getUnits(sec.id);
        final idx = units.indexWhere((u) => u.id == currentUnitId);
        if (idx != -1) {
          if (idx + 1 < units.length) {
            return units[idx + 1];
          }
          if (s + 1 < sections.length) {
            final nextSecUnits = await getUnits(sections[s + 1].id);
            if (nextSecUnits.isNotEmpty) {
              return nextSecUnits.first;
            }
          }
          return null;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async {
    final direct = await _chapterRepo.loadChapter(unitId);
    if (direct != null) return direct;

    try {
      final levelRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_levels')
            .select('id')
            .eq('unit_id', unitId)
            .limit(1),
      );
      if (levelRows.isNotEmpty) {
        final levelId = levelRows.first['id'] as String;
        return await _chapterRepo.loadChapter(levelId);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async {
    try {
      final pathRows = List<Map<String, dynamic>>.from(
        await _client.rpc(
          'unit_learning_path_v2',
          params: <String, dynamic>{'p_unit_id': unitId},
        ),
      );
      if (pathRows.isEmpty) return const [];

      final levelRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_levels')
            .select('id, level_index')
            .eq('unit_id', unitId)
            .order('level_index', ascending: true),
      );
      final levelIds = levelRows.map((l) => '${l['id']}').toList();

      List<Map<String, dynamic>> rawChallenges = const [];
      if (levelIds.isNotEmpty) {
        final sessionRows = List<Map<String, dynamic>>.from(
          await _client
              .from('duo_sessions')
              .select('id, level_id')
              .inFilter('level_id', levelIds),
        );
        final sessionIds = sessionRows
            .map((s) => (s['id'] as num?)?.toInt())
            .whereType<int>()
            .toList();
        final levelBySession = <int, String>{
          for (final session in sessionRows)
            if ((session['id'] as num?) != null)
              (session['id'] as num).toInt(): '${session['level_id'] ?? ''}',
        };

        if (sessionIds.isNotEmpty) {
          final challengeRows = List<Map<String, dynamic>>.from(
            await _client
                .from('duo_challenges')
                .select(
                  'id, session_id, type, prompt, tts, slow_tts, choices_text, solutions, tokens_text',
                )
                .inFilter('session_id', sessionIds)
                .order('id', ascending: true),
          );
          rawChallenges = challengeRows
              .map((challenge) => <String, dynamic>{
                    ...challenge,
                    '_level_id': levelBySession[
                        (challenge['session_id'] as num?)?.toInt()],
                  })
              .toList(growable: false);
        }
      }

      final bossRows = List<Map<String, dynamic>>.from(
        await _client
            .from('boss_stages')
            .select(
              'id, unit_id, stage_order, title, question_count, difficulty, boss_name, boss_hp, player_hp, theme_code',
            )
            .eq('unit_id', unitId)
            .limit(1),
      );
      final rawBossStage = bossRows.isNotEmpty ? bossRows.first : null;

      return _stageGroupingService.groupServerPath(
        unitId: unitId,
        pathRows: pathRows,
        rawChallenges: rawChallenges,
        rawBossStage: rawBossStage,
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<LearningUnitViewModel?> getCurrentProgress() async {
    try {
      final response = await _client.rpc('current_learning_unit_v2');
      if (response is Map) {
        final map = Map<String, dynamic>.from(response);
        final unitId = '${map['unit_id'] ?? ''}';
        if (unitId.isEmpty) return null;
        final secNum = (map['section_number'] as num?)?.toInt() ?? 1;
        final unitNum = (map['unit_number'] as num?)?.toInt() ?? 1;
        final title = LearningPresentationMapper.unitTitle(
          map['unit_title'],
          unitNum,
        );

        final path = List<Map<String, dynamic>>.from(
          await _client.rpc(
            'unit_learning_path_v2',
            params: <String, dynamic>{'p_unit_id': unitId},
          ),
        );
        final learningNodes = path
            .where((node) => node['node_type'] == 'learning')
            .toList(growable: false);
        final bossNode =
            path.where((node) => node['node_type'] == 'boss').firstOrNull;
        final unitRows = List<Map<String, dynamic>>.from(
          await _client
              .from('duo_units')
              .select('section_id')
              .eq('id', unitId)
              .limit(1),
        );

        final masteryMap = map['mastery'] is Map
            ? Map<String, dynamic>.from(map['mastery'] as Map)
            : <String, dynamic>{};
        final mastery =
            (masteryMap['overall_mastery'] as num?)?.toDouble() ?? 0.0;
        final bossWon = bossNode?['is_completed'] == true;
        final bossAvailable = bossNode?['is_unlocked'] == true;

        return LearningUnitViewModel(
          id: unitId,
          sectionId:
              unitRows.isEmpty ? '' : '${unitRows.first['section_id'] ?? ''}',
          sectionNumber: secNum,
          unitNumber: unitNum,
          title: LearningPresentationMapper.unitFullTitle(title, unitNum),
          subtitle: 'Đang theo học',
          teachingObjective: title,
          missionCount: learningNodes.length,
          completedMissionCount: learningNodes
              .where((node) => node['is_completed'] == true)
              .length,
          mastery: mastery,
          state: bossWon
              ? UnitCompletionState.completed
              : bossAvailable
                  ? UnitCompletionState.bossPending
                  : UnitCompletionState.inProgress,
          isUnlocked: true,
          bossAvailable: bossAvailable,
          bossWon: bossWon,
          bossStageId: (bossNode?['boss_stage_id'] as num?)?.toInt(),
          bossName: bossNode?['boss_name'] as String?,
          estimatedMinutes: (learningNodes.length * 5).clamp(3, 35).toInt(),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<LearningNextAction?> getNextAction() async {
    try {
      final recService = _recommendationService ??
          SupabaseLearningRecommendationService(
            client: _client,
            journeyRepository: this,
            reviewRepository: _reviewRepo,
          );
      final nextAction = await recService.recommend();
      if (nextAction != null) {
        return nextAction.toLearningNextAction();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<LearningStageViewModel?> getCurrentStageForActivity(
    LearningStageActivityType type, {
    String? unitId,
    bool allowCompleted = false,
  }) =>
      getCurrentStageForActivities(
        {type},
        unitId: unitId,
        allowCompleted: allowCompleted,
      );

  @override
  Future<LearningStageViewModel?> getCurrentStageForActivities(
    Set<LearningStageActivityType> types, {
    String? unitId,
    bool allowCompleted = false,
  }) async {
    try {
      var targetUnitId = unitId;
      if (targetUnitId == null || targetUnitId.isEmpty) {
        final currentUnit = await getCurrentProgress();
        targetUnitId = currentUnit?.id;
      }
      if (targetUnitId == null || targetUnitId.isEmpty) {
        return null;
      }

      final stages = await getUnitStages(targetUnitId);
      final matching = stages
          .where((stage) => types.contains(stage.activityType))
          .toList(growable: false);

      if (matching.isEmpty) return null;

      final inProgress = matching
          .where((stage) => stage.state == AdventureNodeState.inProgress)
          .firstOrNull;
      if (inProgress != null) return inProgress;

      final available = matching
          .where((stage) =>
              (stage.state == AdventureNodeState.available ||
                  stage.state == AdventureNodeState.failed) &&
              !stage.isLocked)
          .firstOrNull;
      if (available != null) return available;

      if (allowCompleted) {
        return matching.where((stage) => stage.isCompleted).firstOrNull;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
