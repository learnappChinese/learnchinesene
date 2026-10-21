import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_green_button.dart';
import '../../../core/widgets/game_answer_tile.dart';
import '../../../core/widgets/learning_question_card.dart';
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

    return LearningQuestionCard(
      stageLabel: event.stageLabel,
      instruction: event.instruction,
      trailing: PandaCompanion(
        mood: mood,
        size: 72,
        animate: feedback == null,
      ),
      child: event.isDiscovery
          ? _DiscoverContent(
              event: event,
              onSpeak: onSpeak,
              onSpeakSlow: onSpeakSlow,
              onContinue: onCompleteDiscovery,
            )
          : _QuestionContent(
              event: event,
              selectedAnswer: selectedAnswer,
              feedback: feedback,
              onAnswer: onAnswer,
              onSpeak: onSpeak,
            ),
    );
  }
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
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.homeGreenSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Text(
              word.vietnamese,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.homeGreenText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppGreenButton.light(
                label: 'Nghe',
                icon: Icons.volume_up_rounded,
                height: 46,
                fontSize: 14,
                onPressed: onSpeak,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppGreenButton.light(
                label: 'Nghe chậm',
                icon: Icons.slow_motion_video_rounded,
                height: 46,
                fontSize: 14,
                onPressed: onSpeakSlow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppGreenButton(
          label: 'Đã khám phá',
          icon: Icons.auto_awesome_rounded,
          height: 52,
          fontSize: 16,
          expand: true,
          onPressed: onContinue,
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
      width: 96,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.homeGreenSoft],
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeShadow,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
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
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.menu_book_rounded,
            size: 44, color: AppColors.homeGreen),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1E6CF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14635D3B),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
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
                        color: GameVisualTokens.primaryGreenDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                AppHudIconButton(
                  icon: Icons.volume_up_rounded,
                  tooltip: 'Nghe phát âm',
                  size: 46,
                  onPressed: onSpeak,
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
                  for (final (i, answer) in event.choices.indexed)
                    SizedBox(
                      width: tileWidth,
                      child: GameAnswerTile(
                        label: answer,
                        badgeLabel: i < 4 ? 'ABCD'[i] : null,
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
