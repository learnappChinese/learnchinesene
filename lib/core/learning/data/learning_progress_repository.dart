import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/learning_activity_submission.dart';
import '../model/learning_result.dart';
import '../model/unit_mastery.dart';
import '../service/learning_rules_service.dart';

abstract interface class LearningProgressRepository {
  Future<void> startAttempt(LearningActivitySubmission submission);

  Future<void> abandonAttempt(
    String attemptId, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  });

  Future<LearningResult> completeActivity(
    LearningActivitySubmission submission,
  );

  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50});
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({int limit = 50});
  Future<UnitMastery> fetchUnitMastery(String unitId);
  Future<void> migrateGuestProgressToCloud();
}

class SupabaseLearningProgressRepository implements LearningProgressRepository {
  SupabaseLearningProgressRepository({
    SupabaseClient? client,
    SharedPreferences? prefs,
    LearningRulesService rulesService = const LearningRulesService(),
    DateTime Function()? nowProvider,
  })  : _client = client,
        _prefs = prefs,
        _rulesService = rulesService,
        _now = nowProvider ?? DateTime.now;

  final SupabaseClient? _client;
  final LearningRulesService _rulesService;
  final DateTime Function() _now;
  SharedPreferences? _prefs;
  final Map<String, Future<LearningResult>> _localCompletions = {};

  static const String _localStatsKey = 'guest_learning_stats_v2';
  static const String _localXpEventsKey = 'guest_learning_xp_events_v2';
  static const String _localAttemptsKey = 'guest_learning_attempts_v2';

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> abandonAttempt(
    String attemptId, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final client = _activeClient;
    if (client != null && _userId != null) {
      await client.rpc(
        'abandon_learning_attempt_v2',
        params: <String, dynamic>{
          'p_attempt_id': attemptId,
          'p_metadata': metadata,
        },
      );
      return;
    }

    final prefs = await _getPrefs;
    final attempts = _readJsonList(prefs, _localAttemptsKey);
    final index = attempts.indexWhere(
      (row) => row['id'] == attemptId && row['status'] == 'started',
    );
    if (index < 0) return;
    attempts[index] = <String, dynamic>{
      ...attempts[index],
      'status': 'abandoned',
      'completed_at': _now().toUtc().toIso8601String(),
      'metadata': <String, dynamic>{
        if (attempts[index]['metadata'] is Map)
          ...Map<String, dynamic>.from(attempts[index]['metadata'] as Map),
        ...metadata,
      },
    };
    await _writeJsonList(prefs, _localAttemptsKey, attempts);
  }

  Future<SharedPreferences> get _getPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  String? get _userId => _activeClient?.auth.currentUser?.id;

  @override
  Future<void> startAttempt(LearningActivitySubmission submission) async {
    final client = _activeClient;
    if (client != null && _userId != null) {
      await client.rpc(
        'start_learning_attempt_v2',
        params: <String, dynamic>{
          'p_attempt_id': submission.attemptId,
          'p_activity_type': submission.activityType,
          'p_source_type': submission.sourceType,
          'p_source_id': submission.sourceId,
          'p_unit_id': submission.unitId,
          'p_level_id': submission.levelId,
          'p_metadata': submission.metadata,
        },
      );
      return;
    }

    final prefs = await _getPrefs;
    final attempts = _readJsonList(prefs, _localAttemptsKey);
    if (attempts.any((row) => row['id'] == submission.attemptId)) return;
    attempts.add(<String, dynamic>{
      'id': submission.attemptId,
      ...submission.toJson(),
      'status': 'started',
      'started_at': _now().toUtc().toIso8601String(),
    });
    await _writeJsonList(prefs, _localAttemptsKey, attempts);
  }

  @override
  Future<LearningResult> completeActivity(
    LearningActivitySubmission submission,
  ) async {
    final client = _activeClient;
    if (client != null && _userId != null) {
      final response = await client.rpc(
        'complete_learning_activity_v2',
        params: submission.toRpcParams(),
      );
      final data = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return LearningResult.fromMap(data);
    }

    final eventKey = _eventKey(submission);
    final inFlight = _localCompletions[eventKey];
    if (inFlight != null) {
      final result = await inFlight;
      return LearningResult.fromMap(<String, dynamic>{
        ...result.toJson(),
        'idempotent': true,
      });
    }

    final completion = _completeLocalActivity(submission);
    _localCompletions[eventKey] = completion;
    try {
      return await completion;
    } finally {
      _localCompletions.remove(eventKey);
    }
  }

  Future<LearningResult> _completeLocalActivity(
    LearningActivitySubmission submission,
  ) async {
    final prefs = await _getPrefs;
    final events = _readJsonList(prefs, _localXpEventsKey);
    final eventKey = _eventKey(submission);
    final duplicate = events.where((row) => row['event_key'] == eventKey);
    if (duplicate.isNotEmpty) {
      final stored = duplicate.first['result'];
      if (stored is Map) {
        return LearningResult.fromMap(<String, dynamic>{
          ...Map<String, dynamic>.from(stored),
          'idempotent': true,
        });
      }
    }

    final attempts = _readJsonList(prefs, _localAttemptsKey);
    final relatedAttempts = attempts.where(
      (row) =>
          row['source_type'] == submission.sourceType &&
          row['source_id'] == submission.sourceId,
    );
    final firstClear = !relatedAttempts.any((row) => row['status'] == 'passed');
    final attemptNumber = relatedAttempts.length +
        (relatedAttempts.any((row) => row['id'] == submission.attemptId)
            ? 0
            : 1);

    final stats = _readLocalStats(prefs);
    final masteryKey =
        'mastery:${submission.sourceType}:${submission.sourceId}';
    final masteryBefore = (stats[masteryKey] as num?)?.toDouble() ?? 0;
    final previousHanziPractices = relatedAttempts
        .where((row) => row['activity_type'] == 'hanzi')
        .fold<int>(
          0,
          (total, row) =>
              total +
              (((row['metadata'] as Map?)?['practice_attempts'] as num?)
                      ?.toInt() ??
                  0),
        );
    final previousHanziBest = relatedAttempts
        .where((row) => row['activity_type'] == 'hanzi')
        .fold<double>(
      0,
      (best, row) {
        final value = (row['score'] as num?)?.toDouble() ?? 0;
        return value > best ? value : best;
      },
    );
    final evaluation = _rulesService.evaluate(
      submission,
      firstClear: firstClear,
      previousHanziPracticeCount: previousHanziPractices,
      previousHanziBestScore: previousHanziBest,
    );
    final masteryAfter = evaluation.passed
        ? (masteryBefore + (evaluation.accuracy * 0.1)).clamp(0.0, 1.0)
        : masteryBefore;

    final now = _now();
    final streak = _nextLocalStreak(
      stats: stats,
      now: now,
      eligible: evaluation.passed,
    );
    final totalXp = (stats['total_exp'] as num?)?.toInt() ?? 0;
    final newTotalXp = totalXp + evaluation.xpEarned;
    final result = LearningResult(
      activityType: submission.activityType,
      sourceId: submission.sourceId,
      attemptId: submission.attemptId,
      passed: evaluation.passed,
      stars: evaluation.stars,
      score: evaluation.score,
      accuracy: evaluation.accuracy,
      correctCount: submission.correctCount,
      wrongCount: submission.wrongCount,
      xpEarned: evaluation.xpEarned,
      baseXp: evaluation.baseXp,
      bonusXp: evaluation.bonusXp,
      newTotalXp: newTotalXp,
      currentStreak: streak,
      masteryBefore: masteryBefore,
      masteryAfter: masteryAfter,
      bestCombo: submission.bestCombo,
      firstClear: firstClear && evaluation.passed,
      perfect: evaluation.perfect,
      attemptNumber: attemptNumber,
      reason: evaluation.reason,
      metadata: <String, dynamic>{
        ...submission.metadata,
        'hanzi_mastered': evaluation.hanziMastered,
      },
    );

    final completedAttempt = <String, dynamic>{
      'id': submission.attemptId,
      ...submission.toJson(),
      'status': evaluation.passed ? 'passed' : 'failed',
      'score': evaluation.score,
      'accuracy': evaluation.accuracy,
      'stars': evaluation.stars,
      'xp_earned': evaluation.xpEarned,
      'mastery_before': masteryBefore,
      'mastery_after': masteryAfter,
      'completed_at': now.toUtc().toIso8601String(),
    };
    final existingIndex =
        attempts.indexWhere((row) => row['id'] == submission.attemptId);
    if (existingIndex >= 0) {
      attempts[existingIndex] = <String, dynamic>{
        ...attempts[existingIndex],
        ...completedAttempt,
      };
    } else {
      attempts.add(completedAttempt);
    }

    events.add(<String, dynamic>{
      'event_key': eventKey,
      'activity_type': submission.activityType,
      'source_type': submission.sourceType,
      'source_id': submission.sourceId,
      'xp_amount': evaluation.xpEarned,
      'base_xp': evaluation.baseXp,
      'bonus_xp': evaluation.bonusXp,
      'reason': evaluation.reason,
      'created_at': now.toUtc().toIso8601String(),
      'submission': submission.toJson(),
      'result': result.toJson(),
    });

    await _writeJsonList(prefs, _localAttemptsKey, attempts);
    await _writeJsonList(prefs, _localXpEventsKey, events);
    await prefs.setString(
      _localStatsKey,
      jsonEncode(<String, dynamic>{
        ...stats,
        'total_exp': newTotalXp,
        'current_streak': streak,
        if (evaluation.passed)
          'last_study_date': now.toIso8601String()
        else
          'last_study_date': stats['last_study_date'],
        masteryKey: masteryAfter,
      }),
    );
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) async {
    final client = _activeClient;
    final userId = _userId;
    if (client != null && userId != null) {
      return List<Map<String, dynamic>>.from(
        await client
            .from('learning_xp_events')
            .select(
              'id, activity_type, source_type, source_id, xp_amount, '
              'base_xp, bonus_xp, reason, created_at',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit),
      );
    }

    final prefs = await _getPrefs;
    final rows = _readJsonList(prefs, _localXpEventsKey).reversed.toList();
    return rows.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({
    int limit = 50,
  }) async {
    final client = _activeClient;
    final userId = _userId;
    if (client != null && userId != null) {
      return List<Map<String, dynamic>>.from(
        await client
            .from('learning_attempts')
            .select(
              'id, activity_type, source_id, score, accuracy, status, stars, '
              'xp_earned, duration_seconds, best_combo, mastery_before, '
              'mastery_after, completed_at',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit),
      );
    }
    final prefs = await _getPrefs;
    final rows = _readJsonList(prefs, _localAttemptsKey).reversed.toList();
    return rows.take(limit).toList();
  }

  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) async {
    final client = _activeClient;
    if (client == null || _userId == null) return const UnitMastery();
    final response = await client.rpc(
      'unit_mastery_v2',
      params: <String, dynamic>{'p_unit_id': unitId},
    );
    return response is Map
        ? UnitMastery.fromMap(Map<String, dynamic>.from(response))
        : const UnitMastery();
  }

  @override
  Future<void> migrateGuestProgressToCloud() async {
    final client = _activeClient;
    if (client == null || _userId == null) return;

    final prefs = await _getPrefs;
    final events = _readJsonList(prefs, _localXpEventsKey);
    if (events.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final event in events) {
      final raw = event['submission'];
      if (raw is! Map) {
        remaining.add(event);
        continue;
      }
      try {
        final submission = LearningActivitySubmission.fromJson(
          Map<String, dynamic>.from(raw),
        );
        await client.rpc(
          'complete_learning_activity_v2',
          params: submission.toRpcParams(),
        );
      } catch (_) {
        remaining.add(event);
      }
    }

    await _writeJsonList(prefs, _localXpEventsKey, remaining);
    if (remaining.isEmpty) {
      await prefs.remove(_localAttemptsKey);
      await prefs.remove(_localStatsKey);
    }
  }

  String _eventKey(LearningActivitySubmission submission) =>
      '${submission.sourceType}:${submission.sourceId}:${submission.attemptId}:completion';

  Map<String, dynamic> _readLocalStats(SharedPreferences prefs) {
    final raw = prefs.getString(_localStatsKey);
    if (raw == null) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _readJsonList(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getStringList(key) ?? const <String>[];
    return raw
        .map((value) {
          try {
            return Map<String, dynamic>.from(jsonDecode(value) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((row) => row.isNotEmpty)
        .toList();
  }

  Future<void> _writeJsonList(
    SharedPreferences prefs,
    String key,
    List<Map<String, dynamic>> values,
  ) {
    return prefs.setStringList(
      key,
      values.map(jsonEncode).toList(growable: false),
    );
  }

  int _nextLocalStreak({
    required Map<String, dynamic> stats,
    required DateTime now,
    required bool eligible,
  }) {
    final previous = (stats['current_streak'] as num?)?.toInt() ?? 0;
    if (!eligible) return previous;
    final last = DateTime.tryParse('${stats['last_study_date'] ?? ''}');
    if (last == null) return 1;
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final difference = today.difference(lastDay).inDays;
    if (difference <= 0) return previous == 0 ? 1 : previous;
    if (difference == 1) return previous + 1;
    return 1;
  }
}
