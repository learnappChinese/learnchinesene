import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';

enum GameAnswerTileState { idle, selected, correct, wrong, disabled }

class GameAnswerTile extends StatelessWidget {
  const GameAnswerTile({
    super.key,
    required this.label,
    required this.onTap,
    this.state = GameAnswerTileState.idle,
    this.subtitle,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final GameAnswerTileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (state) {
      GameAnswerTileState.correct => (
          GameVisualTokens.jadeMint,
          GameVisualTokens.jade,
          GameVisualTokens.jadeDark,
        ),
      GameAnswerTileState.wrong => (
          const Color(0xFFFFE4E6),
          GameVisualTokens.crimson,
          GameVisualTokens.crimsonDark,
        ),
      GameAnswerTileState.selected => (
          GameVisualTokens.creamStrong,
          GameVisualTokens.imperialGold,
          GameVisualTokens.ink,
        ),
      GameAnswerTileState.disabled => (
          const Color(0xFFF3F4F6),
          const Color(0xFFD1D5DB),
          GameVisualTokens.muted,
        ),
      GameAnswerTileState.idle => (
          GameVisualTokens.parchment,
          GameVisualTokens.goldLight,
          GameVisualTokens.ink,
        ),
    };

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: state == GameAnswerTileState.selected,
      label: subtitle == null ? label : '$label, $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 2),
              boxShadow: state == GameAnswerTileState.idle
                  ? GameVisualTokens.softShadow
                  : null,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground.withValues(alpha: .75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
