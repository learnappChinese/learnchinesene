import '../models/duo_challenge.dart';
import '../models/example_sentence.dart';
import '../models/word.dart';
import 'gameplay_type.dart';

class ChallengeGameplayResolver {
  const ChallengeGameplayResolver();

  GameplayType resolve({
    DuoChallenge? challenge,
    Word? word,
    ExampleSentence? example,
  }) {
    final type = challenge?.type.toLowerCase() ?? '';

    if (type.contains('boss')) return GameplayType.boss;
    if (type.contains('battle')) return GameplayType.miniBattle;
    if (type.contains('speak')) return GameplayType.speaking;
    if (type.contains('dialogue')) return GameplayType.dialogue;
    if (type.contains('hanzi') || type.contains('trace')) {
      return GameplayType.hanziTrace;
    }
    if (type.contains('listen')) return GameplayType.listeningHunt;
    if (type.contains('match')) return GameplayType.memoryMatch;
    if (type.contains('speed')) return GameplayType.speedTap;
    if (challenge?.choicesImage?.any((value) => value.isNotEmpty) == true) {
      return GameplayType.imageMatch;
    }
    if (type.contains('translate') ||
        type.contains('complete') ||
        type.contains('order') ||
        type.contains('gap')) {
      return GameplayType.sentenceBuild;
    }
    if (challenge != null) return GameplayType.multipleChoice;
    if (example != null) return GameplayType.sentenceBuild;
    if (word != null) return GameplayType.discover;

    return GameplayType.multipleChoice;
  }
}
