import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class RestaurantFoodCard extends StatelessWidget {
  const RestaurantFoodCard({
    super.key,
    required this.hanzi,
    required this.vietnamese,
    required this.assetPath,
    required this.fallbackEmoji,
    required this.onTap,
    this.isCorrect = false,
    this.isWrong = false,
  });

  final String hanzi;
  final String vietnamese;
  final String assetPath;
  final String fallbackEmoji;
  final VoidCallback onTap;
  final bool isCorrect;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.primaryOrange;
    Color bgColor = Colors.white;

    if (isCorrect) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFD1FAE5);
    } else if (isWrong) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEE2E2);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isCorrect || isWrong ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCorrect
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : (isWrong
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : Colors.black.withOpacity(0.08)),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Text(fallbackEmoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hanzi,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                vietnamese,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

