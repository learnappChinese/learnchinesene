import 'package:flutter/material.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../duo_stage_node.dart';

class DuoPathItem extends StatelessWidget {
  const DuoPathItem(
      {super.key,
      required this.index,
      required this.secNum,
      required this.secTitle,
      required this.unitNum,
      required this.unitTitle,
      required this.levelIndex,
      required this.cCount,
      required this.isUnlocked,
      required this.stars,
      required this.showSectionHeader,
      required this.showUnitHeader,
      required this.offset,
      required this.status,
      required this.icon,
      required this.onTap});
  final int index;
  final int secNum;
  final String secTitle;
  final int unitNum;
  final String unitTitle;
  final int levelIndex;
  final int cCount;
  final bool isUnlocked;
  final int stars;
  final bool showSectionHeader;
  final bool showUnitHeader;
  final double offset;
  final String status;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSectionHeader)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 28, bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  GameVisualTokens.crimsonDark,
                  GameVisualTokens.crimson,
                  GameVisualTokens.crimsonDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: GameVisualTokens.crimsonDark.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏮 ', style: TextStyle(fontSize: 16)),
                Flexible(
                  child: Text(
                    'PHẦN $secNum: $secTitle'.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Text(' 🏮', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        if (showUnitHeader)
          Container(
            width: double.infinity,
            margin:
                const EdgeInsets.only(top: 8, bottom: 18, left: 16, right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameVisualTokens.parchment,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameVisualTokens.imperialGold.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GameVisualTokens.jade.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📜', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chương $unitNum: $unitTitle',
                    style: const TextStyle(
                      color: GameVisualTokens.templeWood,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (index > 0 && !showSectionHeader && !showUnitHeader)
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: (isUnlocked && cCount > 0)
                  ? GameVisualTokens.imperialGold
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Opacity(
          opacity: cCount == 0 ? 0.4 : 1.0,
          child: Transform.translate(
            offset: Offset(offset, 0),
            child: DuoStageNode(
              stageNumber: levelIndex + 1,
              nameVi: cCount == 0 ? 'Trống' : 'Cấp độ ${levelIndex + 1}',
              icon: icon,
              status: status,
              stars: stars,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class DuoPathHeader extends StatelessWidget {
  const DuoPathHeader(
      {super.key,
      required this.gameName,
      required this.description,
      required this.icon,
      required this.levelCount});
  final String gameName;
  final String description;
  final IconData icon;
  final int levelCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  GameVisualTokens.imperialGold.withValues(alpha: 0.25),
                  GameVisualTokens.imperialGold.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: GameVisualTokens.imperialGold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameVisualTokens.imperialGold.withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: GameVisualTokens.imperialGold,
              size: 56,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            gameName.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: GameVisualTokens.templeWood,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: GameVisualTokens.jade.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: GameVisualTokens.jade.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'TỔNG SỐ: $levelCount MÀN CHƠI',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: GameVisualTokens.jadeDark,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
