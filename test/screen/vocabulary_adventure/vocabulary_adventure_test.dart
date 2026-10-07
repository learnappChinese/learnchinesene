import 'dart:async';

import 'package:flash_learn_chinese/core/models/duo_challenge.dart';
import 'package:flash_learn_chinese/core/models/example_sentence.dart';
import 'package:flash_learn_chinese/core/models/word.dart';
import 'package:flash_learn_chinese/screen/vocabulary_adventure/controller/vocabulary_adventure_controller.dart';
import 'package:flash_learn_chinese/screen/vocabulary_adventure/data/vocabulary_adventure_repository.dart';
import 'package:flash_learn_chinese/screen/vocabulary_adventure/model/vocabulary_adventure.dart';
import 'package:flash_learn_chinese/screen/vocabulary_adventure/service/vocabulary_audio_service.dart';
import 'package:flash_learn_chinese/screen/vocabulary_adventure/widget/vocabulary_feedback_panel.dart';
import 'package:flash_learn_chinese/screen/vocabulary_adventure/widget/vocabulary_gameplay_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  test('event builder paces Discover, Recognize, Recall and Use in pairs', () {
    final mission = _mission();
    expect(
      mission.events.map((event) => event.stage),
      [
        VocabularyStage.discover,
        VocabularyStage.discover,
        VocabularyStage.recognize,
        VocabularyStage.recognize,
        VocabularyStage.recall,
        VocabularyStage.recall,
        VocabularyStage.use,
        VocabularyStage.use,
      ],
    );
    expect(
      mission.events
          .where((event) => !event.isDiscovery)
          .every((event) => event.choices.length >= 2),
      isTrue,
    );
  });

  test('controller only increases mastery on correct Recall and Use', () async {
    final repository = _FakeRepository(mission: _mission());
    final controller = _controller(repository);
    await controller.loadMission();
    controller.startMission();

    await controller.completeDiscovery();
    await controller.completeDiscovery();

    final recognize = controller.currentEvent!;
    controller.submitAnswer('sai');
    await _flush();
    expect(repository.outcomes.single.isCorrect, isFalse);
    controller.retryCurrent();
    controller.submitAnswer(recognize.correctAnswer);
    await _flush();
    expect(repository.outcomes, hasLength(1));
    await controller.continueAfterFeedback();

    final secondRecognize = controller.currentEvent!;
    controller.submitAnswer(secondRecognize.correctAnswer);
    await _flush();
    expect(repository.outcomes, hasLength(1));
    await controller.continueAfterFeedback();

    final recall = controller.currentEvent!;
    controller.submitAnswer(recall.correctAnswer);
    await _flush();
    expect(repository.outcomes.last.masteryLevel, 2);
    expect(repository.outcomes.last.isCorrect, isTrue);
  });

  test('controller completes a full mission and preserves cloud run updates',
      () async {
    final repository = _FakeRepository(mission: _mission());
    final controller = _controller(repository);
    await controller.loadMission();
    controller.startMission();

    while (!controller.isCompleted.value) {
      final event = controller.currentEvent!;
      if (event.isDiscovery) {
        await controller.completeDiscovery();
      } else {
        controller.submitAnswer(event.correctAnswer);
        await _flush();
        await controller.continueAfterFeedback();
      }
    }

    expect(repository.completions, 1);
    expect(repository.savedRuns, isNotEmpty);
    expect(controller.stars, 3);
    expect(controller.bestCombo.value, 6);
    expect(controller.masteredWords.value, 2);
  });

  test('controller exposes empty and error states', () async {
    final emptyRepository = _FakeRepository(mission: null);
    final emptyController = _controller(emptyRepository);
    await emptyController.loadMission();
    expect(emptyController.mission.value, isNull);
    expect(emptyController.errorMessage.value, isNull);

    final errorRepository = _FakeRepository(
      mission: _mission(),
      loadError: StateError('offline'),
    );
    final errorController = _controller(errorRepository);
    await errorController.loadMission();
    expect(errorController.errorMessage.value, isNotNull);
    expect(errorController.isLoading.value, isFalse);
  });

  test('route-owned controller ignores a repository response after disposal',
      () async {
    final completer = Completer<VocabularyMission?>();
    final repository = _FakeRepository(
      mission: _mission(),
      missionCompleter: completer,
    );
    final controller = Get.put(_controller(repository));
    await _flush();
    await Get.delete<VocabularyAdventureController>();

    completer.complete(_mission());
    await _flush();

    expect(controller.mission.value, isNull);
    expect(repository.audio.disposed, isTrue);
  });

  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('gameplay and feedback fit ${width.toInt()}px', (tester) async {
      final event = _mission().events.last;
      await tester.binding.setSurfaceSize(Size(width, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: VocabularyGameplayCard(
                      event: event,
                      selectedAnswer: event.correctAnswer,
                      feedback: VocabularyAnswerFeedback.correct,
                      onAnswer: (_) {},
                      onSpeak: () {},
                      onSpeakSlow: () {},
                      onCompleteDiscovery: () {},
                    ),
                  ),
                ),
                VocabularyFeedbackPanel(
                  feedback: VocabularyAnswerFeedback.correct,
                  event: event,
                  combo: 5,
                  isBusy: false,
                  onContinue: () {},
                  onRetry: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('PERFECT!  +16 XP'), findsOneWidget);
    });
  }
}

VocabularyAdventureController _controller(_FakeRepository repository) =>
    VocabularyAdventureController(
      levelId: 'level-1',
      gameId: 1,
      gameName: 'Từ vựng',
      repository: repository,
      audioService: repository.audio,
    );

VocabularyMission _mission() {
  final words = [
    _missionWord(
      id: 1,
      chinese: '茶',
      pinyin: 'chá',
      vietnamese: 'Trà',
      sentence: '我要一杯茶。',
    ),
    _missionWord(
      id: 2,
      chinese: '水',
      pinyin: 'shuǐ',
      vietnamese: 'Nước',
      sentence: '我喝水。',
    ),
  ];
  return VocabularyMission(
    levelId: 'level-1',
    gameId: 1,
    title: 'Nhà hàng',
    objective: 'Gọi tên đồ uống',
    words: words,
    events: const VocabularyEventBuilder().build(words),
  );
}

VocabularyMissionWord _missionWord({
  required int id,
  required String chinese,
  required String pinyin,
  required String vietnamese,
  required String sentence,
}) {
  final challenge = DuoChallenge(
    id: 'challenge-$id',
    type: 'select',
    prompt: vietnamese,
    choicesText: [chinese, id == 1 ? '水' : '茶'],
    choicesCorrect: const [1, 0],
  );
  return VocabularyMissionWord(
    word: Word(
      id: id,
      chinese: chinese,
      pinyin: pinyin,
      vietnamese: vietnamese,
      english: '',
      ttsUrl: '',
      hskLevelId: 1,
      sectionTitle: 'HSK 1',
      groupSubtitle: 'Đồ uống',
    ),
    sourceChallenge: challenge,
    examples: [
      ExampleSentence(
        id: id,
        wordId: id,
        chinese: sentence,
        pinyin: '',
        vietnamese: 'Ví dụ $vietnamese',
        order: 1,
      ),
    ],
    progress: const VocabularyWordProgress(),
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _Outcome {
  const _Outcome(this.wordId, this.isCorrect, this.masteryLevel);

  final int wordId;
  final bool isCorrect;
  final int masteryLevel;
}

class _FakeRepository implements VocabularyAdventureRepository {
  _FakeRepository({
    required this.mission,
    this.loadError,
    this.missionCompleter,
  });

  final VocabularyMission? mission;
  final Object? loadError;
  final Completer<VocabularyMission?>? missionCompleter;
  final audio = _FakeAudioService();
  final outcomes = <_Outcome>[];
  final savedRuns = <VocabularyRunSnapshot>[];
  int completions = 0;

  @override
  Future<VocabularyMission?> loadMission({
    required String levelId,
    required int gameId,
  }) async {
    if (loadError != null) throw loadError!;
    return missionCompleter?.future ?? mission;
  }

  @override
  Future<VocabularyRunSnapshot?> loadActiveRun({
    required String levelId,
    required int gameId,
  }) async =>
      null;

  @override
  Future<void> saveActiveRun({
    required String levelId,
    required int gameId,
    required VocabularyRunSnapshot snapshot,
  }) async {
    savedRuns.add(snapshot);
  }

  @override
  Future<VocabularyMasteryUpdate?> recordWordOutcome({
    required int wordId,
    required bool isCorrect,
    required int masteryLevel,
  }) async {
    outcomes.add(_Outcome(wordId, isCorrect, masteryLevel));
    return VocabularyMasteryUpdate(
      mastered: isCorrect && masteryLevel >= 3,
    );
  }

  @override
  Future<void> completeMission({
    required String levelId,
    required int gameId,
    required int score,
    required int stars,
  }) async {
    completions++;
  }
}

class _FakeAudioService implements VocabularyAudioService {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }

  @override
  Future<void> speak(String text, {bool slow = false}) async {}

  @override
  Future<void> stop() async {}
}
