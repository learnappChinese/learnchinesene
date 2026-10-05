import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/duo_challenge.dart';
import '../models/duo_flashcard.dart';

/// Cloud-backed data source for the Duolingo-style game center.
///
/// Learning content lives in Supabase. Only tiny per-device session/progress
/// state is stored in SharedPreferences; no SQLite content database is opened
/// or packaged with the app.
class DuoDbHelper {
  DuoDbHelper._();

  static final DuoDbHelper instance = DuoDbHelper._();

  static const _progressPrefix = 'duo_game_progress_v2_';
  static const _sessionPrefix = 'duo_game_session_v2_';

  SupabaseClient get _client => Supabase.instance.client;

  Future<SupabaseClient> get database async {
    await _client.from('duo_game_definitions').select('id').limit(1);
    return _client;
  }

  Future<List<Map<String, dynamic>>> getGamesForCenter() async {
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
    final prefs = await SharedPreferences.getInstance();

    return games.map((game) {
      final gameId = (game['id'] as num?)?.toInt() ?? 0;
      var completedLevels = 0;
      var bestStars = 0;

      for (final key in prefs.getKeys()) {
        if (!key.startsWith('$_progressPrefix${gameId}_')) continue;
        final progress = _decodeMap(prefs.getString(key));
        if (progress['is_completed'] == true) completedLevels++;
        bestStars = max(
          bestStars,
          (progress['stars'] as num?)?.toInt() ?? 0,
        );
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
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'duo_game_path',
        params: {'p_game_code': gameCode},
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    var unlockedFirstPlayable = false;

    return rows.map((row) {
      final levelId = '${row['level_id'] ?? ''}';
      final progress = _decodeMap(
        prefs.getString(_progressKey(gameId, levelId)),
      );
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
    final prefs = await SharedPreferences.getInstance();
    final key = _progressKey(gameId, levelId);
    final current = _decodeMap(prefs.getString(key));
    final now = DateTime.now().toIso8601String();

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
        'is_completed':
            passed || current['is_completed'] == true,
        'last_played_at': now,
        'completed_at': passed
            ? (current['completed_at'] ?? now)
            : current['completed_at'],
      }),
    );
  }

  Future<void> unlockLevel(int gameId, String levelId) async {
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
            existing['started_at'] ?? DateTime.now().toIso8601String(),
        'status': 'active',
      }),
    );
  }

  Future<void> clearActiveSession(int gameId, String levelId) async {
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
