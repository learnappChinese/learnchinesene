import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/learning_result.dart';

abstract interface class LearningProgressRepository {
  Future<LearningResult> recordReward({
    required String activityType,
    required String sourceType,
    required String sourceId,
    required String attemptId,
    required double score,
    required double accuracy,
    required int correctCount,
    required int wrongCount,
    required int stars,
    required bool passed,
    required int baseXp,
    required int bonusXp,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
  });

  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50});
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({int limit = 50});
  Future<void> migrateGuestProgressToCloud();
}

class SupabaseLearningProgressRepository implements LearningProgressRepository {
  SupabaseLearningProgressRepository({
    SupabaseClient? client,
    SharedPreferences? prefs,
  })  : _client = client,
        _prefs = prefs;

  final SupabaseClient? _client;
  SharedPreferences? _prefs;

  static const String _localStatsKey = 'guest_learning_stats_v1';
  static const String _localXpEventsKey = 'guest_learning_xp_events_v1';
  static const String _localAttemptsKey = 'guest_learning_attempts_v1';

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences> get _getPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String? get _userId => _activeClient?.auth.currentUser?.id;

  @override
  Future<LearningResult> recordReward({
    required String activityType,
    required String sourceType,
    required String sourceId,
    required String attemptId,
    required double score,
    required double accuracy,
    required int correctCount,
    required int wrongCount,
    required int stars,
    required bool passed,
    required int baseXp,
    required int bonusXp,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
  }) async {
    final client = _activeClient;
    final userId = _userId;
    final finalMetadata = metadata ?? <String, dynamic>{};

    if (client != null && userId != null) {
      try {
        final res = await client.rpc(
          'record_learning_reward',
          params: {
            'p_activity_type': activityType,
            'p_source_type': sourceType,
            'p_source_id': sourceId,
            'p_attempt_id': attemptId,
            'p_score': score,
            'p_accuracy': accuracy,
            'p_correct_count': correctCount,
            'p_wrong_count': wrongCount,
            'p_stars': stars,
            'p_passed': passed,
            'p_base_xp': baseXp,
            'p_bonus_xp': bonusXp,
            'p_idempotency_key': idempotencyKey,
            'p_metadata': finalMetadata,
          },
        );

        final data =
            res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
        return LearningResult(
          activityType: activityType,
          sourceId: sourceId,
          attemptId: attemptId,
          passed: passed,
          stars: stars,
          score: score,
          accuracy: accuracy,
          correctCount: correctCount,
          wrongCount: wrongCount,
          xpEarned: (data['xp_awarded'] as num?)?.toInt() ?? (baseXp + bonusXp),
          baseXp: baseXp,
          bonusXp: bonusXp,
          newTotalXp: (data['total_exp'] as num?)?.toInt() ?? 0,
          newStreak: (data['current_streak'] as num?)?.toInt() ?? 1,
          isFirstClear: data['is_first_clear'] == true,
          isPerfect: accuracy >= 1.0,
          metadata: finalMetadata,
        );
      } catch (e) {
        // Fallback to local if remote request fails
      }
    }

    // Guest / Offline fallback
    return _recordLocalReward(
      activityType: activityType,
      sourceType: sourceType,
      sourceId: sourceId,
      attemptId: attemptId,
      score: score,
      accuracy: accuracy,
      correctCount: correctCount,
      wrongCount: wrongCount,
      stars: stars,
      passed: passed,
      baseXp: baseXp,
      bonusXp: bonusXp,
      idempotencyKey: idempotencyKey,
      metadata: finalMetadata,
    );
  }

  Future<LearningResult> _recordLocalReward({
    required String activityType,
    required String sourceType,
    required String sourceId,
    required String attemptId,
    required double score,
    required double accuracy,
    required int correctCount,
    required int wrongCount,
    required int stars,
    required bool passed,
    required int baseXp,
    required int bonusXp,
    String? idempotencyKey,
    required Map<String, dynamic> metadata,
  }) async {
    final prefs = await _getPrefs;
    final totalXpAwarded = baseXp + bonusXp;

    // Check idempotency in local events
    final localEventsRaw = prefs.getStringList(_localXpEventsKey) ?? <String>[];
    final idemKey = idempotencyKey ?? 'guest:$sourceType:$sourceId:$attemptId';

    for (final raw in localEventsRaw) {
      try {
        final ev = jsonDecode(raw) as Map<String, dynamic>;
        if (ev['idempotency_key'] == idemKey) {
          final stats = _readLocalStats(prefs);
          return LearningResult(
            activityType: activityType,
            sourceId: sourceId,
            attemptId: attemptId,
            passed: passed,
            stars: stars,
            score: score,
            accuracy: accuracy,
            correctCount: correctCount,
            wrongCount: wrongCount,
            xpEarned: 0,
            baseXp: baseXp,
            bonusXp: bonusXp,
            newTotalXp: stats['total_exp'] ?? 0,
            newStreak: stats['current_streak'] ?? 1,
            isFirstClear: false,
            isPerfect: accuracy >= 1.0,
            metadata: metadata,
          );
        }
      } catch (_) {}
    }

    // Update local stats
    final stats = _readLocalStats(prefs);
    final prevXp = stats['total_exp'] ?? 0;
    final prevStreak = stats['current_streak'] ?? 0;
    final lastStudy = DateTime.tryParse('${stats['last_study_date'] ?? ''}');
    final now = DateTime.now();

    var nextStreak = prevStreak;
    if (passed) {
      if (lastStudy == null) {
        nextStreak = 1;
      } else {
        final diffDays = DateTime(now.year, now.month, now.day)
            .difference(
                DateTime(lastStudy.year, lastStudy.month, lastStudy.day))
            .inDays;
        if (diffDays == 1) {
          nextStreak += 1;
        } else if (diffDays > 1) {
          nextStreak = 1;
        } else if (nextStreak == 0) {
          nextStreak = 1;
        }
      }
    }

    final newTotalXp = prevXp + totalXpAwarded;
    final newStats = {
      'total_exp': newTotalXp,
      'current_streak': nextStreak,
      'last_study_date': now.toIso8601String(),
    };
    await prefs.setString(_localStatsKey, jsonEncode(newStats));

    // Save event
    if (totalXpAwarded > 0) {
      localEventsRaw.add(jsonEncode({
        'activity_type': activityType,
        'source_type': sourceType,
        'source_id': sourceId,
        'xp_amount': totalXpAwarded,
        'idempotency_key': idemKey,
        'created_at': now.toIso8601String(),
      }));
      await prefs.setStringList(_localXpEventsKey, localEventsRaw);
    }

    return LearningResult(
      activityType: activityType,
      sourceId: sourceId,
      attemptId: attemptId,
      passed: passed,
      stars: stars,
      score: score,
      accuracy: accuracy,
      correctCount: correctCount,
      wrongCount: wrongCount,
      xpEarned: totalXpAwarded,
      baseXp: baseXp,
      bonusXp: bonusXp,
      newTotalXp: newTotalXp,
      newStreak: nextStreak,
      isFirstClear: true,
      isPerfect: accuracy >= 1.0,
      metadata: metadata,
    );
  }

  Map<String, dynamic> _readLocalStats(SharedPreferences prefs) {
    final raw = prefs.getString(_localStatsKey);
    if (raw == null) return {'total_exp': 0, 'current_streak': 0};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {'total_exp': 0, 'current_streak': 0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) async {
    final client = _activeClient;
    final userId = _userId;
    if (client != null && userId != null) {
      try {
        final rows = List<Map<String, dynamic>>.from(
          await client
              .from('learning_xp_events')
              .select(
                  'id, activity_type, source_type, xp_amount, reason, created_at')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(limit),
        );
        return rows;
      } catch (_) {}
    }

    // Guest fallback
    final prefs = await _getPrefs;
    final list = prefs.getStringList(_localXpEventsKey) ?? [];
    return list.map((raw) => jsonDecode(raw) as Map<String, dynamic>).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
      {int limit = 50}) async {
    final client = _activeClient;
    final userId = _userId;
    if (client != null && userId != null) {
      try {
        final rows = List<Map<String, dynamic>>.from(
          await client
              .from('learning_attempts')
              .select(
                  'id, activity_type, score, accuracy, status, stars, xp_earned, completed_at')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(limit),
        );
        return rows;
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<void> migrateGuestProgressToCloud() async {
    final client = _activeClient;
    final userId = _userId;
    if (client == null || userId == null) return;

    final prefs = await _getPrefs;
    final guestStats = _readLocalStats(prefs);
    final guestXp = (guestStats['total_exp'] as num?)?.toInt() ?? 0;
    if (guestXp <= 0) return;

    // Migrate local stats into user stats if cloud is empty or lower
    try {
      final cloudStats = await client
          .from('app_user_stats')
          .select('total_exp, current_streak')
          .eq('user_id', userId)
          .maybeSingle();

      if (cloudStats == null) {
        await client.from('app_user_stats').insert({
          'user_id': userId,
          'total_exp': guestXp,
          'current_streak':
              (guestStats['current_streak'] as num?)?.toInt() ?? 1,
          'last_study_date': DateTime.now().toIso8601String(),
        });
      }
      // Clear migrated guest stats to avoid double migration
      await prefs.remove(_localStatsKey);
      await prefs.remove(_localXpEventsKey);
    } catch (_) {}
  }
}
