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
  paused,
  failed,
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
    this.progressLabel,
    this.ctaLabel,
    required this.onTap,
  });

  final AdventureNodeType type;
  final AdventureNodeState state;
  final String title;
  final int stars;
  final bool isActive;
  final double horizontalOffset;
  final String? rewardPreview;
  final String? progressLabel;
  final String? ctaLabel;
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

  /// (nền node, viền node, màu icon, màu bóng/nhấn)
  (Color, Color, Color, Color) _getNodeColors() {
    if (state == AdventureNodeState.locked) {
      return (
        const Color(0xFFF1EDE4),
        const Color(0xFFD9D2C3),
        const Color(0xFFA39C8C),
        const Color(0xFFB8B0A0),
      );
    }

    if (type == AdventureNodeType.boss) {
      return (
        const Color(0xFFFFE4E6),
        GameVisualTokens.crimson,
        GameVisualTokens.crimsonDark,
        GameVisualTokens.crimson,
      );
    }

    switch (state) {
      case AdventureNodeState.perfect:
        return (
          const Color(0xFFFEF3C7),
          GameVisualTokens.imperialGold,
          const Color(0xFFB45309),
          GameVisualTokens.imperialGold,
        );
      case AdventureNodeState.completed:
        return (
          GameVisualTokens.primaryGreen,
          GameVisualTokens.primaryGreenLight,
          Colors.white,
          GameVisualTokens.primaryGreenDark,
        );
      case AdventureNodeState.inProgress:
      case AdventureNodeState.paused:
      case AdventureNodeState.available:
        return (
          Colors.white,
          GameVisualTokens.primaryGreen,
          GameVisualTokens.primaryGreen,
          GameVisualTokens.primaryGreen,
        );
      case AdventureNodeState.failed:
        return (
          const Color(0xFFFFF7ED),
          const Color(0xFFF97316),
          const Color(0xFFC2410C),
          const Color(0xFFF97316),
        );
      case AdventureNodeState.locked:
        return (
          const Color(0xFFF1EDE4),
          const Color(0xFFD9D2C3),
          const Color(0xFFA39C8C),
          const Color(0xFFB8B0A0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, iconColor, accent) = _getNodeColors();
    final bool isLocked = state == AdventureNodeState.locked;
    final bool isBoss = type == AdventureNodeType.boss;
    final bool isDone = state == AdventureNodeState.completed ||
        state == AdventureNodeState.perfect;
    final double nodeSize = isBoss ? 82.0 : 68.0;
    // Nút hành động nổi bật cho chặng đang chơi được.
    final bool primaryCta = !isLocked && !isDone;

    final node = Semantics(
      button: true,
      enabled: true,
      label: '$title, ${state.name}',
      child: GestureDetector(
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
              width: isActive ? 5.0 : 4.0,
            ),
            boxShadow: [
              // Đế nổi khối
              BoxShadow(
                color: Color.lerp(accent, Colors.black, .25)!
                    .withValues(alpha: isLocked ? .35 : .55),
                offset: const Offset(0, 5),
              ),
              if (isActive)
                BoxShadow(
                  color: accent.withValues(alpha: .45),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              isLocked ? Icons.lock_rounded : _getIcon(),
              color: iconColor,
              size: isBoss ? 38 : 30,
            ),
          ),
        ),
      ),
    );

    return Transform.translate(
      offset: Offset(horizontalOffset, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panda đứng cạnh node nhưng không đẩy node lệch khỏi đường đi.
          SizedBox(
            width: nodeSize,
            height: nodeSize + 5,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (isActive)
                  Positioned(
                    right: nodeSize + 2,
                    bottom: 0,
                    child: ExcludeSemantics(
                      child: PandaCompanion(
                        size: 54,
                        mood: isBoss ? PandaMood.archer : PandaMood.happy,
                      ),
                    ),
                  ),
                node,
              ],
            ),
          ),
          if (stars > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: i < stars
                      ? GameVisualTokens.gold
                      : const Color(0xFFE2DCCD),
                );
              }),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isLocked ? .82 : .95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? accent.withValues(alpha: .45)
                    : const Color(0xFFF1E6CF),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14635D3B),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isLocked
                        ? const Color(0xFF8C8577)
                        : const Color(0xFF342E10),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    progressLabel!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8C8577),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (ctaLabel != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 26),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: primaryCta
                            ? LinearGradient(
                                colors: isBoss
                                    ? const [
                                        Color(0xFFEF4444),
                                        GameVisualTokens.crimson,
                                      ]
                                    : const [
                                        GameVisualTokens.primaryGreenLight,
                                        GameVisualTokens.primaryGreen,
                                      ],
                              )
                            : null,
                        color: primaryCta ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                        border: primaryCta
                            ? null
                            : Border.all(
                                color: isLocked
                                    ? const Color(0xFFD9D2C3)
                                    : GameVisualTokens.primaryGreen),
                      ),
                      child: Text(
                        ctaLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryCta
                              ? Colors.white
                              : isLocked
                                  ? const Color(0xFF8C8577)
                                  : GameVisualTokens.primaryGreenDark,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                    ),
                  ),
                ],
                if (rewardPreview != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    rewardPreview!,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
