import 'package:supabase_flutter/supabase_flutter.dart';
import 'learning_progress_repository.dart';

abstract interface class LearningHistoryRepository {
  Future<int> fetchTodayXp();
  Future<List<Map<String, dynamic>>> fetch7DayXpActivity();
  Future<List<Map<String, dynamic>>> fetchRecentTimeline({int limit = 10});
  Future<List<Map<String, dynamic>>> fetchFullXpLedger({
    int limit = 50,
    String? filterType,
  });
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({
    int limit = 50,
    String? activityType,
  });
}

class SupabaseLearningHistoryRepository implements LearningHistoryRepository {
  SupabaseLearningHistoryRepository({
    SupabaseClient? client,
    LearningProgressRepository? progressRepository,
  })  : _client = client,
        _progressRepo = progressRepository ??
            SupabaseLearningProgressRepository(client: client);

  final SupabaseClient? _client;
  final LearningProgressRepository _progressRepo;

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => _activeClient?.auth.currentUser?.id;

  @override
  Future<int> fetchTodayXp() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toUtc();

    final client = _activeClient;
    final userId = _userId;
    if (client != null && userId != null) {
      try {
        final rows = await client
            .from('learning_xp_events')
            .select('xp_amount')
            .eq('user_id', userId)
            .gte('created_at', startOfToday.toIso8601String());

        int sum = 0;
        for (final row in rows) {
          sum += (row['xp_amount'] as num?)?.toInt() ?? 0;
        }
        return sum;
      } catch (_) {}
    }

    // Local fallback
    try {
      final events = await _progressRepo.fetchXpHistory(limit: 100);
      int sum = 0;
      for (final event in events) {
        final rawDate = event['created_at'];
        if (rawDate != null) {
          final date = DateTime.tryParse('$rawDate');
          if (date != null && date.isAfter(startOfToday)) {
            sum += (event['xp_amount'] as num?)?.toInt() ?? 0;
          }
        }
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetch7DayXpActivity() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      days.add(today.subtract(Duration(days: i)));
    }

    final events = await fetchFullXpLedger(limit: 200);

    final dayXpMap = <String, int>{};
    for (final day in days) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      dayXpMap[key] = 0;
    }

    for (final event in events) {
      final rawDate = event['created_at'];
      if (rawDate == null) continue;
      final date = DateTime.tryParse('$rawDate')?.toLocal();
      if (date == null) continue;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (dayXpMap.containsKey(key)) {
        dayXpMap[key] =
            (dayXpMap[key] ?? 0) + ((event['xp_amount'] as num?)?.toInt() ?? 0);
      }
    }

    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return days.map((d) {
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final isToday =
          d.year == now.year && d.month == now.month && d.day == now.day;
      final weekdayIndex = (d.weekday - 1).clamp(0, 6);
      return <String, dynamic>{
        'date': d,
        'dayLabel': dayNames[weekdayIndex],
        'day_label': dayNames[weekdayIndex],
        'xp': dayXpMap[key] ?? 0,
        'isToday': isToday,
        'is_today': isToday,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecentTimeline(
      {int limit = 10}) async {
    final attempts = await _progressRepo.fetchAttemptHistory(limit: limit * 2);
    final results = <Map<String, dynamic>>[];

    for (final attempt in attempts) {
      final activityType = '${attempt['activity_type'] ?? ''}';
      final score = (attempt['score'] as num?)?.toInt() ?? 0;
      final stars = (attempt['stars'] as num?)?.toInt() ?? 0;
      final xp = (attempt['xp_earned'] as num?)?.toInt() ?? 0;
      final completedAt = attempt['completed_at'] ?? attempt['created_at'];

      String title;
      String icon;
      switch (activityType) {
        case 'boss':
          title = 'Khiêu chiến Boss';
          icon = '🐲';
          break;
        case 'vocabulary':
          title = 'Khám phá Từ vựng';
          icon = '📖';
          break;
        case 'listening':
          title = 'Luyện nghe & Thanh điệu';
          icon = '🎧';
          break;
        case 'speaking':
          title = 'Luyện phát âm';
          icon = '🎙️';
          break;
        case 'hanzi':
          title = 'Viết Chữ Hán';
          icon = '✍️';
          break;
        case 'sentence':
        case 'dialogue':
          title = 'Mẫu câu & Đối thoại';
          icon = '💬';
          break;
        case 'quiz':
          title = 'Phản xạ trả lời nhanh';
          icon = '⚡';
          break;
        default:
          title = 'Bài học Trung văn';
          icon = '⭐';
      }

      results.add(<String, dynamic>{
        'title': title,
        'activityType': activityType,
        'activity_type': activityType,
        'icon': icon,
        'score': score,
        'stars': stars,
        'xpEarned': xp,
        'xp_amount': xp,
        'status': attempt['status'] ?? 'passed',
        'timestamp': completedAt,
      });

      if (results.length >= limit) break;
    }

    if (results.isEmpty) {
      final xpEvents = await fetchFullXpLedger(limit: limit);
      for (final event in xpEvents) {
        final activityType = '${event['activity_type'] ?? ''}';
        final xp = (event['xp_amount'] as num?)?.toInt() ?? 0;
        final completedAt = event['created_at'];

        String title;
        String icon;
        switch (activityType) {
          case 'boss':
            title = 'Khiêu chiến Boss';
            icon = '🐲';
            break;
          case 'vocabulary':
            title = 'Từ vựng cốt lõi';
            icon = '📖';
            break;
          case 'listening':
            title = 'Luyện nghe & Thanh điệu';
            icon = '🎧';
            break;
          case 'speaking':
            title = 'Luyện phát âm';
            icon = '🎙️';
            break;
          case 'hanzi':
            title = 'Viết Chữ Hán';
            icon = '✍️';
            break;
          case 'sentence':
          case 'dialogue':
            title = 'Mẫu câu & Đối thoại';
            icon = '💬';
            break;
          case 'quiz':
            title = 'Phản xạ trả lời nhanh';
            icon = '⚡';
            break;
          default:
            title = 'Hoạt động học tập';
            icon = '⭐';
        }

        results.add(<String, dynamic>{
          'title': title,
          'activityType': activityType,
          'activity_type': activityType,
          'icon': icon,
          'score': 100,
          'stars': 3,
          'xpEarned': xp,
          'xp_amount': xp,
          'status': 'passed',
          'timestamp': completedAt,
        });

        if (results.length >= limit) break;
      }
    }

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFullXpLedger({
    int limit = 50,
    String? filterType,
  }) async {
    final allEvents = await _progressRepo.fetchXpHistory(limit: limit * 2);
    if (filterType == null || filterType.isEmpty || filterType == 'all') {
      return allEvents.take(limit).toList();
    }
    return allEvents
        .where((e) =>
            '${e['activity_type']}'.toLowerCase() == filterType.toLowerCase())
        .take(limit)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory({
    int limit = 50,
    String? activityType,
  }) async {
    final allAttempts =
        await _progressRepo.fetchAttemptHistory(limit: limit * 2);
    if (activityType == null || activityType.isEmpty || activityType == 'all') {
      return allAttempts.take(limit).toList();
    }
    return allAttempts
        .where((a) =>
            '${a['activity_type']}'.toLowerCase() == activityType.toLowerCase())
        .take(limit)
        .toList();
  }
}
