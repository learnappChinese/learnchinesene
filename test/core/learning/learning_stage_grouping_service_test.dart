import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_stage_models.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_stage_grouping_service.dart';
import 'package:flash_learn_chinese/core/widgets/adventure_node.dart';

void main() {
  const service = LearningStageGroupingService();

  group('LearningStageGroupingService Dynamic Tests', () {
    test('Empty content produces empty stage list', () {
      final stages = service.groupStagesForUnit(
        unitId: 'unit_empty',
        unitTitle: 'Empty Unit',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: [],
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
      );

      expect(stages, isEmpty);
    });

    test(
        'Small dataset: 3 vocabulary words -> stage with exactly 3 items and 3 segments',
        () {
      final words = [
        {
          'id': 101,
          'word': '水',
          'pinyin': 'shuǐ',
          'meaning': 'nước',
          'part_of_speech': 'n'
        },
        {
          'id': 102,
          'word': '茶',
          'pinyin': 'chá',
          'meaning': 'trà',
          'part_of_speech': 'n'
        },
        {
          'id': 103,
          'word': '米饭',
          'pinyin': 'mǐfàn',
          'meaning': 'cơm',
          'part_of_speech': 'n'
        },
      ];

      final stages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_1',
        unitTitle: 'Đồ ăn đồ uống',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
      );

      expect(stages.length, 1);
      final vocabStage = stages.first;
      expect(vocabStage.activityType, LearningStageActivityType.vocabulary);
      expect(vocabStage.totalItems, 3);
      expect(vocabStage.items.length, 3);
      expect(vocabStage.items.map((i) => i.prompt).toList(), ['水', '茶', '米饭']);
      // First stage is unlocked / available by default
      expect(vocabStage.state, AdventureNodeState.available);
      expect(vocabStage.isAvailable, isTrue);
    });

    test(
        'Medium dataset: 6 vocabulary words -> stage with exactly 6 items and 6 segments',
        () {
      final words = List.generate(
        6,
        (i) => {
          'id': i + 1,
          'word': 'Word $i',
          'pinyin': 'py $i',
          'meaning': 'nghĩa $i'
        },
      );

      final stages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_2',
        unitTitle: 'Gia đình',
        sectionNumber: 1,
        unitNumber: 2,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
      );

      expect(stages.length, 1);
      final vocabStage = stages.first;
      expect(vocabStage.totalItems, 6);
      expect(vocabStage.items.length, 6);
    });

    test(
        'Larger dataset: 14 words adaptively splits into sub-stages without overloading one stage',
        () {
      final words = List.generate(
        14,
        (i) =>
            {'id': i + 1, 'word': 'Từ $i', 'pinyin': 'p $i', 'meaning': 'm $i'},
      );

      final stages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_3',
        unitTitle: 'Từ vựng mở rộng',
        sectionNumber: 1,
        unitNumber: 3,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
      );

      // Should be partitioned into 2 sub-stages (7 and 7)
      expect(stages.length, 2);
      expect(stages[0].totalItems, 7);
      expect(stages[1].totalItems, 7);
      // Total items across stages equals all input words
      expect(stages[0].totalItems + stages[1].totalItems, 14);

      // Stage 2 has prerequisite Stage 1
      expect(stages[1].prerequisiteIds, contains(stages[0].id));
      expect(stages[1].isLocked, isTrue);
    });

    test(
        'Semantic Hanzi grouping: characters linked to current Unit vocabulary',
        () {
      final characters = [
        {
          'id': 1,
          'character': '水',
          'pinyin': 'shuǐ',
          'meaning': 'nước',
          'stroke_count': 4
        },
        {
          'id': 2,
          'character': '茶',
          'pinyin': 'chá',
          'meaning': 'trà',
          'stroke_count': 9
        },
        {
          'id': 3,
          'character': '饭',
          'pinyin': 'fàn',
          'meaning': 'cơm',
          'stroke_count': 7
        },
        {
          'id': 4,
          'character': '吃',
          'pinyin': 'chī',
          'meaning': 'ăn',
          'stroke_count': 6
        },
        {
          'id': 5,
          'character': '喝',
          'pinyin': 'hē',
          'meaning': 'uống',
          'stroke_count': 12
        },
      ];

      final stages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_1',
        unitTitle: 'Ẩm thực',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: [],
        rawCharacters: characters,
        rawChallenges: [],
        rawExamples: [],
      );

      expect(stages.length, 1);
      final hanziStage = stages.first;
      expect(hanziStage.activityType, LearningStageActivityType.hanzi);
      expect(hanziStage.totalItems, 5);
      expect(hanziStage.items.length, 5);
      expect(hanziStage.items.map((i) => i.prompt).toList(),
          ['水', '茶', '饭', '吃', '喝']);
    });

    test(
        'Speaking & Listening stages derive items from real sentences and challenges',
        () {
      final examples = [
        {
          'id': 10,
          'chinese': '我想喝水。',
          'pinyin': 'Wǒ xiǎng hē shuǐ.',
          'meaning': 'Tôi muốn uống nước.'
        },
        {
          'id': 11,
          'chinese': '你吃米饭吗？',
          'pinyin': 'Nǐ chī mǐfàn ma?',
          'meaning': 'Bạn ăn cơm không?'
        },
        {
          'id': 12,
          'chinese': '这个苹果很好吃。',
          'pinyin': 'Zhège píngguǒ hěn hǎochī.',
          'meaning': 'Quả táo này rất ngon.'
        },
      ];

      final challenges = [
        {
          'id': 'c1',
          'type': 'listenTap',
          'session_id': 1,
          'order_index': 1,
          'prompt': 'Nghe và chọn',
          'content': {'audio': 'audio1.mp3', 'text': '你好'},
        },
        {
          'id': 'c2',
          'type': 'listenTap',
          'session_id': 1,
          'order_index': 2,
          'prompt': 'Nghe và chọn',
          'content': {'audio': 'audio2.mp3', 'text': '谢谢'},
        },
      ];

      final stages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_1',
        unitTitle: 'Ẩm thực',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: [],
        rawCharacters: [],
        rawChallenges: challenges,
        rawExamples: examples,
      );

      final listeningStage = stages.firstWhere(
          (s) => s.activityType == LearningStageActivityType.listening);
      final speakingStage = stages.firstWhere(
          (s) => s.activityType == LearningStageActivityType.speaking);

      // Listening has 2 items from challenges
      expect(listeningStage.totalItems, 2);
      expect(listeningStage.items.length, 2);

      // Speaking has 3 items from examples
      expect(speakingStage.totalItems, 3);
      expect(speakingStage.items.length, 3);
    });

    test(
        'Partially completed and fully completed progress merge from user progress map',
        () {
      final words = [
        {'id': 1, 'word': '一', 'pinyin': 'yī', 'meaning': 'một'},
        {'id': 2, 'word': '二', 'pinyin': 'èr', 'meaning': 'hai'},
        {'id': 3, 'word': '三', 'pinyin': 'sān', 'meaning': 'ba'},
        {'id': 4, 'word': '四', 'pinyin': 'sì', 'meaning': 'bốn'},
      ];

      // User has completed words 1 and 2
      final wordProgress = {
        1: {'is_completed': true, 'mastery': 1.0, 'score': 100},
        2: {'is_completed': true, 'mastery': 0.8, 'score': 80},
      };

      final stages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_numbers',
        unitTitle: 'Số đếm',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
        wordProgress: wordProgress,
      );

      expect(stages.length, 1);
      final stage = stages.first;
      expect(stage.totalItems, 4);
      expect(stage.completedItems, 2);
      expect(stage.progress, 0.5);
      expect(stage.state, AdventureNodeState.inProgress);
      expect(stage.isCompleted, isFalse);

      // Now with all 4 items completed
      final fullWordProgress = {
        1: {'is_completed': true, 'mastery': 1.0, 'score': 100},
        2: {'is_completed': true, 'mastery': 0.9, 'score': 90},
        3: {'is_completed': true, 'mastery': 1.0, 'score': 100},
        4: {'is_completed': true, 'mastery': 0.95, 'score': 95},
      };

      final completedStages = service.groupStagesForUnit(
        unitId: 'sec_1_unit_numbers',
        unitTitle: 'Số đếm',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
        wordProgress: fullWordProgress,
      );

      final completedStage = completedStages.first;
      expect(completedStage.totalItems, 4);
      expect(completedStage.completedItems, 4);
      expect(completedStage.progress, 1.0);
      expect(completedStage.state, AdventureNodeState.perfect);
      expect(completedStage.isCompleted, isTrue);
      // High score results in 3 stars
      expect(completedStage.stars, 3);
    });

    test(
        'Stars rating is independent of segment count: completed stage with lower accuracy gets 1 star',
        () {
      final words = [
        {'id': 1, 'word': 'A', 'pinyin': 'a', 'meaning': 'a'},
        {'id': 2, 'word': 'B', 'pinyin': 'b', 'meaning': 'b'},
        {'id': 3, 'word': 'C', 'pinyin': 'c', 'meaning': 'c'},
      ];

      // All 3 items completed, but mastery / accuracy is low (0.5)
      final lowAccuracyProgress = {
        1: {'is_completed': true, 'mastery': 0.5, 'score': 50},
        2: {'is_completed': true, 'mastery': 0.45, 'score': 45},
        3: {'is_completed': true, 'mastery': 0.55, 'score': 55},
      };

      final stages = service.groupStagesForUnit(
        unitId: 'test_unit',
        unitTitle: 'Test',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
        wordProgress: lowAccuracyProgress,
      );

      final stage = stages.first;
      expect(stage.totalItems, 3);
      expect(stage.completedItems, 3); // Full completion -> 3/3 segments
      expect(stage.progress, 1.0);
      expect(stage.isCompleted, isTrue);
      expect(stage.stars, 1); // Only 1 star due to low average score
    });

    test(
        'Optional items: stage is completed when all required items are passed, even if optional item is incomplete',
        () {
      const requiredItem1 = LearningStageItemViewModel(
        id: 'req_1',
        sourceId: '1',
        type: 'word',
        order: 1,
        prompt: 'Word 1',
        state: AdventureNodeState.completed,
        isRequired: true,
      );
      const requiredItem2 = LearningStageItemViewModel(
        id: 'req_2',
        sourceId: '2',
        type: 'word',
        order: 2,
        prompt: 'Word 2',
        state: AdventureNodeState.completed,
        isRequired: true,
      );
      const optionalItem = LearningStageItemViewModel(
        id: 'opt_1',
        sourceId: '3',
        type: 'bonus_phrase',
        order: 3,
        prompt: 'Bonus Phrase',
        state: AdventureNodeState.available,
        isRequired: false, // Optional
      );

      const stage = LearningStageViewModel(
        id: 'stage_test',
        unitId: 'unit_1',
        title: 'Stage with Bonus',
        subtitle: 'Test',
        activityType: LearningStageActivityType.vocabulary,
        learningObjective: 'Vocab',
        items: [requiredItem1, requiredItem2, optionalItem],
        completedItems: 2,
        state: AdventureNodeState.completed,
      );

      expect(stage.totalItems, 3);
      expect(stage.requiredItems.length, 2);
      expect(stage.optionalItems.length, 1);
      expect(stage.areRequiredItemsCompleted, isTrue);
      expect(stage.isCompleted, isTrue);
    });

    test(
        'Boss stage unlocks only when all required stages in the unit are completed',
        () {
      final words = [
        {'id': 1, 'word': '水', 'pinyin': 'shuǐ', 'meaning': 'nước'}
      ];
      final rawBoss = {
        'id': 1,
        'unit_id': 'sec_1_unit_1',
        'stage_order': 5,
        'section_number': 1,
        'unit_number': 1,
        'title': 'Trùm Lửa',
        'question_count': 8,
        'difficulty': 2,
        'boss_name': 'Hỏa Long',
        'boss_hp': 100,
        'player_hp': 100,
        'theme_code': 'fire',
      };

      // 1. When vocab stage is NOT completed -> Boss stage is locked
      final stagesBefore = service.groupStagesForUnit(
        unitId: 'sec_1_unit_1',
        unitTitle: 'Unit with Boss',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
        rawBossStage: rawBoss,
      );

      final bossStageBefore = stagesBefore
          .firstWhere((s) => s.activityType == LearningStageActivityType.boss);
      expect(bossStageBefore.isLocked, isTrue);
      expect(bossStageBefore.state, AdventureNodeState.locked);

      // 2. When vocab stage IS completed -> Boss stage unlocks
      final stagesAfter = service.groupStagesForUnit(
        unitId: 'sec_1_unit_1',
        unitTitle: 'Unit with Boss',
        sectionNumber: 1,
        unitNumber: 1,
        rawWords: words,
        rawCharacters: [],
        rawChallenges: [],
        rawExamples: [],
        rawBossStage: rawBoss,
        wordProgress: {
          1: {'is_completed': true, 'mastery': 1.0, 'score': 100}
        },
      );

      final bossStageAfter = stagesAfter
          .firstWhere((s) => s.activityType == LearningStageActivityType.boss);
      expect(bossStageAfter.isAvailable, isTrue);
      expect(bossStageAfter.state, AdventureNodeState.available);
    });
  });

  group('server-authoritative Stage path', () {
    Map<String, dynamic> node({
      int count = 3,
      int currentIndex = 0,
      int attempts = 0,
      int stars = 0,
      bool unlocked = true,
      bool completed = false,
      bool inProgress = false,
      String? lockReason,
    }) =>
        <String, dynamic>{
          'node_type': 'learning',
          'node_order': 1,
          'unit_id': 'sec_1_unit_1',
          'unit_title': 'Ẩm thực',
          'section_number': 1,
          'unit_number': 1,
          'level_id': 'level_1',
          'game_id': 7,
          'game_code': 'listen_select',
          'game_name': 'Luyện nghe',
          'game_description': 'Nghe và chọn đáp án đúng',
          'challenge_count': count,
          'current_index': currentIndex,
          'attempts': attempts,
          'best_score': completed ? 96 : 62,
          'stars': stars,
          'is_unlocked': unlocked,
          'is_completed': completed,
          'in_progress': inProgress,
          'lock_reason': lockReason,
          'required_node_id': unlocked ? null : '5:level_1',
          'required_mastery': null,
        };

    List<Map<String, dynamic>> challenges(int count) => List.generate(
          count,
          (index) => <String, dynamic>{
            'id': index + 1,
            'session_id': 100,
            '_level_id': 'level_1',
            'type': 'listenTap',
            'prompt': 'Câu ${index + 1}',
          },
        );

    test('segment count comes from the real challenge count', () {
      for (final count in [3, 5, 6]) {
        final stages = service.groupServerPath(
          unitId: 'sec_1_unit_1',
          pathRows: [node(count: count)],
          rawChallenges: challenges(count),
        );

        expect(stages, hasLength(1));
        expect(stages.single.totalItems, count);
        expect(stages.single.sourceGameId, 7);
        expect(stages.single.sourceGameCode, 'listen_select');
      }
    });

    test('resume progress and failed retry state come only from server rows',
        () {
      final resumed = service
          .groupServerPath(
            unitId: 'sec_1_unit_1',
            pathRows: [node(count: 6, currentIndex: 4, inProgress: true)],
            rawChallenges: challenges(6),
          )
          .single;
      expect(resumed.state, AdventureNodeState.inProgress);
      expect(resumed.completedItems, 4);
      expect(resumed.progress, closeTo(4 / 6, .001));

      final failed = service
          .groupServerPath(
            unitId: 'sec_1_unit_1',
            pathRows: [node(attempts: 1)],
            rawChallenges: challenges(3),
          )
          .single;
      expect(failed.state, AdventureNodeState.failed);
      expect(failed.isAvailable, isTrue);
    });

    test('locked dependency and perfect completion are preserved', () {
      final locked = service
          .groupServerPath(
            unitId: 'sec_1_unit_1',
            pathRows: [
              node(unlocked: false, lockReason: 'complete_previous'),
            ],
            rawChallenges: challenges(3),
          )
          .single;
      expect(locked.state, AdventureNodeState.locked);
      expect(locked.lockReason, 'complete_previous');
      expect(locked.requiredStageId, '5:level_1');

      final perfect = service
          .groupServerPath(
            unitId: 'sec_1_unit_1',
            pathRows: [node(completed: true, stars: 3)],
            rawChallenges: challenges(3),
          )
          .single;
      expect(perfect.state, AdventureNodeState.perfect);
      expect(perfect.progress, 1);
      expect(perfect.stars, 3);
    });
  });
}
