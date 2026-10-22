import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning/model/learning_activity_submission.dart';
import '../../learning/service/learning_progress_sync_service.dart';

class MigrationResult {
  const MigrationResult({
    required this.success,
    this.migratedActivities = 0,
    this.migratedDuoLevels = 0,
    this.migratedSessions = 0,
    this.errorMessage,
  });

  final bool success;
  final int migratedActivities;
  final int migratedDuoLevels;
  final int migratedSessions;
  final String? errorMessage;
}

class GuestProgressMigrationService {
  GuestProgressMigrationService({
    SupabaseClient? client,
    SharedPreferences? prefs,
    LearningProgressSyncService? syncService,
  })  : _client = client,
        _prefs = prefs,
        _syncService = syncService;

  final SupabaseClient? _client;
  SharedPreferences? _prefs;
  final LearningProgressSyncService? _syncService;

  static const String _localStatsKey = 'guest_learning_stats_v2';
  static const String _localXpEventsKey = 'guest_learning_xp_events_v2';
  static const String _localAttemptsKey = 'guest_learning_attempts_v2';
  static const String _duoProgressPrefix = 'duo_game_progress_v2_';
  static const String _duoSessionPrefix = 'duo_game_session_v2_';
  static const String _duoMigrationPrefix = 'duo_cloud_migrated_v1_';

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences> get _getPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> hasGuestDataToMigrate() async {
    final prefs = await _getPrefs;
    final events = _readJsonList(prefs, _localXpEventsKey);
    if (events.isNotEmpty) return true;

    final attempts = _readJsonList(prefs, _localAttemptsKey);
    if (attempts.isNotEmpty) return true;

    for (final key in prefs.getKeys()) {
      if (key.startsWith(_duoProgressPrefix) ||
          key.startsWith(_duoSessionPrefix)) {
        return true;
      }
    }
    return false;
  }

  Future<MigrationResult> migrateGuestProgress({
    required String targetUserId,
  }) async {
    final client = _activeClient;
    if (client == null) {
      return const MigrationResult(
        success: false,
        errorMessage: 'Backend client not available',
      );
    }
    final prefs = await _getPrefs;

    int migratedActivities = 0;
    int migratedDuoLevels = 0;
    int migratedSessions = 0;

    try {
      // 1. Migrate Duo level progress via merge_guest_duo_progress_v2
      final localDuoProgress = <Map<String, dynamic>>[];
      final localSessions =
          <({int gameId, String levelId, Map<String, dynamic> data})>[];

      for (final key in prefs.getKeys()) {
        if (key.startsWith(_duoProgressPrefix)) {
          final parsed = _parseCompositeKey(key, _duoProgressPrefix);
          if (parsed == null) continue;
          final local = _decodeMap(prefs.getString(key));
          if (local.isEmpty) continue;

          localDuoProgress.add(<String, dynamic>{
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
        } else if (key.startsWith(_duoSessionPrefix)) {
          final parsed = _parseCompositeKey(key, _duoSessionPrefix);
          if (parsed == null) continue;
          final local = _decodeMap(prefs.getString(key));
          if (local.isNotEmpty && local['status'] == 'active') {
            localSessions.add((
              gameId: parsed.gameId,
              levelId: parsed.levelId,
              data: local,
            ));
          }
        }
      }

      if (localDuoProgress.isNotEmpty) {
        await client.rpc(
          'merge_guest_duo_progress_v2',
          params: <String, dynamic>{'p_progress': localDuoProgress},
        );
        migratedDuoLevels = localDuoProgress.length;
      }

      // 2. Migrate active sessions if any
      for (final session in localSessions) {
        final now = DateTime.now().toUtc().toIso8601String();
        await client.from('user_active_sessions').upsert(
          {
            'user_id': targetUserId,
            'game_id': session.gameId,
            'level_id': session.levelId,
            'current_index':
                (session.data['current_index'] as num?)?.toInt() ?? 0,
            'score': (session.data['score'] as num?)?.toInt() ?? 0,
            'correct_count':
                (session.data['correct_count'] as num?)?.toInt() ?? 0,
            'wrong_count': (session.data['wrong_count'] as num?)?.toInt() ?? 0,
            'attempt_id': session.data['attempt_id'],
            'status': 'active',
            'started_at': session.data['started_at'] ?? now,
            'updated_at': now,
          },
          onConflict: 'user_id,game_id,level_id',
        );
        migratedSessions++;
      }

      // 3. Migrate pending learning activity submissions (complete_learning_activity_v2)
      final xpEvents = _readJsonList(prefs, _localXpEventsKey);
      final remainingEvents = <Map<String, dynamic>>[];

      for (final event in xpEvents) {
        final raw = event['submission'];
        if (raw is! Map) {
          remainingEvents.add(event);
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
          migratedActivities++;
        } catch (_) {
          remainingEvents.add(event);
        }
      }

      // 4. Update local storage only after cloud confirms
      await _writeJsonList(prefs, _localXpEventsKey, remainingEvents);
      if (remainingEvents.isEmpty) {
        await prefs.remove(_localAttemptsKey);
        await prefs.remove(_localStatsKey);
      }

      // Mark migration flag for user
      await prefs.setBool('$_duoMigrationPrefix$targetUserId', true);

      // 5. Invalidate progress sync domains across app
      final sync = _syncService;
      if (sync != null) {
        await sync.invalidate(
          LearningDomainEvent(
            type: LearningDomainEventType.identityChanged,
            domains: LearningDomain.values.toSet(),
            identityKey: targetUserId,
          ),
        );
      }

      return MigrationResult(
        success: true,
        migratedActivities: migratedActivities,
        migratedDuoLevels: migratedDuoLevels,
        migratedSessions: migratedSessions,
      );
    } catch (e) {
      return MigrationResult(
        success: false,
        migratedActivities: migratedActivities,
        migratedDuoLevels: migratedDuoLevels,
        migratedSessions: migratedSessions,
        errorMessage: e.toString(),
      );
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
        debugPrint('[GuestProgressMigrationService] _readJsonList failed: $e');
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

  static ({int gameId, String levelId})? _parseCompositeKey(
    String key,
    String prefix,
  ) {
    final rest = key.substring(prefix.length);
    final separator = rest.indexOf('_');
    if (separator <= 0 || separator >= rest.length - 1) return null;
    final gameId = int.tryParse(rest.substring(0, separator));
    if (gameId == null) return null;
    return (gameId: gameId, levelId: rest.substring(separator + 1));
  }

  static Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
