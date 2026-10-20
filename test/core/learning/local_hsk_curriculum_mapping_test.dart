import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pandarin/core/database/app_database.dart';
import 'package:pandarin/core/learning/data/guest_learning_progress_store.dart';
import 'package:pandarin/core/learning/data/learning_journey_repository.dart';
import 'package:pandarin/core/learning/model/learning_source_context.dart';
import 'package:pandarin/core/learning/model/learning_stage_models.dart';
import 'package:pandarin/core/learning/service/learning_session_composer.dart';
import 'package:pandarin/core/widgets/adventure_node.dart';
import 'package:pandarin/features/vocabulary_adventure/data/vocabulary_adventure_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDb;
  late GuestLearningProgressStore guestStore;
  late SupabaseLearningJourneyRepository journeyRepo;
  late LearningSessionComposer sessionComposer;
  late SupabaseVocabularyAdventureRepository vocabRepo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});

    appDb = AppDatabase.instance;
    await appDb.init(customPath: inMemoryDatabasePath);

    // Seed bundled curriculum pack
    final packFile = File('assets/data/hsk_curriculum_pack_v1.json');
    if (packFile.existsSync()) {
      final jsonString = await packFile.readAsString();
      await appDb.ensureContentPackSeeded(jsonOverride: jsonString);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    guestStore = GuestLearningProgressStore();

    journeyRepo = SupabaseLearningJourneyRepository(
      guestStore: guestStore,
    );

    sessionComposer = LearningSessionComposer();
    vocabRepo = SupabaseVocabularyAdventureRepository();
  });

  tearDownAll(() async {
    await appDb.close();
  });

  group('Slice 3 — Local HSK Curriculum Mapping & Offline Learning Flow', () {
    test('1. Database has bundled HSK 1-4 curriculum content', () async {
      final levels = await appDb.getHskLevels();
      expect(levels.length, equals(4), reason: 'Phải có 4 cấp độ HSK 1-4');

      final hsk1Units = await appDb.getUnitsByHskLevel(1);
      expect(hsk1Units.length, equals(10), reason: 'HSK 1 có 10 bài học');

      final unit1Words = await appDb.getWordsByUnit(1);
      expect(unit1Words, isNotEmpty, reason: 'Bài 1 phải có danh sách từ vựng');
    });

    test('2. getSections() returns HSK 1-4 sections offline with sequential unlock',
        () async {
      final sections = await journeyRepo.getSections();
      expect(sections.length, equals(4));

      // Section 1 (HSK 1) is unlocked by default
      expect(sections[0].sectionNumber, equals(1));
      expect(sections[0].isUnlocked, isTrue);
      expect(sections[0].unitCount, equals(10));

      // Section 2 is initially locked
      expect(sections[1].sectionNumber, equals(2));
      expect(sections[1].isUnlocked, isFalse);
    });

    test('3. getUnits() returns units with Unit 1 unlocked and Unit 2 locked initially',
        () async {
      final units = await journeyRepo.getUnits('section_hsk_1');
      expect(units.length, equals(10));

      expect(units[0].unitNumber, equals(1));
      expect(units[0].isUnlocked, isTrue, reason: 'Bài 1 phải mở sẵn cho người học');

      expect(units[1].unitNumber, equals(2));
      expect(units[1].isUnlocked, isFalse, reason: 'Bài 2 phải khóa cho đến khi hạ gục Boss Bài 1');
    });

    test('4. getUnitStages() returns 4 canonical stages (Vocab, Hanzi, Speaking, Boss)',
        () async {
      final stages = await journeyRepo.getUnitStages('1');
      expect(stages.length, equals(4));

      // Stage 1: Vocabulary
      expect(stages[0].activityType, equals(LearningStageActivityType.vocabulary));
      expect(stages[0].state, equals(AdventureNodeState.available));
      expect(stages[0].items, isNotEmpty);

      // Stage 2: Hanzi
      expect(stages[1].activityType, equals(LearningStageActivityType.hanzi));
      expect(stages[1].state, equals(AdventureNodeState.locked));

      // Stage 3: Speaking
      expect(stages[2].activityType, equals(LearningStageActivityType.speaking));
      expect(stages[2].state, equals(AdventureNodeState.locked));

      // Stage 4: Boss
      expect(stages[3].activityType, equals(LearningStageActivityType.boss));
      expect(stages[3].state, equals(AdventureNodeState.locked));
      expect(stages[3].bossStage, isNotNull);
    });

    test('5. Sequential stage completion unlocks next stages and defeats Boss to unlock Unit 2',
        () async {
      // Step 1: Complete Stage 1 (Vocabulary)
      await guestStore.recordStagePassed(
        gameId: 1,
        levelId: '1_stage_1',
        score: 100,
        stars: 3,
        unitId: '1',
      );

      var stages = await journeyRepo.getUnitStages('1');
      expect(stages[0].isCompleted, isTrue);
      expect(stages[1].state, equals(AdventureNodeState.available),
          reason: 'Hoàn thành Ải 1 phải mở khóa Ải 2 (Hanzi)');

      // Step 2: Complete Stage 2 (Hanzi)
      await guestStore.recordStagePassed(
        gameId: 2,
        levelId: '1_stage_2',
        score: 100,
        stars: 3,
        unitId: '1',
      );

      stages = await journeyRepo.getUnitStages('1');
      expect(stages[1].isCompleted, isTrue);
      expect(stages[2].state, equals(AdventureNodeState.available),
          reason: 'Hoàn thành Ải 2 phải mở khóa Ải 3 (Speaking)');

      // Step 3: Complete Stage 3 (Speaking)
      await guestStore.recordStagePassed(
        gameId: 3,
        levelId: '1_stage_3',
        score: 100,
        stars: 3,
        unitId: '1',
      );

      stages = await journeyRepo.getUnitStages('1');
      expect(stages[2].isCompleted, isTrue);
      expect(stages[3].state, equals(AdventureNodeState.available),
          reason: 'Hoàn thành 3 ải đầu phải mở Cổng Boss');

      // Step 4: Defeat Boss of Unit 1
      await guestStore.recordBossWon(
        unitId: '1',
        stageId: 1,
        score: 100,
        stars: 3,
      );

      stages = await journeyRepo.getUnitStages('1');
      expect(stages[3].isCompleted, isTrue);

      // Verify Unit 2 is now UNLOCKED!
      final units = await journeyRepo.getUnits('section_hsk_1');
      expect(units[0].bossWon, isTrue, reason: 'Boss Bài 1 đã bị đánh bại');
      expect(units[1].isUnlocked, isTrue,
          reason: 'Hạ Boss Bài 1 phải tự động mở khóa Bài 2');
    });

    test('6. LearningSessionComposer synthesizes offline challenges without ContentUnavailableException',
        () async {
      // Test learn_words
      final vocabContext = LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: '1',
        levelId: '1_stage_1',
        gameCode: 'learn_words',
        mode: LearningMode.duoMission,
      );
      final vocabSession = await sessionComposer.composeSession(
        sourceContext: vocabContext,
        gameId: 1,
      );
      expect(vocabSession.items, isNotEmpty);
      expect(vocabSession.items.first.type, equals('flashcard'));

      // Test select_answer (quiz)
      final quizContext = LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: '1',
        levelId: '1_stage_quiz',
        gameCode: 'select_answer',
        mode: LearningMode.duoMission,
      );
      final quizSession = await sessionComposer.composeSession(
        sourceContext: quizContext,
        gameId: 3,
      );
      expect(quizSession.items, isNotEmpty);
      expect(quizSession.items.first.type, equals('select'));

      // Test word_connect
      final matchContext = LearningSourceContext(
        courseId: 'duo_chinese',
        duoUnitId: '1',
        levelId: '1_stage_match',
        gameCode: 'word_connect',
        mode: LearningMode.duoMission,
      );
      final matchSession = await sessionComposer.composeSession(
        sourceContext: matchContext,
        gameId: 2,
      );
      expect(matchSession.items, isNotEmpty);
      expect(matchSession.items.first.type, equals('pair'));
    });

    test('7. VocabularyAdventureRepository loads mission from local SQLite words offline',
        () async {
      final mission = await vocabRepo.loadMission(
        levelId: '1_stage_1',
        gameId: 1,
      );
      expect(mission, isNotNull);
      expect(mission!.words, isNotEmpty);
      expect(mission.events, isNotEmpty);
      expect(mission.title, contains('Bài 1'));
    });
  });
}
