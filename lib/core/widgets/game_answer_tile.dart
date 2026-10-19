import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';

enum GameAnswerTileState { idle, selected, correct, wrong, disabled }

/// Ô đáp án nổi khối dùng chung cho các dạng câu hỏi
/// (cùng kiểu với thẻ đáp án ở màn Boss).
class GameAnswerTile extends StatelessWidget {
  const GameAnswerTile({
    super.key,
    required this.label,
    required this.onTap,
    this.state = GameAnswerTileState.idle,
    this.subtitle,
    this.leading,
    this.badgeLabel,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;

  /// Nhãn nhỏ ở góc trái (ví dụ A, B, C, D).
  final String? badgeLabel;
  final GameAnswerTileState state;
  final VoidCallback? onTap;

  static const _ink = Color(0xFF342E10);

  @override
  Widget build(BuildContext context) {
    final (background, border, depth, foreground, badgeBg, badgeFg) =
        switch (state) {
      GameAnswerTileState.correct => (
          GameVisualTokens.primaryGreenSoft,
          GameVisualTokens.primaryGreen,
          GameVisualTokens.primaryGreenDark,
          GameVisualTokens.primaryGreenDark,
          GameVisualTokens.primaryGreen,
          Colors.white,
        ),
      GameAnswerTileState.wrong => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          const Color(0xFFC62828),
          const Color(0xFFB71C1C),
          const Color(0xFFC62828),
          Colors.white,
        ),
      GameAnswerTileState.selected => (
          Colors.white,
          GameVisualTokens.primaryGreen,
          GameVisualTokens.primaryGreen,
          _ink,
          GameVisualTokens.primaryGreenSoft,
          GameVisualTokens.primaryGreenDark,
        ),
      GameAnswerTileState.disabled => (
          Colors.white,
          const Color(0xFFE8E1D6),
          const Color(0xFFE8E1D6),
          GameVisualTokens.muted,
          const Color(0xFFF3EEE4),
          GameVisualTokens.muted,
        ),
      GameAnswerTileState.idle => (
          Colors.white,
          const Color(0xFFE8E1D6),
          const Color(0xFFE8E1D6),
          _ink,
          const Color(0xFFFFF7E8),
          const Color(0xFFB45309),
        ),
    };
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: state == GameAnswerTileState.selected,
      label: subtitle == null ? label : '$label, $subtitle',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: state == GameAnswerTileState.disabled ? .55 : 1,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: Border.all(
                color: border,
                width: state == GameAnswerTileState.idle ||
                        state == GameAnswerTileState.disabled
                    ? 1.5
                    : 2,
              ),
              boxShadow: [BoxShadow(color: depth, offset: const Offset(0, 4))],
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: RoundedRectangleBorder(borderRadius: radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 62),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        if (badgeLabel != null)
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badgeLabel!,
                              style: TextStyle(
                                color: badgeFg,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        if (leading != null) ...[
                          if (badgeLabel != null) const SizedBox(width: 8),
                          leading!,
                        ],
                        if (badgeLabel != null || leading != null)
                          const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 19,
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
                        // Cân đối với nhãn bên trái để chữ nằm giữa thẻ.
                        if (badgeLabel != null) const SizedBox(width: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
