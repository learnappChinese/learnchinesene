import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';
import 'combo_badge.dart';

class GameProgressHud extends StatelessWidget {
  const GameProgressHud({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.xp,
    required this.combo,
    required this.stageLabel,
  });

  final int currentStep;
  final int totalSteps;
  final int xp;
  final int combo;
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps <= 0 ? 1 : totalSteps;
    final progress = (currentStep / safeTotal).clamp(0.0, 1.0);

    return Material(
      color: GameVisualTokens.parchment.withValues(alpha: .94),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stageLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameVisualTokens.jadeDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ComboBadge(combo: combo),
                if (combo >= 2) const SizedBox(width: 8),
                Text(
                  '+$xp XP',
                  style: const TextStyle(
                    color: GameVisualTokens.crimsonDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color: GameVisualTokens.imperialGold,
                      backgroundColor: Colors.black12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$currentStep/$safeTotal',
                  style: const TextStyle(
                    color: GameVisualTokens.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
