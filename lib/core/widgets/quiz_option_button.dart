import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum QuizOptionState { idle, selected, correct, wrong }

class QuizOptionButton extends StatelessWidget {
  const QuizOptionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.state = QuizOptionState.idle,
    this.index,
  });
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final QuizOptionState state;
  final int? index;
  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      QuizOptionState.correct => AppColors.success,
      QuizOptionState.wrong => AppColors.error,
      QuizOptionState.selected => AppColors.orange,
      _ => const Color(0xFFE9DFDD),
    };
    final fill = switch (state) {
      QuizOptionState.correct => const Color(0xFFE7F7F0),
      QuizOptionState.wrong => const Color(0xFFFFE9E7),
      QuizOptionState.selected => const Color(0xFFFFF1E7),
      _ => Colors.white,
    };
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color,
              width: state == QuizOptionState.idle ? 1 : 2,
            ),
          ),
          child: Row(
            children: [
              _buildStateIndicator(color),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateIndicator(Color color) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == QuizOptionState.idle ? const Color(0xFFF5EFED) : color,
        shape: BoxShape.circle,
      ),
      child: state == QuizOptionState.correct
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            )
          : state == QuizOptionState.wrong
              ? const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                )
              : Text(
                  String.fromCharCode(65 + (index ?? 0)),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: state == QuizOptionState.idle
                        ? AppColors.muted
                        : Colors.white,
                  ),
                ),
    );
  }
}
