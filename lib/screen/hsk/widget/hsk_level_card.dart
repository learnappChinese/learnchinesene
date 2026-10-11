import 'package:flutter/material.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/models/hsk_level.dart';
import '../../../core/widgets/panda_companion.dart';

class HskWorldMeta {
  final String worldName;
  final String vietnameseName;
  final String emoji;
  final PandaMood pandaMood;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color borderColor;

  const HskWorldMeta({
    required this.worldName,
    required this.vietnameseName,
    required this.emoji,
    required this.pandaMood,
    required this.gradientColors,
    required this.accentColor,
    required this.borderColor,
  });
}

class HskLevelCard extends StatelessWidget {
  const HskLevelCard({
    super.key,
    required this.level,
    required this.index,
    required this.count,
    required this.progress,
    required this.isUnlocked,
    required this.onTap,
  });

  final HskLevel level;
  final int index;
  final int count;
  final double progress;
  final bool isUnlocked;
  final VoidCallback onTap;

  static const Map<int, HskWorldMeta> _worldConfig = {
    1: HskWorldMeta(
      worldName: 'Bamboo Village',
      vietnameseName: 'Thôn Trúc Xanh',
      emoji: '🌿',
      pandaMood: PandaMood.happy,
      gradientColors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7), Color(0xFFE8F5E9)],
      accentColor: GameVisualTokens.jadeDark,
      borderColor: Color(0xFF86EFAC),
    ),
    2: HskWorldMeta(
      worldName: 'Lantern Town',
      vietnameseName: 'Trấn Đèn Lồng',
      emoji: '🏮',
      pandaMood: PandaMood.chef,
      gradientColors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFFF3E0)],
      accentColor: Color(0xFFB45309),
      borderColor: Color(0xFFFCD34D),
    ),
    3: HskWorldMeta(
      worldName: 'Shanghai City',
      vietnameseName: 'Thành Phố Thượng Hải',
      emoji: '🏙',
      pandaMood: PandaMood.thinking,
      gradientColors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFE1F5FE)],
      accentColor: Color(0xFF0369A1),
      borderColor: Color(0xFF7DD3FC),
    ),
    4: HskWorldMeta(
      worldName: 'Mountain Temple',
      vietnameseName: 'Cổ Tự Mây Ngàn',
      emoji: '⛰',
      pandaMood: PandaMood.ninja,
      gradientColors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFEDE7F6)],
      accentColor: Color(0xFF6D28D9),
      borderColor: Color(0xFFD8B4FE),
    ),
    5: HskWorldMeta(
      worldName: 'Imperial City',
      vietnameseName: 'Hoàng Thành Thâm Nghiêm',
      emoji: '🏯',
      pandaMood: PandaMood.archer,
      gradientColors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFFEBEE)],
      accentColor: GameVisualTokens.crimsonDark,
      borderColor: Color(0xFFFDA4AF),
    ),
    6: HskWorldMeta(
      worldName: 'Dragon Realm',
      vietnameseName: 'Long Uy Cảnh Giới',
      emoji: '🐉',
      pandaMood: PandaMood.victory,
      gradientColors: [Color(0xFF241432), Color(0xFF381B4B), Color(0xFF1E0E2E)],
      accentColor: GameVisualTokens.imperialGold,
      borderColor: Color(0xFFF59E0B),
    ),
  };

  HskWorldMeta _getMeta(int order) {
    return _worldConfig[order] ??
        HskWorldMeta(
          worldName: 'HSK $order World',
          vietnameseName: 'Vùng Đất HSK $order',
          emoji: '✨',
          pandaMood: PandaMood.idle,
          gradientColors: const [Color(0xFFFFFDF5), Color(0xFFF9F6EB)],
          accentColor: GameVisualTokens.templeWood,
          borderColor: GameVisualTokens.gold,
        );
  }

  int _calculateStars(double progress) {
    if (progress >= 0.95) return 3;
    if (progress >= 0.50) return 2;
    if (progress >= 0.15) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _getMeta(level.order);
    final isDarkWorld = level.order == 6;
    final stars = _calculateStars(progress);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: meta.accentColor.withValues(alpha: isDarkWorld ? 0.35 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUnlocked
                    ? meta.gradientColors
                    : [
                        const Color(0xFFE2E8F0),
                        const Color(0xFFCBD5E1),
                        const Color(0xFF94A3B8),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isUnlocked
                    ? meta.borderColor
                    : const Color(0xFF94A3B8),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // World Seal Badge
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnlocked
                          ? [
                              meta.accentColor,
                              meta.accentColor.withValues(alpha: 0.8),
                            ]
                          : [Colors.grey.shade600, Colors.grey.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked ? GameVisualTokens.gold : Colors.white60,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: meta.accentColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        meta.emoji,
                        style: const TextStyle(fontSize: 16, height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HSK ${level.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // World details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${meta.worldName} • ${meta.vietnameseName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDarkWorld && isUnlocked
                                    ? Colors.white
                                    : GameVisualTokens.ink,
                              ),
                            ),
                          ),
                          // Stars
                          if (isUnlocked)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (starIdx) {
                                final isLit = starIdx < stars;
                                return Icon(
                                  isLit
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: isLit
                                      ? GameVisualTokens.gold
                                      : (isDarkWorld
                                          ? Colors.white38
                                          : Colors.black26),
                                  size: 15,
                                );
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count bài • hoàn thành ${(progress * 100).round()}%',
                        style: TextStyle(
                          color: isDarkWorld && isUnlocked
                              ? Colors.white70
                              : const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      // RPG Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: isDarkWorld
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnlocked
                                ? (progress >= 1.0
                                    ? GameVisualTokens.gold
                                    : meta.accentColor)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Panda Companion & Lock state
                if (isUnlocked)
                  PandaCompanion(
                    mood: meta.pandaMood,
                    size: 46,
                    animate: false,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.lock_rounded,
                          color: GameVisualTokens.crimsonDark,
                          size: 18,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Khóa',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: GameVisualTokens.crimsonDark,
                          ),
                        ),
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

