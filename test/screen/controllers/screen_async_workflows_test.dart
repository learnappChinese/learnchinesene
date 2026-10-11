import 'dart:async';

import 'package:flash_learn_chinese/core/database/db_helper.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_reward_service.dart';
import 'package:flash_learn_chinese/core/models/hanzi_character.dart';
import 'package:flash_learn_chinese/core/models/unit_model.dart';
import 'package:flash_learn_chinese/core/models/word.dart';
import 'package:flash_learn_chinese/core/services/history_service.dart';
import 'package:flash_learn_chinese/screen/boss_battle/controller/boss_stage_map_controller.dart';
import 'package:flash_learn_chinese/screen/boss_battle/model/boss_battle_stage.dart';
import 'package:flash_learn_chinese/screen/dictionary/controller/dictionary_controller.dart';
import 'package:flash_learn_chinese/screen/flashcards/controller/flashcards_controller.dart';
import 'package:flash_learn_chinese/screen/hanzi_writing/controller/hanzi_writing_home_controller.dart';
import 'package:flash_learn_chinese/screen/hanzi_writing/controller/hanzi_writing_controller.dart';
import 'package:flash_learn_chinese/screen/hanzi_writing/models/hanzi_practice_config.dart';
import 'package:flash_learn_chinese/screen/hsk_quiz/controller/hsk_quiz_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Database implements DbHelper {
  Future<List<Word>> review = Future.value([]);
  final units = <int, Future<List<UnitModel>>>{};
  final words = <int, List<Word>>{};
  final searches = <String?, Future<List<HanziCharacter>>>{};
  final ratings = <(int, bool)>[];
  Future<HanziCharacter?> character = Future.value(null);

  @override
  Future<HanziCharacter?> getCharacterForWritingById(int id) => character;

  @override
  Future<List<Word>> getReviewWords() => review;

  @override
  Future<List<UnitModel>> getUnitsByLevel(int level) =>
      units[level] ?? Future.value([]);

  @override
  Future<List<Word>> getWordsByUnit(int unit) async => words[unit] ?? [];

  @override
  Future<List<HanziCharacter>> getCharactersForWriting(
          {String? keyword, int? hskLevel}) =>
      searches[keyword] ?? Future.value([]);

  @override
  Future<void> upsertProgress(
      {required int wordId, required bool isCorrect, int level = 1}) async {
    ratings.add((wordId, isCorrect));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LearningProgressRepository implements LearningProgressRepository {
  final completions = <LearningActivitySubmission>[];

  @override
  Future<LearningResult> completeActivity(
    LearningActivitySubmission submission,
  ) async {
    completions.add(submission);
    return LearningResult.fromMap(<String, dynamic>{
      ...submission.toJson(),
      'passed': true,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<dynamic> _vocabulary() => List.generate(
    40,
    (i) => {
          'hanzi': '字$i',
          'meaning_vi': 'Nghĩa $i',
          'pinyin': 'pinyin $i',
        });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async => Get.reset());

  test('Dictionary saves only the latest lookup and trims the query', () async {
    final older = Completer<Map<String, dynamic>>();
    final newer = Completer<Map<String, dynamic>>();
    final history = <HistoryItem>[];
    final queries = <String>[];
    final controller = Get.put(DictionaryController(
      lookup: (query) {
        queries.add(query);
        return query == '旧' ? older.future : newer.future;
      },
      saveHistory: (item) async => history.add(item),
    ));
    final first = controller.search('旧');
    final second = controller.search(' 新 ');
    newer.complete({'hanzi': '新'});
    await second;
    older.completeError(StateError('Old request failed'));
    await first;
    expect(queries, ['旧', '新']);
    expect(controller.entry.value, {'hanzi': '新'});
    expect(history.single.content, {'hanzi': '新'});
    expect(controller.error.value, isEmpty);
    expect(controller.isLoading.value, isFalse);
  });

  test('Dictionary failure clears loading and an empty query does nothing',
      () async {
    var calls = 0;
    final controller = Get.put(DictionaryController(
      lookup: (_) async {
        calls++;
        throw StateError('Network');
      },
      saveHistory: (_) async {},
    ));
    await controller.search(' ');
    expect(calls, 0);
    await controller.search('字');
    expect(controller.error.value, isNotEmpty);
    expect(controller.entry.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test(
      'Closing a dictionary instance ignores its pending result and retains other instances',
      () async {
    final pending = Completer<Map<String, dynamic>>();
    final history = <HistoryItem>[];
    DictionaryController create() => DictionaryController(
          lookup: (_) => pending.future,
          saveHistory: (item) async => history.add(item),
        );
    final first = Get.put(create(), tag: 'first');
    final second = Get.put(create(), tag: 'second');
    final load = first.search('字');
    await Get.delete<DictionaryController>(tag: 'first');
    pending.complete({'hanzi': '字'});
    await load;
    expect(first.isClosed, isTrue);
    expect(first.entry.value, isNull);
    expect(history, isEmpty);
    expect(Get.find<DictionaryController>(tag: 'second'), same(second));
    expect(second.isClosed, isFalse);
  });

  test('Flashcards cap a shuffled deck without changing the source list',
      () async {
    final database = _Database();
    final source = List.generate(40, (i) => Word.fromMap({'id': i}));
    database.review = Future.value(source);
    final controller = Get.put(FlashcardsController(database: database));
    await controller.loadDeck(0);
    expect(controller.deck, hasLength(30));
    expect(controller.deck.map((word) => word.id).toSet(), hasLength(30));
    expect(source.map((word) => word.id),
        orderedEquals(List.generate(40, (i) => i)));
    expect(controller.isLoading.value, isFalse);
  });

  test('Changing the flashcard level ignores a previous review response',
      () async {
    final database = _Database();
    final pending = Completer<List<Word>>();
    database.review = pending.future;
    database.units[2] =
        Future.value([const UnitModel(id: 2, title: 'Bài 2', order: 1)]);
    database.words[2] = [
      Word.fromMap({'id': 2})
    ];
    final controller = Get.put(FlashcardsController(database: database));
    final older = controller.loadDeck(0);
    await controller.loadDeck(2);
    pending.complete([
      Word.fromMap({'id': 1})
    ]);
    await older;
    expect(controller.deck.single.id, 2);
    expect(controller.isLoading.value, isFalse);
  });

  test(
      'Flashcard failures and empty levels finish with the existing empty state',
      () async {
    final database = _Database();
    final controller = Get.put(FlashcardsController(database: database));
    await controller.loadDeck(1);
    expect(controller.deck, isEmpty);
    database.review = Future.error(StateError('Offline'));
    await controller.loadDeck(0);
    expect(controller.deck, isEmpty);
    expect(controller.isLoading.value, isFalse);
  });

  test('Flashcard ratings preserve progress and closing ignores a pending deck',
      () async {
    final database = _Database();
    final pending = Completer<List<Word>>();
    database.review = pending.future;
    final controller = Get.put(FlashcardsController(database: database));
    final word = Word.fromMap({'id': 1});
    for (final rating in ['hard', 'good', 'easy']) {
      await controller.rate(word, rating);
    }
    expect(database.ratings, [(1, false), (1, true), (1, true)]);
    final load = controller.loadDeck(0);
    await Get.delete<FlashcardsController>();
    pending.complete([word]);
    await load;
    await controller.rate(word, 'easy');
    expect(controller.deck, isEmpty);
    expect(database.ratings, hasLength(3));
  });

  test('Writing search discards a result invalidated during debounce',
      () async {
    final database = _Database();
    final pending = Completer<List<HanziCharacter>>();
    database.searches['old'] = pending.future;
    database.searches['new'] = Future.value([
      HanziCharacter.fromMap({'id': 2, 'character': '新'})
    ]);
    final controller = Get.put(HanziWritingHomeController(database: database));
    final older = controller.loadCharacters(keyword: 'old');
    controller.invalidateSearch();
    pending.complete([
      HanziCharacter.fromMap({'id': 1, 'character': '旧'})
    ]);
    await older;
    expect(controller.characters, isEmpty);
    await controller.loadCharacters(keyword: 'new');
    expect(controller.characters.single.character, '新');
    expect(controller.isLoading.value, isFalse);
  });

  test(
      'Writing search preserves the current list on failure and supports empty results',
      () async {
    final database = _Database();
    database.searches['字'] = Future.value([
      HanziCharacter.fromMap({'id': 1})
    ]);
    final controller = Get.put(HanziWritingHomeController(database: database));
    await controller.loadCharacters(keyword: '字');
    database.searches['error'] = Future.error(StateError('Offline'));
    await controller.loadCharacters(keyword: 'error');
    expect(controller.characters.single.id, 1);
    expect(controller.isLoading.value, isFalse);
    await controller.loadCharacters(keyword: '');
    expect(controller.characters, isEmpty);
  });

  test('Closing writing search ignores a pending load', () async {
    final database = _Database();
    final pending = Completer<List<HanziCharacter>>();
    database.searches[null] = pending.future;
    final controller = Get.put(HanziWritingHomeController(database: database));
    final load = controller.loadCharacters(keyword: '');
    await Get.delete<HanziWritingHomeController>();
    pending.complete([
      HanziCharacter.fromMap({'id': 1})
    ]);
    await load;
    expect(controller.isClosed, isTrue);
    expect(controller.characters, isEmpty);
  });

  test('HSK quiz records each answer once and finishes all ten questions',
      () async {
    final controller =
        Get.put(HskQuizController(loadVocabulary: (_) async => _vocabulary()));
    await controller.generate(1);
    controller.nextQuestion();
    expect(controller.currentIndex.value, 0);
    for (var i = 0; i < 10; i++) {
      final answer = controller.questions[i]['correctAnswer'] as String;
      controller.answer(answer);
      controller.answer('Duplicate');
      expect(controller.userAnswers[i], answer);
      controller.nextQuestion();
    }
    expect(controller.state.value, QuizState.finished);
    expect(controller.score.value, 10);
    controller.answer('After finishing');
    expect(controller.score.value, 10);
    await controller.generate(1);
    expect(controller.score.value, 0);
    expect(controller.userAnswers.every((answer) => answer == null), isTrue);
    expect(controller.state.value, QuizState.playing);
  });

  test(
      'HSK quiz ignores duplicate loading and exposes failures without starting',
      () async {
    final pending = Completer<List<dynamic>>();
    var calls = 0;
    final controller = Get.put(HskQuizController(loadVocabulary: (_) {
      calls++;
      return pending.future;
    }));
    final load = controller.generate(1);
    await controller.generate(2);
    expect(calls, 1);
    pending.complete([]);
    await load;
    expect(controller.state.value, QuizState.setup);
    expect(controller.error.value, isNotNull);
    expect(controller.isLoading.value, isFalse);
    expect(controller.questions, isEmpty);
  });

  test('Closing HSK quiz ignores pending vocabulary', () async {
    final pending = Completer<List<dynamic>>();
    final controller =
        Get.put(HskQuizController(loadVocabulary: (_) => pending.future));
    final load = controller.generate(1);
    await Get.delete<HskQuizController>();
    pending.complete(_vocabulary());
    await load;
    expect(controller.isClosed, isTrue);
    expect(controller.questions, isEmpty);
    expect(controller.state.value, QuizState.setup);
  });

  test('Writing session saves the average score and sum of attempts', () async {
    final database = _Database();
    final progress = _LearningProgressRepository();
    final controller = Get.put(HanziWritingController(
      database: database,
      rewardService: LearningRewardService(repository: progress),
    ));
    await controller.saveProgress(7, const [
      HanziRoundResult(
          roundNumber: 1,
          mode: HanziPracticeMode.guidedTrace,
          drawnStrokeCount: 3,
          attemptCount: 4,
          score: 80,
          durationMilliseconds: 10),
      HanziRoundResult(
          roundNumber: 2,
          mode: HanziPracticeMode.fromScratch,
          drawnStrokeCount: 3,
          attemptCount: 5,
          score: 100,
          durationMilliseconds: 20),
    ]);
    await controller.saveProgress(7, []);
    expect(progress.completions, hasLength(2));
    expect(progress.completions[0].sourceId, '7');
    expect(progress.completions[0].hanziScore, 90);
    expect(progress.completions[0].metadata['practice_attempts'], 9);
    expect(progress.completions[1].hanziScore, 0);
    expect(progress.completions[1].metadata['practice_attempts'], 0);
    await Get.delete<HanziWritingController>();
    await controller.saveProgress(7, []);
    expect(progress.completions, hasLength(2));
  });

  test(
      'Writing session distinguishes the next character, end and empty catalog',
      () async {
    final database = _Database();
    database.searches[null] = Future.value([
      HanziCharacter.fromMap({'id': 3}),
      HanziCharacter.fromMap({'id': 7}),
    ]);
    final controller = Get.put(HanziWritingController(database: database));
    expect(await controller.nextCharacter(3), (id: 7, hasCharacters: true));
    expect(await controller.nextCharacter(7), (id: null, hasCharacters: true));
    database.searches[null] = Future.value([]);
    expect(await controller.nextCharacter(3), (id: null, hasCharacters: false));
  });

  test('Writing session cannot return a character after closing', () async {
    final database = _Database();
    final pending = Completer<HanziCharacter?>();
    database.character = pending.future;
    final controller = Get.put(HanziWritingController(database: database));
    final load = controller.loadCharacter(3);
    await Get.delete<HanziWritingController>();
    pending.complete(HanziCharacter.fromMap({'id': 3}));
    expect(await load, isNull);
  });

  test(
      'Boss stage catalog reuses its future until retry and stops after closing',
      () async {
    var calls = 0;
    final controller = Get.put(BossStageMapController(loadStages: () async {
      calls++;
      return <BossBattleStage>[];
    }));
    final first = controller.stages;
    expect(await first, isEmpty);
    expect(controller.stages, same(first));
    expect(calls, 1);
    controller.reload();
    await controller.stages;
    expect(calls, 2);
    await Get.delete<BossStageMapController>();
    controller.reload();
    expect(calls, 2);
  });
}
