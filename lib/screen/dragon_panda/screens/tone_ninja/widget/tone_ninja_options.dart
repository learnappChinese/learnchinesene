import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ToneOptionCard extends StatelessWidget {
  const ToneOptionCard({
    super.key,
    required this.text,
    this.isCorrect = false,
    this.isWrong = false,
    this.onTap,
  });

  final String text;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white.withOpacity(0.12);
    Color borderColor = Colors.white30;
    Color textColor = Colors.white;

    if (isCorrect) {
      bgColor = const Color(0xFF20D66B).withOpacity(0.35);
      borderColor = AppColors.successGreen;
      textColor = AppColors.successGreen;
    } else if (isWrong) {
      bgColor = const Color(0xFFEF4444).withOpacity(0.35);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFFF8A80);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isCorrect || isWrong ? 2.5 : 1.2,
          ),
          boxShadow: [
            if (isCorrect)
              BoxShadow(
                color: AppColors.successGreen.withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 2),
              )
            else if (isWrong)
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

