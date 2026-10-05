import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/hsk_level.dart';

class HskLevelCard extends StatelessWidget {
  const HskLevelCard(
      {super.key,
      required this.level,
      required this.index,
      required this.count,
      required this.progress,
      required this.isUnlocked,
      required this.onTap});
  final HskLevel level;
  final int index;
  final int count;
  final double progress;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B3B1518),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.red,
                      index.isEven ? AppColors.orange : AppColors.redDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${level.order}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count bài • hoàn thành ${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isUnlocked
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_rounded,
                size: 16,
                color: isUnlocked ? AppColors.muted : AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
