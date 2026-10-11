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
      required this.missionTitle,
      required this.attempts,
      required this.bestScore,
      required this.currentIndex,
      required this.currentTotal,
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
  final String missionTitle;
  final int attempts;
  final int bestScore;
  final int currentIndex;
  final int currentTotal;
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
                  GameVisualTokens.jadeDark,
                  GameVisualTokens.jade,
                  GameVisualTokens.jadeDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: GameVisualTokens.jadeDark.withValues(alpha: 0.24),
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
                    'Bài $unitNum: $unitTitle',
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
              nameVi: cCount == 0 ? 'Chưa có nội dung' : missionTitle,
              icon: icon,
              status: status,
              stars: stars,
              score: bestScore,
              currentIndex: currentIndex,
              currentTotal: currentTotal,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class DuoPathHeader extends StatelessWidget {
  const DuoPathHeader({
    super.key,
    required this.gameName,
    required this.description,
    required this.icon,
    this.sectionNumber = 1,
    this.sectionTitle = '',
    this.unitNumber = 1,
    this.unitTitle = '',
    this.missionTitle,
    required this.completedCount,
    required this.missionCount,
    this.availableSections = const [1],
    this.selectedSection = 1,
    this.onSelectSection,
    this.onQuickPractice,
    // backward compatibility
    int? chapterNumber,
    String? chapterTitle,
  });

  final String gameName;
  final String description;
  final IconData icon;
  final int sectionNumber;
  final String sectionTitle;
  final int unitNumber;
  final String unitTitle;
  final String? missionTitle;
  final int completedCount;
  final int missionCount;
  final List<int> availableSections;
  final int selectedSection;
  final ValueChanged<int>? onSelectSection;
  final VoidCallback? onQuickPractice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Column(
        children: [
          // 1. Icon & Name
          Container(
            padding: const EdgeInsets.all(20),
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
              size: 52,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            gameName.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: GameVisualTokens.templeWood,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // 2. Current Context Card (Requirement 27)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: GameVisualTokens.imperialGold.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GameVisualTokens.imperialGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PHẦN $sectionNumber: $sectionTitle'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF451A03),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      '$completedCount / $missionCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: GameVisualTokens.goldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bài $unitNumber: ${unitTitle.isNotEmpty ? unitTitle : 'Bài học hiện tại'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                if (missionTitle != null && missionTitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Nhiệm vụ: $missionTitle',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Quick Practice CTA Button
          if (onQuickPractice != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: onQuickPractice,
                  icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'LUYỆN TẬP NHANH (QUICK PRACTICE)',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: GameVisualTokens.crimson,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 4. Section Selector Chips
          if (availableSections.length > 1) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableSections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final sec = availableSections[i];
                  final isSel = sec == selectedSection;
                  return ChoiceChip(
                    label: Text('Phần $sec'),
                    selected: isSel,
                    onSelected: (_) => onSelectSection?.call(sec),
                    selectedColor: GameVisualTokens.jade,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : GameVisualTokens.templeWood,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSel
                            ? GameVisualTokens.jade
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

