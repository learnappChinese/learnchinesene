import 'package:flutter/material.dart';
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
            margin: const EdgeInsets.only(top: 24, bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: Colors.blue.shade800,
            child: Text(
              'PHẦN $secNum: $secTitle'.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        if (showUnitHeader)
          Container(
            width: double.infinity,
            margin:
                const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Chương $unitNum: $unitTitle',
              style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        if (index > 0 && !showSectionHeader && !showUnitHeader)
          Container(
            width: 4,
            height: 30,
            color: (isUnlocked && cCount > 0)
                ? Colors.blue.shade300
                : Colors.grey.shade300,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            gameName.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TỔNG SỐ: $levelCount MÀN CHƠI',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
