import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ConversationBubble extends StatelessWidget {
  const ConversationBubble(
      {super.key,
      required this.chinese,
      required this.vietnamese,
      required this.turn,
      required this.onSpeak});
  final String chinese;
  final String vietnamese;
  final int turn;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpeakerA = turn % 2 == 1;
    final bubbleColor = isSpeakerA
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final alignment =
        isSpeakerA ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final paddingLeft = isSpeakerA ? 0.0 : 40.0;
    final paddingRight = isSpeakerA ? 40.0 : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(paddingLeft, 4, paddingRight, 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            isSpeakerA ? 'Speaker A' : 'Speaker B',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.muted.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onSpeak,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            chinese,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                              fontFamily: 'FZKaiTiPinyin',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.volume_up_rounded,
                            size: 18, color: AppColors.red),
                      ],
                    ),
                    const Divider(height: 16),
                    Text(
                      vietnamese,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
