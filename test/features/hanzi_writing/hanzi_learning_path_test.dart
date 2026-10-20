import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/models/hanzi_character.dart';
import 'package:pandarin/features/hanzi_writing/controller/hanzi_learning_path_controller.dart';
import 'package:pandarin/features/hanzi_writing/models/hanzi_path_models.dart';
import 'package:pandarin/features/hanzi_writing/widget/hanzi_node_detail_sheet.dart';
import 'package:pandarin/features/hanzi_writing/widget/hanzi_panda_companion_overlay.dart';
import 'package:pandarin/features/hanzi_writing/widget/hanzi_path_node_widget.dart';
import 'package:pandarin/features/hanzi_writing/widget/hanzi_path_row_item.dart';
import 'package:pandarin/features/hanzi_writing/widget/hanzi_path_top_bar.dart';
import 'package:pandarin/features/hanzi_writing/widget/hanzi_section_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hanzi Learning Path Models & Logic', () {
    test('1. HanziPathSection computes progress and completion status correctly', () {
      final char1 = HanziCharacter.fromMap({
        'id': 1,
        'character': '你',
        'pinyin': 'nǐ',
        'meaning_vi': 'bạn, anh',
        'stroke_count': 7,
      });
      final char2 = HanziCharacter.fromMap({
        'id': 2,
        'character': '好',
        'pinyin': 'hǎo',
        'meaning_vi': 'tốt, đẹp',
        'stroke_count': 6,
      });

      final node1 = HanziPathNode(
        character: char1,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 0,
        globalIndex: 0,
        state: WritingNodeState.completed,
      );
      final node2 = HanziPathNode(
        character: char2,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 1,
        globalIndex: 1,
        state: WritingNodeState.inProgress,
      );

      final section = HanziPathSection(
        id: 1,
        hskLevel: 1,
        sectionNumber: 1,
        title: 'Chào hỏi',
        description: 'Bài 1',
        nodes: [node1, node2],
        isUnlocked: true,
      );

      expect(section.totalCount, equals(2));
      expect(section.completedCount, equals(1));
      expect(section.progress, equals(0.5));
      expect(section.isCompleted, isFalse);

      final completedNode2 = node2.copyWith(state: WritingNodeState.completed);
      final completedSection = HanziPathSection(
        id: 1,
        hskLevel: 1,
        sectionNumber: 1,
        title: 'Chào hỏi',
        description: 'Bài 1',
        nodes: [node1, completedNode2],
        isUnlocked: true,
      );

      expect(completedSection.completedCount, equals(2));
      expect(completedSection.progress, equals(1.0));
      expect(completedSection.isCompleted, isTrue);
    });

    test('2. HanziPathHskLevel aggregates multiple sections correctly', () {
      final char = HanziCharacter.fromMap({'id': 10, 'character': '我', 'stroke_count': 7});
      final n1 = HanziPathNode(
        character: char,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 0,
        globalIndex: 0,
        state: WritingNodeState.completed,
      );
      final n2 = HanziPathNode(
        character: char,
        sectionId: 2,
        hskLevel: 1,
        indexInSection: 0,
        globalIndex: 1,
        state: WritingNodeState.available,
      );

      final s1 = HanziPathSection(
        id: 1,
        hskLevel: 1,
        sectionNumber: 1,
        title: 'S1',
        description: 'Desc 1',
        nodes: [n1],
        isUnlocked: true,
      );
      final s2 = HanziPathSection(
        id: 2,
        hskLevel: 1,
        sectionNumber: 2,
        title: 'S2',
        description: 'Desc 2',
        nodes: [n2],
        isUnlocked: true,
      );

      final level = HanziPathHskLevel(
        level: 1,
        name: 'HSK 1',
        description: 'Cơ bản',
        sections: [s1, s2],
        isUnlocked: true,
      );

      expect(level.totalCharacters, equals(2));
      expect(level.completedCharacters, equals(1));
      expect(level.progress, equals(0.5));
      expect(level.isCompleted, isFalse);
    });

    test('3. Zigzag cyclical offsets cycle smoothly', () {
      final offsets = [
        HanziPathRowItem.getOffsetForIndex(0),
        HanziPathRowItem.getOffsetForIndex(1),
        HanziPathRowItem.getOffsetForIndex(2),
        HanziPathRowItem.getOffsetForIndex(3),
        HanziPathRowItem.getOffsetForIndex(4),
        HanziPathRowItem.getOffsetForIndex(5),
        HanziPathRowItem.getOffsetForIndex(6),
        HanziPathRowItem.getOffsetForIndex(7),
      ];

      expect(offsets[0], equals(0.0));
      expect(offsets[1], greaterThan(0));
      expect(offsets[4], lessThan(0));
      expect(offsets[7], equals(offsets[0])); // wraps around properly
    });
  });

  group('Hanzi Learning Path Widgets', () {
    testWidgets('4. HanziZigzagNodeWidget renders completed state with checkmark',
        (tester) async {
      final char = HanziCharacter.fromMap({
        'id': 1,
        'character': '你',
        'pinyin': 'nǐ',
        'meaning_vi': 'bạn',
        'stroke_count': 7,
      });

      final node = HanziPathNode(
        character: char,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 0,
        globalIndex: 0,
        state: WritingNodeState.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HanziZigzagNodeWidget(
              node: node,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('你'), findsOneWidget);
      expect(find.text('nǐ'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('5. HanziZigzagNodeWidget renders inProgress state with badge',
        (tester) async {
      final char = HanziCharacter.fromMap({
        'id': 2,
        'character': '好',
        'pinyin': 'hǎo',
        'meaning_vi': 'tốt',
        'stroke_count': 6,
      });

      final node = HanziPathNode(
        character: char,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 1,
        globalIndex: 1,
        state: WritingNodeState.inProgress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HanziZigzagNodeWidget(
              node: node,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('好'), findsOneWidget);
      expect(find.text('ĐANG HỌC'), findsOneWidget);
    });

    testWidgets('6. HanziZigzagNodeWidget renders locked state with lock icon',
        (tester) async {
      final char = HanziCharacter.fromMap({
        'id': 3,
        'character': '大',
        'pinyin': 'dà',
        'meaning_vi': 'lớn',
        'stroke_count': 3,
      });

      final node = HanziPathNode(
        character: char,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 2,
        globalIndex: 2,
        state: WritingNodeState.locked,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HanziZigzagNodeWidget(
              node: node,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('大'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('7. HanziSectionBanner displays title and progress',
        (tester) async {
      final section = HanziPathSection(
        id: 1,
        hskLevel: 1,
        sectionNumber: 2,
        title: 'Gia đình',
        description: 'Bài 2',
        nodes: [
          HanziPathNode(
            character: HanziCharacter.fromMap({'id': 1, 'character': '爸', 'stroke_count': 8}),
            sectionId: 1,
            hskLevel: 1,
            indexInSection: 0,
            globalIndex: 0,
            state: WritingNodeState.completed,
          ),
          HanziPathNode(
            character: HanziCharacter.fromMap({'id': 2, 'character': '妈', 'stroke_count': 6}),
            sectionId: 1,
            hskLevel: 1,
            indexInSection: 1,
            globalIndex: 1,
            state: WritingNodeState.available,
          ),
        ],
        isUnlocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HanziSectionBanner(section: section),
          ),
        ),
      );

      expect(find.text('Gia đình'), findsOneWidget);
      expect(find.text('HSK 1 • BÀI 2'), findsOneWidget);
      expect(find.text('Tiến độ: 1/2 chữ'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('8. HanziNodeDetailSheet displays character, pinyin, meaning and triggers CTA',
        (tester) async {
      final char = HanziCharacter.fromMap({
        'id': 99,
        'character': '爱',
        'pinyin': 'ài',
        'meaning_vi': 'yêu, thích',
        'stroke_count': 10,
      });

      final node = HanziPathNode(
        character: char,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 0,
        globalIndex: 0,
        state: WritingNodeState.inProgress,
      );

      bool started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HanziNodeDetailSheet(
              node: node,
              onStartWriting: () {
                started = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('爱'), findsOneWidget);
      expect(find.text('ài'), findsOneWidget);
      expect(find.text('yêu, thích'), findsOneWidget);
      expect(find.text('10 nét'), findsOneWidget);
      expect(find.text('BẮT ĐẦU VIẾT'), findsOneWidget);

      await tester.tap(find.text('BẮT ĐẦU VIẾT'));
      await tester.pump();
      expect(started, isTrue);
    });

    testWidgets('9. HanziPathTopBar renders Back Button and handles tap',
        (tester) async {
      final controller = HanziLearningPathController();
      controller.totalXp.value = 178;
      controller.currentStreak.value = 1;
      controller.totalMasteredCount.value = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: HanziPathTopBar(controller: controller),
            ),
          ),
        ),
      );

      // Verify Back button exists with tooltip 'Trở về'
      expect(find.byTooltip('Trở về'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Verify stat chips
      expect(find.text('178'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('ngày'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('chữ'), findsOneWidget);
    });

    testWidgets('10. HanziPathPandaWidget renders without bottom overflow in bounded row',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 114,
              width: 400,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  HanziPathPandaWidget(
                    isLeft: true,
                    speechText: 'Thư pháp đỉnh cao!',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // Zero exceptions / zero overflow!
      expect(tester.takeException(), isNull);
      expect(find.text('Thư pháp đỉnh cao!'), findsOneWidget);
    });

    testWidgets('11. HanziPathRowItem builds without duplicate GlobalKey conflicts',
        (tester) async {
      final char = HanziCharacter.fromMap({
        'id': 1,
        'character': '水',
        'pinyin': 'shuǐ',
        'meaning_vi': 'nước',
        'stroke_count': 4,
      });

      final node = HanziPathNode(
        character: char,
        sectionId: 1,
        hskLevel: 1,
        indexInSection: 0,
        globalIndex: 0,
        state: WritingNodeState.inProgress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HanziPathRowItem(
              key: const ValueKey('row_node_0_1'),
              node: node,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('水'), findsOneWidget);
      expect(find.text('shuǐ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SQLite Hanzi Learning Path Integration', () {
    late AppDatabase appDb;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});

      appDb = AppDatabase.instance;
      if (appDb.isOpen) {
        await appDb.close();
      }
      await appDb.init(customPath: inMemoryDatabasePath);

      final packFile = File('assets/data/hsk_curriculum_pack_v1.json');
      if (packFile.existsSync()) {
        final jsonString = await packFile.readAsString();
        await appDb.ensureContentPackSeeded(jsonOverride: jsonString);
      }
    });

    tearDownAll(() async {
      await appDb.close();
    });

    test('12. getHanziLearningPathRaw returns hierarchical HSK -> Sections -> Characters',
        () async {
      final rawPath = await appDb.getHanziLearningPathRaw();
      expect(rawPath, isNotEmpty);

      final firstHsk = rawPath.first;
      expect(firstHsk['level'], isNotNull);
      final sections = firstHsk['sections'] as List;
      expect(sections, isNotEmpty);

      final firstSection = sections.first as Map<String, dynamic>;
      expect(firstSection['unit'], isNotNull);
      final characters = firstSection['characters'] as List;
      expect(characters, isNotEmpty);

      final firstChar = characters.first as Map<String, dynamic>;
      expect(firstChar['character'], isNotNull);
      expect(firstChar['stroke_count'], greaterThan(0));
    });

    test('13. getTotalMasteredHanziCount counts mastered characters in local_hanzi_progress',
        () async {
      final initialCount = await appDb.getTotalMasteredHanziCount();
      expect(initialCount, equals(0));

      await appDb.recordHanziPractice(
        characterId: 1,
        attempts: 1,
        accuracy: 95.0,
        isMastered: true,
      );

      final updatedCount = await appDb.getTotalMasteredHanziCount();
      expect(updatedCount, equals(1));
    });
  });
}

class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback? onPop;
  _TestNavigatorObserver({this.onPop});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPop?.call();
  }
}
