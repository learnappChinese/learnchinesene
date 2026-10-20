import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppDatabase Local-First Verification', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.instance;
      await db.init(customPath: inMemoryDatabasePath);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Khởi tạo database in-memory và tạo local_profile với UUID hợp lệ',
        () async {
      expect(db.isOpen, isTrue);
      final profileId = db.activeProfileId;
      expect(profileId, isNotEmpty);
      expect(profileId.length, equals(32));

      // Gọi lại ensureLocalProfile() phải trả về cùng một UUID
      final secondCall = await db.ensureLocalProfile();
      expect(secondCall, equals(profileId));

      final rows = await db.database.query('local_profiles');
      expect(rows.length, equals(1));
      expect(rows.first['local_id'], equals(profileId));
      expect(rows.first['timezone_id'], equals('Asia/Ho_Chi_Minh'));
    });

    test('2. Nạp thành công gói giáo trình seed pack HSK 1-4', () async {
      final file = File('assets/data/hsk_curriculum_pack_v1.json');
      expect(file.existsSync(), isTrue,
          reason: 'Tệp assets/data/hsk_curriculum_pack_v1.json phải tồn tại');

      final jsonString = await file.readAsString();
      final seeded = await db.ensureContentPackSeeded(jsonOverride: jsonString);
      expect(seeded, isTrue);

      // Lần nạp thứ hai phải trả về false (idempotent)
      final seededAgain =
          await db.ensureContentPackSeeded(jsonOverride: jsonString);
      expect(seededAgain, isFalse);

      // Kiểm tra số lượng cấp độ HSK 1-4
      final levels = await db.getHskLevels();
      expect(levels.length, equals(4));
      expect(levels.map((l) => l['name']).toList(),
          equals(['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4']));

      // Kiểm tra số lượng Units theo HSK 1
      final hsk1Units = await db.getUnitsByHskLevel(1);
      expect(hsk1Units.length, equals(10));

      // Kiểm tra từ vựng của Unit 1
      final unit1Words = await db.getWordsByUnit(1);
      expect(unit1Words, isNotEmpty);

      // Kiểm tra chữ Hán
      final chars = await db.getAllCharacters(limit: 20);
      expect(chars, isNotEmpty);
      expect(chars.first['stroke_paths'], isNotEmpty);
    });

    test('3. Ghi nhận và tính toán XP từ sổ cái local_xp_events', () async {
      final profileId = db.activeProfileId;
      expect(await db.getTotalXp(), equals(0));

      // Thêm 1 attempt
      await db.database.insert('local_activity_attempts', {
        'attempt_id': 'att_001',
        'local_id': profileId,
        'activity_type': 'vocabulary',
        'source_namespace': 'hsk',
        'source_id': 'unit_1',
        'started_at_utc': DateTime.now().toUtc().toIso8601String(),
        'status': 'passed',
        'score': 100.0,
        'stars': 3,
      });

      // Thêm XP event
      await db.database.insert('local_xp_events', {
        'event_id': 'evt_001',
        'event_key': 'hsk:unit_1:att_001',
        'local_id': profileId,
        'attempt_id': 'att_001',
        'source_namespace': 'hsk',
        'source_id': 'unit_1',
        'base_xp': 20,
        'bonus_xp': 5,
        'xp_amount': 25,
        'earned_at_utc': DateTime.now().toUtc().toIso8601String(),
      });

      expect(await db.getTotalXp(), equals(25));
    });

    test('4. Ràng buộc khóa ngoại PRAGMA foreign_keys hoạt động nghiêm ngặt',
        () async {
      // Chèn attempt với local_id không tồn tại phải throw DatabaseException
      expect(
        () async => await db.database.insert('local_activity_attempts', {
          'attempt_id': 'att_invalid',
          'local_id': 'non_existent_uuid',
          'activity_type': 'vocabulary',
          'source_namespace': 'hsk',
          'source_id': 'unit_1',
          'started_at_utc': DateTime.now().toUtc().toIso8601String(),
          'status': 'passed',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
