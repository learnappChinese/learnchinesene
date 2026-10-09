import 'package:flutter/material.dart';

import '../theme/learning_theme.dart';

class MissionProgressHeader extends StatelessWidget {
  const MissionProgressHeader({
    super.key,
    required this.chapterNumber,
    required this.current,
    required this.total,
    this.label = 'NHIỆM VỤ',
    this.trailing,
  });

  final int chapterNumber;
  final int current;
  final int total;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total < 1 ? 1 : total;
    final value = (current / safeTotal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              'CHAPTER ${chapterNumber < 1 ? 1 : chapterNumber}  •  '
              '$label ${current.clamp(0, safeTotal)} / $safeTotal',
              style: LearningTypography.label,
            ),
          ),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(LearningRadius.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: LearningColors.surfaceStrong,
            valueColor: const AlwaysStoppedAnimation(LearningColors.gold),
          ),
        ),
      ]),
    );
  }
}
