import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class RadicalOptionTile extends StatelessWidget {
  const RadicalOptionTile({
    super.key,
    required this.radical,
    required this.onTap,
    this.isCorrect,
    this.isWrong = false,
  });

  final String radical;
  final VoidCallback onTap;
  final bool? isCorrect;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF0F766E);
    Color bgColor = Colors.white;
    Color textColor = AppColors.textDark;

    if (isCorrect == true) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFD1FAE5);
      textColor = const Color(0xFF065F46);
    } else if (isWrong) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isCorrect == true || isWrong ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: isCorrect == true
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : (isWrong
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : Colors.black.withOpacity(0.08)),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            radical,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

