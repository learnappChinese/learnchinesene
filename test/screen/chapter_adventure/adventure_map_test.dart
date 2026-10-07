import 'dart:async';

import 'package:flash_learn_chinese/core/widgets/adventure_node.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/controller/chapter_adventure_controller.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/data/chapter_adventure_repository.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/model/chapter_adventure.dart';
import 'package:flash_learn_chinese/screen/chapter_adventure/widget/adventure_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const missions = <ChapterMission>[
  ChapterMission(
      gameId: 1,
      gameCode: 'learn_words',
      title: 'Khám phá từ mới',
      description: '',
      type: AdventureNodeType.learn,
      state: AdventureNodeState.completed,
      stars: 2),
  ChapterMission(
      gameId: 2,
      gameCode: 'select_answer',
      title: 'Nhận diện',
      description: '',
      type: AdventureNodeType.select,
      state: AdventureNodeState.available,
      stars: 0),
  ChapterMission(
      gameId: 3,
      gameCode: 'listen_select',
      title: 'Săn âm thanh',
      description: '',
      type: AdventureNodeType.listening,
      state: AdventureNodeState.available,
      stars: 0),
  ChapterMission(
      gameId: 4,
      gameCode: 'translate',
      title: 'Dùng trong câu',
      description: '',
      type: AdventureNodeType.game,
      state: AdventureNodeState.locked,
      stars: 0),
  ChapterMission(
      gameId: 7,
      gameCode: 'match_pairs',
      title: 'Nối cặp',
      description: '',
      type: AdventureNodeType.select,
      state: AdventureNodeState.locked,
      stars: 0),
];

const chapter = ChapterAdventure(
  levelId: 'level-1',
  unitId: 'unit-1',
  regionNumber: 1,
  chapterNumber: 5,
  title: 'Gọi tên món ăn và đồ uống',
  objective: 'Gọi tên món ăn và đồ uống',
  missions: missions,
);

class _Repository implements ChapterAdventureRepository {
  _Repository(this.result);
  final Future<ChapterAdventure?> result;
  @override
  Future<ChapterAdventure?> loadChapter(String levelId) => result;
}

void main() {
  tearDown(() async => Get.reset());

  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('adventure map fits ${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tapped = <int>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdventureMap(
              missions: missions,
              bossUnlocked: false,
              onMissionTap: (mission) => tapped.add(mission.gameId),
              onBossTap: () {},
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Khám phá từ mới'), findsOneWidget);
      expect(find.text('Săn âm thanh'), findsOneWidget);
      expect(find.text('Chapter Boss'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.extension_rounded).first);
      expect(tapped, [2]);
      expect(tester.takeException(), isNull);
    });
  }

  test('controller exposes loaded, empty, and failure states', () async {
    final loaded = ChapterAdventureController(
      levelId: 'level-1',
      repository: _Repository(Future.value(chapter)),
    );
    await loaded.loadChapter();
    expect(loaded.chapter.value, same(chapter));
    expect(loaded.errorMessage.value, isNull);

    final empty = ChapterAdventureController(
      levelId: 'level-2',
      repository: _Repository(Future.value(null)),
    );
    await empty.loadChapter();
    expect(empty.chapter.value, isNull);

    final failed = ChapterAdventureController(
      levelId: 'level-3',
      repository: _Repository(Future.error(StateError('offline'))),
    );
    await failed.loadChapter();
    expect(failed.errorMessage.value, isNotNull);
    expect(failed.isLoading.value, isFalse);
  });

  test('closed controller ignores a late repository response', () async {
    final completer = Completer<ChapterAdventure?>();
    final controller = Get.put(ChapterAdventureController(
      levelId: 'level-1',
      repository: _Repository(completer.future),
    ));
    await Get.delete<ChapterAdventureController>();
    completer.complete(chapter);
    await Future<void>.delayed(Duration.zero);
    expect(controller.chapter.value, isNull);
  });
}
