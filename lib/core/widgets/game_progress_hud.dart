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

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Material(
      color: Colors.transparent,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Semantics(
          container: true,
          label:
              '$stageLabel, tiến độ $currentStep trên $safeTotal, $xp điểm kinh nghiệm',
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [GameVisualTokens.jadeDark, GameVisualTokens.jade],
              ),
              border: Border(
                bottom: BorderSide(
                  color: GameVisualTokens.imperialGold,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text('🏮', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        stageLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    ComboBadge(combo: combo),
                    if (combo >= 2) const SizedBox(width: 8),
                    Text(
                      '+$xp XP',
                      style: const TextStyle(
                        color: GameVisualTokens.goldLight,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: progress),
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 320),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            color: GameVisualTokens.imperialGold,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$currentStep/$safeTotal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
