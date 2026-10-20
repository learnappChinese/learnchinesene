import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/app_database.dart';
import '../learning_rules_config.dart';
import '../model/learning_activity_submission.dart';
import '../model/learning_result.dart';
import '../model/learning_skill_taxonomy.dart';
import '../model/unit_mastery.dart';
import '../service/learning_rules_service.dart';
import 'guest_learning_progress_store.dart';
import '../../../features/hanzi_writing/services/hanzi_stroke_cache.dart';
import '../service/guest_journey_resolver.dart';

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
    GuestLearningProgressStore? guestStore,
    GuestJourneyResolver guestResolver = const GuestJourneyResolver(),
  })  : _client = client,
        _prefs = prefs,
        _rulesService = rulesService,
        _now = nowProvider ?? DateTime.now,
        _guestStore = guestStore ??
            GuestLearningProgressStore(
              prefs: prefs,
              nowProvider: nowProvider,
            ),
        _guestResolver = guestResolver;

  final SupabaseClient? _client;
  final LearningRulesService _rulesService;
  final DateTime Function() _now;
  final GuestLearningProgressStore _guestStore;
  final GuestJourneyResolver _guestResolver;
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

    if (AppDatabase.instance.isOpen) {
      try {
        final db = AppDatabase.instance.database;
        final profileId = AppDatabase.instance.activeProfileId;
        final nowUtc = _now().toUtc().toIso8601String();
        await db.rawUpdate('''
          UPDATE local_activity_attempts
          SET status = 'abandoned', completed_at_utc = ?
          WHERE attempt_id = ? AND local_id = ? AND status = 'started';
        ''', [nowUtc, attemptId, profileId]);
      } catch (e) {
        debugPrint('[LearningProgressRepository] SQLite abandonAttempt error: $e');
      }
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

    if (AppDatabase.instance.isOpen) {
      try {
        final db = AppDatabase.instance.database;
        final profileId = AppDatabase.instance.activeProfileId;
        final nowUtc = _now().toUtc().toIso8601String();
        await db.rawInsert('''
          INSERT OR IGNORE INTO local_activity_attempts (
            attempt_id, local_id, activity_type, source_namespace, source_id,
            unit_id, level_id, started_at_utc, status, metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'started', ?);
        ''', [
          submission.attemptId,
          profileId,
          submission.activityType,
          submission.sourceType,
          submission.sourceId,
          submission.unitId,
          submission.levelId,
          nowUtc,
          jsonEncode(submission.metadata),
        ]);
      } catch (e) {
        debugPrint('[LearningProgressRepository] SQLite startAttempt error: $e');
      }
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
    final eventKey = _eventKey(submission);

    if (AppDatabase.instance.isOpen) {
      try {
        final db = AppDatabase.instance.database;
        final existingEvents = await db.query(
          'local_xp_events',
          where: 'event_key = ?',
          whereArgs: [eventKey],
          limit: 1,
        );
        if (existingEvents.isNotEmpty) {
          final existingAttempts = await db.query(
            'local_activity_attempts',
            where: 'attempt_id = ?',
            whereArgs: [submission.attemptId],
            limit: 1,
          );
          final score = (existingAttempts.firstOrNull?['score'] as num?)?.toDouble() ?? 100.0;
          final stars = (existingAttempts.firstOrNull?['stars'] as num?)?.toInt() ?? 3;
          final xp = (existingEvents.first['xp_amount'] as num?)?.toInt() ?? 0;
          final totalXp = await AppDatabase.instance.getTotalXp();
          final streak = await AppDatabase.instance.getCurrentStreak();
          return LearningResult(
            activityType: submission.activityType,
            sourceId: submission.sourceId,
            attemptId: submission.attemptId,
            passed: true,
            stars: stars,
            score: score,
            accuracy: 1.0,
            correctCount: submission.correctCount,
            wrongCount: submission.wrongCount,
            xpEarned: xp,
            baseXp: xp,
            bonusXp: 0,
            newTotalXp: totalXp,
            currentStreak: streak,
            masteryBefore: 1.0,
            masteryAfter: 1.0,
            bestCombo: submission.bestCombo,
            firstClear: false,
            perfect: false,
            attemptNumber: 1,
            unlockedNext: false,
            idempotent: true,
          );
        }
      } catch (_) {}
    }

    final prefs = await _getPrefs;
    final events = _readJsonList(prefs, _localXpEventsKey);
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
    final isBossAct = submission.activityType == 'boss';
    final isUnitDone = isBossAct && evaluation.passed;

    String? resolvedNextNodeId;
    String? resolvedNextUnitId;
    bool isUnlockedNext = false;
    bool isBossAvail = false;

    if (evaluation.passed) {
      if (isBossAct) {
        final stageId = (submission.metadata['stage_id'] as num?)?.toInt() ??
            int.tryParse(submission.sourceId) ??
            1;
        final unitId = submission.unitId ?? '';
        if (unitId.isNotEmpty) {
          await _guestStore.recordBossWon(
            unitId: unitId,
            stageId: stageId,
            score: evaluation.score.toInt(),
            stars: evaluation.stars,
          );
          resolvedNextUnitId = await _resolveNextUnitForGuest(unitId);
        }
        isUnlockedNext = resolvedNextUnitId != null;
      } else {
        final gameId = (submission.metadata['game_id'] as num?)?.toInt() ??
            int.tryParse(submission.sourceId.split(':').firstOrNull ?? '') ??
            1;
        final levelId = submission.levelId ??
            (submission.sourceId.contains(':')
                ? submission.sourceId.split(':').last
                : submission.sourceId);
        final unitId = submission.unitId;

        await _guestStore.recordStagePassed(
          gameId: gameId,
          levelId: levelId,
          unitId: unitId,
          score: evaluation.score.toInt(),
          stars: evaluation.stars,
          activityType: submission.activityType,
        );

        if (unitId != null && unitId.isNotEmpty) {
          final pathRows = await _fetchUnitPathRows(unitId);
          if (pathRows.isNotEmpty) {
            final nextResolution =
                await _guestResolver.resolveNextNodeAfterStageCompletion(
              unitId: unitId,
              completedGameId: gameId,
              completedLevelId: levelId,
              pathRows: pathRows,
              store: _guestStore,
              overallMastery: masteryAfter,
            );
            resolvedNextNodeId = nextResolution.nextNodeId;
            isUnlockedNext = nextResolution.unlockedNext;
            isBossAvail = nextResolution.bossReady;
          }
        }
      }
    }

    if (!isBossAvail &&
        submission.unitId != null &&
        submission.unitId!.isNotEmpty) {
      final localMastery = await _fetchLocalUnitMastery(submission.unitId!);
      isBossAvail = localMastery.isBossAvailable && !localMastery.isCompleted;
    }

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
      unlockedNext: isUnlockedNext,
      nextNodeId: resolvedNextNodeId,
      nextUnitId: resolvedNextUnitId,
      bossReady: isBossAvail,
      unitCompleted: isUnitDone,
      reason: evaluation.reason,
      metadata: <String, dynamic>{
        ...submission.metadata,
        'hanzi_mastered': evaluation.hanziMastered,
        'boss_ready': isBossAvail,
        'unit_completed': isUnitDone,
        if (resolvedNextNodeId != null) 'next_node_id': resolvedNextNodeId,
        if (resolvedNextUnitId != null) 'next_unit_id': resolvedNextUnitId,
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
    if (AppDatabase.instance.isOpen) {
      try {
        final db = AppDatabase.instance.database;
        final profileId = AppDatabase.instance.activeProfileId;
        final nowUtc = now.toUtc().toIso8601String();
        final dateStr = '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';

        await db.transaction((txn) async {
          // 1. Nhật ký lượt làm bài
          await txn.rawInsert('''
            INSERT OR REPLACE INTO local_activity_attempts (
              attempt_id, local_id, activity_type, source_namespace, source_id,
              unit_id, level_id, started_at_utc, completed_at_utc, status,
              score, accuracy, correct_count, wrong_count, stars, duration_seconds,
              metadata_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
          ''', [
            submission.attemptId,
            profileId,
            submission.activityType,
            submission.sourceType,
            submission.sourceId,
            submission.unitId,
            submission.levelId,
            submission.metadata['started_at'] ?? nowUtc,
            nowUtc,
            evaluation.passed ? 'passed' : 'failed',
            evaluation.score,
            evaluation.accuracy,
            submission.correctCount,
            submission.wrongCount,
            evaluation.stars,
            submission.durationSeconds,
            jsonEncode(submission.metadata),
          ]);

          // 2. Tiến độ ải học nếu vượt qua
          if (evaluation.passed) {
            final levelId = submission.levelId ??
                (isBossAct ? 'boss:${submission.unitId}' : submission.sourceId);
            await txn.rawInsert('''
              INSERT INTO local_stage_progress (
                local_id, level_id, status, best_score, best_stars, first_completed_at_utc, last_attempt_id
              ) VALUES (?, ?, 'completed', ?, ?, ?, ?)
              ON CONFLICT(local_id, level_id) DO UPDATE SET
                status = 'completed',
                best_score = MAX(best_score, excluded.best_score),
                best_stars = MAX(best_stars, excluded.best_stars),
                last_attempt_id = excluded.last_attempt_id;
            ''', [
              profileId,
              levelId,
              evaluation.score,
              evaluation.stars,
              nowUtc,
              submission.attemptId,
            ]);

            // 3. Chuỗi ngày học
            await txn.rawInsert('''
              INSERT OR IGNORE INTO local_study_days (local_id, local_date, first_qualifying_attempt_id)
              VALUES (?, ?, ?);
            ''', [profileId, dateStr, submission.attemptId]);
          }

          // 2b. Tiến độ luyện viết chữ Hán nếu là bài tập Hanzi
          if (submission.activityType == 'hanzi') {
            final charId = (submission.metadata['character_id'] as num?)?.toInt() ??
                int.tryParse(submission.sourceId) ??
                0;
            if (charId > 0) {
              final practiceAttempts =
                  (submission.metadata['practice_attempts'] as num?)?.toInt() ?? 1;
              final isMastered = (evaluation.hanziMastered || evaluation.score >= 90.0) ? 1 : 0;
              await txn.rawInsert('''
                INSERT INTO local_hanzi_progress (
                  local_id, character_id, attempts, best_accuracy, last_practiced_at_utc, is_mastered
                ) VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(local_id, character_id) DO UPDATE SET
                  attempts = attempts + excluded.attempts,
                  best_accuracy = MAX(best_accuracy, excluded.best_accuracy),
                  last_practiced_at_utc = excluded.last_practiced_at_utc,
                  is_mastered = MAX(is_mastered, excluded.is_mastered);
              ''', [
                profileId,
                charId,
                practiceAttempts,
                evaluation.score,
                nowUtc,
                isMastered,
              ]);
              HanziStrokeCache.instance.invalidateCharacter(charId);
            }
          }

          // 4. Sổ cái XP bất biến với event_key duy nhất
          await txn.rawInsert('''
            INSERT OR IGNORE INTO local_xp_events (
              event_id, event_key, local_id, attempt_id, source_namespace, source_id,
              base_xp, bonus_xp, xp_amount, earned_at_utc, reward_rule_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1);
          ''', [
            _generateRandomUuid(),
            eventKey,
            profileId,
            submission.attemptId,
            submission.sourceType,
            submission.sourceId,
            evaluation.baseXp,
            evaluation.bonusXp,
            evaluation.xpEarned,
            nowUtc,
          ]);
        });
      } catch (e) {
        debugPrint('[LearningProgressRepository] SQLite completeActivity error: $e');
      }
    }

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

    if (AppDatabase.instance.isOpen) {
      try {
        final profileId = AppDatabase.instance.activeProfileId;
        final rows = await AppDatabase.instance.database.query(
          'local_xp_events',
          where: 'local_id = ?',
          whereArgs: [profileId],
          orderBy: 'earned_at_utc DESC',
          limit: limit,
        );
        if (rows.isNotEmpty) {
          return rows.map((r) => <String, dynamic>{
            'id': r['event_id'],
            'event_key': r['event_key'],
            'activity_type': r['source_namespace'],
            'source_type': r['source_namespace'],
            'source_id': r['source_id'],
            'xp_amount': r['xp_amount'],
            'base_xp': r['base_xp'],
            'bonus_xp': r['bonus_xp'],
            'reason': 'Học bài',
            'created_at': r['earned_at_utc'],
          }).toList();
        }
      } catch (_) {}
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

    if (AppDatabase.instance.isOpen) {
      try {
        final profileId = AppDatabase.instance.activeProfileId;
        final rows = await AppDatabase.instance.database.query(
          'local_activity_attempts',
          where: 'local_id = ?',
          whereArgs: [profileId],
          orderBy: 'started_at_utc DESC',
          limit: limit,
        );
        if (rows.isNotEmpty) {
          return rows.map((r) => <String, dynamic>{
            'id': r['attempt_id'],
            'activity_type': r['activity_type'],
            'source_id': r['source_id'],
            'score': r['score'],
            'accuracy': r['accuracy'],
            'status': r['status'],
            'stars': r['stars'],
            'xp_earned': 0,
            'duration_seconds': r['duration_seconds'],
            'best_combo': 0,
            'mastery_before': 0.0,
            'mastery_after': 0.0,
            'completed_at': r['completed_at_utc'],
          }).toList();
        }
      } catch (_) {}
    }

    final prefs = await _getPrefs;
    final rows = _readJsonList(prefs, _localAttemptsKey).reversed.toList();
    return rows.take(limit).toList();
  }

  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) async {
    final client = _activeClient;
    if (client == null || _userId == null) {
      return _fetchLocalUnitMastery(unitId);
    }
    final response = await client.rpc(
      'unit_mastery_v2',
      params: <String, dynamic>{'p_unit_id': unitId},
    );
    return response is Map
        ? UnitMastery.fromMap(Map<String, dynamic>.from(response))
        : const UnitMastery();
  }

  Future<UnitMastery> _fetchLocalUnitMastery(String unitId) async {
    final prefs = await _getPrefs;
    final attempts = _readJsonList(prefs, _localAttemptsKey);
    final normUnit =
        unitId.replaceAll('unit_', '').replaceAll('_duo', '').trim();
    final unitAttempts = attempts.where((row) {
      final status = '${row['status'] ?? ''}';
      if (status != 'passed' && status != 'failed') return false;
      final storedUnit = '${row['unit_id'] ?? ''}'.trim();
      if (storedUnit.isNotEmpty) {
        if (storedUnit == unitId) return true;
        final normStored =
            storedUnit.replaceAll('unit_', '').replaceAll('_duo', '').trim();
        if (normStored == normUnit) return true;
      }
      final levelId = '${row['level_id'] ?? ''}'.trim();
      if (levelId.startsWith(unitId) ||
          (normUnit.isNotEmpty &&
              (levelId.startsWith('unit_$normUnit') ||
                  levelId.startsWith('${normUnit}_')))) {
        return true;
      }
      return false;
    }).toList();

    if (unitAttempts.isEmpty) {
      final passedKeys = await _guestStore.getAllPassedStageKeys();
      final stages = <Map<String, dynamic>>[];
      for (final key in passedKeys) {
        final parts = key.split(':');
        if (parts.length == 2) {
          final gId = int.tryParse(parts[0]) ?? 0;
          final lId = parts[1];
          final rec = await _guestStore.getStageRecord(gId, lId);
          if (rec != null) {
            final storedUnit = '${rec['unit_id'] ?? ''}'.trim();
            final normStored = storedUnit
                .replaceAll('unit_', '')
                .replaceAll('_duo', '')
                .trim();
            if (storedUnit == unitId ||
                (normUnit.isNotEmpty && normStored == normUnit) ||
                lId.startsWith(unitId) ||
                (normUnit.isNotEmpty &&
                    (lId.startsWith('unit_$normUnit') ||
                        lId.startsWith('${normUnit}_')))) {
              stages.add(rec);
            }
          }
        }
      }
      if (stages.isNotEmpty) {
        final avgScore = stages
                .map((s) => (s['score'] as num?)?.toDouble() ?? 70.0)
                .reduce((a, b) => a + b) /
            stages.length;
        final derivedMastery = (avgScore / 100).clamp(0.0, 1.0);
        final bossWon = await _guestStore.isBossWon(unitId);
        return UnitMastery(
          overall: derivedMastery,
          vocabulary: derivedMastery,
          allRequiredMissionsPassed: false,
          bossWon: bossWon,
          state: bossWon
              ? UnitCompletionState.completed
              : UnitCompletionState.inProgress,
        );
      }
      return const UnitMastery();
    }

    final bestBySource = <String, double>{};
    final sourceSkill = <String, String>{};

    for (final row in unitAttempts) {
      final sourceType = '${row['source_type'] ?? ''}';
      final sourceId = '${row['source_id'] ?? ''}';
      final sourceKey = '$sourceType:$sourceId';

      final activityType = '${row['activity_type'] ?? ''}';
      final metadata = row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'] as Map)
          : const <String, dynamic>{};
      final gameCode = metadata['game_code'] as String?;
      final skill = LearningSkillTaxonomy.skillBucketFor(
        activityType: activityType,
        gameCode: gameCode,
      );

      final double mastery;
      if (activityType == 'speaking' || activityType == 'hanzi') {
        mastery =
            (((row['score'] as num?)?.toDouble() ?? 0) / 100).clamp(0.0, 1.0);
      } else {
        mastery = ((row['accuracy'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
      }

      final existing = bestBySource[sourceKey] ?? 0.0;
      if (mastery > existing || !bestBySource.containsKey(sourceKey)) {
        bestBySource[sourceKey] = mastery;
        sourceSkill[sourceKey] = skill;
      }
    }

    final skillScores = <String, List<double>>{
      'vocabulary': <double>[],
      'listening': <double>[],
      'speaking': <double>[],
      'hanzi': <double>[],
    };

    for (final entry in bestBySource.entries) {
      final skill = sourceSkill[entry.key];
      if (skill != null && skillScores.containsKey(skill)) {
        skillScores[skill]!.add(entry.value);
      }
    }

    double? avg(String skill) {
      final scores = skillScores[skill]!;
      if (scores.isEmpty) return null;
      return scores.reduce((a, b) => a + b) / scores.length;
    }

    final vocab = avg('vocabulary');
    final listen = avg('listening');
    final speak = avg('speaking');
    final hanzi = avg('hanzi');

    final overall = LearningRulesConfig.calculateUnitMastery(
      vocabularyMastery: vocab,
      listeningMastery: listen,
      speakingMastery: speak,
      hanziMastery: hanzi,
    );

    final bossWon = await _guestStore.isBossWon(unitId);
    final pathRows = await _fetchUnitPathRows(unitId);
    final learningNodes =
        pathRows.where((r) => r['node_type'] == 'learning').toList();

    final bool allPassed;
    if (learningNodes.isNotEmpty) {
      final passedKeys = await _guestStore.getAllPassedStageKeys();
      allPassed = learningNodes.every((node) {
        final gId = (node['game_id'] as num?)?.toInt() ?? 0;
        final lId = '${node['level_id'] ?? ''}'.trim();
        return passedKeys.contains('$gId:$lId') ||
            passedKeys.any((k) => k.endsWith(':$lId'));
      });
    } else {
      allPassed = unitAttempts.any((row) => row['status'] == 'passed');
    }

    final bossAvailable =
        allPassed && (overall >= LearningRulesConfig.unitMasteryThreshold);

    final state = bossWon
        ? UnitCompletionState.completed
        : (bossAvailable
            ? UnitCompletionState.bossPending
            : UnitCompletionState.inProgress);

    return UnitMastery(
      vocabulary: vocab,
      listening: listen,
      speaking: speak,
      hanzi: hanzi,
      overall: overall,
      allRequiredMissionsPassed: allPassed,
      masteryThreshold: LearningRulesConfig.unitMasteryThreshold,
      bossRequired: true,
      bossAvailable: bossAvailable,
      bossWon: bossWon,
      state: state,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUnitPathRows(String unitId) async {
    final client = _activeClient;
    if (client != null) {
      try {
        final rows = List<Map<String, dynamic>>.from(
          await client.rpc(
            'unit_learning_path_v2',
            params: <String, dynamic>{'p_unit_id': unitId},
          ),
        );
        if (rows.isNotEmpty) return rows;
      } catch (_) {}
    }
    return const [];
  }

  Future<String?> _resolveNextUnitForGuest(String currentUnitId) async {
    final client = _activeClient;
    if (client == null) return null;
    try {
      final sectionRows = List<Map<String, dynamic>>.from(
        await client.rpc('learning_sections_v2'),
      );
      for (final sec in sectionRows) {
        final secId = '${sec['section_id'] ?? ''}';
        final unitRows = List<Map<String, dynamic>>.from(
          await client.rpc(
            'learning_units_v2',
            params: <String, dynamic>{'p_section_id': secId},
          ),
        );
        final idx =
            unitRows.indexWhere((u) => '${u['unit_id']}' == currentUnitId);
        if (idx != -1) {
          if (idx + 1 < unitRows.length) {
            return '${unitRows[idx + 1]['unit_id']}';
          }
          final secIdx = sectionRows.indexOf(sec);
          if (secIdx + 1 < sectionRows.length) {
            final nextSecId = '${sectionRows[secIdx + 1]['section_id'] ?? ''}';
            final nextSecUnits = List<Map<String, dynamic>>.from(
              await client.rpc(
                'learning_units_v2',
                params: <String, dynamic>{'p_section_id': nextSecId},
              ),
            );
            if (nextSecUnits.isNotEmpty) {
              return '${nextSecUnits.first['unit_id']}';
            }
          }
          return null;
        }
      }
    } catch (e) {
      debugPrint('[LearningProgressRepository] _resolveNextUnitForGuest: $e');
    }
    return null;
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
    final listRaw = prefs.getStringList(key);
    if (listRaw != null) {
      return listRaw
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
    final singleRaw = prefs.getString(key);
    if (singleRaw != null) {
      try {
        final decoded = jsonDecode(singleRaw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
        }
      } catch (e) {
        debugPrint('[LearningProgressRepository] _readJsonList failed: $e');
      }
    }
    return <Map<String, dynamic>>[];
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

  String _generateRandomUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // v4
    values[8] = (values[8] & 0x3f) | 0x80; // variant
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
