import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../backend/query_cache.dart';
import '../../database/app_database.dart';
import '../../presentation/learning_presentation_mapper.dart';
import '../../widgets/adventure_node.dart';
import '../../../features/boss_battle/model/boss_battle_stage.dart';
import '../../../features/chapter_adventure/data/chapter_adventure_repository.dart';
import '../../../features/chapter_adventure/model/chapter_adventure.dart';
import '../../../features/review/data/review_repository.dart';
import '../model/learning_journey_models.dart';
import '../model/unit_mastery.dart';

import '../model/learning_stage_models.dart';
import '../service/learning_recommendation_service.dart';
import '../service/learning_stage_grouping_service.dart';
import 'guest_learning_progress_store.dart';
import '../service/guest_journey_resolver.dart';
import 'learning_progress_repository.dart';

abstract interface class LearningJourneyRepository {
  Future<List<LearningSectionViewModel>> getSections();
  Future<List<LearningUnitViewModel>> getUnits(
    String sectionId, {
    bool? isSectionUnlocked,
  });
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
    LearningProgressRepository? progressRepository,
    GuestLearningProgressStore? guestStore,
    GuestJourneyResolver guestResolver = const GuestJourneyResolver(),
  })  : _client = client ?? _tryGetClient(),
        _chapterRepo =
            chapterAdventureRepository ?? SupabaseChapterAdventureRepository(),
        _reviewRepo = reviewRepository ?? SupabaseReviewRepository(),
        _stageGroupingService =
            stageGroupingService ?? const LearningStageGroupingService(),
        _recommendationService = recommendationService,
        _progressRepo = progressRepository ??
            SupabaseLearningProgressRepository(
              client: client,
              guestStore: guestStore,
              guestResolver: guestResolver,
            ),
        _guestStore = guestStore ?? GuestLearningProgressStore(),
        _guestResolver = guestResolver;

  static SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final SupabaseClient? _client;
  final ChapterAdventureRepository _chapterRepo;
  final ReviewRepository _reviewRepo;
  final LearningStageGroupingService _stageGroupingService;
  final LearningRecommendationService? _recommendationService;
  final LearningProgressRepository _progressRepo;
  final GuestLearningProgressStore _guestStore;
  final GuestJourneyResolver _guestResolver;

  /// Danh sách phần học chưa ghép tiến độ của khách.
  Future<List<LearningSectionViewModel>> _getRawSections() async {
    final client = _client;
    if (client == null) return await _getLocalSections();
    try {
      final rows = await QueryCache.userScoped(
        client,
        'learning_sections_v2',
        () async => List<Map<String, dynamic>>.from(
          await client.rpc('learning_sections_v2'),
        ),
      );
      if (rows.isNotEmpty) return rows.map(_mapSectionRow).toList();
    } catch (_) {}
    return await _getLocalSections();
  }

  LearningSectionViewModel _mapSectionRow(Map<String, dynamic> row) {
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
      completedUnitCount: (row['completed_unit_count'] as num?)?.toInt() ?? 0,
      isUnlocked: row['is_unlocked'] == true,
      lockReason: row['lock_reason'] as String?,
      requiredSectionNumber: (row['required_section_number'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<LearningSectionViewModel>> getSections() async {
    final client = _client;
    if (client == null) {
      return await _getLocalSections();
    }
    try {
      final rows = await QueryCache.userScoped(
        client,
        'learning_sections_v2',
        () async => List<Map<String, dynamic>>.from(
          await client.rpc('learning_sections_v2'),
        ),
      );
      if (rows.isNotEmpty) {
        final rawSections =
            rows.map(_mapSectionRow).toList(growable: false);

        if (client.auth.currentUser == null) {
          return await _guestResolver.overlaySections(
            sections: rawSections,
            store: _guestStore,
            unitsLoader: _getRawUnits,
          );
        }
        return rawSections;
      }
    } catch (_) {}

    return await _getLocalSections();
  }

  Future<List<LearningSectionViewModel>> _getLocalSections() async {
    if (!AppDatabase.instance.isOpen) return const [];
    try {
      final levels = await AppDatabase.instance.getHskLevels();
      final List<LearningSectionViewModel> rawSections = [];
      for (final lvl in levels) {
        final lvlId = (lvl['id'] as num?)?.toInt() ?? 1;
        final secNum = (lvl['sort_order'] as num?)?.toInt() ?? lvlId;
        final units = await AppDatabase.instance.getUnitsByHskLevel(lvlId);

        int completedCount = 0;
        for (final u in units) {
          final uId = '${u['id']}';
          if (await _guestStore.isBossWon(uId)) {
            completedCount++;
          }
        }

        final isUnlocked = secNum == 1 ||
            (secNum > 1 &&
                rawSections.isNotEmpty &&
                rawSections.last.isCompleted);

        rawSections.add(LearningSectionViewModel(
          id: 'section_hsk_$lvlId',
          sectionNumber: secNum,
          title: LearningPresentationMapper.sectionHeading(secNum),
          subtitle: '${lvl['name'] ?? 'HSK $secNum'}',
          unitCount: units.length,
          completedUnitCount: completedCount,
          isUnlocked: isUnlocked,
          lockReason:
              isUnlocked ? null : 'Hoàn thành HSK ${secNum - 1} để mở khóa',
          requiredSectionNumber: secNum > 1 ? secNum - 1 : null,
        ));
      }

      return await _guestResolver.overlaySections(
        sections: rawSections,
        store: _guestStore,
        unitsLoader: (sectionId) => getUnits(sectionId),
      );
    } catch (e) {
      debugPrint('[LearningJourneyRepository] _getLocalSections failed: $e');
      return const [];
    }
  }

  Future<List<LearningUnitViewModel>> _getRawUnits(String sectionId) async {
    final client = _client;
    if (client == null) {
      return await _getLocalRawUnits(sectionId);
    }
    try {
      final rows = await QueryCache.userScoped(
        client,
        'learning_units_v2|$sectionId',
        () async => List<Map<String, dynamic>>.from(
          await client.rpc(
            'learning_units_v2',
            params: <String, dynamic>{'p_section_id': sectionId},
          ),
        ),
      );

      if (rows.isNotEmpty) {
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
                  .map((candidate) =>
                      (candidate['unit_number'] as num?)?.toInt())
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
      }
    } catch (_) {}

    return await _getLocalRawUnits(sectionId);
  }

  Future<List<LearningUnitViewModel>> _getLocalRawUnits(String sectionId) async {
    if (!AppDatabase.instance.isOpen) return const [];
    try {
      final hskLevelId = _resolveHskLevelId(sectionId);
      final rows = await AppDatabase.instance.getUnitsByHskLevel(hskLevelId);

      return rows.map((row) {
        final uId = '${row['id']}';
        final uNum = (row['unit_number'] as num?)?.toInt() ??
            (row['sort_order'] as num?)?.toInt() ??
            1;
        final rawTitle = '${row['title'] ?? 'Bài $uNum'}';
        final title = LearningPresentationMapper.unitTitle(rawTitle, uNum);

        return LearningUnitViewModel(
          id: uId,
          sectionId: sectionId,
          sectionNumber: hskLevelId,
          unitNumber: uNum,
          title: LearningPresentationMapper.unitFullTitle(title, uNum),
          subtitle: 'Bài học $uNum',
          teachingObjective: rawTitle,
          missionCount: 4,
          completedMissionCount: 0,
          mastery: 0.0,
          state: UnitCompletionState.inProgress,
          isUnlocked: uNum == 1,
          bossAvailable: false,
          bossWon: false,
          bossStageId: int.tryParse(uId),
          bossName: 'Thủ Lĩnh Bài $uNum',
          estimatedMinutes: 20,
        );
      }).toList(growable: false);
    } catch (e) {
      debugPrint('[LearningJourneyRepository] _getLocalRawUnits failed: $e');
      return const [];
    }
  }

  int _resolveHskLevelId(String sectionId, [List<LearningUnitViewModel>? units]) {
    if (units != null && units.isNotEmpty) {
      final secNum = units.first.sectionNumber;
      if (secNum > 0) return secNum;
    }
    if (sectionId.startsWith('section_hsk_')) {
      final parsed = int.tryParse(sectionId.replaceFirst('section_hsk_', ''));
      if (parsed != null && parsed > 0) return parsed;
    }
    final dashIndex = sectionId.lastIndexOf('-');
    if (dashIndex != -1) {
      final suffix = sectionId.substring(dashIndex + 1);
      final idx = int.tryParse(suffix);
      if (idx != null) {
        return idx + 1;
      }
    }
    final clean = sectionId.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length > 4) {
      return 1;
    }
    return int.tryParse(clean) ?? 1;
  }

  @override
  Future<List<LearningUnitViewModel>> getUnits(
    String sectionId, {
    bool? isSectionUnlocked,
  }) async {
    final rawUnits = await _getRawUnits(sectionId);
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      try {
        final hskLevelId = _resolveHskLevelId(sectionId, rawUnits);
        final effectiveSectionUnlocked = isSectionUnlocked ?? (hskLevelId <= 1);

        String? prevSectionLastUnitId;
        if (hskLevelId > 1 && AppDatabase.instance.isOpen) {
          try {
            final prevUnits =
                await AppDatabase.instance.getUnitsByHskLevel(hskLevelId - 1);
            if (prevUnits.isNotEmpty) {
              prevSectionLastUnitId = '${prevUnits.last['id']}';
            }
          } catch (_) {}
        }

        return await _guestResolver.overlayUnits(
          sectionId: sectionId,
          units: rawUnits,
          store: _guestStore,
          isSectionUnlocked: effectiveSectionUnlocked,
          previousSectionLastUnitId: prevSectionLastUnitId,
          pathRowsLoader: client == null
              ? null
              : (uId) => QueryCache.unitPathRows(client, uId),
          masteryLoader: (uId) async {
            try {
              final m = await _progressRepo.fetchUnitMastery(uId);
              return m.overall;
            } catch (_) {
              return 0.0;
            }
          },
        );
      } catch (e) {
        debugPrint('[LearningJourneyRepository] overlayUnits fallback: $e');
        if (rawUnits.isNotEmpty) {
          return [
            rawUnits.first.copyWith(isUnlocked: true, lockReason: null),
            ...rawUnits.skip(1),
          ];
        }
      }
    }
    return rawUnits;
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
    } catch (e) {
      debugPrint('[LearningJourneyRepository] getNextUnit failed: $e');
    }
    return null;
  }

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async {
    final direct = await _chapterRepo.loadChapter(unitId);
    if (direct != null) return direct;

    final client = _client;
    if (client != null) {
      try {
        final levelRows = await QueryCache.run(
          'duo_levels.first|$unitId',
          () async => List<Map<String, dynamic>>.from(
            await client
                .from('duo_levels')
                .select('id')
                .eq('unit_id', unitId)
                .limit(1),
          ),
          keep: true,
        );
        if (levelRows.isNotEmpty) {
          final levelId = levelRows.first['id'] as String;
          final res = await _chapterRepo.loadChapter(levelId);
          if (res != null) return res;
        }
      } catch (e) {
        debugPrint(
            '[LearningJourneyRepository] getUnitJourney fallback failed: $e');
      }
    }

    if (AppDatabase.instance.isOpen) {
      try {
        final intUnitId =
            int.tryParse(unitId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
        final stages = await getUnitStages(unitId);
        final bossStage = stages
            .where((s) => s.bossStage != null)
            .firstOrNull
            ?.bossStage;
        final allDone = stages
            .where((s) =>
                s.isRequired &&
                s.activityType != LearningStageActivityType.boss)
            .every((s) => s.isCompleted);
        final bossWon = await _guestStore.isBossWon(unitId);

        return ChapterAdventure(
          levelId: unitId,
          unitId: unitId,
          regionNumber: 1,
          chapterNumber: intUnitId,
          title: 'Bài học $intUnitId',
          objective: 'Nắm vững từ vựng và chữ Hán trong bài.',
          missions: const [],
          overallMastery: bossWon ? 1.0 : 0.0,
          bossUnlocked: allDone,
          boss: bossStage,
        );
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async {
    final client = _client;
    if (client == null) {
      return await _getLocalUnitStages(unitId);
    }
    try {
      // Tải nội dung tĩnh song song với RPC tiến độ.
      final contentFuture = _loadUnitStaticContent(client, unitId);
      final pathRows = await QueryCache.unitPathRows(client, unitId);
      if (pathRows.isNotEmpty) {
        final content = await contentFuture;
        final rawChallenges = content.challenges;
        final rawBossStage = content.bossStage;

        var resolvedPathRows = pathRows;
        if (client.auth.currentUser == null) {
          final mastery = await _progressRepo.fetchUnitMastery(unitId);
          bool isUnitUnlocked = true;
          try {
            final unitRows = await QueryCache.run(
              'duo_units.position|$unitId',
              () async => List<Map<String, dynamic>>.from(
                await client
                    .from('duo_units')
                    .select('section_id, unit_number')
                    .eq('id', unitId)
                    .limit(1),
              ),
              keep: true,
            );
            if (unitRows.isNotEmpty) {
              final secId = '${unitRows.first['section_id'] ?? ''}';
              final uNum =
                  (unitRows.first['unit_number'] as num?)?.toInt() ?? 1;
              if (secId.isNotEmpty && uNum > 1) {
                final rawUnits = await _getRawUnits(secId);
                final prevUnit = rawUnits
                    .where((u) => u.unitNumber == uNum - 1)
                    .firstOrNull;
                if (prevUnit != null) {
                  isUnitUnlocked = await _guestStore.isBossWon(prevUnit.id);
                }
              }
            }
          } catch (_) {}

          resolvedPathRows = await _guestResolver.overlayUnitPath(
            unitId: unitId,
            pathRows: pathRows,
            store: _guestStore,
            overallMastery: mastery.overall,
            isUnitUnlocked: isUnitUnlocked,
          );
        }

        return _stageGroupingService.groupServerPath(
          unitId: unitId,
          pathRows: resolvedPathRows,
          rawChallenges: rawChallenges,
          rawBossStage: rawBossStage,
        );
      }
    } catch (_) {}

    return await _getLocalUnitStages(unitId);
  }

  /// Nội dung curriculum của một unit (challenge, boss) không phụ thuộc người
  /// học nên được cache trong suốt phiên chạy app. Mỗi lần quay về màn bài học
  /// chỉ còn gọi RPC tiến độ thay vì 4-5 query nội dung tuần tự.
  Future<_UnitStaticContent> _loadUnitStaticContent(
    SupabaseClient client,
    String unitId,
  ) =>
      QueryCache.run(
        'unit_static_content|$unitId',
        () => _fetchUnitStaticContent(client, unitId),
        keep: true,
      );

  Future<_UnitStaticContent> _fetchUnitStaticContent(
    SupabaseClient client,
    String unitId,
  ) async {
    Future<List<Map<String, dynamic>>> loadChallenges() async {
      final levelRows = List<Map<String, dynamic>>.from(
        await client
            .from('duo_levels')
            .select('id, level_index')
            .eq('unit_id', unitId)
            .order('level_index', ascending: true),
      );
      final levelIds = levelRows.map((l) => '${l['id']}').toList();
      if (levelIds.isEmpty) return const [];

      final sessionRows = List<Map<String, dynamic>>.from(
        await client
            .from('duo_sessions')
            .select('id, level_id')
            .inFilter('level_id', levelIds),
      );
      final sessionIds = sessionRows
          .map((s) => (s['id'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      if (sessionIds.isEmpty) return const [];
      final levelBySession = <int, String>{
        for (final session in sessionRows)
          if ((session['id'] as num?) != null)
            (session['id'] as num).toInt(): '${session['level_id'] ?? ''}',
      };

      final challengeRows = List<Map<String, dynamic>>.from(
        await client
            .from('duo_challenges')
            .select(
              'id, session_id, type, prompt, tts, slow_tts, choices_text, solutions, tokens_text',
            )
            .inFilter('session_id', sessionIds)
            .order('id', ascending: true),
      );
      return challengeRows
          .map((challenge) => <String, dynamic>{
                ...challenge,
                '_level_id':
                    levelBySession[(challenge['session_id'] as num?)?.toInt()],
              })
          .toList(growable: false);
    }

    Future<Map<String, dynamic>?> loadBoss() async {
      final bossRows = List<Map<String, dynamic>>.from(
        await client
            .from('boss_stages')
            .select(
              'id, unit_id, stage_order, title, question_count, difficulty, boss_name, boss_hp, player_hp, theme_code',
            )
            .eq('unit_id', unitId)
            .limit(1),
      );
      return bossRows.isNotEmpty ? bossRows.first : null;
    }

    final results = await Future.wait<Object?>([loadChallenges(), loadBoss()]);
    return _UnitStaticContent(
      challenges: results[0] as List<Map<String, dynamic>>,
      bossStage: results[1] as Map<String, dynamic>?,
    );
  }

  Future<List<LearningStageViewModel>> _getLocalUnitStages(String unitId) async {
    if (!AppDatabase.instance.isOpen) return const [];
    try {
      final intUnitId =
          int.tryParse(unitId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      final words = await AppDatabase.instance.getWordsByUnit(intUnitId);
      if (words.isEmpty) return const [];

      final characters =
          await AppDatabase.instance.getCharactersByUnit(intUnitId);

      final stage1Passed =
          await _guestStore.isStagePassed(1, '${unitId}_stage_1');
      final stage2Passed =
          await _guestStore.isStagePassed(2, '${unitId}_stage_2');
      final stage3Passed =
          await _guestStore.isStagePassed(3, '${unitId}_stage_3');
      final bossWon = await _guestStore.isBossWon(unitId);

      // Stage 1: Vocabulary
      final vocabItems = words.asMap().entries.map((e) {
        final idx = e.key;
        final w = e.value;
        return LearningStageItemViewModel(
          id: '${unitId}_vocab_${w['id']}',
          sourceId: '${w['id']}',
          type: 'word',
          order: idx + 1,
          prompt: '${w['word']}',
          content: {
            'word': w['word'],
            'pinyin': w['pinyin'],
            'meaning_vi': w['meaning_vi'],
            'tts_url': w['tts_url'],
          },
          state: stage1Passed
              ? AdventureNodeState.completed
              : AdventureNodeState.available,
          score: stage1Passed ? 1.0 : 0.0,
          mastery: stage1Passed ? 1.0 : 0.0,
        );
      }).toList();

      final stage1 = LearningStageViewModel(
        id: '${unitId}_stage_1',
        unitId: unitId,
        sourceLevelIds: ['${unitId}_stage_1'],
        sourceGameId: 1,
        sourceGameCode: 'learn_words',
        title: 'Ải 1: Học từ vựng',
        subtitle: 'Khám phá ${words.length} từ mới cốt lõi',
        activityType: LearningStageActivityType.vocabulary,
        learningObjective: 'Làm quen và ghi nhớ từ vựng mới',
        items: vocabItems,
        completedItems: stage1Passed ? vocabItems.length : 0,
        state: stage1Passed
            ? AdventureNodeState.completed
            : AdventureNodeState.available,
        mastery: stage1Passed ? 1.0 : 0.0,
        stars: stage1Passed ? 3 : 0,
        isRequired: true,
      );

      // Stage 2: Hanzi Writing
      final hanziItems = (characters.isNotEmpty ? characters : words)
          .asMap()
          .entries
          .map((e) {
        final idx = e.key;
        final c = e.value;
        final charId = '${c['id']}';
        final charText = '${c['character'] ?? c['word']}';
        return LearningStageItemViewModel(
          id: '${unitId}_hanzi_$charId',
          sourceId: charId,
          type: 'character',
          order: idx + 1,
          prompt: charText,
          content: {
            'character': charText,
            'stroke_paths': c['stroke_paths'] ?? '',
          },
          state: stage2Passed
              ? AdventureNodeState.completed
              : (stage1Passed
                  ? AdventureNodeState.available
                  : AdventureNodeState.locked),
          score: stage2Passed ? 1.0 : 0.0,
          mastery: stage2Passed ? 1.0 : 0.0,
        );
      }).toList();

      final stage2State = stage2Passed
          ? AdventureNodeState.completed
          : (stage1Passed
              ? AdventureNodeState.available
              : AdventureNodeState.locked);

      final stage2 = LearningStageViewModel(
        id: '${unitId}_stage_2',
        unitId: unitId,
        sourceLevelIds: ['${unitId}_stage_2'],
        sourceGameId: 2,
        sourceGameCode: 'hanzi',
        title: 'Ải 2: Luyện viết chữ Hán',
        subtitle: 'Thực hành các nét viết chữ Hán',
        activityType: LearningStageActivityType.hanzi,
        learningObjective: 'Tập viết đúng quy tắc bút thuận',
        items: hanziItems,
        completedItems: stage2Passed ? hanziItems.length : 0,
        state: stage2State,
        mastery: stage2Passed ? 1.0 : 0.0,
        stars: stage2Passed ? 3 : 0,
        requiredStageId: '1:${unitId}_stage_1',
        lockReason: stage1Passed ? null : 'Hoàn thành Ải 1 để mở khóa',
        isRequired: true,
      );

      // Stage 3: Speaking
      final speakingItems = words.asMap().entries.map((e) {
        final idx = e.key;
        final w = e.value;
        return LearningStageItemViewModel(
          id: '${unitId}_speaking_${w['id']}',
          sourceId: '${w['id']}',
          type: 'speaking',
          order: idx + 1,
          prompt: '${w['word']}',
          content: {
            'word': w['word'],
            'pinyin': w['pinyin'],
          },
          state: stage3Passed
              ? AdventureNodeState.completed
              : (stage2Passed
                  ? AdventureNodeState.available
                  : AdventureNodeState.locked),
          score: stage3Passed ? 1.0 : 0.0,
          mastery: stage3Passed ? 1.0 : 0.0,
        );
      }).toList();

      final stage3State = stage3Passed
          ? AdventureNodeState.completed
          : (stage2Passed
              ? AdventureNodeState.available
              : AdventureNodeState.locked);

      final stage3 = LearningStageViewModel(
        id: '${unitId}_stage_3',
        unitId: unitId,
        sourceLevelIds: ['${unitId}_stage_3'],
        sourceGameId: 3,
        sourceGameCode: 'speaking',
        title: 'Ải 3: Luyện phát âm',
        subtitle: 'Luyện thanh điệu và phát âm chuẩn',
        activityType: LearningStageActivityType.speaking,
        learningObjective: 'Thực hành phát âm chuẩn xác',
        items: speakingItems,
        completedItems: stage3Passed ? speakingItems.length : 0,
        state: stage3State,
        mastery: stage3Passed ? 1.0 : 0.0,
        stars: stage3Passed ? 3 : 0,
        requiredStageId: '2:${unitId}_stage_2',
        lockReason: stage2Passed ? null : 'Hoàn thành Ải 2 để mở khóa',
        isRequired: true,
      );

      // Stage 4: Boss Battle
      final bossReady = stage1Passed && stage2Passed && stage3Passed;
      final bossState = bossWon
          ? AdventureNodeState.completed
          : (bossReady
              ? AdventureNodeState.available
              : AdventureNodeState.locked);

      final bossBattleStage = BossBattleStage(
        id: intUnitId,
        unitId: unitId,
        stageOrder: 4,
        sectionNumber: 1,
        unitNumber: intUnitId,
        title: 'Thủ Lĩnh Bài $intUnitId',
        questionCount: 5,
        difficulty: 2,
        bossName: 'Chiến Binh Trúc HSK',
        bossHp: 100,
        playerHp: 100,
        themeCode: 'bamboo',
      );

      final stageBoss = LearningStageViewModel(
        id: '${unitId}_stage_boss',
        unitId: unitId,
        sourceLevelIds: ['${unitId}_stage_boss'],
        sourceGameId: 4,
        sourceGameCode: 'boss_battle',
        title: 'Ải 4: Khiêu chiến Boss',
        subtitle: 'Đánh bại Boss để hoàn thành bài học',
        activityType: LearningStageActivityType.boss,
        learningObjective: 'Tổng ôn tập và vượt qua thử thách cuối cùng',
        items: [
          LearningStageItemViewModel(
            id: '${unitId}_boss_item',
            sourceId: '$intUnitId',
            type: 'boss',
            order: 1,
            prompt: 'Đánh bại Boss',
            state: bossWon
                ? AdventureNodeState.completed
                : (bossReady
                    ? AdventureNodeState.available
                    : AdventureNodeState.locked),
          ),
        ],
        completedItems: bossWon ? 1 : 0,
        state: bossState,
        mastery: bossWon ? 1.0 : 0.0,
        stars: bossWon ? 3 : 0,
        bossStage: bossBattleStage,
        requiredStageId: '3:${unitId}_stage_3',
        lockReason: bossReady
            ? null
            : 'Hoàn thành tất cả các ải trước để mở Cổng Boss',
        isRequired: true,
      );

      return [stage1, stage2, stage3, stageBoss];
    } catch (e) {
      debugPrint('[LearningJourneyRepository] _getLocalUnitStages failed: $e');
      return const [];
    }
  }

  @override
  Future<LearningUnitViewModel?> getCurrentProgress() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      try {
        // Duyệt lần lượt từng phần học và dừng ngay khi tìm thấy bài đang học,
        // thay vì tải units của mọi phần như getSections() phải làm.
        final sections = await _getRawSections();
        List<LearningUnitViewModel>? firstUnits;
        for (final section in sections) {
          final units = await getUnits(section.id);
          firstUnits ??= units;
          for (final unit in units) {
            if (unit.isUnlocked && !unit.bossWon) {
              return unit;
            }
          }
          // Phần sau chỉ mở khi phần này đã hoàn thành toàn bộ.
          if (units.isEmpty || !units.every((u) => u.bossWon)) break;
        }
        if (firstUnits != null && firstUnits.isNotEmpty) {
          return firstUnits.first;
        }
      } catch (e) {
        debugPrint(
            '[LearningJourneyRepository] getCurrentProgress guest failed: $e');
      }
      return null;
    }

    try {
      final response = await client.rpc('current_learning_unit_v2');
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

        final path = await QueryCache.unitPathRows(client, unitId);
        final learningNodes = path
            .where((node) => node['node_type'] == 'learning')
            .toList(growable: false);
        final bossNode =
            path.where((node) => node['node_type'] == 'boss').firstOrNull;
        final unitRows = List<Map<String, dynamic>>.from(
          await client
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
    } catch (e) {
      debugPrint(
          '[LearningJourneyRepository] getUnitOverview fallback failed: $e');
    }
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
    } catch (e) {
      debugPrint('[LearningJourneyRepository] getNextAction failed: $e');
    }
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

class _UnitStaticContent {
  const _UnitStaticContent({required this.challenges, required this.bossStage});

  final List<Map<String, dynamic>> challenges;
  final Map<String, dynamic>? bossStage;
}
