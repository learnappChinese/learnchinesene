import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

enum AdventureNodeType {
  learn,      // 📚
  listening,  // 🎧
  select,     // 🧠
  hanzi,      // ✍️
  speaking,   // 🎤
  dialogue,   // 💬
  game,       // 🎮
  boss,       // 🐉
}

enum AdventureNodeState {
  locked,
  available,
  inProgress,
  completed,
  perfect,
}

class AdventureNode extends StatelessWidget {
  const AdventureNode({
    super.key,
    required this.type,
    required this.state,
    required this.title,
    this.stars = 0,
    this.isActive = false,
    this.horizontalOffset = 0.0,
    required this.onTap,
  });

  final AdventureNodeType type;
  final AdventureNodeState state;
  final String title;
  final int stars;
  final bool isActive;
  final double horizontalOffset;
  final VoidCallback onTap;

  String _getEmoji() {
    switch (type) {
      case AdventureNodeType.learn:
        return '📚';
      case AdventureNodeType.listening:
        return '🎧';
      case AdventureNodeType.select:
        return '🧠';
      case AdventureNodeType.hanzi:
        return '✍️';
      case AdventureNodeType.speaking:
        return '🎤';
      case AdventureNodeType.dialogue:
        return '💬';
      case AdventureNodeType.game:
        return '🎮';
      case AdventureNodeType.boss:
        return '🐉';
    }
  }

  (Color, Color, Color) _getNodeColors() {
    if (state == AdventureNodeState.locked) {
      return (
        const Color(0xFFE2E8F0),
        const Color(0xFF94A3B8),
        const Color(0xFF64748B),
      );
    }

    if (type == AdventureNodeType.boss) {
      return (
        const Color(0xFFFFE4E6),
        GameVisualTokens.crimson,
        GameVisualTokens.crimsonDark,
      );
    }

    switch (state) {
      case AdventureNodeState.perfect:
        return (
          const Color(0xFFFEF3C7),
          GameVisualTokens.imperialGold,
          const Color(0xFFB45309),
        );
      case AdventureNodeState.completed:
        return (
          GameVisualTokens.jadeMint,
          GameVisualTokens.jadeLight,
          GameVisualTokens.jade,
        );
      case AdventureNodeState.inProgress:
      case AdventureNodeState.available:
        return (
          const Color(0xFFE0F2FE),
          GameVisualTokens.blue,
          const Color(0xFF0369A1),
        );
      case AdventureNodeState.locked:
        return (
          const Color(0xFFE2E8F0),
          const Color(0xFF94A3B8),
          const Color(0xFF64748B),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, glowColor) = _getNodeColors();
    final bool isLocked = state == AdventureNodeState.locked;
    final bool isBoss = type == AdventureNodeType.boss;
    final double nodeSize = isBoss ? 82.0 : 68.0;

    return Transform.translate(
      offset: Offset(horizontalOffset, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PandaCompanion(
                    size: 54,
                    mood: isBoss ? PandaMood.archer : PandaMood.happy,
                  ),
                ),
              GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: isActive ? 4.0 : 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: isActive ? 0.45 : 0.2),
                        blurRadius: isActive ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLocked
                        ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 28)
                        : Text(
                            _getEmoji(),
                            style: TextStyle(fontSize: isBoss ? 38 : 30),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Star indicators for completed nodes
          if (stars > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: i < stars ? GameVisualTokens.gold : Colors.grey.shade300,
                );
              }),
            ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isLocked ? const Color(0xFF94A3B8) : GameVisualTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}
