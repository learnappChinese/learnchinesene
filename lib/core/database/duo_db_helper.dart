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

    final levelRows = List<Map<String, dynamic>>.from(
      await _client.from('duo_levels').select('id'),
    );
    final totalLevels = levelRows.length;

    final userId = _userId;
    final cloudRows = userId == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _client
                .from('duo_level_progress')
                .select('game_id, is_completed, stars')
                .eq('user_id', userId),
          );
    final prefs = userId == null ? await SharedPreferences.getInstance() : null;

    return games.map((game) {
      final gameId = (game['id'] as num?)?.toInt() ?? 0;
      var completedLevels = 0;
      var bestStars = 0;

      if (userId != null) {
        for (final progress in cloudRows) {
          if ((progress['game_id'] as num?)?.toInt() != gameId) continue;
          if (progress['is_completed'] == true) completedLevels++;
          bestStars = max(
            bestStars,
            (progress['stars'] as num?)?.toInt() ?? 0,
          );
        }
      } else {
        for (final key in prefs!.getKeys()) {
          if (!key.startsWith('$_progressPrefix${gameId}_')) continue;
          final progress = _decodeMap(prefs.getString(key));
          if (progress['is_completed'] == true) completedLevels++;
          bestStars = max(
            bestStars,
            (progress['stars'] as num?)?.toInt() ?? 0,
          );
        }
      }

      return <String, dynamic>{
        ...game,
        'id': gameId,
        'game_order': (game['game_order'] as num?)?.toInt() ?? 0,
        'total_levels': totalLevels,
        'completed_levels': completedLevels,
        'best_stars': bestStars,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getGamePath(
    int gameId,
    String gameCode,
  ) async {
    await _migrateLegacyStateIfNeeded();

    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'duo_game_path',
        params: {'p_game_code': gameCode},
      ),
    );

    final userId = _userId;
    final progressByLevel = <String, Map<String, dynamic>>{};

    SharedPreferences? prefs;
    if (userId != null) {
      final progressRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_level_progress')
            .select(
              'level_id, attempts, best_score, stars, is_unlocked, '
              'is_completed, last_played_at, completed_at',
            )
            .eq('user_id', userId)
            .eq('game_id', gameId),
      );
      for (final row in progressRows) {
        progressByLevel['${row['level_id'] ?? ''}'] = row;
      }
    } else {
      prefs = await SharedPreferences.getInstance();
    }

    var unlockedFirstPlayable = false;

    return rows.map((row) {
      final levelId = '${row['level_id'] ?? ''}';
      final progress = userId != null
          ? (progressByLevel[levelId] ?? <String, dynamic>{})
          : _decodeMap(prefs!.getString(_progressKey(gameId, levelId)));
      final challengeCount =
          (row['challenge_count'] as num?)?.toInt() ?? 0;

      var isUnlocked = progress['is_unlocked'] == true;
      if (!unlockedFirstPlayable && challengeCount > 0) {
        unlockedFirstPlayable = true;
        if (progress.isEmpty) isUnlocked = true;
      }

      return <String, dynamic>{
        ...row,
        'section_number':
            (row['section_number'] as num?)?.toInt() ?? 0,
        'unit_number': (row['unit_number'] as num?)?.toInt() ?? 0,
        'level_index': (row['level_index'] as num?)?.toInt() ?? 0,
        'challenge_count': challengeCount,
        'attempts': (progress['attempts'] as num?)?.toInt() ?? 0,
        'best_score': (progress['best_score'] as num?)?.toInt() ?? 0,
        'stars': (progress['stars'] as num?)?.toInt() ?? 0,
        'is_unlocked': isUnlocked ? 1 : 0,
        'is_completed': progress['is_completed'] == true ? 1 : 0,
        'last_played_at': progress['last_played_at'],
        'completed_at': progress['completed_at'],
      };
    }).toList();
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
      await _client.rpc(
        'record_duo_level_progress',
        params: {
          'p_game_id': gameId,
          'p_level_id': levelId,
          'p_score': max(0, score),
          'p_stars': stars.clamp(0, 3),
          'p_passed': passed,
        },
      );
      return;
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
        'completed_at': passed
            ? (current['completed_at'] ?? now)
            : current['completed_at'],
      }),
    );
  }

  Future<void> unlockLevel(int gameId, String levelId) async {
    final userId = _userId;
    if (userId != null) {
      await _client.rpc(
        'unlock_duo_level',
        params: {
          'p_game_id': gameId,
          'p_level_id': levelId,
        },
      );
      return;
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
              'wrong_count, started_at, status, updated_at',
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
        'started_at':
            existing['started_at'] ??
                DateTime.now().toUtc().toIso8601String(),
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

    final cloudProgressRows = List<Map<String, dynamic>>.from(
      await _client
          .from('duo_level_progress')
          .select(
            'game_id, level_id, attempts, best_score, stars, is_unlocked, '
            'is_completed, last_played_at, completed_at',
          )
          .eq('user_id', userId),
    );

    final cloudProgress = <String, Map<String, dynamic>>{
      for (final row in cloudProgressRows)
        '${row['game_id']}_${row['level_id']}': row,
    };

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

        final composite = '${parsed.gameId}_${parsed.levelId}';
        final remote = cloudProgress[composite] ?? <String, dynamic>{};
        final localCompleted = local['is_completed'] == true;
        final remoteCompleted = remote['is_completed'] == true;

        await _client.from('duo_level_progress').upsert(
          {
            'user_id': userId,
            'game_id': parsed.gameId,
            'level_id': parsed.levelId,
            'attempts': max(
              (local['attempts'] as num?)?.toInt() ?? 0,
              (remote['attempts'] as num?)?.toInt() ?? 0,
            ),
            'best_score': max(
              (local['best_score'] as num?)?.toInt() ?? 0,
              (remote['best_score'] as num?)?.toInt() ?? 0,
            ),
            'stars': max(
              (local['stars'] as num?)?.toInt() ?? 0,
              (remote['stars'] as num?)?.toInt() ?? 0,
            ).clamp(0, 3),
            'is_unlocked':
                local['is_unlocked'] == true ||
                remote['is_unlocked'] == true,
            'is_completed': localCompleted || remoteCompleted,
            'last_played_at': _latestIso(
              local['last_played_at'],
              remote['last_played_at'],
            ),
            'completed_at':
                remote['completed_at'] ?? local['completed_at'],
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,game_id,level_id',
        );
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
            'current_index':
                (local['current_index'] as num?)?.toInt() ?? 0,
            'score': (local['score'] as num?)?.toInt() ?? 0,
            'correct_count':
                (local['correct_count'] as num?)?.toInt() ?? 0,
            'wrong_count':
                (local['wrong_count'] as num?)?.toInt() ?? 0,
            'status': 'active',
            'started_at':
                local['started_at'] ??
                DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,game_id,level_id',
        );
      }
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

  static String? _latestIso(dynamic a, dynamic b) {
    final aDate = DateTime.tryParse('${a ?? ''}');
    final bDate = DateTime.tryParse('${b ?? ''}');
    if (aDate == null) return bDate?.toUtc().toIso8601String();
    if (bDate == null) return aDate.toUtc().toIso8601String();
    return aDate.isAfter(bDate)
        ? aDate.toUtc().toIso8601String()
        : bDate.toUtc().toIso8601String();
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
