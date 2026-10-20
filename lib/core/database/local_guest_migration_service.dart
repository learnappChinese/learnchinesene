import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_database.dart';

/// Dịch vụ di chuyển dữ liệu người học cũ từ SharedPreferences sang SQLite (AppDatabase).
///
/// Tuân thủ nguyên tắc:
/// 1. Idempotent: chạy nhiều lần không tạo bản ghi trùng lặp, không nhân đôi XP.
/// 2. Bất biến dữ liệu gốc: TUYỆT ĐỐI KHÔNG xóa hoặc sửa các key SharedPreferences cũ.
/// 3. Dung thứ lỗi: dữ liệu hỏng/không đối chiếu được sẽ lưu vào `unresolved_legacy_progress`
///    thay vì throw exception làm treo app.
/// 4. Bảo toàn XP và Streak: đối chiếu tổng XP với `guest_learning_stats_v2` và bù đắp nếu cần.
class LocalGuestMigrationService {
  LocalGuestMigrationService({
    AppDatabase? database,
    SharedPreferences? prefs,
    DateTime Function()? nowProvider,
  })  : _db = database ?? AppDatabase.instance,
        _prefs = prefs,
        _now = nowProvider ?? DateTime.now;

  static final LocalGuestMigrationService instance =
      LocalGuestMigrationService._();

  LocalGuestMigrationService._()
      : _db = AppDatabase.instance,
        _prefs = null,
        _now = DateTime.now;

  final AppDatabase _db;
  final SharedPreferences? _prefs;
  final DateTime Function() _now;

  static const String migrationSourceKey = 'shared_preferences_guest_v1';

  // SharedPreferences keys
  static const String _completedStagesKey =
      'guest_learning_completed_stages_v1';
  static const String _completedBossesKey =
      'guest_learning_completed_bosses_v1';
  static const String _attemptsKey = 'guest_learning_attempts_v2';
  static const String _xpEventsKey = 'guest_learning_xp_events_v2';
  static const String _statsKey = 'guest_learning_stats_v2';

  Future<SharedPreferences> get _getPrefs async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Thực hiện migration từ SharedPreferences sang SQLite nếu chưa thực hiện trước đó.
  /// Trả về số lượng bản ghi đã được import thành công.
  Future<MigrationResult> migrateGuestDataToSqlite({bool force = false}) async {
    if (!_db.isOpen) {
      debugPrint('[LocalGuestMigration] AppDatabase chưa mở. Bỏ qua.');
      return const MigrationResult(success: false, message: 'Database not open');
    }

    final db = _db.database;

    // 1. Kiểm tra xem migration này đã chạy thành công chưa
    if (!force) {
      final existingLog = await db.query(
        'local_migration_log',
        where: 'source_key = ?',
        whereArgs: [migrationSourceKey],
        limit: 1,
      );
      if (existingLog.isNotEmpty) {
        return MigrationResult(
          success: true,
          alreadyMigrated: true,
          rowsImported: (existingLog.first['rows_imported'] as num?)?.toInt() ?? 0,
          message: 'Already migrated previously',
        );
      }
    }

    final prefs = await _getPrefs;
    final profileId = _db.activeProfileId;
    final nowUtc = _now().toUtc().toIso8601String();
    final warnings = <String>[];
    int totalImported = 0;

    // Đọc các key nguồn từ SharedPreferences
    final stagesMap = _readMap(prefs, _completedStagesKey);
    final bossesMap = _readMap(prefs, _completedBossesKey);
    final rawAttempts = _readList(prefs, _attemptsKey);
    final rawXpEvents = _readList(prefs, _xpEventsKey);
    final statsMap = _readMap(prefs, _statsKey);

    final hasAnyGuestData = stagesMap.isNotEmpty ||
        bossesMap.isNotEmpty ||
        rawAttempts.isNotEmpty ||
        rawXpEvents.isNotEmpty ||
        statsMap.isNotEmpty;

    if (!hasAnyGuestData) {
      return const MigrationResult(
        success: true,
        rowsImported: 0,
        message: 'No guest data to migrate',
      );
    }

    // Chạy toàn bộ migration trong một transaction SQLite an toàn
    await db.transaction((txn) async {
      // --- A. Chuyển đổi completed stages ---
      for (final entry in stagesMap.entries) {
        try {
          final val = entry.value;
          if (val is! Map) continue;
          final map = Map<String, dynamic>.from(val);
          final levelId = '${map['level_id'] ?? entry.key}'.trim();
          if (levelId.isEmpty) continue;

          final score = (map['score'] as num?)?.toDouble() ?? 0.0;
          final stars = (map['stars'] as num?)?.toInt().clamp(0, 3) ?? 0;
          final completedAt = map['completed_at'] ?? nowUtc;

          await txn.rawInsert('''
            INSERT INTO local_stage_progress (
              local_id, level_id, status, best_score, best_stars, first_completed_at_utc
            ) VALUES (?, ?, 'completed', ?, ?, ?)
            ON CONFLICT(local_id, level_id) DO UPDATE SET
              status = 'completed',
              best_score = MAX(best_score, excluded.best_score),
              best_stars = MAX(best_stars, excluded.best_stars);
          ''', [profileId, levelId, score, stars, completedAt]);
          totalImported++;
        } catch (e) {
          warnings.add('Error migrating stage ${entry.key}: $e');
          await _logUnresolved(txn, entry.key, entry.value, 'Failed stage parse: $e');
        }
      }

      // --- B. Chuyển đổi completed bosses ---
      for (final entry in bossesMap.entries) {
        try {
          final val = entry.value;
          if (val is! Map) continue;
          final map = Map<String, dynamic>.from(val);
          final unitId = '${map['unit_id'] ?? entry.key}'.trim();
          if (unitId.isEmpty) continue;

          final score = (map['score'] as num?)?.toDouble() ?? 0.0;
          final stars = (map['stars'] as num?)?.toInt().clamp(0, 3) ?? 0;
          final completedAt = map['completed_at'] ?? nowUtc;
          final bossLevelId = 'boss:$unitId';

          await txn.rawInsert('''
            INSERT INTO local_stage_progress (
              local_id, level_id, status, best_score, best_stars, first_completed_at_utc
            ) VALUES (?, ?, 'completed', ?, ?, ?)
            ON CONFLICT(local_id, level_id) DO UPDATE SET
              status = 'completed',
              best_score = MAX(best_score, excluded.best_score),
              best_stars = MAX(best_stars, excluded.best_stars);
          ''', [profileId, bossLevelId, score, stars, completedAt]);
          totalImported++;
        } catch (e) {
          warnings.add('Error migrating boss ${entry.key}: $e');
          await _logUnresolved(txn, entry.key, entry.value, 'Failed boss parse: $e');
        }
      }

      // --- C. Chuyển đổi learning attempts ---
      final datesToRecord = <String>{};

      for (var i = 0; i < rawAttempts.length; i++) {
        final item = rawAttempts[i];
        try {
          final map = _normalizeItemMap(item);
          if (map == null) {
            await _logUnresolved(txn, 'attempt_$i', item, 'Non-map attempt');
            continue;
          }

          final attemptId = '${map['id'] ?? map['attempt_id'] ?? _generateUuid()}';
          final activityType = '${map['activity_type'] ?? 'lesson'}';
          final sourceNamespace = '${map['source_type'] ?? 'learning'}';
          final sourceId = '${map['source_id'] ?? ''}';
          final unitId = map['unit_id'] != null ? '${map['unit_id']}' : null;
          final levelId = map['level_id'] != null ? '${map['level_id']}' : null;
          final startedAt = '${map['started_at'] ?? map['completed_at'] ?? nowUtc}';
          final completedAt = map['completed_at'] != null ? '${map['completed_at']}' : null;
          final rawStatus = '${map['status'] ?? 'passed'}';
          final status = const {'started', 'passed', 'failed', 'abandoned'}.contains(rawStatus)
              ? rawStatus
              : 'passed';

          final score = (map['score'] as num?)?.toDouble() ?? 0.0;
          final accuracy = (map['accuracy'] as num?)?.toDouble().clamp(0.0, 1.0);
          final correctCount = (map['correct_count'] as num?)?.toInt() ?? 0;
          final wrongCount = (map['wrong_count'] as num?)?.toInt() ?? 0;
          final stars = (map['stars'] as num?)?.toInt().clamp(0, 3) ?? 0;
          final durationSeconds = (map['duration_seconds'] as num?)?.toInt() ?? 0;
          final metadataJson = jsonEncode(map['metadata'] ?? <String, dynamic>{});

          await txn.rawInsert('''
            INSERT OR IGNORE INTO local_activity_attempts (
              attempt_id, local_id, activity_type, source_namespace, source_id,
              unit_id, level_id, started_at_utc, completed_at_utc, status,
              score, accuracy, correct_count, wrong_count, stars, duration_seconds,
              metadata_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
          ''', [
            attemptId,
            profileId,
            activityType,
            sourceNamespace,
            sourceId,
            unitId,
            levelId,
            startedAt,
            completedAt,
            status,
            score,
            accuracy,
            correctCount,
            wrongCount,
            stars,
            durationSeconds,
            metadataJson,
          ]);

          if (completedAt != null && status == 'passed') {
            final dateStr = _extractDate(completedAt);
            if (dateStr != null) datesToRecord.add(dateStr);
          }
          totalImported++;
        } catch (e) {
          warnings.add('Error migrating attempt #$i: $e');
          await _logUnresolved(txn, 'attempt_$i', item, 'Attempt error: $e');
        }
      }

      // --- D. Chuyển đổi XP Events (Sổ cái XP bất biến) ---
      int totalXpMigrated = 0;

      for (var i = 0; i < rawXpEvents.length; i++) {
        final item = rawXpEvents[i];
        try {
          final map = _normalizeItemMap(item);
          if (map == null) {
            await _logUnresolved(txn, 'xp_event_$i', item, 'Non-map xp event');
            continue;
          }

          final eventId = _generateUuid();
          final eventKey = '${map['event_key'] ?? 'legacy_xp_${profileId}_$i'}';
          final sourceNamespace = '${map['source_type'] ?? 'learning'}';
          final sourceId = '${map['source_id'] ?? ''}';
          final baseXp = (map['base_xp'] as num?)?.toInt() ?? 0;
          final bonusXp = (map['bonus_xp'] as num?)?.toInt() ?? 0;
          final xpAmount = (map['xp_amount'] as num?)?.toInt() ?? (baseXp + bonusXp);
          final earnedAt = '${map['created_at'] ?? nowUtc}';

          await txn.rawInsert('''
            INSERT OR IGNORE INTO local_xp_events (
              event_id, event_key, local_id, source_namespace, source_id,
              base_xp, bonus_xp, xp_amount, earned_at_utc, reward_rule_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1);
          ''', [
            eventId,
            eventKey,
            profileId,
            sourceNamespace,
            sourceId,
            baseXp,
            bonusXp,
            xpAmount,
            earnedAt,
          ]);

          totalXpMigrated += xpAmount;
          final dateStr = _extractDate(earnedAt);
          if (dateStr != null) datesToRecord.add(dateStr);
          totalImported++;
        } catch (e) {
          warnings.add('Error migrating xp_event #$i: $e');
          await _logUnresolved(txn, 'xp_event_$i', item, 'XP event error: $e');
        }
      }

      // --- E. Bù đắp XP nếu guest_learning_stats_v2 có total_exp lớn hơn sổ cái ---
      final legacyTotalExp = (statsMap['total_exp'] as num?)?.toInt() ?? 0;
      if (legacyTotalExp > totalXpMigrated) {
        final deltaXp = legacyTotalExp - totalXpMigrated;
        final deltaKey = 'legacy_guest_initial_xp_migration';
        await txn.rawInsert('''
          INSERT OR IGNORE INTO local_xp_events (
            event_id, event_key, local_id, source_namespace, source_id,
            base_xp, bonus_xp, xp_amount, earned_at_utc, reward_rule_version
          ) VALUES (?, ?, ?, 'legacy_migration', 'guest_learning_stats_v2', ?, 0, ?, ?, 1);
        ''', [
          _generateUuid(),
          deltaKey,
          profileId,
          deltaXp,
          deltaXp,
          nowUtc,
        ]);
        totalImported++;
      }

      // --- F. Ghi nhận chuỗi ngày học (local_study_days) ---
      final lastStudyDate = statsMap['last_study_date'] as String?;
      if (lastStudyDate != null) {
        final d = _extractDate(lastStudyDate);
        if (d != null) datesToRecord.add(d);
      }

      for (final dateStr in datesToRecord) {
        await txn.rawInsert('''
          INSERT OR IGNORE INTO local_study_days (local_id, local_date)
          VALUES (?, ?);
        ''', [profileId, dateStr]);
      }

      // --- G. Ghi nhật ký di chuyển (local_migration_log) ---
      await txn.rawInsert('''
        INSERT INTO local_migration_log (
          migration_id, source_key, source_checksum, rows_imported, warnings_json, completed_at_utc
        ) VALUES (?, ?, ?, ?, ?, ?);
      ''', [
        _generateUuid(),
        migrationSourceKey,
        'stages:${stagesMap.length};bosses:${bossesMap.length};attempts:${rawAttempts.length};xp:${rawXpEvents.length}',
        totalImported,
        jsonEncode(warnings),
        nowUtc,
      ]);
    });

    debugPrint(
      '[LocalGuestMigration] Hoàn tất di chuyển: $totalImported bản ghi. Cảnh báo: ${warnings.length}',
    );

    return MigrationResult(
      success: true,
      rowsImported: totalImported,
      warnings: warnings,
      message: 'Migration completed successfully',
    );
  }

  Future<void> _logUnresolved(
    Transaction txn,
    String key,
    dynamic raw,
    String reason,
  ) async {
    try {
      await txn.rawInsert('''
        INSERT OR IGNORE INTO unresolved_legacy_progress (
          id, source_key, source_record_json, unresolved_reason, recorded_at_utc
        ) VALUES (?, ?, ?, ?, ?);
      ''', [
        _generateUuid(),
        key,
        jsonEncode(raw),
        reason,
        _now().toUtc().toIso8601String(),
      ]);
    } catch (_) {}
  }

  Map<String, dynamic>? _normalizeItemMap(dynamic item) {
    if (item is Map) return Map<String, dynamic>.from(item);
    if (item is String) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  String? _extractDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      if (isoString.length >= 10 && isoString[4] == '-' && isoString[7] == '-') {
        return isoString.substring(0, 10);
      }
      return null;
    }
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

  List<dynamic> _readList(SharedPreferences prefs, String key) {
    final strList = prefs.getStringList(key);
    if (strList != null) return strList;

    final raw = prefs.getString(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return const [];
  }

  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // v4
    values[8] = (values[8] & 0x3f) | 0x80; // variant
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

class MigrationResult {
  const MigrationResult({
    required this.success,
    this.alreadyMigrated = false,
    this.rowsImported = 0,
    this.warnings = const [],
    this.message = '',
  });

  final bool success;
  final bool alreadyMigrated;
  final int rowsImported;
  final List<String> warnings;
  final String message;
}
