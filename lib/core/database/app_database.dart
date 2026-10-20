import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_guest_migration_service.dart';
import '../learning/service/spaced_repetition_service.dart';
import '../../features/hanzi_writing/services/hanzi_stroke_cache.dart';

/// Database trung tâm cục bộ (Local-First SQLite Database).
///
/// Quản lý dữ liệu người học và giáo trình HSK offline.
/// Hỗ trợ cả mobile (Android/iOS) và desktop/test qua FFI.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _dbVersion = 1;
  static const String _dbFileName = 'pandarin.db';

  Database? _db;
  String? _cachedLocalId;

  Database get database {
    final db = _db;
    if (db == null || !db.isOpen) {
      throw StateError(
        'AppDatabase chưa được khởi tạo. Hãy gọi AppDatabase.instance.init() trước.',
      );
    }
    return db;
  }

  bool get isOpen => _db != null && _db!.isOpen;

  String get activeProfileId {
    final id = _cachedLocalId;
    if (id == null) {
      throw StateError('Chưa có hồ sơ người học cục bộ (local_profile).');
    }
    return id;
  }

  /// Khởi tạo database SQLite.
  /// Có thể truyền `customPath` (ví dụ `inMemoryDatabasePath`) khi chạy Unit Test.
  Future<Database> init({String? customPath}) async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = customPath ?? await _resolveDatabasePath();

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _ensureFlashcardTables(_db!);
    await ensureLocalProfile();
    try {
      await LocalGuestMigrationService.instance.migrateGuestDataToSqlite();
    } catch (e) {
      debugPrint('[AppDatabase] Guest migration skipped or failed: $e');
    }
    return _db!;
  }

  Future<String> _resolveDatabasePath() async {
    final defaultPath = await getDatabasesPath();
    final dir = Directory(defaultPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.join(defaultPath, _dbFileName);
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ==========================================
    // 1. CÁC BẢNG DỮ LIỆU NGƯỜI HỌC (USER TABLES)
    // ==========================================

    // Hồ sơ người học cục bộ
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_profiles (
        local_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        timezone_id TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh'
      );
    ''');

    // Nhật ký lượt học chi tiết
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_activity_attempts (
        attempt_id TEXT PRIMARY KEY,
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        activity_type TEXT NOT NULL,
        source_namespace TEXT NOT NULL,
        source_id TEXT NOT NULL,
        unit_namespace TEXT,
        unit_id TEXT,
        level_id TEXT,
        started_at_utc TEXT NOT NULL,
        completed_at_utc TEXT,
        status TEXT NOT NULL CHECK(status IN ('started','passed','failed','abandoned')),
        score REAL NOT NULL DEFAULT 0,
        accuracy REAL CHECK(accuracy IS NULL OR (accuracy BETWEEN 0 AND 1)),
        correct_count INTEGER NOT NULL DEFAULT 0 CHECK(correct_count >= 0),
        wrong_count INTEGER NOT NULL DEFAULT 0 CHECK(wrong_count >= 0),
        stars INTEGER NOT NULL DEFAULT 0 CHECK(stars BETWEEN 0 AND 3),
        duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK(duration_seconds >= 0),
        metadata_json TEXT NOT NULL DEFAULT '{}'
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_attempts_by_user_time
        ON local_activity_attempts(local_id, started_at_utc DESC);
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_attempts_by_source
        ON local_activity_attempts(source_namespace, source_id);
    ''');

    // Tiến độ ải học
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_stage_progress (
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        level_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'locked' CHECK(status IN ('locked','available','completed')),
        best_score REAL NOT NULL DEFAULT 0,
        best_stars INTEGER NOT NULL DEFAULT 0 CHECK(best_stars BETWEEN 0 AND 3),
        first_completed_at_utc TEXT,
        last_attempt_id TEXT,
        PRIMARY KEY(local_id, level_id)
      );
    ''');

    // Trạng thái Spaced Repetition (SRS Flashcards)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_word_srs (
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        word_id INTEGER NOT NULL,
        srs_stage INTEGER NOT NULL DEFAULT 0 CHECK(srs_stage >= 0),
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0 CHECK(interval_days >= 0),
        repetition_count INTEGER NOT NULL DEFAULT 0 CHECK(repetition_count >= 0),
        next_review_at_utc TEXT NOT NULL,
        last_reviewed_at_utc TEXT,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(local_id, word_id)
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_due_srs
        ON local_word_srs(local_id, next_review_at_utc);
    ''');

    // Tiến độ luyện viết chữ Hán
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_hanzi_progress (
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        character_id INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        best_accuracy REAL NOT NULL DEFAULT 0,
        last_practiced_at_utc TEXT,
        is_mastered INTEGER NOT NULL DEFAULT 0 CHECK(is_mastered IN (0,1)),
        PRIMARY KEY(local_id, character_id)
      );
    ''');

    // Sổ cái XP bất biến
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_xp_events (
        event_id TEXT PRIMARY KEY,
        event_key TEXT NOT NULL UNIQUE,
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        attempt_id TEXT REFERENCES local_activity_attempts(attempt_id),
        source_namespace TEXT NOT NULL,
        source_id TEXT NOT NULL,
        base_xp INTEGER NOT NULL DEFAULT 0 CHECK(base_xp >= 0),
        bonus_xp INTEGER NOT NULL DEFAULT 0 CHECK(bonus_xp >= 0),
        xp_amount INTEGER NOT NULL DEFAULT 0 CHECK(xp_amount >= 0),
        earned_at_utc TEXT NOT NULL,
        reward_rule_version INTEGER NOT NULL DEFAULT 1
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_xp_user_date
        ON local_xp_events(local_id, earned_at_utc DESC);
    ''');

    // Ngày học ghi nhận chuỗi Streak
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_study_days (
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        local_date TEXT NOT NULL,
        first_qualifying_attempt_id TEXT,
        PRIMARY KEY(local_id, local_date)
      );
    ''');

    // Phiên làm bài dở dang
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_active_sessions (
        session_key TEXT PRIMARY KEY,
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        attempt_id TEXT,
        source_namespace TEXT NOT NULL,
        source_id TEXT NOT NULL,
        state_json TEXT NOT NULL,
        session_schema_version INTEGER NOT NULL,
        updated_at_utc TEXT NOT NULL
      );
    ''');

    // Nhật ký di chuyển dữ liệu cũ
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_migration_log (
        migration_id TEXT PRIMARY KEY,
        source_key TEXT NOT NULL,
        source_checksum TEXT,
        rows_imported INTEGER NOT NULL DEFAULT 0,
        warnings_json TEXT NOT NULL DEFAULT '[]',
        completed_at_utc TEXT NOT NULL
      );
    ''');

    // Dữ liệu cũ chưa đối chiếu
    batch.execute('''
      CREATE TABLE IF NOT EXISTS unresolved_legacy_progress (
        id TEXT PRIMARY KEY,
        source_key TEXT NOT NULL,
        source_record_json TEXT NOT NULL,
        unresolved_reason TEXT NOT NULL,
        recorded_at_utc TEXT NOT NULL
      );
    ''');

    // Outbox đồng bộ trong tương lai
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_sync_outbox (
        event_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at_utc TEXT NOT NULL,
        local_revision INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      );
    ''');

    // ==========================================
    // 2. CÁC BẢNG NỘI DUNG GIÁO TRÌNH (CONTENT)
    // ==========================================

    batch.execute('''
      CREATE TABLE IF NOT EXISTS content_packs (
        pack_id TEXT PRIMARY KEY,
        version INTEGER NOT NULL,
        checksum TEXT,
        content_schema_version INTEGER NOT NULL DEFAULT 1,
        imported_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active'
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lexicon_hsk_levels (
        id INTEGER PRIMARY KEY,
        section_number INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lexicon_units (
        id INTEGER PRIMARY KEY,
        hsk_level_id INTEGER NOT NULL REFERENCES lexicon_hsk_levels(id),
        title TEXT NOT NULL,
        sort_order INTEGER,
        unit_number INTEGER,
        source_section_id INTEGER
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_units_by_hsk
        ON lexicon_units(hsk_level_id, unit_number);
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lexicon_words (
        id INTEGER PRIMARY KEY,
        word TEXT NOT NULL,
        pinyin TEXT,
        meaning_vi TEXT,
        meaning_en TEXT,
        tts_url TEXT,
        main_character_id INTEGER,
        hsk_level_id INTEGER,
        part_of_speech_id INTEGER,
        frequency_rank INTEGER,
        frequency_score REAL,
        notes TEXT
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_words_by_hsk
        ON lexicon_words(hsk_level_id);
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_words_word
        ON lexicon_words(word);
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lexicon_word_sources (
        id INTEGER PRIMARY KEY,
        word_id INTEGER,
        unit_id INTEGER,
        topic_id INTEGER,
        source_sheet TEXT,
        source_row INTEGER
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_word_sources_unit
        ON lexicon_word_sources(unit_id);
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_word_sources_word
        ON lexicon_word_sources(word_id);
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lexicon_characters (
        id INTEGER PRIMARY KEY,
        character TEXT NOT NULL UNIQUE,
        stroke_width INTEGER,
        stroke_height INTEGER,
        stroke_paths TEXT NOT NULL,
        stroke_count INTEGER,
        radical_id INTEGER,
        notes TEXT
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_character_char
        ON lexicon_characters(character);
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lexicon_examples (
        id INTEGER PRIMARY KEY,
        word_id INTEGER REFERENCES lexicon_words(id),
        chinese TEXT NOT NULL,
        pinyin TEXT,
        vietnamese TEXT NOT NULL
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_examples_word
        ON lexicon_examples(word_id);
    ''');

    await batch.commit(noResult: true);
    await _ensureFlashcardTables(db);
  }

  /// Đảm bảo các bảng dữ liệu Flashcard, FSRS Progress, Logs và Settings luôn sẵn sàng.
  Future<void> _ensureFlashcardTables(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_flashcard_progress (
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        card_id INTEGER NOT NULL,
        word_id INTEGER NOT NULL REFERENCES lexicon_words(id),
        direction TEXT NOT NULL DEFAULT 'zh_vi',
        state INTEGER NOT NULL DEFAULT 0,
        step INTEGER,
        stability REAL,
        difficulty REAL,
        due_at_utc TEXT NOT NULL,
        last_review_at_utc TEXT,
        reps INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        scheduled_days INTEGER NOT NULL DEFAULT 0,
        algorithm_version TEXT NOT NULL DEFAULT 'FSRS-v2',
        PRIMARY KEY(local_id, card_id)
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_fc_progress_due
        ON local_flashcard_progress(local_id, due_at_utc);
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_fc_progress_word
        ON local_flashcard_progress(local_id, word_id);
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_flashcard_review_logs (
        review_id TEXT PRIMARY KEY,
        local_id TEXT NOT NULL REFERENCES local_profiles(local_id),
        card_id INTEGER NOT NULL,
        word_id INTEGER NOT NULL REFERENCES lexicon_words(id),
        rating INTEGER NOT NULL,
        review_at_utc TEXT NOT NULL,
        review_duration_ms INTEGER,
        state_before INTEGER,
        state_after INTEGER,
        stability_after REAL,
        difficulty_after REAL,
        due_before_utc TEXT,
        due_after_utc TEXT,
        interval_days_after REAL,
        algorithm_version TEXT NOT NULL DEFAULT 'FSRS-v2'
      );
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_fc_review_logs_date
        ON local_flashcard_review_logs(local_id, review_at_utc);
    ''');
    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_fc_review_logs_card
        ON local_flashcard_review_logs(local_id, card_id);
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS local_flashcard_settings (
        local_id TEXT PRIMARY KEY REFERENCES local_profiles(local_id),
        desired_retention REAL NOT NULL DEFAULT 0.90,
        maximum_interval INTEGER NOT NULL DEFAULT 7,
        enable_fuzzing INTEGER NOT NULL DEFAULT 1,
        new_cards_per_day INTEGER NOT NULL DEFAULT 20,
        max_reviews_per_day INTEGER NOT NULL DEFAULT 100,
        card_direction TEXT NOT NULL DEFAULT 'zh_vi',
        auto_play_audio INTEGER NOT NULL DEFAULT 1,
        preset_name TEXT NOT NULL DEFAULT 'Cân bằng'
      );
    ''');
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Phiên bản v1 hiện tại, nâng cấp tương lai qua migration script
  }

  // ==========================================
  // QUẢN LÝ HỒ SƠ CỤC BỘ (LOCAL PROFILE)
  // ==========================================

  /// Đảm bảo người dùng có một Local Identity duy nhất.
  Future<String> ensureLocalProfile() async {
    if (_cachedLocalId != null) return _cachedLocalId!;

    final rows = await database.query(
      'local_profiles',
      columns: ['local_id'],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      _cachedLocalId = rows.first['local_id'] as String;
      return _cachedLocalId!;
    }

    final newId = _generateUuid();
    await database.insert('local_profiles', <String, dynamic>{
      'local_id': newId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'timezone_id': 'Asia/Ho_Chi_Minh',
    });

    _cachedLocalId = newId;
    return newId;
  }

  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ==========================================
  // NẠP GÓI GIÁO TRÌNH ĐÓNG GÓI SẴN (SEED PACK)
  // ==========================================

  /// Nạp gói giáo trình HSK 1-4 vào SQLite khi mở app lần đầu.
  Future<bool> ensureContentPackSeeded({String? jsonOverride}) async {
    final existingPack = await database.query(
      'content_packs',
      where: 'pack_id = ?',
      whereArgs: ['hsk_curriculum_pack_v1'],
      limit: 1,
    );

    if (existingPack.isNotEmpty) {
      return false; // Đã nạp trước đó
    }

    String jsonString;
    if (jsonOverride != null) {
      jsonString = jsonOverride;
    } else {
      try {
        jsonString = await rootBundle.loadString(
          'assets/data/hsk_curriculum_pack_v1.json',
        );
      } catch (e) {
        debugPrint('Chưa tìm thấy asset hsk_curriculum_pack_v1.json: $e');
        return false;
      }
    }

    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) return false;

    await database.transaction((txn) async {
      final batch = txn.batch();

      // 1. Levels
      final levels = _extractList(decoded['hsk_levels']);
      for (final lvl in levels) {
        if (lvl is Map) {
          batch.insert(
            'lexicon_hsk_levels',
            Map<String, dynamic>.from(lvl),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 2. Units
      final units = _extractList(decoded['units']);
      for (final u in units) {
        if (u is Map) {
          batch.insert(
            'lexicon_units',
            Map<String, dynamic>.from(u),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 3. Words
      final words = _extractList(decoded['words']);
      for (final w in words) {
        if (w is Map) {
          batch.insert(
            'lexicon_words',
            Map<String, dynamic>.from(w),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 4. Word sources
      final sources = _extractList(decoded['word_sources']);
      for (final s in sources) {
        if (s is Map) {
          batch.insert(
            'lexicon_word_sources',
            Map<String, dynamic>.from(s),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 5. Characters
      final chars = _extractList(decoded['characters']);
      for (final c in chars) {
        if (c is Map) {
          batch.insert(
            'lexicon_characters',
            Map<String, dynamic>.from(c),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // 6. Ghi nhận Pack
      batch.insert('content_packs', <String, dynamic>{
        'pack_id': decoded['pack_id'] ?? 'hsk_curriculum_pack_v1',
        'version': decoded['version'] ?? 1,
        'content_schema_version': decoded['content_schema_version'] ?? 1,
        'imported_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'active',
      });

      await batch.commit(noResult: true);
    });

    return true;
  }

  List<dynamic> _extractList(dynamic input) {
    if (input is List) return input;
    if (input is Map && input['value'] is List) return input['value'] as List;
    return const [];
  }

  // ==========================================
  // TRUY VẤN NỘI DUNG GIÁO TRÌNH (READ-ONLY)
  // ==========================================

  Future<List<Map<String, dynamic>>> getHskLevels() async {
    return database.query(
      'lexicon_hsk_levels',
      orderBy: 'sort_order ASC, id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnitsByHskLevel(int hskLevelId) async {
    return database.query(
      'lexicon_units',
      where: 'hsk_level_id = ?',
      whereArgs: [hskLevelId],
      orderBy: 'sort_order ASC, unit_number ASC, id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getWordsByUnit(int unitId) async {
    return database.rawQuery('''
      SELECT w.*, s.topic_id
      FROM lexicon_words w
      INNER JOIN lexicon_word_sources s ON w.id = s.word_id
      WHERE s.unit_id = ?
      ORDER BY w.id ASC
    ''', [unitId]);
  }

  /// Lấy toàn bộ từ vựng thuộc cấp độ HSK trong 1 câu truy vấn nhanh.
  Future<List<Map<String, dynamic>>> getWordsByHskLevel(
    int hskLevelId, {
    int? limit,
  }) async {
    return database.rawQuery('''
      SELECT DISTINCT w.*, s.topic_id
      FROM lexicon_words w
      INNER JOIN lexicon_word_sources s ON w.id = s.word_id
      INNER JOIN lexicon_units u ON s.unit_id = u.id
      WHERE u.hsk_level_id = ?
      ORDER BY w.id ASC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''', [hskLevelId]);
  }

  /// Lấy danh sách từ vựng đến hạn ôn tập (Due) hoặc đã từng trả lời sai.
  Future<List<Map<String, dynamic>>> getDueSrsWords({int limit = 30}) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    return database.rawQuery('''
      SELECT w.*, srs.srs_stage, srs.ease_factor, srs.interval_days, 
             srs.repetition_count, srs.next_review_at_utc, srs.wrong_count, srs.correct_count
      FROM local_word_srs srs
      INNER JOIN lexicon_words w ON srs.word_id = w.id
      WHERE srs.local_id = ?
        AND (srs.wrong_count > 0 OR srs.next_review_at_utc <= ?)
      ORDER BY srs.next_review_at_utc ASC
      LIMIT ?
    ''', [activeProfileId, nowUtc, limit]);
  }

  /// Lấy trạng thái SRS hiện tại của một từ vựng.
  Future<Map<String, dynamic>?> getWordSrsState(int wordId) async {
    final rows = await database.query(
      'local_word_srs',
      where: 'local_id = ? AND word_id = ?',
      whereArgs: [activeProfileId, wordId],
      limit: 1,
    );
    return rows.firstOrNull;
  }

  /// Đánh giá từ vựng theo thuật toán SM-2 và lưu bền vững vào local_word_srs.
  Future<SrsCardState> recordWordSrsRating({
    required int wordId,
    required SrsRating rating,
    SpacedRepetitionService srsService = const SpacedRepetitionService(),
  }) async {
    final profileId = activeProfileId;
    final existingRow = await getWordSrsState(wordId);
    final currentState = existingRow != null
        ? SrsCardState.fromMap(existingRow)
        : SrsCardState.initial();

    final nextState = srsService.calculateNextState(
      current: currentState,
      rating: rating,
    );

    final map = nextState.toMap(localId: profileId, wordId: wordId);

    if (existingRow == null) {
      await database.insert('local_word_srs', map);
    } else {
      await database.update(
        'local_word_srs',
        map,
        where: 'local_id = ? AND word_id = ?',
        whereArgs: [profileId, wordId],
      );
    }

    return nextState;
  }

  /// Lấy 1 chữ Hán nhanh kèm thông tin từ vựng và tiến độ luyện viết cục bộ.
  Future<Map<String, dynamic>?> getCharacterById(int characterId) async {
    final rows = await database.rawQuery('''
      SELECT c.*, w.pinyin, w.meaning_vi, w.hsk_level_id,
             COALESCE(p.attempts, 0) as practice_count,
             COALESCE(p.best_accuracy, 0.0) as best_score,
             COALESCE(p.is_mastered, 0) as is_mastered
      FROM lexicon_characters c
      LEFT JOIN lexicon_words w ON w.word LIKE '%' || c.character || '%'
      LEFT JOIN local_hanzi_progress p ON p.character_id = c.id AND p.local_id = ?
      WHERE c.id = ?
      LIMIT 1
    ''', [activeProfileId, characterId]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Lấy danh sách chữ Hán theo bài học (Unit) kèm pinyin, nghĩa và tiến độ viết.
  Future<List<Map<String, dynamic>>> getCharactersByUnit(int unitId) async {
    return database.rawQuery('''
      SELECT DISTINCT c.*, w.pinyin, w.meaning_vi, w.hsk_level_id,
             COALESCE(p.attempts, 0) as practice_count,
             COALESCE(p.best_accuracy, 0.0) as best_score,
             COALESCE(p.is_mastered, 0) as is_mastered
      FROM lexicon_characters c
      INNER JOIN lexicon_words w ON w.word LIKE '%' || c.character || '%'
      INNER JOIN lexicon_word_sources s ON w.id = s.word_id
      LEFT JOIN local_hanzi_progress p ON p.character_id = c.id AND p.local_id = ?
      WHERE s.unit_id = ?
      ORDER BY c.id ASC
    ''', [activeProfileId, unitId]);
  }

  /// Lấy danh sách chữ Hán theo cấp độ HSK và/hoặc từ khóa tìm kiếm (kèm tiến độ).
  Future<List<Map<String, dynamic>>> getCharactersByHskLevel({
    int? hskLevel,
    int limit = 1000,
    String? keyword,
  }) async {
    final hasKeyword = keyword != null && keyword.trim().isNotEmpty;
    final kwPattern = hasKeyword ? '%${keyword.trim().toLowerCase()}%' : null;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[activeProfileId];

    if (hskLevel != null) {
      whereClauses.add('w.hsk_level_id = ?');
      whereArgs.add(hskLevel);
    }
    if (hasKeyword) {
      whereClauses.add(
        '(LOWER(c.character) LIKE ? OR LOWER(w.pinyin) LIKE ? OR LOWER(w.meaning_vi) LIKE ?)',
      );
      whereArgs.addAll([kwPattern, kwPattern, kwPattern]);
    }

    final whereStr = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    whereArgs.add(limit);

    return database.rawQuery('''
      SELECT DISTINCT c.*, w.pinyin, w.meaning_vi, w.hsk_level_id,
             COALESCE(p.attempts, 0) as practice_count,
             COALESCE(p.best_accuracy, 0.0) as best_score,
             COALESCE(p.is_mastered, 0) as is_mastered
      FROM lexicon_characters c
      LEFT JOIN lexicon_words w ON w.word LIKE '%' || c.character || '%'
      LEFT JOIN local_hanzi_progress p ON p.character_id = c.id AND p.local_id = ?
      $whereStr
      ORDER BY c.id ASC
      LIMIT ?
    ''', whereArgs);
  }

  /// Ghi nhận kết quả một lần luyện viết chữ Hán vào local_hanzi_progress.
  Future<void> recordHanziPractice({
    required int characterId,
    required double accuracy,
    required int attempts,
    bool? isMastered,
  }) async {
    final db = database;
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final mastered = (isMastered == true || accuracy >= 90.0) ? 1 : 0;
    await db.rawInsert('''
      INSERT INTO local_hanzi_progress (
        local_id, character_id, attempts, best_accuracy, last_practiced_at_utc, is_mastered
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(local_id, character_id) DO UPDATE SET
        attempts = attempts + excluded.attempts,
        best_accuracy = MAX(best_accuracy, excluded.best_accuracy),
        last_practiced_at_utc = excluded.last_practiced_at_utc,
        is_mastered = MAX(is_mastered, excluded.is_mastered);
    ''', [
      activeProfileId,
      characterId,
      attempts,
      accuracy,
      nowUtc,
      mastered,
    ]);
    HanziStrokeCache.instance.invalidateCharacter(characterId);
  }

  /// Lấy tiến độ luyện viết của một chữ Hán.
  Future<Map<String, dynamic>?> getHanziProgress(int characterId) async {
    final rows = await database.query(
      'local_hanzi_progress',
      where: 'local_id = ? AND character_id = ?',
      whereArgs: [activeProfileId, characterId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllCharacters({int limit = 100}) async {
    return database.query(
      'lexicon_characters',
      orderBy: 'id ASC',
      limit: limit,
    );
  }

  /// Lấy tổng số chữ Hán người học đã thuộc / hoàn thành.
  Future<int> getTotalMasteredHanziCount() async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) AS total
      FROM local_hanzi_progress
      WHERE local_id = ? AND (is_mastered = 1 OR best_accuracy >= 80.0)
    ''', [activeProfileId]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Lấy toàn bộ cấu trúc phân cấp HSK -> Section -> Chữ Hán phục vụ lộ trình học viết.
  Future<List<Map<String, dynamic>>> getHanziLearningPathRaw() async {
    final levels = await getHskLevels();
    final List<Map<String, dynamic>> result = [];

    for (final lvl in levels) {
      final lvlId = (lvl['id'] as num?)?.toInt() ?? 1;
      final units = await getUnitsByHskLevel(lvlId);
      final allLvlChars = await getCharactersByHskLevel(hskLevel: lvlId);

      final List<Map<String, dynamic>> sectionList = [];
      final usedCharIds = <int>{};

      for (int uIdx = 0; uIdx < units.length; uIdx++) {
        final u = units[uIdx];
        final uId = (u['id'] as num?)?.toInt() ?? (uIdx + 1);
        final rawChars = await getCharactersByUnit(uId);

        final charsForThisUnit = <Map<String, dynamic>>[];
        for (final c in rawChars) {
          final cId = (c['id'] as num?)?.toInt();
          if (cId != null && usedCharIds.add(cId)) {
            charsForThisUnit.add(c);
          }
        }

        sectionList.add({
          'unit': u,
          'characters': charsForThisUnit,
        });
      }

      // Phân bổ các chữ còn lại của HSK level này vào các Section
      final unusedChars = allLvlChars.where((c) {
        final cId = (c['id'] as num?)?.toInt();
        return cId != null && !usedCharIds.contains(cId);
      }).toList();

      if (unusedChars.isNotEmpty && sectionList.isNotEmpty) {
        int secIdx = 0;
        for (final c in unusedChars) {
          final cId = (c['id'] as num?)?.toInt();
          if (cId != null && usedCharIds.add(cId)) {
            (sectionList[secIdx % sectionList.length]['characters'] as List)
                .add(c);
            secIdx++;
          }
        }
      }

      result.add({
        'level': lvl,
        'sections': sectionList,
      });
    }

    return result;
  }

  // ==========================================
  // CÁC THỦ TỤC DỮ LIỆU TIẾN ĐỘ & SỔ CÁI
  // ==========================================

  /// Tính tổng XP hiện tại từ sổ cái bất biến.
  Future<int> getTotalXp() async {
    final result = await database.rawQuery('''
      SELECT COALESCE(SUM(xp_amount), 0) AS total_xp
      FROM local_xp_events
      WHERE local_id = ?
    ''', [activeProfileId]);
    return (result.first['total_xp'] as num?)?.toInt() ?? 0;
  }

  /// Tính số ngày streak liên tục gần nhất.
  Future<int> getCurrentStreak() async {
    final rows = await database.query(
      'local_study_days',
      where: 'local_id = ?',
      whereArgs: [activeProfileId],
      orderBy: 'local_date DESC',
    );

    if (rows.isEmpty) return 0;

    final dates = rows.map((r) => r['local_date'] as String).toList();
    final today = _formatDateLocal(DateTime.now());
    final yesterday = _formatDateLocal(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (!dates.contains(today) && !dates.contains(yesterday)) {
      return 0; // Đã đứt chuỗi
    }

    int streak = 0;
    var checkDate = dates.contains(today)
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    while (dates.contains(_formatDateLocal(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _formatDateLocal(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Ghi nhận sự kiện nhận XP bền vững (idempotent qua event_key).
  Future<bool> recordXpEvent({
    required String eventKey,
    required String sourceNamespace,
    required String sourceId,
    required int xpAmount,
    int baseXp = 0,
    int bonusXp = 0,
    String? attemptId,
  }) async {
    final profileId = activeProfileId;
    final now = DateTime.now().toUtc();
    final eventId = 'xp_${DateTime.now().millisecondsSinceEpoch}_$sourceId';

    try {
      await database.insert('local_xp_events', {
        'event_id': eventId,
        'event_key': eventKey,
        'local_id': profileId,
        'attempt_id': attemptId,
        'source_namespace': sourceNamespace,
        'source_id': sourceId,
        'base_xp': baseXp > 0 ? baseXp : xpAmount,
        'bonus_xp': bonusXp,
        'xp_amount': xpAmount,
        'earned_at_utc': now.toIso8601String(),
        'reward_rule_version': 1,
      });

      // Ghi nhận ngày học hôm nay để duy trì streak
      await recordStudyDay(now);
      return true;
    } catch (_) {
      // Trùng event_key (idempotent), bỏ qua không cộng trùng
      return false;
    }
  }

  /// Ghi nhận ngày học hôm nay để duy trì streak.
  Future<void> recordStudyDay([DateTime? date]) async {
    final profileId = activeProfileId;
    final dt = date ?? DateTime.now();
    final localDate = _formatDateLocal(dt);

    await database.insert(
      'local_study_days',
      {
        'local_id': profileId,
        'local_date': localDate,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Hoàn thành một session Flashcards và ghi nhận XP, streak.
  Future<int> recordFlashcardSessionCompleted({
    required int cardsReviewed,
    required int correctCards,
  }) async {
    if (cardsReviewed <= 0) return 0;
    final now = DateTime.now().toUtc();
    final sessionKey = 'fc_${now.millisecondsSinceEpoch}';
    final baseXp = 10;
    final bonusXp = correctCards * 2;
    final totalXp = baseXp + bonusXp;

    await recordXpEvent(
      eventKey: 'session_flashcard_$sessionKey',
      sourceNamespace: 'flashcard',
      sourceId: sessionKey,
      xpAmount: totalXp,
      baseXp: baseXp,
      bonusXp: bonusXp,
    );

    await recordStudyDay(now);
    return totalXp;
  }

  // ==========================================
  // FLASHCARD & FSRS ÔN TẬP THÔNG MINH
  // ==========================================

  /// Lấy cấu hình ôn tập FSRS của người học.
  Future<Map<String, dynamic>> getFlashcardSettings() async {
    final rows = await database.query(
      'local_flashcard_settings',
      where: 'local_id = ?',
      whereArgs: [activeProfileId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final map = Map<String, dynamic>.from(rows.first);
      // Tối đa 7 ngày theo yêu cầu người học
      final rawMax = (map['maximum_interval'] as num?)?.toInt() ?? 7;
      map['maximum_interval'] = rawMax.clamp(1, 7);
      return map;
    }
    return {
      'local_id': activeProfileId,
      'desired_retention': 0.90,
      'maximum_interval': 7,
      'enable_fuzzing': 1,
      'new_cards_per_day': 20,
      'max_reviews_per_day': 100,
      'card_direction': 'zh_vi',
      'auto_play_audio': 1,
      'preset_name': 'Cân bằng',
    };
  }

  /// Lưu cấu hình ôn tập FSRS.
  Future<void> saveFlashcardSettings(Map<String, dynamic> settings) async {
    final map = Map<String, dynamic>.from(settings);
    map['local_id'] = activeProfileId;
    await database.insert(
      'local_flashcard_settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy số liệu tổng quan trên Dashboard Flashcard hôm nay.
  Future<Map<String, dynamic>> getFlashcardDashboardSummary() async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final profileId = activeProfileId;

    // 1. Thẻ cần ôn hôm nay (due <= now)
    final dueRows = await database.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM local_flashcard_progress
      WHERE local_id = ? AND due_at_utc <= ?
    ''', [profileId, nowUtc]);
    final dueToday = (dueRows.first['cnt'] as num?)?.toInt() ?? 0;

    // 2. Thẻ quá hạn (> 24 giờ trước)
    final oneDayAgoUtc = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
    final overdueRows = await database.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM local_flashcard_progress
      WHERE local_id = ? AND due_at_utc <= ?
    ''', [profileId, oneDayAgoUtc]);
    final overdueCount = (overdueRows.first['cnt'] as num?)?.toInt() ?? 0;

    // 3. Thẻ đang học (state = 1: learning hoặc state = 3: relearning)
    final learningRows = await database.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM local_flashcard_progress
      WHERE local_id = ? AND state IN (1, 3)
    ''', [profileId]);
    final learningCount = (learningRows.first['cnt'] as num?)?.toInt() ?? 0;

    // 4. Thẻ đã nhớ (state = 2: review)
    final reviewRows = await database.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM local_flashcard_progress
      WHERE local_id = ? AND state = 2
    ''', [profileId]);
    final reviewCount = (reviewRows.first['cnt'] as num?)?.toInt() ?? 0;

    // 5. Tổng số từ vựng trong giáo trình
    final totalWordsRows = await database.rawQuery('''
      SELECT COUNT(*) as cnt FROM lexicon_words
    ''');
    final totalWords = (totalWordsRows.first['cnt'] as num?)?.toInt() ?? 0;

    // 6. Số từ vựng đã bắt đầu học
    final startedRows = await database.rawQuery('''
      SELECT COUNT(DISTINCT word_id) as cnt
      FROM local_flashcard_progress
      WHERE local_id = ?
    ''', [profileId]);
    final startedWords = (startedRows.first['cnt'] as num?)?.toInt() ?? 0;
    final newAvailable = (totalWords - startedWords) > 0 ? (totalWords - startedWords) : 0;

    // 7. Chuỗi ngày streak
    final streak = await getCurrentStreak();

    return {
      'due_today': dueToday,
      'overdue_count': overdueCount,
      'learning_count': learningCount,
      'review_count': reviewCount,
      'new_available': newAvailable,
      'total_words': totalWords,
      'streak_days': streak,
    };
  }

  /// Lấy danh sách bộ thẻ theo HSK và Section (Unit) kèm số lượng thẻ thực tế.
  Future<List<Map<String, dynamic>>> getFlashcardDecksHierarchy() async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final profileId = activeProfileId;
    final levels = await getHskLevels();
    final List<Map<String, dynamic>> result = [];

    for (final lvl in levels) {
      final lvlId = (lvl['id'] as num?)?.toInt() ?? 1;
      final units = await getUnitsByHskLevel(lvlId);
      final List<Map<String, dynamic>> sectionList = [];

      for (final u in units) {
        final unitId = (u['id'] as num?)?.toInt() ?? 1;

        final statsRow = await database.rawQuery('''
          SELECT
            COUNT(DISTINCT w.id) as total_words,
            COUNT(DISTINCT CASE WHEN p.card_id IS NOT NULL AND p.due_at_utc <= ? THEN w.id END) as due_words,
            COUNT(DISTINCT CASE WHEN p.card_id IS NOT NULL AND p.state IN (1, 3) THEN w.id END) as learning_words,
            COUNT(DISTINCT CASE WHEN p.card_id IS NOT NULL AND p.state = 2 THEN w.id END) as review_words,
            COUNT(DISTINCT CASE WHEN p.card_id IS NULL THEN w.id END) as new_words
          FROM lexicon_word_sources s
          INNER JOIN lexicon_words w ON s.word_id = w.id
          LEFT JOIN local_flashcard_progress p ON p.word_id = w.id AND p.local_id = ?
          WHERE s.unit_id = ?
        ''', [nowUtc, profileId, unitId]);

        final stats = statsRow.isNotEmpty ? statsRow.first : {};
        sectionList.add({
          'unit': u,
          'total_words': (stats['total_words'] as num?)?.toInt() ?? 0,
          'due_words': (stats['due_words'] as num?)?.toInt() ?? 0,
          'learning_words': (stats['learning_words'] as num?)?.toInt() ?? 0,
          'review_words': (stats['review_words'] as num?)?.toInt() ?? 0,
          'new_words': (stats['new_words'] as num?)?.toInt() ?? 0,
        });
      }

      result.add({
        'level': lvl,
        'sections': sectionList,
      });
    }

    return result;
  }

  /// Lấy danh sách thẻ từ vựng phục vụ một phiên học/ôn tập Flashcard.
  Future<List<Map<String, dynamic>>> fetchCardsForSession({
    int? hskLevel,
    int? unitId,
    List<int>? unitIds,
    bool onlyDue = false,
    bool onlyNew = false,
    int limit = 20,
    String direction = 'zh_vi',
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final profileId = activeProfileId;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (hskLevel != null && hskLevel > 0) {
      whereClauses.add('w.hsk_level_id = ?');
      whereArgs.add(hskLevel);
    }

    if (unitId != null) {
      whereClauses.add('s.unit_id = ?');
      whereArgs.add(unitId);
    } else if (unitIds != null && unitIds.isNotEmpty) {
      final placeholders = List.filled(unitIds.length, '?').join(',');
      whereClauses.add('s.unit_id IN ($placeholders)');
      whereArgs.addAll(unitIds);
    }

    if (onlyDue) {
      whereClauses.add('p.card_id IS NOT NULL AND p.due_at_utc <= ?');
      whereArgs.add(nowUtc);
    } else if (onlyNew) {
      whereClauses.add('p.card_id IS NULL');
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final query = '''
      SELECT DISTINCT w.*,
             w.id as word_id,
             u.id as unit_id, u.title as unit_title, u.unit_number,
             p.card_id, p.state as card_state, p.step, p.stability, p.difficulty,
             p.due_at_utc, p.last_review_at_utc, p.reps, p.lapses, p.scheduled_days
      FROM lexicon_words w
      LEFT JOIN lexicon_word_sources s ON s.word_id = w.id
      LEFT JOIN lexicon_units u ON s.unit_id = u.id
      LEFT JOIN local_flashcard_progress p
             ON p.word_id = w.id AND p.direction = ? AND p.local_id = ?
      $whereSql
      ORDER BY
        CASE
          WHEN p.card_id IS NOT NULL AND p.due_at_utc <= ? THEN 0 -- Thẻ đến hạn lên đầu
          WHEN p.card_id IS NOT NULL THEN 1                       -- Thẻ đã học
          ELSE 2                                                  -- Thẻ mới
        END ASC,
        p.due_at_utc ASC,
        w.id ASC
      LIMIT ?
    ''';

    final fullArgs = [direction, profileId, ...whereArgs, nowUtc, limit];
    return database.rawQuery(query, fullArgs);
  }

  /// Ghi nhận kết quả đánh giá thẻ Flashcard theo FSRS trong cùng 1 Transaction nguyên tử.
  Future<void> recordFlashcardReviewAtomic({
    required int cardId,
    required int wordId,
    required int rating, // 1=again, 2=hard, 3=good, 4=easy
    required int stateBefore,
    required int stateAfter,
    required DateTime dueAfterUtc,
    required double stabilityAfter,
    required double difficultyAfter,
    DateTime? dueBeforeUtc,
    DateTime? lastReviewUtc,
    int? step,
    int? durationMs,
    int scheduledDays = 0,
    int reps = 0,
    int lapses = 0,
    String direction = 'zh_vi',
  }) async {
    final profileId = activeProfileId;
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();
    final reviewId = 'rev_${cardId}_${now.microsecondsSinceEpoch}';

    await database.transaction((txn) async {
      // 1. Upsert tiến độ thẻ local_flashcard_progress
      await txn.rawInsert('''
        INSERT INTO local_flashcard_progress (
          local_id, card_id, word_id, direction, state, step,
          stability, difficulty, due_at_utc, last_review_at_utc,
          reps, lapses, scheduled_days, algorithm_version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'FSRS-v2')
        ON CONFLICT(local_id, card_id) DO UPDATE SET
          state = excluded.state,
          step = excluded.step,
          stability = excluded.stability,
          difficulty = excluded.difficulty,
          due_at_utc = excluded.due_at_utc,
          last_review_at_utc = excluded.last_review_at_utc,
          reps = excluded.reps,
          lapses = excluded.lapses,
          scheduled_days = excluded.scheduled_days,
          algorithm_version = excluded.algorithm_version;
      ''', [
        profileId,
        cardId,
        wordId,
        direction,
        stateAfter,
        step,
        stabilityAfter,
        difficultyAfter,
        dueAfterUtc.toIso8601String(),
        nowIso,
        reps,
        lapses,
        scheduledDays,
      ]);

      // 2. Ghi nhận log ôn tập bất biến local_flashcard_review_logs
      final intervalDays = dueAfterUtc.difference(now).inHours / 24.0;
      await txn.insert('local_flashcard_review_logs', {
        'review_id': reviewId,
        'local_id': profileId,
        'card_id': cardId,
        'word_id': wordId,
        'rating': rating,
        'review_at_utc': nowIso,
        'review_duration_ms': durationMs ?? 0,
        'state_before': stateBefore,
        'state_after': stateAfter,
        'stability_after': stabilityAfter,
        'difficulty_after': difficultyAfter,
        'due_before_utc': dueBeforeUtc?.toIso8601String(),
        'due_after_utc': dueAfterUtc.toIso8601String(),
        'interval_days_after': intervalDays,
        'algorithm_version': 'FSRS-v2',
      });

      // 3. Đồng bộ tương thích sang local_word_srs
      await txn.rawInsert('''
        INSERT INTO local_word_srs (
          local_id, word_id, srs_stage, ease_factor, interval_days,
          repetition_count, next_review_at_utc, last_reviewed_at_utc,
          correct_count, wrong_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(local_id, word_id) DO UPDATE SET
          srs_stage = excluded.srs_stage,
          ease_factor = excluded.ease_factor,
          interval_days = excluded.interval_days,
          repetition_count = repetition_count + 1,
          next_review_at_utc = excluded.next_review_at_utc,
          last_reviewed_at_utc = excluded.last_reviewed_at_utc,
          correct_count = correct_count + (CASE WHEN ? >= 3 THEN 1 ELSE 0 END),
          wrong_count = wrong_count + (CASE WHEN ? < 3 THEN 1 ELSE 0 END);
      ''', [
        profileId,
        wordId,
        stateAfter,
        stabilityAfter,
        scheduledDays,
        reps,
        dueAfterUtc.toIso8601String(),
        nowIso,
        rating >= 3 ? 1 : 0,
        rating < 3 ? 1 : 0,
        rating,
        rating,
      ]);

      // 4. Ghi nhận sự kiện XP (3 XP cho mỗi lần review)
      final xpKey = 'fc_rev_$reviewId';
      await txn.insert(
        'local_xp_events',
        {
          'event_id': _generateUuid(),
          'event_key': xpKey,
          'local_id': profileId,
          'source_namespace': 'flashcard',
          'source_id': '$wordId',
          'base_xp': rating >= 3 ? 3 : 1,
          'bonus_xp': rating == 4 ? 2 : 0,
          'xp_amount': rating == 4 ? 5 : (rating >= 3 ? 3 : 1),
          'earned_at_utc': nowIso,
          'reward_rule_version': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // 5. Ghi nhận chuỗi ngày học
      final localDate = _formatDateLocal(now);
      await txn.insert(
        'local_study_days',
        {
          'local_id': profileId,
          'local_date': localDate,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  /// Lấy danh sách ví dụ câu cho từ vựng.
  Future<List<Map<String, dynamic>>> getWordExamples(int wordId) async {
    return database.query(
      'lexicon_examples',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  /// Lấy danh sách chữ Hán cấu tạo nên từ vựng để liên kết Luyện viết chữ.
  Future<List<Map<String, dynamic>>> getCharactersForWord(String word) async {
    final chars = word.runes.map((r) => String.fromCharCode(r)).toSet().toList();
    if (chars.isEmpty) return [];
    final placeholders = List.filled(chars.length, '?').join(',');
    return database.rawQuery('''
      SELECT * FROM lexicon_characters
      WHERE character IN ($placeholders)
      ORDER BY id ASC
    ''', chars);
  }

  /// Lấy số liệu thống kê lịch sử: Heatmap, Phân bổ xếp hạng, Dự báo 7 ngày.
  Future<Map<String, dynamic>> getFlashcardStatsHistory({int days = 90}) async {
    final profileId = activeProfileId;
    final now = DateTime.now().toUtc();
    final startUtc = now.subtract(Duration(days: days)).toIso8601String();

    // 1. Heatmap theo ngày
    final heatmapRows = await database.rawQuery('''
      SELECT
        SUBSTR(review_at_utc, 1, 10) as review_date,
        COUNT(*) as total_reviews,
        SUM(CASE WHEN rating >= 3 THEN 1 ELSE 0 END) as correct_reviews
      FROM local_flashcard_review_logs
      WHERE local_id = ? AND review_at_utc >= ?
      GROUP BY review_date
      ORDER BY review_date ASC
    ''', [profileId, startUtc]);

    // 2. Phân bổ xếp hạng (Again, Hard, Good, Easy)
    final ratingRows = await database.rawQuery('''
      SELECT rating, COUNT(*) as cnt
      FROM local_flashcard_review_logs
      WHERE local_id = ?
      GROUP BY rating
    ''', [profileId]);

    final ratingCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};
    for (final r in ratingRows) {
      final rate = (r['rating'] as num?)?.toInt() ?? 1;
      ratingCounts[rate] = (r['cnt'] as num?)?.toInt() ?? 0;
    }

    // 3. Dự báo lịch ôn (Forecast)
    final forecastRows = await database.rawQuery('''
      SELECT
        SUBSTR(due_at_utc, 1, 10) as due_date,
        COUNT(*) as card_count
      FROM local_flashcard_progress
      WHERE local_id = ? AND due_at_utc > ?
      GROUP BY due_date
      ORDER BY due_date ASC
      LIMIT 14
    ''', [profileId, now.toIso8601String()]);

    return {
      'heatmap': heatmapRows,
      'ratings': ratingCounts,
      'forecast': forecastRows,
    };
  }

  /// Đóng kết nối database (dùng trong test hoặc dọn dẹp).
  Future<void> close() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
    _cachedLocalId = null;
  }
}
