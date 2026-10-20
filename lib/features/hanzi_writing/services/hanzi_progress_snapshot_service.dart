import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HanziProgressSnapshot {
  const HanziProgressSnapshot({
    this.practiceCount = 0,
    this.bestScore = 0,
    this.lastScore = 0,
    this.nextReviewAt,
  });

  final int practiceCount;
  final double bestScore;
  final double lastScore;
  final DateTime? nextReviewAt;
}

class HanziProgressSnapshotService {
  HanziProgressSnapshotService({
    SupabaseClient? client,
    Future<SharedPreferences>? preferences,
  })  : _client = client ?? Supabase.instance.client,
        _preferences = preferences ?? SharedPreferences.getInstance();

  static const String guestAttemptsKey = 'guest_learning_attempts_v2';

  final SupabaseClient _client;
  final Future<SharedPreferences> _preferences;

  Future<HanziProgressSnapshot> loadForCharacter(int characterId) async {
    final result = await loadForCharacters(<int>[characterId]);
    return result[characterId] ?? const HanziProgressSnapshot();
  }

  Future<Map<int, HanziProgressSnapshot>> loadForCharacters(
    Iterable<int> characterIds,
  ) async {
    final ids = characterIds.where((id) => id > 0).toSet().toList();
    if (ids.isEmpty) return const <int, HanziProgressSnapshot>{};
    final user = _client.auth.currentUser;
    if (user == null) return _loadGuest(ids);
    return _loadCloud(user.id, ids);
  }

  Future<Map<int, HanziProgressSnapshot>> _loadCloud(
    String userId,
    List<int> ids,
  ) async {
    final rows = <Map<String, dynamic>>[];
    const chunkSize = 150;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);
      rows.addAll(List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_hanzi_progress')
            .select(
              'character_id,practice_count,best_score,last_score,next_review_at',
            )
            .eq('user_id', userId)
            .inFilter('character_id', chunk),
      ));
    }

    return <int, HanziProgressSnapshot>{
      for (final row in rows)
        if (row['character_id'] is num)
          (row['character_id'] as num).toInt(): HanziProgressSnapshot(
            practiceCount: (row['practice_count'] as num?)?.toInt() ?? 0,
            bestScore: (row['best_score'] as num?)?.toDouble() ?? 0,
            lastScore: (row['last_score'] as num?)?.toDouble() ?? 0,
            nextReviewAt:
                DateTime.tryParse('${row['next_review_at'] ?? ''}'),
          ),
    };
  }

  Future<Map<int, HanziProgressSnapshot>> _loadGuest(List<int> ids) async {
    final wanted = ids.toSet();
    final prefs = await _preferences;
    final raw = prefs.getString(guestAttemptsKey);
    if (raw == null || raw.isEmpty) {
      return const <int, HanziProgressSnapshot>{};
    }

    List<dynamic> attempts;
    try {
      final decoded = jsonDecode(raw);
      attempts = decoded is List ? decoded : const <dynamic>[];
    } catch (_) {
      return const <int, HanziProgressSnapshot>{};
    }

    final practiceCount = <int, int>{};
    final bestScore = <int, double>{};
    final latest = <int, _LatestGuestAttempt>{};

    for (final item in attempts) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      if (row['activity_type'] != 'hanzi' ||
          row['source_type'] != 'character') {
        continue;
      }
      final id = int.tryParse('${row['source_id'] ?? ''}');
      if (id == null || !wanted.contains(id)) continue;

      final metadata = row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'] as Map)
          : const <String, dynamic>{};
      practiceCount[id] = (practiceCount[id] ?? 0) +
          ((metadata['practice_attempts'] as num?)?.toInt() ?? 0);

      final score = (row['score'] as num?)?.toDouble() ?? 0;
      if (score > (bestScore[id] ?? 0)) bestScore[id] = score;

      final completedAt =
          DateTime.tryParse('${row['completed_at'] ?? ''}') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final current = latest[id];
      if (current == null || completedAt.isAfter(current.completedAt)) {
        latest[id] = _LatestGuestAttempt(
          completedAt: completedAt,
          score: score,
        );
      }
    }

    return <int, HanziProgressSnapshot>{
      for (final id in wanted)
        if (practiceCount.containsKey(id) || bestScore.containsKey(id))
          id: HanziProgressSnapshot(
            practiceCount: practiceCount[id] ?? 0,
            bestScore: bestScore[id] ?? 0,
            lastScore: latest[id]?.score ?? 0,
          ),
    };
  }
}

class _LatestGuestAttempt {
  const _LatestGuestAttempt({
    required this.completedAt,
    required this.score,
  });

  final DateTime completedAt;
  final double score;
}
