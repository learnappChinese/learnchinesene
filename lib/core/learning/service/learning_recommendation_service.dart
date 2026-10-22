import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/learning_journey_repository.dart';
import '../data/learning_progress_repository.dart';
import '../model/learning_journey_models.dart';
import '../model/recommended_next_action.dart';
import '../model/unit_mastery.dart';
import '../data/guest_learning_progress_store.dart';
import 'guest_journey_resolver.dart';
import '../../../screen/review/data/review_repository.dart';

abstract interface class LearningRecommendationService {
  Future<RecommendedNextAction?> recommend({
    String? unitId,
    String? levelId,
  });
}

class SupabaseLearningRecommendationService
    implements LearningRecommendationService {
  SupabaseLearningRecommendationService({
    SupabaseClient? client,
    LearningProgressRepository? progressRepository,
    LearningJourneyRepository? journeyRepository,
    ReviewRepository? reviewRepository,
    Future<List<Map<String, dynamic>>> Function(String unitId)? pathLoader,
    Future<List<Map<String, dynamic>>> Function(
            {String? userId, String? levelId})?
        activeSessionLoader,
    Future<int> Function()? overdueCountLoader,
  })  : _client = client,
        _progressRepository = progressRepository,
        _journeyRepository = journeyRepository,
        _reviewRepository = reviewRepository,
        _pathLoader = pathLoader,
        _activeSessionLoader = activeSessionLoader,
        _overdueCountLoader = overdueCountLoader;

  final SupabaseClient? _client;
  final LearningProgressRepository? _progressRepository;
  final LearningJourneyRepository? _journeyRepository;
  final ReviewRepository? _reviewRepository;
  final Future<List<Map<String, dynamic>>> Function(String unitId)? _pathLoader;
  final Future<List<Map<String, dynamic>>> Function(
      {String? userId, String? levelId})? _activeSessionLoader;
  final Future<int> Function()? _overdueCountLoader;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  LearningProgressRepository get _resolvedProgressRepo =>
      _progressRepository ??
      SupabaseLearningProgressRepository(client: _client);

  LearningJourneyRepository get _resolvedJourneyRepo =>
      _journeyRepository ??
      SupabaseLearningJourneyRepository(
        client: _client,
        recommendationService: this,
      );

  ReviewRepository get _resolvedReviewRepo =>
      _reviewRepository ?? SupabaseReviewRepository(client: _client);

  @override
  Future<RecommendedNextAction?> recommend({
    String? unitId,
    String? levelId,
  }) async {
    // 1. Resolve current unit context
    LearningUnitViewModel? currentUnit;
    var targetUnitId = unitId;

    try {
      if (targetUnitId == null || targetUnitId.isEmpty) {
        currentUnit = await _resolvedJourneyRepo.getCurrentProgress();
        targetUnitId = currentUnit?.id;
      } else {
        // If unitId is passed, attempt to load current progress or verify unit
        currentUnit = await _resolvedJourneyRepo.getCurrentProgress();
        if (currentUnit?.id != targetUnitId) {
          // Attempt to find unit by id across sections
          final sections = await _resolvedJourneyRepo.getSections();
          for (final section in sections) {
            final units = await _resolvedJourneyRepo.getUnits(section.id);
            final match = units.where((u) => u.id == targetUnitId).firstOrNull;
            if (match != null) {
              currentUnit = match;
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[LearningRecommendationService] Resolve targetUnitId from progress failed: $e');
    }

    // Fallback for new user with zero prior activity
    if (targetUnitId == null || targetUnitId.isEmpty) {
      try {
        final sections = await _resolvedJourneyRepo.getSections();
        if (sections.isNotEmpty) {
          final firstSectionUnits =
              await _resolvedJourneyRepo.getUnits(sections.first.id);
          final firstUnlocked =
              firstSectionUnits.where((u) => u.isUnlocked).firstOrNull ??
                  firstSectionUnits.firstOrNull;
          if (firstUnlocked != null) {
            currentUnit = firstUnlocked;
            targetUnitId = firstUnlocked.id;
          }
        }
      } catch (e) {
        debugPrint(
            '[LearningRecommendationService] Fallback firstSectionUnits failed: $e');
      }
    }

    final userId = _client?.auth.currentUser?.id;

    // -------------------------------------------------------------
    // PRIORITY 1: Resume Active Session
    // -------------------------------------------------------------
    final active = await _loadActiveSession(
      userId: userId,
      levelId: levelId,
      unitId: targetUnitId,
      currentUnit: currentUnit,
    );
    if (active != null) return active;

    // -------------------------------------------------------------
    // PRIORITY 2: Next Unit CTA (when user just completed a Unit)
    // -------------------------------------------------------------
    if (currentUnit != null &&
        (currentUnit.state == UnitCompletionState.completed ||
            currentUnit.bossWon)) {
      try {
        final nextUnit = await _resolvedJourneyRepo.getNextUnit(currentUnit.id);
        if (nextUnit != null && nextUnit.isUnlocked) {
          return RecommendedNextAction(
            type: RecommendedActionType.nextUnit,
            destination: 'unit:${nextUnit.id}',
            unitId: nextUnit.id,
            sectionNumber: nextUnit.sectionNumber,
            unitNumber: nextUnit.unitNumber,
            reasonCode: 'unit_completed_next_unit',
            label: 'BÀI TIẾP THEO',
            title: 'Bài ${nextUnit.unitNumber}: ${nextUnit.title}',
            subtitle: 'Bắt đầu bài học tiếp theo trên hành trình',
            description: nextUnit.teachingObjective.isNotEmpty
                ? nextUnit.teachingObjective
                : 'Đã hoàn thành bài học trước. Tiếp tục hành trình mới!',
            estimatedMinutes: nextUnit.estimatedMinutes,
            xpReward: 30,
            rewardPreview: '+30 XP mở bài',
            metadata: <String, dynamic>{
              'unitTitle': nextUnit.title,
              'sectionNumber': nextUnit.sectionNumber,
            },
          );
        } else if (nextUnit == null) {
          // Completed all units in the curriculum
          return RecommendedNextAction(
            type: RecommendedActionType.explore,
            destination: 'sections',
            unitId: currentUnit.id,
            sectionNumber: currentUnit.sectionNumber,
            unitNumber: currentUnit.unitNumber,
            reasonCode: 'explore_world',
            label: 'KHÁM PHÁ',
            title: 'Khám phá bản đồ học tập',
            subtitle: 'Bạn đã hoàn thành các bài học hiện tại!',
            description:
                'Xem lại các khu vực và thử thách trên toàn hành trình.',
            estimatedMinutes: 3,
            xpReward: 10,
            rewardPreview: 'Khám phá thế giới',
          );
        }
      } catch (e) {
        debugPrint(
            '[LearningRecommendationService] Check unit completed/nextUnit failed: $e');
      }
    }

    // -------------------------------------------------------------
    // LOAD SERVER TRUTH: Path from unit_learning_path_v2
    // -------------------------------------------------------------
    List<Map<String, dynamic>> path = const [];
    if (targetUnitId != null && targetUnitId.isNotEmpty) {
      try {
        path = await _loadPath(targetUnitId);
      } catch (e) {
        debugPrint('[LearningRecommendationService] _loadPath failed: $e');
      }
    }

    final bossNode = path.cast<Map<String, dynamic>?>().firstWhere(
          (node) => node?['node_type'] == 'boss',
          orElse: () => null,
        );

    final isBossUnlocked = bossNode?['is_unlocked'] == true;
    final isBossCompleted = bossNode?['is_completed'] == true;
    final bossStageId = (bossNode?['boss_stage_id'] as num?)?.toInt() ??
        currentUnit?.bossStageId;
    final bossName = bossNode?['boss_name'] as String? ??
        bossNode?['game_name'] as String? ??
        currentUnit?.bossName ??
        'cuối bài';

    final isBossReady = (isBossUnlocked && !isBossCompleted) ||
        (currentUnit != null &&
            currentUnit.bossAvailable &&
            !currentUnit.bossWon);

    // -------------------------------------------------------------
    // PRIORITY 3: Boss CTA (when Boss is unlocked and ready)
    // -------------------------------------------------------------
    if (isBossReady && !isBossCompleted) {
      return RecommendedNextAction(
        type: RecommendedActionType.fightBoss,
        destination: 'boss:${bossStageId ?? ''}',
        unitId: targetUnitId,
        stageId: bossStageId,
        sectionNumber: currentUnit?.sectionNumber,
        unitNumber: currentUnit?.unitNumber,
        reasonCode: 'boss_ready',
        label: 'ĐÁNH BOSS',
        title: 'Thử thách Boss: $bossName',
        subtitle: 'Cổng Boss đã mở',
        description:
            'Bạn đã hoàn thành đủ nhiệm vụ yêu cầu. Đánh bại Boss để mở bài tiếp theo!',
        estimatedMinutes: 7,
        xpReward: 50,
        rewardPreview: 'Thưởng Boss + mở bài',
        metadata: <String, dynamic>{
          'bossStageId': bossStageId,
          'bossName': bossName,
        },
      );
    }

    // -------------------------------------------------------------
    // PRIORITY 4: Overdue Review (suggested if due, does not lock path)
    // -------------------------------------------------------------
    final overdueCount = await _loadOverdueReviewCount();
    if (overdueCount > 0) {
      return RecommendedNextAction(
        type: RecommendedActionType.review,
        destination: 'review:overdue',
        unitId: targetUnitId,
        sectionNumber: currentUnit?.sectionNumber,
        unitNumber: currentUnit?.unitNumber,
        reasonCode: 'overdue_review',
        label: 'ÔN NGAY',
        title: 'Ôn lại $overdueCount mục đến hạn',
        subtitle: 'Củng cố kiến thức trước khi tiếp tục hành trình',
        description: 'Những mục đến hạn có nguy cơ bị quên cao nhất.',
        estimatedMinutes: (overdueCount / 3).ceil().clamp(2, 8),
        xpReward: 25,
        rewardPreview: '+25 XP ôn luyện',
        canBypass: true,
      );
    }

    // -------------------------------------------------------------
    // PRIORITY 5: Active unfinished mission / path progression
    // -------------------------------------------------------------
    final nextMission = path.cast<Map<String, dynamic>?>().firstWhere(
          (node) =>
              node?['node_type'] == 'learning' &&
              node?['is_unlocked'] == true &&
              node?['is_completed'] != true,
          orElse: () => null,
        );
    if (nextMission != null) {
      final gameName = '${nextMission['game_name'] ?? 'Nhiệm vụ tiếp theo'}';
      final isFailed =
          nextMission['is_failed'] == true || nextMission['state'] == 'failed';
      final gameId = (nextMission['game_id'] as num?)?.toInt();
      final stageId = (nextMission['stage_id'] as num?)?.toInt();

      return RecommendedNextAction(
        type: RecommendedActionType.startMission,
        destination: 'mission:${gameId ?? ''}',
        unitId: targetUnitId,
        stageId: stageId,
        gameId: gameId,
        gameCode: nextMission['game_code'] as String?,
        sectionNumber: currentUnit?.sectionNumber,
        unitNumber: currentUnit?.unitNumber,
        reasonCode: 'in_progress_mission',
        label: isFailed ? 'THỬ LẠI' : 'TIẾP TỤC',
        title: gameName,
        subtitle: 'Tiếp tục bài học hiện tại',
        description:
            '${nextMission['game_description'] ?? 'Đây là nhiệm vụ đã mở gần nhất trên hành trình.'}',
        estimatedMinutes: 5,
        xpReward: 20,
        rewardPreview: '+20 XP',
        metadata: <String, dynamic>{
          'gameId': gameId,
          'gameCode': nextMission['game_code'],
          'stageId': stageId,
        },
      );
    }

    // -------------------------------------------------------------
    // PRIORITY 6: Weak-skill practice (evidence-based from UnitMastery)
    // -------------------------------------------------------------
    if (targetUnitId != null && targetUnitId.isNotEmpty) {
      try {
        final mastery =
            await _resolvedProgressRepo.fetchUnitMastery(targetUnitId);
        final weakSkill =
            _weakSkillRecommendation(mastery, targetUnitId, currentUnit);
        if (weakSkill != null) return weakSkill;
      } catch (e) {
        debugPrint(
            '[LearningRecommendationService] fetchUnitMastery failed: $e');
      }
    }

    // -------------------------------------------------------------
    // PRIORITY 7: Explore (fallback for new chapter or exploration)
    // -------------------------------------------------------------
    return RecommendedNextAction(
      type: RecommendedActionType.explore,
      destination: 'sections',
      unitId: targetUnitId,
      sectionNumber: currentUnit?.sectionNumber,
      unitNumber: currentUnit?.unitNumber,
      reasonCode: 'explore_world',
      label: currentUnit == null ? 'BẮT ĐẦU' : 'KHÁM PHÁ',
      title: currentUnit != null
          ? 'Khám phá bài học tiếp theo'
          : 'Bắt đầu hành trình tiếng Trung',
      subtitle: 'Xem toàn bộ lộ trình và thử thách',
      description: 'Khám phá các khu vực và thử thách mới.',
      estimatedMinutes: 3,
      xpReward: 10,
      rewardPreview: 'Nhiệm vụ mới',
    );
  }

  Future<RecommendedNextAction?> _loadActiveSession({
    String? userId,
    String? levelId,
    String? unitId,
    LearningUnitViewModel? currentUnit,
  }) async {
    try {
      List<Map<String, dynamic>> rows;
      if (_activeSessionLoader != null) {
        rows = await _activeSessionLoader(userId: userId, levelId: levelId);
      } else {
        var query = _resolvedClient
            .from('user_active_sessions')
            .select(
                'attempt_id, game_id, level_id, current_index, score, correct_count, wrong_count, status')
            .eq('status', 'active');
        if (userId != null && userId.isNotEmpty) {
          query = query.eq('user_id', userId);
        } else if (levelId != null && levelId.isNotEmpty) {
          query = query.eq('level_id', levelId);
        }
        rows = List<Map<String, dynamic>>.from(
          await query.order('updated_at', ascending: false).limit(1),
        );
      }

      if (rows.isEmpty) return null;
      final session = rows.first;
      final currentIndex = (session['current_index'] as num?)?.toInt() ?? 0;
      final gameId = (session['game_id'] as num?)?.toInt();
      final resolvedLevelId = '${session['level_id'] ?? levelId ?? ''}';

      return RecommendedNextAction(
        type: RecommendedActionType.resume,
        destination: 'session:${gameId ?? ''}',
        unitId: unitId,
        gameId: gameId,
        levelId: resolvedLevelId,
        sectionNumber: currentUnit?.sectionNumber,
        unitNumber: currentUnit?.unitNumber,
        currentIndex: currentIndex,
        reasonCode: 'active_session',
        label: 'TIẾP TỤC',
        title: 'Tiếp tục nhiệm vụ đang dở',
        subtitle: 'Bạn đang ở câu ${currentIndex + 1}',
        description: 'Tiếp tục câu hỏi đang làm dở, không mất tiến độ.',
        estimatedMinutes: 4,
        xpReward: 20,
        rewardPreview: 'Giữ nguyên tiến độ',
        metadata: <String, dynamic>{
          'currentIndex': currentIndex,
          'gameId': gameId,
          'levelId': resolvedLevelId,
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> _loadOverdueReviewCount() async {
    try {
      if (_overdueCountLoader != null) {
        return await _overdueCountLoader();
      }
      final summary = await _resolvedReviewRepo.loadReviewSummary();
      if (summary.totalDue > 0) return summary.totalDue;

      final now = DateTime.now().toUtc().toIso8601String();
      final rows = List<Map<String, dynamic>>.from(
        await _resolvedClient
            .from('user_word_progress')
            .select('word_id')
            .lte('next_review_at', now)
            .limit(20),
      );
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _loadPath(String unitId) async {
    if (_pathLoader != null) {
      return await _pathLoader(unitId);
    }
    final rows = List<Map<String, dynamic>>.from(
      await _resolvedClient.rpc(
        'unit_learning_path_v2',
        params: <String, dynamic>{'p_unit_id': unitId},
      ),
    );
    if (_resolvedClient.auth.currentUser == null) {
      final store = GuestLearningProgressStore();
      final resolver = const GuestJourneyResolver();
      final mastery = await _resolvedProgressRepo.fetchUnitMastery(unitId);
      return await resolver.overlayUnitPath(
        unitId: unitId,
        pathRows: rows,
        store: store,
        overallMastery: mastery.overall,
        isUnitUnlocked: true,
      );
    }
    return rows;
  }

  RecommendedNextAction? _weakSkillRecommendation(
    UnitMastery mastery,
    String unitId,
    LearningUnitViewModel? currentUnit,
  ) {
    final skills = <String, (String, double?)>{
      'vocabulary': ('Từ vựng', mastery.vocabulary),
      'listening': ('Nghe', mastery.listening),
      'speaking': ('Phát âm', mastery.speaking),
      'hanzi': ('Hanzi', mastery.hanzi),
    };
    final available = skills.entries
        .where((entry) => entry.value.$2 != null)
        .toList(growable: false)
      ..sort((a, b) => a.value.$2!.compareTo(b.value.$2!));
    if (available.isEmpty || mastery.overall >= mastery.masteryThreshold) {
      return null;
    }
    final skill = available.first;
    final skillKey = skill.key;
    final skillLabel = skill.value.$1;
    final score = skill.value.$2!;

    return RecommendedNextAction(
      type: RecommendedActionType.practiceWeakness,
      destination: 'weak:$skillKey:$unitId',
      unitId: unitId,
      sectionNumber: currentUnit?.sectionNumber,
      unitNumber: currentUnit?.unitNumber,
      reasonCode: 'weak_skill',
      label: 'LUYỆN NGAY',
      title: 'Củng cố $skillLabel',
      subtitle: 'Mastery hiện tại ${(score * 100).round()}%',
      description: 'Đây là kỹ năng cần củng cố nhất trong bài học hiện tại.',
      estimatedMinutes: 5,
      xpReward: 20,
      rewardPreview: 'Tăng mastery',
      metadata: <String, dynamic>{
        'skill': skillKey,
        'skillLabel': skillLabel,
        'mastery': score,
      },
    );
  }
}
