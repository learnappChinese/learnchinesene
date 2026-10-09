import 'package:flutter/material.dart';

import '../../../core/theme/learning_theme.dart';

class DuoGameCard extends StatelessWidget {
  const DuoGameCard(
      {super.key,
      required this.nameVi,
      required this.descVi,
      required this.totalLevels,
      required this.completedLevels,
      required this.bestStars,
      required this.chapterNumber,
      required this.chapterTitle,
      required this.state,
      required this.currentIndex,
      required this.currentTotal,
      required this.iconData,
      required this.gameColor,
      required this.onTap});
  final String nameVi;
  final String descVi;
  final int totalLevels;
  final int completedLevels;
  final int bestStars;
  final int chapterNumber;
  final String chapterTitle;
  final String state;
  final int currentIndex;
  final int currentTotal;
  final IconData iconData;
  final Color gameColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cta = switch (state) {
      'in_progress' => 'TIẾP TỤC',
      'failed' => 'THỬ LẠI',
      'available' => 'BẮT ĐẦU',
      'completed' => 'CHƠI LẠI',
      'locked' => 'XEM ĐIỀU KIỆN',
      _ => 'LUYỆN NHANH',
    };
    return Card(
      elevation: 0,
      color: LearningColors.surface,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LearningRadius.lg),
        side: BorderSide(color: gameColor.withValues(alpha: .24)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LearningRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gameColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: gameColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameVi.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          descVi,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 18),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'CHAPTER $chapterNumber',
                style: LearningTypography.label,
              ),
              if (chapterTitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  chapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LearningColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    state == 'in_progress' && currentTotal > 0
                        ? 'Đang học: ${currentIndex + 1} / $currentTotal câu'
                        : totalLevels > 0
                            ? '$completedLevels / $totalLevels nhiệm vụ'
                            : 'Quick Practice',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  if (bestStars > 0)
                    Row(
                      children: List.generate(3, (starIdx) {
                        return Icon(
                          starIdx < bestStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: totalLevels > 0 ? (completedLevels / totalLevels) : 0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: gameColor,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: state == 'locked'
                        ? LearningColors.surfaceStrong
                        : LearningColors.jade,
                    borderRadius: BorderRadius.circular(LearningRadius.pill),
                  ),
                  child: Text(
                    cta,
                    style: TextStyle(
                      color: state == 'locked'
                          ? LearningColors.muted
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
