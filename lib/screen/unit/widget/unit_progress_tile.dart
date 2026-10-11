import 'package:flutter/material.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/models/unit_model.dart';

class UnitProgressTile extends StatelessWidget {
  const UnitProgressTile({
    super.key,
    required this.unit,
    required this.number,
    required this.words,
    required this.learned,
    required this.onTap,
  });

  final UnitModel unit;
  final int number;
  final int words;
  final int learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = words == 0 ? 0.0 : learned / words;
    final isMastered = p >= 1.0;
    final isLearning = p > 0.0;
    final status = isMastered
        ? 'Đã thuần thục'
        : isLearning
            ? 'Đang tu luyện'
            : 'Chưa mở';

    final Color accentColor = isMastered
        ? GameVisualTokens.gold
        : isLearning
            ? GameVisualTokens.jadeLight
            : const Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLearning || isMastered
              ? GameVisualTokens.gold.withValues(alpha: 0.45)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Chapter Stamp
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isMastered
                          ? [
                              const Color(0xFFF59E0B),
                              const Color(0xFFD97706)
                            ]
                          : isLearning
                              ? [
                                  const Color(0xFF0F766E),
                                  const Color(0xFF10B981)
                                ]
                              : [
                                  const Color(0xFFE2E8F0),
                                  const Color(0xFFCBD5E1)
                                ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isMastered
                          ? GameVisualTokens.goldLight
                          : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CHƯƠNG',
                        style: TextStyle(
                          color: isLearning || isMastered
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$number',
                        style: TextStyle(
                          color: isLearning || isMastered
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        unit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: GameVisualTokens.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '$words từ cốt lõi',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isMastered
                                    ? const Color(0xFFB45309)
                                    : isLearning
                                        ? GameVisualTokens.jadeDark
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 5,
                          backgroundColor:
                              const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation(
                            isMastered
                                ? GameVisualTokens.gold
                                : GameVisualTokens.jadeLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Percentage & Compass Arrow
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(p * 100).round()}%',
                      style: TextStyle(
                        color: isMastered
                            ? GameVisualTokens.imperialGold
                            : isLearning
                                ? GameVisualTokens.jadeDark
                                : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isLearning || isMastered
                          ? GameVisualTokens.gold
                          : const Color(0xFFCBD5E1),
                      size: 20,
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

