import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/duo_challenge.dart';
import '../models/duo_flashcard.dart';

/// Cloud-backed data source for the Duolingo-style game center.
///
/// - Signed-in users: progress + active sessions are stored in Supabase.
/// - Guest users: the existing SharedPreferences fallback is preserved.
/// - Existing local signed-in progress is migrated once into Supabase.
class DuoDbHelper {
  DuoDbHelper._();

  static final DuoDbHelper instance = DuoDbHelper._();

  static const _progressPrefix = 'duo_game_progress_v2_';
  static const _sessionPrefix = 'duo_game_session_v2_';
  static const _migrationPrefix = 'duo_cloud_migrated_v1_';

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;
  bool get isSignedIn => _userId != null;

  Future<SupabaseClient> get database async {
    await _client.from('duo_game_definitions').select('id').limit(1);
    return _client;
  }

  Future<List<Map<String, dynamic>>> getGamesForCenter() async {
    await _migrateLegacyStateIfNeeded();

    final games = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_game_definitions')
          .select(
            'id, game_code, name_vi, description_vi, icon, game_order',
          )
          .order('game_order'),
    );

    final chapter = await _loadCurrentUnitPath();
    final current = chapter.current;
    final path = chapter.rows;

    return games.map((game) {
      final gameId = (game['id'] as num?)?.toInt() ?? 0;
      final missions = path
          .where((row) =>
              row['node_type'] == 'learning' &&
              (row['game_id'] as num?)?.toInt() == gameId)
          .toList(growable: false);
      final completed =
          missions.where((row) => row['is_completed'] == true).length;
      final target = _currentTarget(missions);
      final bestStars = missions.fold<int>(
        0,
        (best, row) => max(best, (row['stars'] as num?)?.toInt() ?? 0),
      );
      final state = target == null
          ? (missions.isNotEmpty && completed == missions.length
              ? 'completed'
              : 'quick_practice')
          : target['in_progress'] == true
              ? 'in_progress'
              : ((target['attempts'] as num?)?.toInt() ?? 0) > 0
                  ? 'failed'
                  : target['is_unlocked'] == true
                      ? 'available'
                      : 'locked';

      return <String, dynamic>{
        ...game,
        'id': gameId,
        'game_order': (game['game_order'] as num?)?.toInt() ?? 0,
        'unit_id': '${current['unit_id'] ?? ''}',
        'chapter_number': (current['unit_number'] as num?)?.toInt() ?? 1,
        'chapter_title': '${current['unit_title'] ?? ''}',
        'total_levels': missions.length,
        'completed_levels': completed,
        'best_stars': bestStars,
        'state': state,
        'target_level_id': target?['level_id'],
        'current_index': (target?['current_index'] as num?)?.toInt() ?? 0,
        'current_total': (target?['current_total'] as num?)?.toInt() ?? 0,
        'best_score': (target?['best_score'] as num?)?.toInt() ?? 0,
        'lock_reason': target?['lock_reason'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getGamePath(
    int gameId,
    String gameCode,
  ) async {
    await _migrateLegacyStateIfNeeded();

    final chapter = await _loadCurrentUnitPath();
    final current = chapter.current;
    return chapter.rows
        .where((row) =>
            row['node_type'] == 'learning' && row['game_code'] == gameCode)
        .map((row) => <String, dynamic>{
              ...row,
              'section_title': current['section_title'],
              'unit_title': current['unit_title'],
              'section_number': (row['section_number'] as num?)?.toInt() ?? 1,
              'unit_number': (row['unit_number'] as num?)?.toInt() ?? 1,
              'level_index': (row['level_index'] as num?)?.toInt() ?? 0,
              'challenge_count': (row['challenge_count'] as num?)?.toInt() ?? 0,
              'attempts': (row['attempts'] as num?)?.toInt() ?? 0,
              'best_score': (row['best_score'] as num?)?.toInt() ?? 0,
              'stars': (row['stars'] as num?)?.toInt() ?? 0,
              'is_unlocked': row['is_unlocked'] == true ? 1 : 0,
              'is_completed': row['is_completed'] == true ? 1 : 0,
            })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getUnitLearningPath(String unitId) async {
    var rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'unit_learning_path_v2',
        params: <String, dynamic>{'p_unit_id': unitId},
      ),
    );
    if (_userId == null) rows = await _overlayGuestPath(rows);
    return rows;
  }

  Future<
      ({
        Map<String, dynamic> current,
        List<Map<String, dynamic>> rows,
      })> _loadCurrentUnitPath() async {
    final response = await _client.rpc('current_learning_unit_v2');
    final current = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final unitId = '${current['unit_id'] ?? ''}';
    if (unitId.isEmpty) {
      return (current: current, rows: const <Map<String, dynamic>>[]);
    }

    final rows = await getUnitLearningPath(unitId);
    return (current: current, rows: rows);
  }

  Future<List<Map<String, dynamic>>> _overlayGuestPath(
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return rows.map((row) {
      if (row['node_type'] != 'learning') return row;
      final gameId = (row['game_id'] as num?)?.toInt() ?? 0;
      final levelId = '${row['level_id'] ?? ''}';
      final progress =
          _decodeMap(prefs.getString(_progressKey(gameId, levelId)));
      final active = _decodeMap(prefs.getString(_sessionKey(gameId, levelId)));
      final inProgress = active['status'] == 'active';
      return <String, dynamic>{
        ...row,
        'attempts': (progress['attempts'] as num?)?.toInt() ?? row['attempts'],
        'best_score':
            (progress['best_score'] as num?)?.toInt() ?? row['best_score'],
        'stars': (progress['stars'] as num?)?.toInt() ?? row['stars'],
        'is_unlocked': row['is_unlocked'] == true ||
            progress['is_unlocked'] == true ||
            progress['is_completed'] == true,
        'is_completed': progress['is_completed'] == true,
        'in_progress': inProgress,
        'current_index': inProgress
            ? (active['current_index'] as num?)?.toInt() ?? 0
            : row['current_index'],
        'current_total': row['current_total'],
      };
    }).toList(growable: false);
  }

  Map<String, dynamic>? _currentTarget(List<Map<String, dynamic>> missions) {
    for (final row in missions) {
      if (row['in_progress'] == true) return row;
    }
    for (final row in missions) {
      if (row['is_unlocked'] == true && row['is_completed'] != true) return row;
    }
    for (final row in missions) {
      if (row['is_completed'] != true) return row;
    }
    return null;
  }

  Future<void> saveLevelProgress(
    int gameId,
    String levelId,
    int score,
    int stars,
    bool passed,
  ) async {
    final userId = _userId;
    if (userId != null) {
      throw StateError(
        'Cloud level progress must be written by '
        'complete_learning_activity_v2.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _progressKey(gameId, levelId);
    final current = _decodeMap(prefs.getString(key));
    final now = DateTime.now().toUtc().toIso8601String();

    await prefs.setString(
      key,
      jsonEncode({
        'game_id': gameId,
        'level_id': levelId,
        'attempts': ((current['attempts'] as num?)?.toInt() ?? 0) + 1,
        'best_score': max(
          (current['best_score'] as num?)?.toInt() ?? 0,
          score,
        ),
        'stars': max((current['stars'] as num?)?.toInt() ?? 0, stars),
        'is_unlocked': true,
        'is_completed': passed || current['is_completed'] == true,
        'last_played_at': now,
        'completed_at':
            passed ? (current['completed_at'] ?? now) : current['completed_at'],
      }),
    );
  }

  Future<void> unlockLevel(int gameId, String levelId) async {
    final userId = _userId;
    if (userId != null) {
      throw StateError(
        'Cloud unlocks must be derived by complete_learning_activity_v2.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _progressKey(gameId, levelId);
    final current = _decodeMap(prefs.getString(key));

    await prefs.setString(
      key,
      jsonEncode({
        ...current,
        'game_id': gameId,
        'level_id': levelId,
        'is_unlocked': true,
      }),
    );
  }

  Future<List<DuoChallenge>> getChallengesForGameLevel(
    String levelId,
    String gameCode, {
    int limit = 10,
  }) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'duo_level_challenges',
        params: {
          'p_level_id': levelId,
          'p_game_code': gameCode,
          'p_limit': limit,
        },
      ),
    );

    return rows.map(DuoChallenge.fromMap).toList();
  }

  Future<List<DuoFlashcard>> getFlashcardsForWords(
    List<String> words,
  ) async {
    if (words.isEmpty) return <DuoFlashcard>[];

    final uniqueWords = words.toSet().toList();
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_flashcards')
          .select('id, word, pinyin, meaning, tts_url')
          .inFilter('word', uniqueWords),
    );

    return rows.map(DuoFlashcard.fromMap).toList();
  }

  Future<Map<String, dynamic>?> getActiveSession(
    int gameId,
    String levelId,
  ) async {
    await _migrateLegacyStateIfNeeded();

    final userId = _userId;
    if (userId != null) {
      final rows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_active_sessions')
            .select(
              'game_id, level_id, current_index, score, correct_count, '
              'wrong_count, attempt_id, started_at, status, updated_at',
            )
            .eq('user_id', userId)
            .eq('game_id', gameId)
            .eq('level_id', levelId)
            .eq('status', 'active')
            .limit(1),
      );
      return rows.isEmpty ? null : rows.first;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey(gameId, levelId));
    if (raw == null) return null;

    final session = _decodeMap(raw);
    return session['status'] == 'active' ? session : null;
  }

  Future<void> saveActiveSession(
    int gameId,
    String levelId,
    int currentIndex,
    int score,
    int correct,
    int wrong,
    String attemptId,
  ) async {
    final userId = _userId;
    if (userId != null) {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('duo_active_sessions').upsert(
        {
          'user_id': userId,
          'game_id': gameId,
          'level_id': levelId,
          'current_index': max(0, currentIndex),
          'score': max(0, score),
          'correct_count': max(0, correct),
          'wrong_count': max(0, wrong),
          'attempt_id': attemptId,
          'status': 'active',
          'updated_at': now,
        },
        onConflict: 'user_id,game_id,level_id',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _sessionKey(gameId, levelId);
    final existing = _decodeMap(prefs.getString(key));

    await prefs.setString(
      key,
      jsonEncode({
        'game_id': gameId,
        'level_id': levelId,
        'current_index': currentIndex,
        'score': score,
        'correct_count': correct,
        'wrong_count': wrong,
        'attempt_id': attemptId,
        'started_at':
            existing['started_at'] ?? DateTime.now().toUtc().toIso8601String(),
        'status': 'active',
      }),
    );
  }

  Future<void> clearActiveSession(int gameId, String levelId) async {
    final userId = _userId;
    if (userId != null) {
      await _client
          .from('duo_active_sessions')
          .delete()
          .eq('user_id', userId)
          .eq('game_id', gameId)
          .eq('level_id', levelId);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey(gameId, levelId));
  }

  Future<List<DuoFlashcard>> getRandomFlashcards({
    int limit = 20,
  }) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'random_duo_flashcards',
        params: {'p_limit': limit},
      ),
    );

    return rows.map(DuoFlashcard.fromMap).toList();
  }

  Future<void> _migrateLegacyStateIfNeeded() async {
    final userId = _userId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final migrationKey = '$_migrationPrefix$userId';
    if (prefs.getBool(migrationKey) == true) return;

    final localProgress = <Map<String, dynamic>>[];

    final cloudSessionRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_active_sessions')
          .select('game_id, level_id')
          .eq('user_id', userId)
          .eq('status', 'active'),
    );
    final cloudSessions = cloudSessionRows
        .map((row) => '${row['game_id']}_${row['level_id']}')
        .toSet();

    for (final key in prefs.getKeys()) {
      if (key.startsWith(_progressPrefix)) {
        final parsed = _parseLegacyCompositeKey(key, _progressPrefix);
        if (parsed == null) continue;
        final local = _decodeMap(prefs.getString(key));
        if (local.isEmpty) continue;

        localProgress.add(<String, dynamic>{
          'game_id': parsed.gameId,
          'level_id': parsed.levelId,
          'attempts': (local['attempts'] as num?)?.toInt() ?? 0,
          'best_score': (local['best_score'] as num?)?.toInt() ?? 0,
          'stars': (local['stars'] as num?)?.toInt() ?? 0,
          'is_unlocked': local['is_unlocked'] == true,
          'is_completed': local['is_completed'] == true,
          'last_played_at': local['last_played_at'],
          'completed_at': local['completed_at'],
        });
      } else if (key.startsWith(_sessionPrefix)) {
        final parsed = _parseLegacyCompositeKey(key, _sessionPrefix);
        if (parsed == null) continue;

        final composite = '${parsed.gameId}_${parsed.levelId}';
        if (cloudSessions.contains(composite)) continue;

        final local = _decodeMap(prefs.getString(key));
        if (local.isEmpty || local['status'] != 'active') continue;

        await _client.from('duo_active_sessions').upsert(
          {
            'user_id': userId,
            'game_id': parsed.gameId,
            'level_id': parsed.levelId,
            'current_index': (local['current_index'] as num?)?.toInt() ?? 0,
            'score': (local['score'] as num?)?.toInt() ?? 0,
            'correct_count': (local['correct_count'] as num?)?.toInt() ?? 0,
            'wrong_count': (local['wrong_count'] as num?)?.toInt() ?? 0,
            'attempt_id': local['attempt_id'],
            'status': 'active',
            'started_at':
                local['started_at'] ?? DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,game_id,level_id',
        );
      }
    }

    if (localProgress.isNotEmpty) {
      await _client.rpc(
        'merge_guest_duo_progress_v2',
        params: <String, dynamic>{'p_progress': localProgress},
      );
    }

    await prefs.setBool(migrationKey, true);
  }

  static _LegacyKey? _parseLegacyCompositeKey(
    String key,
    String prefix,
  ) {
    final rest = key.substring(prefix.length);
    final separator = rest.indexOf('_');
    if (separator <= 0 || separator >= rest.length - 1) return null;

    final gameId = int.tryParse(rest.substring(0, separator));
    if (gameId == null) return null;

    return _LegacyKey(
      gameId: gameId,
      levelId: rest.substring(separator + 1),
    );
  }

  static String _progressKey(int gameId, String levelId) =>
      '$_progressPrefix${gameId}_$levelId';

  static String _sessionKey(int gameId, String levelId) =>
      '$_sessionPrefix${gameId}_$levelId';

  static Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

class _LegacyKey {
  const _LegacyKey({
    required this.gameId,
    required this.levelId,
  });

  final int gameId;
  final String levelId;
}
