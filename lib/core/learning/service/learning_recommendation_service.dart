import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/learning_progress_repository.dart';
import '../model/learning_recommendation.dart';
import '../model/unit_mastery.dart';

abstract interface class LearningRecommendationService {
  Future<LearningRecommendation?> recommend({
    required String unitId,
    required String levelId,
  });
}

class SupabaseLearningRecommendationService
    implements LearningRecommendationService {
  SupabaseLearningRecommendationService({
    SupabaseClient? client,
    LearningProgressRepository? progressRepository,
  })  : _client = client ?? Supabase.instance.client,
        _progressRepository = progressRepository ??
            SupabaseLearningProgressRepository(client: client);

  final SupabaseClient _client;
  final LearningProgressRepository _progressRepository;

  @override
  Future<LearningRecommendation?> recommend({
    required String unitId,
    required String levelId,
  }) async {
    final active = await _activeSession(levelId);
    if (active != null) return active;

    final overdueCount = await _overdueReviewCount();
    if (overdueCount > 0) {
      return LearningRecommendation(
        type: LearningRecommendationType.overdueReview,
        title: 'Ôn lại $overdueCount mục đến hạn',
        subtitle: 'Củng cố trước khi tiếp tục hành trình',
        reason: 'Những mục đến hạn có nguy cơ bị quên cao nhất.',
        cta: 'ÔN NGAY',
        targetId: 'review:overdue',
        estimatedMinutes: (overdueCount / 3).ceil().clamp(2, 8),
        rewardPreview: '+XP ôn luyện',
      );
    }

    final path = await _loadPath(unitId);
    final nextMission = path.cast<Map<String, dynamic>?>().firstWhere(
          (node) =>
              node?['node_type'] == 'learning' &&
              node?['is_unlocked'] == true &&
              node?['is_completed'] != true,
          orElse: () => null,
        );
    if (nextMission != null) {
      final gameName = '${nextMission['game_name'] ?? 'Nhiệm vụ tiếp theo'}';
      return LearningRecommendation(
        type: LearningRecommendationType.chapterProgression,
        title: gameName,
        subtitle: 'Tiếp tục Chapter hiện tại',
        reason: 'Đây là nhiệm vụ đã mở gần nhất trên hành trình.',
        cta: 'TIẾP TỤC',
        targetId: '${nextMission['game_id'] ?? ''}',
        estimatedMinutes: 5,
        rewardPreview: '+XP và sao nhiệm vụ',
      );
    }

    final mastery = await _progressRepository.fetchUnitMastery(unitId);
    final weakSkill = _weakSkillRecommendation(mastery, unitId);
    if (weakSkill != null) return weakSkill;

    final boss = path.cast<Map<String, dynamic>?>().firstWhere(
          (node) =>
              node?['node_type'] == 'boss' && node?['is_unlocked'] == true,
          orElse: () => null,
        );
    if (boss != null) {
      return LearningRecommendation(
        type: LearningRecommendationType.bossReady,
        title: '${boss['boss_name'] ?? boss['game_name'] ?? 'Boss Chapter'}',
        subtitle: 'Cổng Boss đã mở',
        reason: 'Bạn đã hoàn thành đủ nhiệm vụ và mastery yêu cầu.',
        cta: 'ĐÁNH BOSS',
        targetId: '${boss['boss_stage_id'] ?? ''}',
        estimatedMinutes: 7,
        rewardPreview: 'Thưởng Boss + mở Chapter',
      );
    }

    return LearningRecommendation(
      type: LearningRecommendationType.newChapter,
      title: 'Khám phá Chapter tiếp theo',
      subtitle: 'Một hành trình mới đang chờ bạn',
      reason: 'Chapter hiện tại không còn hoạt động khả dụng.',
      cta: 'MỞ BẢN ĐỒ',
      targetId: unitId,
      estimatedMinutes: 3,
      rewardPreview: 'Nhiệm vụ mới',
    );
  }

  Future<LearningRecommendation?> _activeSession(String levelId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_active_sessions')
          .select('attempt_id, game_id, level_id, current_index')
          .eq('level_id', levelId)
          .eq('status', 'active')
          .order('updated_at', ascending: false)
          .limit(1),
    );
    if (rows.isEmpty) return null;
    final session = rows.first;
    final currentIndex = (session['current_index'] as num?)?.toInt() ?? 0;
    return LearningRecommendation(
      type: LearningRecommendationType.activeSession,
      title: 'Tiếp tục nhiệm vụ đang dở',
      subtitle: 'Bạn đang ở câu ${currentIndex + 1}',
      reason: 'Tiếp tục đúng vị trí đã dừng gần nhất.',
      cta: 'TIẾP TỤC',
      targetId: '${session['game_id'] ?? ''}',
      estimatedMinutes: 4,
      rewardPreview: 'Giữ nguyên tiến độ',
    );
  }

  Future<int> _overdueReviewCount() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('lexicon_user_progress')
          .select('word_id')
          .lte('next_review_at', now)
          .limit(20),
    );
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> _loadPath(String unitId) async {
    return List<Map<String, dynamic>>.from(
      await _client.rpc(
        'unit_learning_path_v2',
        params: <String, dynamic>{'p_unit_id': unitId},
      ),
    );
  }

  LearningRecommendation? _weakSkillRecommendation(
    UnitMastery mastery,
    String unitId,
  ) {
    final scores = <String, double?>{
      'Từ vựng': mastery.vocabulary,
      'Nghe': mastery.listening,
      'Phát âm': mastery.speaking,
      'Hanzi': mastery.hanzi,
    };
    final available = scores.entries
        .where((entry) => entry.value != null)
        .toList(growable: false)
      ..sort((a, b) => a.value!.compareTo(b.value!));
    if (available.isEmpty || mastery.overall >= mastery.masteryThreshold) {
      return null;
    }
    final skill = available.first;
    return LearningRecommendation(
      type: LearningRecommendationType.weakSkill,
      title: 'Củng cố ${skill.key}',
      subtitle: 'Mastery hiện tại ${(skill.value! * 100).round()}%',
      reason: 'Đây là kỹ năng yếu nhất trong Chapter hiện tại.',
      cta: 'LUYỆN NGAY',
      targetId: 'weak:${skill.key.toLowerCase()}:$unitId',
      estimatedMinutes: 5,
      rewardPreview: 'Tăng mastery',
    );
  }
}
