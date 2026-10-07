import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';

class ComboBadge extends StatelessWidget {
  const ComboBadge({super.key, required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    if (combo < 2) return const SizedBox.shrink();

    final milestone = switch (combo) {
      >= 10 => 'PERFECT STREAK',
      >= 5 => 'FIRE',
      _ => null,
    };

    return Semantics(
      label: 'Combo x$combo${milestone == null ? '' : ', $milestone'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: combo >= 5
              ? GameVisualTokens.crimson
              : GameVisualTokens.imperialGold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: GameVisualTokens.softShadow,
        ),
        child: Text(
          milestone == null ? 'x$combo' : 'x$combo  $milestone',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
