import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/learning_presentation_mapper.dart';
import '../../widgets/adventure_node.dart';
import '../../../screen/chapter_adventure/data/chapter_adventure_repository.dart';
import '../../../screen/chapter_adventure/model/chapter_adventure.dart';
import '../../../screen/review/data/review_repository.dart';
import '../model/learning_journey_models.dart';
import '../model/unit_mastery.dart';

import '../model/learning_stage_models.dart';
import '../service/learning_stage_grouping_service.dart';

abstract interface class LearningJourneyRepository {
  Future<List<LearningSectionViewModel>> getSections();
  Future<List<LearningUnitViewModel>> getUnits(String sectionId);
  Future<ChapterAdventure?> getUnitJourney(String unitId);
  Future<List<LearningStageViewModel>> getUnitStages(String unitId);
  Future<LearningUnitViewModel?> getCurrentProgress();
  Future<LearningNextAction?> getNextAction();
}

class SupabaseLearningJourneyRepository implements LearningJourneyRepository {
  SupabaseLearningJourneyRepository({
    SupabaseClient? client,
    ChapterAdventureRepository? chapterAdventureRepository,
    ReviewRepository? reviewRepository,
    LearningStageGroupingService? stageGroupingService,
  })  : _client = client ?? Supabase.instance.client,
        _chapterRepo =
            chapterAdventureRepository ?? SupabaseChapterAdventureRepository(),
        _reviewRepo = reviewRepository ?? SupabaseReviewRepository(),
        _stageGroupingService =
            stageGroupingService ?? const LearningStageGroupingService();

  final SupabaseClient _client;
  final ChapterAdventureRepository _chapterRepo;
  final ReviewRepository _reviewRepo;
  final LearningStageGroupingService _stageGroupingService;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<List<LearningSectionViewModel>> getSections() async {
    try {
      final sectionRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_sections')
            .select('id, section_number, title')
            .order('section_number', ascending: true),
      );

      if (sectionRows.isEmpty) {
        return _fallbackSections();
      }

      // Query units count and completed units count
      final unitRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_units')
            .select('id, section_id, unit_number, title')
            .order('unit_number', ascending: true),
      );

      // Completed units map (from boss_stage_progress if logged in)
      final completedUnitIds = <String>{};
      if (_userId != null) {
        try {
          final completedBosses = List<Map<String, dynamic>>.from(
            await _client
                .from('boss_stage_progress')
                .select('stage_id')
                .eq('user_id', _userId!)
                .eq('completed', true),
          );
          final completedStageIds = completedBosses
              .map((row) => (row['stage_id'] as num?)?.toInt())
              .whereType<int>()
              .toSet();

          if (completedStageIds.isNotEmpty) {
            final stages = List<Map<String, dynamic>>.from(
              await _client
                  .from('boss_stages')
                  .select('id, unit_id')
                  .inFilter('id', completedStageIds.toList()),
            );
            for (final stage in stages) {
              final uid = stage['unit_id'] as String?;
              if (uid != null) completedUnitIds.add(uid);
            }
          }
        } catch (_) {}
      }

      final sections = <LearningSectionViewModel>[];
      bool previousSectionCompleted = true;

      for (final sec in sectionRows) {
        final secId = sec['id'] as String;
        final secNum = (sec['section_number'] as num?)?.toInt() ?? 1;
        final rawTitle = sec['title'] as String?;
        final cleanTitle = LearningPresentationMapper.sectionName(secNum, rawTitle);

        final secUnits = unitRows.where((u) => u['section_id'] == secId).toList();
        final unitCount = secUnits.length;
        final completedCount = secUnits
            .where((u) => completedUnitIds.contains(u['id'] as String))
            .length;

        final isUnlocked = secNum == 1 || previousSectionCompleted || completedCount > 0;
        if (completedCount < unitCount) {
          previousSectionCompleted = false;
        }

        sections.add(
          LearningSectionViewModel(
            id: secId,
            sectionNumber: secNum,
            title: LearningPresentationMapper.sectionHeading(secNum),
            subtitle: cleanTitle,
            unitCount: unitCount,
            completedUnitCount: completedCount,
            isUnlocked: isUnlocked,
          ),
        );
      }

      return sections;
    } catch (_) {
      return _fallbackSections();
    }
  }

  @override
  Future<List<LearningUnitViewModel>> getUnits(String sectionId) async {
    try {
      final unitRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_units')
            .select('id, section_id, unit_number, title')
            .eq('section_id', sectionId)
            .order('unit_number', ascending: true),
      );

      if (unitRows.isEmpty) return const [];

      final secNum = int.tryParse(sectionId.split('-').last) ?? 1;

      // Query boss stages for this section's units
      final unitIds = unitRows.map((u) => u['id'] as String).toList();
      final bossRows = List<Map<String, dynamic>>.from(
        await _client
            .from('boss_stages')
            .select('id, unit_id, boss_name')
            .inFilter('unit_id', unitIds),
      );
      final bossMap = {for (final b in bossRows) b['unit_id'] as String: b};

      // Query user progress if logged in
      final bossCompletedIds = <String>{};
      if (_userId != null) {
        try {
          final completed = List<Map<String, dynamic>>.from(
            await _client
                .from('boss_stage_progress')
                .select('stage_id')
                .eq('user_id', _userId!)
                .eq('completed', true),
          );
          final stageIds = completed
              .map((r) => (r['stage_id'] as num?)?.toInt())
              .whereType<int>()
              .toSet();

          for (final b in bossRows) {
            final stageId = (b['id'] as num?)?.toInt();
            if (stageId != null && stageIds.contains(stageId)) {
              bossCompletedIds.add(b['unit_id'] as String);
            }
          }
        } catch (_) {}
      }

      final result = <LearningUnitViewModel>[];
      bool previousUnitPassed = true;

      for (int i = 0; i < unitRows.length; i++) {
        final row = unitRows[i];
        final unitId = row['id'] as String;
        final unitNum = (row['unit_number'] as num?)?.toInt() ?? (i + 1);
        final title = LearningPresentationMapper.unitTitle(row['title'], unitNum);
        final boss = bossMap[unitId];
        final bossWon = bossCompletedIds.contains(unitId);

        // Lock logic cấp Unit: Unit 1 luôn mở. Unit tiếp theo mở khi Unit trước hoàn thành.
        final isUnlocked = i == 0 || previousUnitPassed || bossWon;

        UnitCompletionState state = UnitCompletionState.inProgress;
        if (bossWon) {
          state = UnitCompletionState.completed;
          previousUnitPassed = true;
        } else {
          previousUnitPassed = false;
        }

        result.add(
          LearningUnitViewModel(
            id: unitId,
            sectionId: sectionId,
            sectionNumber: secNum,
            unitNumber: unitNum,
            title: 'Bài $unitNum: $title',
            subtitle: 'Hành trình bài học toàn diện',
            teachingObjective: title,
            missionCount: 6,
            completedMissionCount: bossWon ? 6 : 0,
            mastery: bossWon ? 1.0 : 0.0,
            state: state,
            isUnlocked: isUnlocked,
            bossAvailable: isUnlocked && !bossWon,
            bossWon: bossWon,
            bossStageId: (boss?['id'] as num?)?.toInt(),
            bossName: boss?['boss_name'] as String?,
            estimatedMinutes: 15,
            lockReason: isUnlocked ? null : 'Hoàn thành bài học trước để mở khóa.',
          ),
        );
      }

      return result;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ChapterAdventure?> getUnitJourney(String unitId) async {
    return _chapterRepo.loadChapter(unitId);
  }

  @override
  Future<List<LearningStageViewModel>> getUnitStages(String unitId) async {
    try {
      // 1. Fetch duo_unit
      final unitRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_units')
            .select('id, section_id, unit_number, title')
            .eq('id', unitId)
            .limit(1),
      );
      if (unitRows.isEmpty) return const [];
      final unitRow = unitRows.first;
      final unitNumber = (unitRow['unit_number'] as num?)?.toInt() ?? 1;
      final unitTitle = LearningPresentationMapper.unitTitle(
        unitRow['title'],
        unitNumber,
      );
      final sectionId = '${unitRow['section_id'] ?? ''}';
      final secNum = int.tryParse(sectionId.split('-').last) ?? 1;

      // 2. Fetch lexicon_unit
      final lexiconUnitRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_units')
            .select('id, unit_number, title')
            .eq('unit_number', unitNumber)
            .limit(1),
      );
      final lexiconUnitId = lexiconUnitRows.isNotEmpty
          ? (lexiconUnitRows.first['id'] as num?)?.toInt()
          : null;

      // 3. Fetch words & characters
      List<Map<String, dynamic>> rawWords = const [];
      List<Map<String, dynamic>> rawCharacters = const [];
      List<Map<String, dynamic>> rawExamples = const [];

      if (lexiconUnitId != null) {
        final wordUnitRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_word_units')
              .select('word_id')
              .eq('unit_id', lexiconUnitId),
        );
        final wordIds = wordUnitRows
            .map((r) => (r['word_id'] as num?)?.toInt())
            .whereType<int>()
            .toList();

        if (wordIds.isNotEmpty) {
          rawWords = List<Map<String, dynamic>>.from(
            await _client
                .from('lexicon_words')
                .select(
                  'id, word, pinyin, meaning_vi, meaning_en, tts_url, main_character_id',
                )
                .inFilter('id', wordIds),
          );

          final charIds = rawWords
              .map((w) => (w['main_character_id'] as num?)?.toInt())
              .whereType<int>()
              .toSet()
              .toList();

          if (charIds.isNotEmpty) {
            rawCharacters = List<Map<String, dynamic>>.from(
              await _client
                  .from('lexicon_characters')
                  .select(
                    'id, character, stroke_count, stroke_paths, radical_id',
                  )
                  .inFilter('id', charIds),
            );
          }
        }

        rawExamples = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_examples')
              .select('id, word_id, sentence_cn, sentence_pinyin, sentence_vi')
              .eq('unit_id', lexiconUnitId)
              .limit(15),
        );
      }

      // 4. Fetch duo challenges
      final levelRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_levels')
            .select('id')
            .eq('unit_id', unitId),
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

        if (sessionIds.isNotEmpty) {
          rawChallenges = List<Map<String, dynamic>>.from(
            await _client
                .from('duo_challenges')
                .select(
                  'id, session_id, type, prompt, tts, slow_tts, choices_text, solutions, tokens_text',
                )
                .inFilter('session_id', sessionIds),
          );
        }
      }

      // 5. Fetch boss stage
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

      // 6. Fetch user progress if signed in
      Map<int, Map<String, dynamic>> wordProgress = {};
      Map<int, Map<String, dynamic>> hanziProgress = {};
      Map<int, Map<String, dynamic>> speakingProgress = {};
      Map<String, Map<String, dynamic>> gameProgress = {};
      Map<String, dynamic>? bossProg;

      if (_userId != null) {
        try {
          if (rawWords.isNotEmpty) {
            final wIds = rawWords.map((w) => w['id'] as int).toList();
            final wpList = List<Map<String, dynamic>>.from(
              await _client
                  .from('lexicon_user_progress')
                  .select('word_id, correct_count, mastered')
                  .eq('user_id', _userId!)
                  .inFilter('word_id', wIds),
            );
            wordProgress = {
              for (final row in wpList) (row['word_id'] as num).toInt(): row
            };
          }

          if (rawCharacters.isNotEmpty) {
            final cIds = rawCharacters.map((c) => c['id'] as int).toList();
            final hpList = List<Map<String, dynamic>>.from(
              await _client
                  .from('lexicon_hanzi_progress')
                  .select('character_id, practice_count, best_score')
                  .eq('user_id', _userId!)
                  .inFilter('character_id', cIds),
            );
            hanziProgress = {
              for (final row in hpList) (row['character_id'] as num).toInt(): row
            };
          }

          if (rawBossStage != null) {
            final bossId = (rawBossStage['id'] as num).toInt();
            final bpList = List<Map<String, dynamic>>.from(
              await _client
                  .from('boss_stage_progress')
                  .select('stage_id, completed, stars, best_score')
                  .eq('user_id', _userId!)
                  .eq('stage_id', bossId)
                  .limit(1),
            );
            if (bpList.isNotEmpty) bossProg = bpList.first;
          }
        } catch (_) {}
      }

      return _stageGroupingService.groupStagesForUnit(
        unitId: unitId,
        unitTitle: unitTitle,
        sectionNumber: secNum,
        unitNumber: unitNumber,
        rawWords: rawWords,
        rawCharacters: rawCharacters,
        rawChallenges: rawChallenges,
        rawExamples: rawExamples,
        rawBossStage: rawBossStage,
        wordProgress: wordProgress,
        hanziProgress: hanziProgress,
        speakingProgress: speakingProgress,
        gameProgress: gameProgress,
        bossProgress: bossProg,
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
        final secNum = (map['section_number'] as num?)?.toInt() ?? 1;
        final unitNum = (map['unit_number'] as num?)?.toInt() ?? 1;
        final title = LearningPresentationMapper.unitTitle(
          map['unit_title'],
          unitNum,
        );

        final masteryMap = map['mastery'] is Map
            ? Map<String, dynamic>.from(map['mastery'] as Map)
            : <String, dynamic>{};
        final mastery = (masteryMap['overall_mastery'] as num?)?.toDouble() ?? 0.0;

        return LearningUnitViewModel(
          id: unitId,
          sectionId: 'sec_$secNum',
          sectionNumber: secNum,
          unitNumber: unitNum,
          title: 'Bài $unitNum: $title',
          subtitle: 'Đang theo học',
          teachingObjective: title,
          missionCount: 6,
          completedMissionCount: (mastery * 6).round(),
          mastery: mastery,
          state: UnitCompletionState.inProgress,
          isUnlocked: true,
          bossAvailable: map['boss_available'] == true,
          bossWon: false,
          estimatedMinutes: 15,
        );
      }
    } catch (_) {}

    // Fallback to Unit 1
    return const LearningUnitViewModel(
      id: 'sec_1_unit_1',
      sectionId: '52b0a204e5bed4d512cc78ecaca69b4c-0',
      sectionNumber: 1,
      unitNumber: 1,
      title: 'Bài 1: Gọi tên món ăn và đồ uống',
      subtitle: 'Khởi đầu hành trình',
      teachingObjective: 'Gọi tên món ăn và đồ uống cơ bản',
      missionCount: 6,
      completedMissionCount: 0,
      mastery: 0.0,
      state: UnitCompletionState.inProgress,
      isUnlocked: true,
      bossAvailable: false,
      bossWon: false,
      estimatedMinutes: 15,
    );
  }

  @override
  Future<LearningNextAction?> getNextAction() async {
    try {
      // 1. Kiểm tra active session đang dở
      if (_userId != null) {
        final activeRows = List<Map<String, dynamic>>.from(
          await _client
              .from('duo_active_sessions')
              .select('game_id, level_id, current_index, score, status')
              .eq('user_id', _userId!)
              .eq('status', 'in_progress')
              .limit(1),
        );

        if (activeRows.isNotEmpty) {
          final active = activeRows.first;
          final levelId = '${active['level_id'] ?? ''}';
          final gameId = (active['game_id'] as num?)?.toInt();
          final currIdx = (active['current_index'] as num?)?.toInt() ?? 0;

          return LearningNextAction(
            type: LearningActionType.activeSession,
            unitId: 'sec_1_unit_1',
            sectionNumber: 1,
            unitNumber: 1,
            sectionTitle: LearningPresentationMapper.sectionName(1),
            unitTitle: 'Bài học hiện tại',
            missionTitle: 'Lượt học đang tiếp diễn',
            gameId: gameId,
            levelId: levelId,
            label: 'TIẾP TỤC ($currIdx câu đã làm)',
            description: 'Tiếp tục câu hỏi đang làm dở, không mất tiến độ.',
            currentIndex: currIdx,
          );
        }
      }

      // 2. Kiểm tra current unit và nhiệm vụ tiếp theo
      final currentUnit = await getCurrentProgress();
      if (currentUnit != null) {
        final journey = await getUnitJourney(currentUnit.id);
        if (journey != null && journey.missions.isNotEmpty) {
          // Check if boss ready
          if (journey.bossUnlocked && journey.boss != null && !currentUnit.bossWon) {
            return LearningNextAction(
              type: LearningActionType.fightBoss,
              unitId: currentUnit.id,
              sectionNumber: currentUnit.sectionNumber,
              unitNumber: currentUnit.unitNumber,
              sectionTitle: LearningPresentationMapper.sectionName(currentUnit.sectionNumber),
              unitTitle: currentUnit.title,
              missionTitle: 'Đấu Boss: ${journey.boss!.bossName}',
              label: 'KHIÊU CHIẾN BOSS',
              description: 'Đánh bại Boss để hoàn thành bài học và mở bài tiếp theo!',
              xpReward: 50,
            );
          }

          // Next mission in unit
          final nextMission = journey.missions.firstWhere(
            (m) => !m.isCompleted && m.state != AdventureNodeState.locked,
            orElse: () => journey.missions.first,
          );

          return LearningNextAction(
            type: LearningActionType.continueMission,
            unitId: currentUnit.id,
            sectionNumber: currentUnit.sectionNumber,
            unitNumber: currentUnit.unitNumber,
            sectionTitle: LearningPresentationMapper.sectionName(currentUnit.sectionNumber),
            unitTitle: currentUnit.title,
            missionTitle: nextMission.title,
            gameId: nextMission.gameId,
            gameCode: nextMission.gameCode,
            levelId: journey.levelId,
            label: 'TIẾP TỤC BÀI',
            description: nextMission.description,
            xpReward: 20,
          );
        }
      }

      // 3. Kiểm tra Review overdue
      final reviewSummary = await _reviewRepo.loadReviewSummary();
      if (reviewSummary.totalDue > 0) {
        return LearningNextAction(
          type: LearningActionType.reviewOverdue,
          unitId: 'review',
          sectionNumber: 1,
          unitNumber: 1,
          sectionTitle: 'Ôn tập thông minh',
          unitTitle: 'Củng cố kiến thức',
          missionTitle: 'Có ${reviewSummary.totalDue} mục đến hạn ôn',
          label: 'ÔN TẬP NGAY',
          description: 'Hệ thống ngắt quãng (SRS) nhắc bạn ôn tập để ghi nhớ lâu dài.',
          xpReward: 25,
        );
      }
    } catch (_) {}

    return const LearningNextAction(
      type: LearningActionType.startUnit,
      unitId: 'sec_1_unit_1',
      sectionNumber: 1,
      unitNumber: 1,
      sectionTitle: 'Giao tiếp cơ bản',
      unitTitle: 'Bài 1: Gọi tên món ăn và đồ uống',
      missionTitle: 'Khám phá từ mới',
      label: 'BẮT ĐẦU HỌC',
      description: 'Làm quen với các từ vựng và câu đầu tiên.',
      xpReward: 20,
    );
  }

  List<LearningSectionViewModel> _fallbackSections() {
    return List.generate(8, (i) {
      final secNum = i + 1;
      final unitCounts = [10, 30, 30, 60, 51, 49, 40, 40];
      return LearningSectionViewModel(
        id: 'sec_$secNum',
        sectionNumber: secNum,
        title: LearningPresentationMapper.sectionHeading(secNum),
        subtitle: LearningPresentationMapper.sectionName(secNum),
        unitCount: unitCounts[i],
        completedUnitCount: secNum == 1 ? 0 : 0,
        isUnlocked: secNum == 1,
      );
    });
  }
}
