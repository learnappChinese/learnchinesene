import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MasteredWordsSummary extends StatelessWidget {
  const MasteredWordsSummary({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redDark, AppColors.red, AppColors.orange],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'từ đã thành thạo',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
