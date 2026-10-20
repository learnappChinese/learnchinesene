import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/database/db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Startup & Local-First Boot Verification (Slice 1 Acceptance)',
      () {
    late AppDatabase db;
    late DbHelper dbHelper;

    setUp(() async {
      db = AppDatabase.instance;
      await db.init(customPath: inMemoryDatabasePath);

      // Nạp gói giáo trình seed pack từ assets
      final file = File('assets/data/hsk_curriculum_pack_v1.json');
      final jsonString = await file.readAsString();
      await db.ensureContentPackSeeded(jsonOverride: jsonString);

      dbHelper = DbHelper.instance;
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Không cần mạng: DbHelper đọc HSK 1-4 thành công từ SQLite',
        () async {
      final levels = await dbHelper.getHskLevels();
      expect(levels.length, equals(4));
      expect(levels[0].title, equals('HSK 1'));
      expect(levels[1].title, equals('HSK 2'));
      expect(levels[2].title, equals('HSK 3'));
      expect(levels[3].title, equals('HSK 4'));
    });

    test('2. Không cần mạng: Đọc danh sách Units của HSK 1', () async {
      final units = await dbHelper.getUnitsByLevel(1);
      expect(units.length, equals(10));
      expect(units.first.title, contains('Unit 1'));
    });

    test('3. Không cần mạng: Đọc từ vựng của Unit 1', () async {
      final words = await dbHelper.getWordsByUnit(1);
      expect(words, isNotEmpty);
      expect(words.first.chinese, isNotEmpty);
      expect(words.first.pinyin, isNotEmpty);
      expect(words.first.vietnamese, isNotEmpty);
    });

    test('4. Không cần mạng: Đọc danh sách chữ Hán luyện viết từ SQLite',
        () async {
      final chars = await dbHelper.getCharactersForWriting();
      expect(chars, isNotEmpty);
      expect(chars.first.character, isNotEmpty);
      expect(chars.first.strokePathData, isNotEmpty);
      expect(chars.first.strokeCount, greaterThan(0));
    });

    test('5. Không cần mạng: getStats() trả về dữ liệu thực không crash',
        () async {
      final stats = await dbHelper.getStats();
      expect(stats, isNotNull);
      expect(stats['totalExp'], equals(0));
      expect(stats['streak'], equals(0));
      expect(stats['wordsMastered'], equals(0));
    });

    test('6. Đánh dấu đã thuộc từ (markLearned) lưu bền vững vào local_word_srs',
        () async {
      final words = await dbHelper.getWordsByUnit(1);
      final wordId = words.first.id;

      await dbHelper.markLearned(wordId);

      final stats = await dbHelper.getStats();
      expect(stats['wordsMastered'], equals(1));
    });
  });
}
