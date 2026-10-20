import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../../core/theme/game_visual_tokens.dart';

/// Bốn nút đánh giá mức độ ghi nhớ theo chuẩn Anki và thuật toán FSRS:
/// AGAIN (Đỏ) - HARD (Cam) - GOOD (Xanh lá) - EASY (Xanh dương).
class AnkiRatingButtons extends StatelessWidget {
  final String againHint;
  final String hardHint;
  final String goodHint;
  final String easyHint;
  final ValueChanged<fsrs.Rating> onRate;
  final bool isEnabled;

  const AnkiRatingButtons({
    super.key,
    required this.againHint,
    required this.hardHint,
    required this.goodHint,
    required this.easyHint,
    required this.onRate,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 1. AGAIN - Quên (Đỏ)
          Expanded(
            child: _buildAnkiButton(
              rating: fsrs.Rating.again,
              label: 'Quên',
              hint: againHint,
              color: const Color(0xFFEF4444),
              darkColor: const Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(width: 8),

          // 2. HARD - Khó (Cam)
          Expanded(
            child: _buildAnkiButton(
              rating: fsrs.Rating.hard,
              label: 'Khó',
              hint: hardHint,
              color: const Color(0xFFF97316),
              darkColor: const Color(0xFFC2410C),
            ),
          ),
          const SizedBox(width: 8),

          // 3. GOOD - Nhớ (Xanh lá)
          Expanded(
            child: _buildAnkiButton(
              rating: fsrs.Rating.good,
              label: 'Nhớ',
              hint: goodHint,
              color: GameVisualTokens.primaryGreen,
              darkColor: GameVisualTokens.primaryGreenDark,
            ),
          ),
          const SizedBox(width: 8),

          // 4. EASY - Dễ (Xanh dương)
          Expanded(
            child: _buildAnkiButton(
              rating: fsrs.Rating.easy,
              label: 'Dễ',
              hint: easyHint,
              color: const Color(0xFF0284C7),
              darkColor: const Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnkiButton({
    required fsrs.Rating rating,
    required String label,
    required String hint,
    required Color color,
    required Color darkColor,
  }) {
    return GestureDetector(
      onTap: isEnabled ? () => onRate(rating) : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled ? color : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? darkColor : const Color(0xFF94A3B8),
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: darkColor.withValues(alpha: 0.4),
                    offset: const Offset(0, 3.5),
                    blurRadius: 0, // Độ sâu 3D xúc giác
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hint,
              style: TextStyle(
                color: isEnabled
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
