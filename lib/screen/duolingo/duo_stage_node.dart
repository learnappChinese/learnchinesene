import 'package:flutter/material.dart';
import '../../core/theme/game_visual_tokens.dart';

class DuoStageNode extends StatelessWidget {
  final int stageNumber;
  final String nameVi;
  final String icon;
  final String status; // 'available', 'completed', 'locked'
  final int stars;
  final int score;
  final int currentIndex;
  final int currentTotal;
  final VoidCallback onTap;

  const DuoStageNode({
    super.key,
    required this.stageNumber,
    required this.nameVi,
    required this.icon,
    required this.status,
    required this.stars,
    this.score = 0,
    this.currentIndex = 0,
    this.currentTotal = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = status == 'locked';
    final bool isCompleted = status == 'completed';
    final bool isInProgress = status == 'in_progress';
    final bool isFailed = status == 'failed';

    Color nodeBgColor = isLocked
        ? Colors.grey.shade300
        : isCompleted
            ? GameVisualTokens.jade
            : isFailed
                ? const Color(0xFFE58B7C)
                : isInProgress
                    ? GameVisualTokens.orange
                    : GameVisualTokens.imperialGold;

    Color shadowColor = isLocked
        ? Colors.grey.shade500
        : isCompleted
            ? GameVisualTokens.jadeDark
            : isFailed
                ? GameVisualTokens.crimsonDark
                : isInProgress
                    ? const Color(0xFFB45309)
                    : const Color(0xFFB8860B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: nodeBgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded, color: Colors.grey, size: 32)
                  : Text(
                      icon,
                      style: const TextStyle(fontSize: 34),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: GameVisualTokens.parchment,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked
                  ? Colors.grey.shade300
                  : GameVisualTokens.imperialGold.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Màn $stageNumber: $nameVi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : GameVisualTokens.templeWood,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ] else if (isInProgress && currentTotal > 0) ...[
                const SizedBox(height: 3),
                Text(
                  'ĐANG HỌC  •  ${currentIndex + 1}/$currentTotal',
                  style: const TextStyle(
                    color: GameVisualTokens.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ] else if (isFailed) ...[
                const SizedBox(height: 3),
                Text(
                  'CHƯA ĐẠT  •  $score%',
                  style: const TextStyle(
                    color: GameVisualTokens.crimsonDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ] else if (isLocked) ...[
                const SizedBox(height: 3),
                const Text(
                  'XEM ĐIỀU KIỆN',
                  style: TextStyle(
                    color: GameVisualTokens.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
