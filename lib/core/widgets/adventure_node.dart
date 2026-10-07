import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

enum AdventureNodeType {
  learn,
  listening,
  select,
  hanzi,
  speaking,
  dialogue,
  game,
  boss,
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
    this.rewardPreview,
    required this.onTap,
  });

  final AdventureNodeType type;
  final AdventureNodeState state;
  final String title;
  final int stars;
  final bool isActive;
  final double horizontalOffset;
  final String? rewardPreview;
  final VoidCallback onTap;

  IconData _getIcon() {
    switch (type) {
      case AdventureNodeType.learn:
        return Icons.menu_book_rounded;
      case AdventureNodeType.listening:
        return Icons.headphones_rounded;
      case AdventureNodeType.select:
        return Icons.extension_rounded;
      case AdventureNodeType.hanzi:
        return Icons.gesture_rounded;
      case AdventureNodeType.speaking:
        return Icons.mic_rounded;
      case AdventureNodeType.dialogue:
        return Icons.forum_rounded;
      case AdventureNodeType.game:
        return Icons.sports_esports_rounded;
      case AdventureNodeType.boss:
        return Icons.local_fire_department_rounded;
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
              Semantics(
                button: true,
                enabled: !isLocked,
                label: '$title, ${state.name}',
                child: GestureDetector(
                  onTap: isLocked ? null : onTap,
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
                          color: glowColor.withValues(
                              alpha: isActive ? 0.45 : 0.2),
                          blurRadius: isActive ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isLocked ? Icons.lock_rounded : _getIcon(),
                        color: isLocked ? const Color(0xFF94A3B8) : glowColor,
                        size: isBoss ? 38 : 30,
                      ),
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
                  color:
                      i < stars ? GameVisualTokens.gold : Colors.grey.shade300,
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
          if (rewardPreview != null) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: GameVisualTokens.imperialGold.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                rewardPreview!,
                style: const TextStyle(
                  color: GameVisualTokens.templeWood,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
