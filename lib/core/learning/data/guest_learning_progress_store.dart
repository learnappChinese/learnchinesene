import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authoritative local persistent store for Guest learning progress.
///
/// Ensures Guest completions, scores, stars and boss victories are persisted
/// idempotently across app restarts, with migration for legacy guest data.
class GuestLearningProgressStore {
  GuestLearningProgressStore({
    SharedPreferences? prefs,
    DateTime Function()? nowProvider,
  })  : _prefs = prefs,
        _now = nowProvider ?? DateTime.now;

  SharedPreferences? _prefs;
  final DateTime Function() _now;

  static const String _completedStagesKey =
      'guest_learning_completed_stages_v1';
  static const String _completedBossesKey =
      'guest_learning_completed_bosses_v1';
  static const String _migratedFlagKey = 'guest_learning_store_migrated_v1';

  // Legacy keys from earlier iterations
  static const String _legacyAttemptsKey = 'guest_learning_attempts_v2';

  Future<SharedPreferences> get _getPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  bool _isMigrated = false;

  /// Ensures legacy guest records in SharedPreferences are converted
  /// into canonical completed nodes without data loss.
  Future<void> ensureMigrated() async {
    if (_isMigrated) return;
    final prefs = await _getPrefs;
    if (prefs.getBool(_migratedFlagKey) == true) {
      _isMigrated = true;
      return;
    }

    try {
      final stageMap = _readMap(prefs, _completedStagesKey);
      final bossMap = _readMap(prefs, _completedBossesKey);

      // 1. Scan legacy attempts list
      final rawAttempts = prefs.getStringList(_legacyAttemptsKey) ?? const [];
      for (final raw in rawAttempts) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) continue;
          final map = Map<String, dynamic>.from(decoded);
          final status = '${map['status'] ?? ''}';
          final activityType = '${map['activity_type'] ?? ''}';

          if (status != 'passed') continue;

          if (activityType == 'boss') {
            final stageId = (map['metadata'] is Map
                    ? (map['metadata']['stage_id'] as num?)?.toInt()
                    : null) ??
                int.tryParse('${map['source_id'] ?? ''}') ??
                0;
            final unitId = '${map['unit_id'] ?? ''}'.trim();
            if (unitId.isNotEmpty) {
              final existing = bossMap[unitId] is Map
                  ? Map<String, dynamic>.from(bossMap[unitId] as Map)
                  : null;
              final score = (map['score'] as num?)?.toInt() ?? 0;
              final stars = (map['stars'] as num?)?.toInt() ?? 1;
              bossMap[unitId] = <String, dynamic>{
                'unit_id': unitId,
                'stage_id': stageId,
                'score': (existing?['score'] as num?)?.toInt() ?? score,
                'stars': (existing?['stars'] as num?)?.toInt() ?? stars,
                'attempts': ((existing?['attempts'] as num?)?.toInt() ?? 0) + 1,
                'won': true,
                'completed_at': map['completed_at'] ?? _now().toIso8601String(),
              };
            }
          } else {
            // duo_level or other learning activity
            final levelId = '${map['level_id'] ?? ''}'.trim();
            final gameId = (map['metadata'] is Map
                    ? (map['metadata']['game_id'] as num?)?.toInt()
                    : null) ??
                int.tryParse(
                    '${map['source_id'] ?? ''}'.split(':').firstOrNull ?? '') ??
                1;
            if (levelId.isNotEmpty) {
              final key = '$gameId:$levelId';
              final existing = stageMap[key] is Map
                  ? Map<String, dynamic>.from(stageMap[key] as Map)
                  : null;
              final score = (map['score'] as num?)?.toInt() ?? 0;
              final stars = (map['stars'] as num?)?.toInt() ?? 1;
              stageMap[key] = <String, dynamic>{
                'game_id': gameId,
                'level_id': levelId,
                'unit_id': map['unit_id'],
                'score': ((existing?['score'] as num?)?.toInt() ?? 0) > score
                    ? existing!['score']
                    : score,
                'stars': ((existing?['stars'] as num?)?.toInt() ?? 0) > stars
                    ? existing!['stars']
                    : stars,
                'attempts': ((existing?['attempts'] as num?)?.toInt() ?? 0) + 1,
                'passed': true,
                'completed_at': map['completed_at'] ?? _now().toIso8601String(),
                'activity_type': activityType,
              };
            }
          }
        } catch (_) {}
      }

      // 2. Scan legacy `guest_progress_${gameId}_${levelId}` keys
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (!key.startsWith('guest_progress_')) continue;
        try {
          final raw = prefs.getString(key);
          if (raw == null) continue;
          final decoded = jsonDecode(raw);
          if (decoded is! Map) continue;
          final progress = Map<String, dynamic>.from(decoded);
          if (progress['is_completed'] != true) continue;

          final gameId = (progress['game_id'] as num?)?.toInt();
          final levelId = '${progress['level_id'] ?? ''}'.trim();
          if (gameId != null && levelId.isNotEmpty) {
            final nodeKey = '$gameId:$levelId';
            if (!stageMap.containsKey(nodeKey)) {
              stageMap[nodeKey] = <String, dynamic>{
                'game_id': gameId,
                'level_id': levelId,
                'score': (progress['best_score'] as num?)?.toInt() ?? 0,
                'stars': (progress['stars'] as num?)?.toInt() ?? 1,
                'attempts': (progress['attempts'] as num?)?.toInt() ?? 1,
                'passed': true,
                'completed_at': _now().toIso8601String(),
              };
            }
          }
        } catch (_) {}
      }

      await _writeMap(prefs, _completedStagesKey, stageMap);
      await _writeMap(prefs, _completedBossesKey, bossMap);
      await prefs.setBool(_migratedFlagKey, true);
    } catch (e) {
      debugPrint('[GuestLearningProgressStore] Migration warning: $e');
    } finally {
      _isMigrated = true;
    }
  }

  /// Records that a learning stage was passed.
  Future<void> recordStagePassed({
    required int gameId,
    required String levelId,
    String? unitId,
    required int score,
    required int stars,
    String? activityType,
  }) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final stageMap = _readMap(prefs, _completedStagesKey);
    final key = '$gameId:$levelId';

    final existing = stageMap[key] is Map
        ? Map<String, dynamic>.from(stageMap[key] as Map)
        : null;

    final existingScore = (existing?['score'] as num?)?.toInt() ?? 0;
    final existingStars = (existing?['stars'] as num?)?.toInt() ?? 0;
    final existingAttempts = (existing?['attempts'] as num?)?.toInt() ?? 0;

    stageMap[key] = <String, dynamic>{
      'game_id': gameId,
      'level_id': levelId,
      if (unitId != null && unitId.isNotEmpty) 'unit_id': unitId,
      'score': score > existingScore ? score : existingScore,
      'stars': stars > existingStars ? stars : existingStars,
      'attempts': existingAttempts + 1,
      'passed': true,
      'completed_at': _now().toIso8601String(),
      if (activityType != null) 'activity_type': activityType,
    };

    await _writeMap(prefs, _completedStagesKey, stageMap);

    // Keep legacy key in sync for backward compatibility
    final legacyKey = 'guest_progress_${gameId}_$levelId';
    await prefs.setString(
      legacyKey,
      jsonEncode(<String, dynamic>{
        'game_id': gameId,
        'level_id': levelId,
        'best_score': score > existingScore ? score : existingScore,
        'stars': stars > existingStars ? stars : existingStars,
        'is_completed': true,
        'is_unlocked': true,
        'attempts': existingAttempts + 1,
      }),
    );
  }

  /// Records that a Boss was defeated.
  Future<void> recordBossWon({
    required String unitId,
    required int stageId,
    required int score,
    required int stars,
  }) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final bossMap = _readMap(prefs, _completedBossesKey);

    final existing = bossMap[unitId] is Map
        ? Map<String, dynamic>.from(bossMap[unitId] as Map)
        : null;

    final existingScore = (existing?['score'] as num?)?.toInt() ?? 0;
    final existingStars = (existing?['stars'] as num?)?.toInt() ?? 0;
    final existingAttempts = (existing?['attempts'] as num?)?.toInt() ?? 0;

    bossMap[unitId] = <String, dynamic>{
      'unit_id': unitId,
      'stage_id': stageId,
      'score': score > existingScore ? score : existingScore,
      'stars': stars > existingStars ? stars : existingStars,
      'attempts': existingAttempts + 1,
      'won': true,
      'completed_at': _now().toIso8601String(),
    };

    await _writeMap(prefs, _completedBossesKey, bossMap);
  }

  /// Checks if a stage has been passed by Guest.
  Future<bool> isStagePassed(int gameId, String levelId) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final stageMap = _readMap(prefs, _completedStagesKey);
    final key = '$gameId:$levelId';
    final record = stageMap[key];
    if (record is Map && record['passed'] == true) return true;

    // Check by levelId alone if gameId differs (cross-gamecode fallback)
    for (final entry in stageMap.entries) {
      if (entry.value is Map) {
        final map = entry.value as Map;
        if (map['level_id'] == levelId && map['passed'] == true) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if the boss of a given Unit has been won.
  Future<bool> isBossWon(String unitId, [int? stageId]) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final bossMap = _readMap(prefs, _completedBossesKey);

    final record = bossMap[unitId];
    if (record is Map && record['won'] == true) return true;

    if (stageId != null && stageId > 0) {
      for (final entry in bossMap.entries) {
        if (entry.value is Map) {
          final map = entry.value as Map;
          if (map['stage_id'] == stageId && map['won'] == true) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Returns stage record if passed or attempted.
  Future<Map<String, dynamic>?> getStageRecord(
      int gameId, String levelId) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final stageMap = _readMap(prefs, _completedStagesKey);
    final key = '$gameId:$levelId';
    final record = stageMap[key];
    if (record is Map) return Map<String, dynamic>.from(record);
    return null;
  }

  /// Returns boss record for unit if won.
  Future<Map<String, dynamic>?> getBossRecord(String unitId) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final bossMap = _readMap(prefs, _completedBossesKey);
    final record = bossMap[unitId];
    if (record is Map) return Map<String, dynamic>.from(record);
    return null;
  }

  /// Returns all passed stage keys in format `'$gameId:$levelId'`.
  Future<Set<String>> getAllPassedStageKeys() async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final stageMap = _readMap(prefs, _completedStagesKey);
    return stageMap.keys
        .where((k) => stageMap[k] is Map && stageMap[k]['passed'] == true)
        .toSet();
  }

  /// Returns all Unit IDs where Boss has been won.
  Future<Set<String>> getAllWonBossUnitIds() async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final bossMap = _readMap(prefs, _completedBossesKey);
    return bossMap.keys
        .where((k) => bossMap[k] is Map && bossMap[k]['won'] == true)
        .toSet();
  }

  /// Returns the count of passed stages for a specific unitId.
  Future<int> getPassedStageCountForUnit(String unitId) async {
    await ensureMigrated();
    final prefs = await _getPrefs;
    final stageMap = _readMap(prefs, _completedStagesKey);
    final normUnit = unitId.replaceAll('unit_', '').replaceAll('_duo', '').trim();

    return stageMap.values.where((v) {
      if (v is! Map || v['passed'] != true) return false;
      final storedUnit = '${v['unit_id'] ?? ''}'.trim();
      if (storedUnit.isNotEmpty) {
        if (storedUnit == unitId) return true;
        final normStored =
            storedUnit.replaceAll('unit_', '').replaceAll('_duo', '').trim();
        if (normStored == normUnit) return true;
      }
      // Fallback check level_id (e.g. 'unit_1_stage_2' or '1_2')
      final levelId = '${v['level_id'] ?? ''}'.trim();
      if (levelId.startsWith(unitId) ||
          (normUnit.isNotEmpty &&
              (levelId.startsWith('unit_$normUnit') ||
                  levelId.startsWith('${normUnit}_')))) {
        return true;
      }
      return false;
    }).length;
  }

  Map<String, dynamic> _readMap(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _writeMap(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic> map,
  ) async {
    await prefs.setString(key, jsonEncode(map));
  }
}
