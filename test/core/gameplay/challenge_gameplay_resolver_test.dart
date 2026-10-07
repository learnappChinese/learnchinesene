import 'package:flash_learn_chinese/core/gameplay/challenge_gameplay_resolver.dart';
import 'package:flash_learn_chinese/core/gameplay/gameplay_type.dart';
import 'package:flash_learn_chinese/core/models/duo_challenge.dart';
import 'package:flash_learn_chinese/core/models/example_sentence.dart';
import 'package:flash_learn_chinese/core/models/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = ChallengeGameplayResolver();
  const word = Word(
    id: 1,
    chinese: '茶',
    pinyin: 'chá',
    vietnamese: 'Trà',
    english: 'Tea',
    ttsUrl: '',
    hskLevelId: 1,
    sectionTitle: 'HSK 1',
    groupSubtitle: 'Đồ uống',
  );
  const example = ExampleSentence(
    id: 1,
    wordId: 1,
    chinese: '我要一杯茶。',
    pinyin: 'Wǒ yào yì bēi chá.',
    vietnamese: 'Tôi muốn một tách trà.',
    order: 1,
  );

  test('resolves presentation types from challenge, word and example data', () {
    expect(resolver.resolve(word: word), GameplayType.discover);
    expect(resolver.resolve(word: word, example: example),
        GameplayType.sentenceBuild);
    expect(
      resolver.resolve(
        challenge: DuoChallenge(id: '1', type: 'listenTap'),
      ),
      GameplayType.listeningHunt,
    );
    expect(
      resolver.resolve(challenge: DuoChallenge(id: '2', type: 'match')),
      GameplayType.memoryMatch,
    );
    expect(
      resolver.resolve(
        challenge: DuoChallenge(
          id: '3',
          type: 'select',
          choicesImage: const ['tea.png'],
        ),
      ),
      GameplayType.imageMatch,
    );
  });
}
