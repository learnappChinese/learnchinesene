import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../model/vocabulary_adventure.dart';

class VocabularyFeedbackPanel extends StatelessWidget {
  const VocabularyFeedbackPanel({
    super.key,
    required this.feedback,
    required this.event,
    required this.combo,
    required this.isBusy,
    required this.onContinue,
    required this.onRetry,
  });

  final VocabularyAnswerFeedback feedback;
  final VocabularyGameplayEvent event;
  final int combo;
  final bool isBusy;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final correct = feedback == VocabularyAnswerFeedback.correct;
    final color = correct ? GameVisualTokens.jade : GameVisualTokens.crimson;
    final title =
        correct ? (combo >= 5 ? 'PERFECT!' : 'GREAT!') : 'GẦN ĐÚNG RỒI';

    return Material(
      color: correct ? const Color(0xFFE7F8EF) : const Color(0xFFFFECEC),
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    correct ? Icons.auto_awesome_rounded : Icons.replay_rounded,
                    color: color,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          correct ? '$title  +${event.xpReward} XP' : title,
                          style: TextStyle(
                            color: color,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          correct
                              ? event.explanation
                              : '${event.explanation} Thử lại để ghi nhớ lâu hơn.',
                          style: const TextStyle(
                            color: GameVisualTokens.ink,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: isBusy
                        ? null
                        : correct
                            ? onContinue
                            : onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    child: isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(correct ? 'TIẾP' : 'THỬ LẠI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
