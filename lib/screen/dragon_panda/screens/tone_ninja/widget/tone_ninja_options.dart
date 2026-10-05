import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ToneOptionCard extends StatelessWidget {
  const ToneOptionCard({super.key, required this.text, this.isCorrect = false});
  final String text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF20D66B).withOpacity(0.28)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect ? AppColors.successGreen : Colors.white30,
          width: isCorrect ? 2.5 : 1.2,
        ),
        boxShadow: [
          if (isCorrect)
            BoxShadow(
              color: AppColors.successGreen.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isCorrect ? AppColors.successGreen : Colors.white,
          ),
        ),
      ),
    );
  }
}
