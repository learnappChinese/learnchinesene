import '../../../core/gameplay/challenge_gameplay_resolver.dart';
import '../../../core/gameplay/gameplay_type.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/models/example_sentence.dart';
import '../../../core/models/word.dart';

enum VocabularyStage { discover, recognize, recall, use }

enum VocabularyAnswerFeedback { correct, wrong }

class VocabularyWordProgress {
  const VocabularyWordProgress({
    this.correctCount = 0,
    this.wrongCount = 0,
    this.mastered = false,
    this.nextReviewAt,
  });

  final int correctCount;
  final int wrongCount;
  final bool mastered;
  final DateTime? nextReviewAt;
}

class VocabularyMissionWord {
  const VocabularyMissionWord({
    required this.word,
    required this.sourceChallenge,
    required this.examples,
    required this.progress,
    this.imageUrl,
  });

  final Word word;
  final DuoChallenge sourceChallenge;
  final List<ExampleSentence> examples;
  final VocabularyWordProgress progress;
  final String? imageUrl;
}

class VocabularyGameplayEvent {
  const VocabularyGameplayEvent({
    required this.id,
    required this.stage,
    required this.gameplayType,
    required this.missionWord,
    required this.prompt,
    required this.correctAnswer,
    this.choices = const [],
    this.example,
  });

  final String id;
  final VocabularyStage stage;
  final GameplayType gameplayType;
  final VocabularyMissionWord missionWord;
  final String prompt;
  final String correctAnswer;
  final List<String> choices;
  final ExampleSentence? example;

  Word get word => missionWord.word;
  bool get isDiscovery => stage == VocabularyStage.discover;

  int get xpReward => switch (stage) {
        VocabularyStage.discover => 3,
        VocabularyStage.recognize => 8,
        VocabularyStage.recall => 12,
        VocabularyStage.use => 16,
      };

  int get masteryLevel => switch (stage) {
        VocabularyStage.discover => 0,
        VocabularyStage.recognize => 1,
        VocabularyStage.recall => 2,
        VocabularyStage.use => 3,
      };

  String get stageLabel => switch (stage) {
        VocabularyStage.discover => 'KHÁM PHÁ',
        VocabularyStage.recognize => 'NHẬN DIỆN',
        VocabularyStage.recall => 'GỢI NHỚ',
        VocabularyStage.use => 'VẬN DỤNG',
      };

  String get instruction => switch (stage) {
        VocabularyStage.discover => 'Nghe và khám phá từ mới',
        VocabularyStage.recognize => 'Chọn nghĩa đúng của từ',
        VocabularyStage.recall => 'Gọi lại chữ Hán từ nghĩa',
        VocabularyStage.use => 'Chọn từ phù hợp với câu',
      };

  String get explanation =>
      '${word.chinese} (${word.pinyin}) nghĩa là “${word.vietnamese}”.';
}

class VocabularyMission {
  const VocabularyMission({
    required this.levelId,
    required this.gameId,
    required this.title,
    required this.objective,
    required this.words,
    required this.events,
  });

  final String levelId;
  final int gameId;
  final String title;
  final String objective;
  final List<VocabularyMissionWord> words;
  final List<VocabularyGameplayEvent> events;
}

class VocabularyRunSnapshot {
  const VocabularyRunSnapshot({
    required this.currentIndex,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
  });

  final int currentIndex;
  final int score;
  final int correctCount;
  final int wrongCount;
}

class VocabularyMasteryUpdate {
  const VocabularyMasteryUpdate({required this.mastered});

  final bool mastered;
}

class VocabularyEventBuilder {
  const VocabularyEventBuilder({
    this.resolver = const ChallengeGameplayResolver(),
  });

  final ChallengeGameplayResolver resolver;

  List<VocabularyGameplayEvent> build(List<VocabularyMissionWord> words) {
    if (words.length < 2) return const [];

    final events = <VocabularyGameplayEvent>[];
    for (var offset = 0; offset < words.length; offset += 2) {
      final end = (offset + 2).clamp(0, words.length);
      final round = words.sublist(offset, end);

      for (final item in round) {
        events.add(_discover(item));
      }
      for (final item in round) {
        events.add(_recognize(item, words));
      }
      for (final item in round) {
        events.add(_recall(item, words));
      }
      for (final item in round) {
        if (item.examples.isNotEmpty) {
          events.add(_use(item, words));
        }
      }
    }
    return events;
  }

  VocabularyGameplayEvent _discover(VocabularyMissionWord item) =>
      VocabularyGameplayEvent(
        id: '${item.word.id}-discover',
        stage: VocabularyStage.discover,
        gameplayType: resolver.resolve(word: item.word),
        missionWord: item,
        prompt: item.word.chinese,
        correctAnswer: item.word.chinese,
      );

  VocabularyGameplayEvent _recognize(
    VocabularyMissionWord item,
    List<VocabularyMissionWord> pool,
  ) =>
      VocabularyGameplayEvent(
        id: '${item.word.id}-recognize',
        stage: VocabularyStage.recognize,
        gameplayType: resolver.resolve(
          challenge: item.sourceChallenge,
          word: item.word,
        ),
        missionWord: item,
        prompt: item.word.chinese,
        correctAnswer: item.word.vietnamese,
        choices: _choices(
          correct: item.word.vietnamese,
          candidates: pool.map((value) => value.word.vietnamese),
          seed: item.word.id,
        ),
      );

  VocabularyGameplayEvent _recall(
    VocabularyMissionWord item,
    List<VocabularyMissionWord> pool,
  ) =>
      VocabularyGameplayEvent(
        id: '${item.word.id}-recall',
        stage: VocabularyStage.recall,
        gameplayType: resolver.resolve(
          challenge: item.sourceChallenge,
          word: item.word,
        ),
        missionWord: item,
        prompt: item.word.vietnamese,
        correctAnswer: item.word.chinese,
        choices: _choices(
          correct: item.word.chinese,
          candidates: pool.map((value) => value.word.chinese),
          seed: item.word.id + 1,
        ),
      );

  VocabularyGameplayEvent _use(
    VocabularyMissionWord item,
    List<VocabularyMissionWord> pool,
  ) {
    final example = item.examples.first;
    final sentence = example.chinese.contains(item.word.chinese)
        ? example.chinese.replaceAll(item.word.chinese, '＿＿')
        : example.chinese;
    return VocabularyGameplayEvent(
      id: '${item.word.id}-use',
      stage: VocabularyStage.use,
      gameplayType: resolver.resolve(word: item.word, example: example),
      missionWord: item,
      prompt: sentence,
      correctAnswer: item.word.chinese,
      choices: _choices(
        correct: item.word.chinese,
        candidates: pool.map((value) => value.word.chinese),
        seed: item.word.id + 2,
      ),
      example: example,
    );
  }

  List<String> _choices({
    required String correct,
    required Iterable<String> candidates,
    required int seed,
  }) {
    final unique = <String>{
      correct,
      ...candidates.where((value) => value.isNotEmpty)
    }.take(4).toList();
    if (unique.length < 2) return unique;

    final rotation = seed.abs() % unique.length;
    return [...unique.skip(rotation), ...unique.take(rotation)];
  }
}
