import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AnswerButtonState { idle, selected, correct, wrong }

class AnswerButton extends StatelessWidget {
  final String text;
  final String? subtitle;
  final AnswerButtonState state;
  final VoidCallback onTap;

  const AnswerButton({
    Key? key,
    required this.text,
    this.subtitle,
    required this.state,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE2DDD5);
    Color textColor = AppColors.textDark;

    if (state == AnswerButtonState.correct) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = AppColors.successGreen;
      textColor = AppColors.successGreen;
    } else if (state == AnswerButtonState.wrong) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = AppColors.dangerRed;
      textColor = AppColors.dangerRed;
    }

    return Expanded(
      child: GestureDetector(
        onTap: state == AnswerButtonState.idle ? onTap : null,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: state != AnswerButtonState.idle ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (state == AnswerButtonState.correct)
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              else if (state == AnswerButtonState.wrong)
                BoxShadow(
                  color: AppColors.dangerRed.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
