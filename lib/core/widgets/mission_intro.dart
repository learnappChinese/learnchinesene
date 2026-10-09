import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

class MissionIntro extends StatelessWidget {
  const MissionIntro({
    super.key,
    required this.title,
    required this.objective,
    required this.rewardText,
    required this.onStart,
    this.eyebrow = 'NHIỆM VỤ HỌC TẬP',
    this.coachText = 'Sẵn sàng cho thử thách tiếp theo chứ?',
  });

  final String title;
  final String objective;
  final String rewardText;
  final VoidCallback onStart;
  final String eyebrow;
  final String coachText;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: GameVisualTokens.parchment.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: GameVisualTokens.imperialGold,
                  width: 2,
                ),
                boxShadow: GameVisualTokens.gameShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: GameVisualTokens.crimsonDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameVisualTokens.ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    objective,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameVisualTokens.muted,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PandaCompanion(
                    mood: PandaMood.encourage,
                    size: 122,
                    speechText: coachText,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: GameVisualTokens.goldLight.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      rewardText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GameVisualTokens.templeWood,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.explore_rounded),
                      label: const Text('BẮT ĐẦU PHIÊU LƯU'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GameVisualTokens.jade,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
