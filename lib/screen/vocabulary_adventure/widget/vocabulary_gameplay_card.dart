import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/game_answer_tile.dart';
import '../../../core/widgets/panda_companion.dart';
import '../model/vocabulary_adventure.dart';

class VocabularyGameplayCard extends StatelessWidget {
  const VocabularyGameplayCard({
    super.key,
    required this.event,
    required this.selectedAnswer,
    required this.feedback,
    required this.onAnswer,
    required this.onSpeak,
    required this.onSpeakSlow,
    required this.onCompleteDiscovery,
  });

  final VocabularyGameplayEvent event;
  final String? selectedAnswer;
  final VocabularyAnswerFeedback? feedback;
  final ValueChanged<String> onAnswer;
  final VoidCallback onSpeak;
  final VoidCallback onSpeakSlow;
  final VoidCallback onCompleteDiscovery;

  @override
  Widget build(BuildContext context) {
    final mood = switch (feedback) {
      VocabularyAnswerFeedback.correct => PandaMood.happy,
      VocabularyAnswerFeedback.wrong => PandaMood.encourage,
      null => event.isDiscovery ? PandaMood.idle : PandaMood.thinking,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: GameVisualTokens.parchment.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: GameVisualTokens.goldLight, width: 2),
          boxShadow: GameVisualTokens.gameShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StageHeader(event: event)),
                const SizedBox(width: 8),
                PandaCompanion(
                  mood: mood,
                  size: 72,
                  animate: feedback == null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (event.isDiscovery)
              _DiscoverContent(
                event: event,
                onSpeak: onSpeak,
                onSpeakSlow: onSpeakSlow,
                onContinue: onCompleteDiscovery,
              )
            else
              _QuestionContent(
                event: event,
                selectedAnswer: selectedAnswer,
                feedback: feedback,
                onAnswer: onAnswer,
                onSpeak: onSpeak,
              ),
          ],
        ),
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.event});

  final VocabularyGameplayEvent event;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: GameVisualTokens.jade,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              child: Text(
                event.stageLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.instruction,
            style: const TextStyle(
              color: GameVisualTokens.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}

class _DiscoverContent extends StatelessWidget {
  const _DiscoverContent({
    required this.event,
    required this.onSpeak,
    required this.onSpeakSlow,
    required this.onContinue,
  });

  final VocabularyGameplayEvent event;
  final VoidCallback onSpeak;
  final VoidCallback onSpeakSlow;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final word = event.word;
    return Column(
      children: [
        _WordVisual(imageUrl: event.missionWord.imageUrl),
        const SizedBox(height: 14),
        Text(
          word.chinese,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GameVisualTokens.ink,
            fontSize: 54,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          word.pinyin,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GameVisualTokens.crimsonDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          word.vietnamese,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GameVisualTokens.jadeDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Nghe'),
            ),
            OutlinedButton.icon(
              onPressed: onSpeakSlow,
              icon: const Icon(Icons.slow_motion_video_rounded),
              label: const Text('Nghe chậm'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('ĐÃ KHÁM PHÁ'),
            style: FilledButton.styleFrom(
              backgroundColor: GameVisualTokens.jade,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _WordVisual extends StatelessWidget {
  const _WordVisual({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final canLoadImage = imageUrl?.startsWith('http') == true;
    return Container(
      width: 118,
      height: 94,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GameVisualTokens.creamStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GameVisualTokens.imperialGold),
      ),
      child: canLoadImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _ScrollIllustration(),
            )
          : const _ScrollIllustration(),
    );
  }
}

class _ScrollIllustration extends StatelessWidget {
  const _ScrollIllustration();

  @override
  Widget build(BuildContext context) => const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.landscape_rounded, size: 68, color: Color(0x337D1D24)),
          Icon(Icons.menu_book_rounded, size: 42, color: GameVisualTokens.jade),
        ],
      );
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    required this.event,
    required this.selectedAnswer,
    required this.feedback,
    required this.onAnswer,
    required this.onSpeak,
  });

  final VocabularyGameplayEvent event;
  final String? selectedAnswer;
  final VocabularyAnswerFeedback? feedback;
  final ValueChanged<String> onAnswer;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GameVisualTokens.creamStrong),
            ),
            child: Column(
              children: [
                Text(
                  event.prompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameVisualTokens.ink,
                    fontSize: event.stage == VocabularyStage.use ? 26 : 38,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (event.stage == VocabularyStage.recognize) ...[
                  const SizedBox(height: 7),
                  Text(
                    event.word.pinyin,
                    style: const TextStyle(
                      color: GameVisualTokens.crimsonDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (event.example case final example?) ...[
                  const SizedBox(height: 8),
                  Text(
                    example.pinyin,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: GameVisualTokens.muted),
                  ),
                  if (example.vietnamese.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      example.vietnamese,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GameVisualTokens.jadeDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  onPressed: onSpeak,
                  tooltip: 'Nghe phát âm',
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 430;
              final tileWidth = twoColumns
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final answer in event.choices)
                    SizedBox(
                      width: tileWidth,
                      child: GameAnswerTile(
                        label: answer,
                        state: _tileState(answer),
                        onTap: feedback == null ? () => onAnswer(answer) : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );

  GameAnswerTileState _tileState(String answer) {
    if (feedback == null) {
      return selectedAnswer == answer
          ? GameAnswerTileState.selected
          : GameAnswerTileState.idle;
    }
    if (answer == event.correctAnswer) return GameAnswerTileState.correct;
    if (answer == selectedAnswer &&
        feedback == VocabularyAnswerFeedback.wrong) {
      return GameAnswerTileState.wrong;
    }
    return GameAnswerTileState.disabled;
  }
}
