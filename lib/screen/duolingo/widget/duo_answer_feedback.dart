import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DuoAnswerFeedback extends StatelessWidget {
  const DuoAnswerFeedback(
      {super.key,
      required this.correct,
      required this.solution,
      required this.onContinue});
  final bool correct;
  final String? solution;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: correct
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.15),
        border: Border(
          top: BorderSide(
            color: correct ? AppColors.success : AppColors.error,
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? AppColors.success : AppColors.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  correct ? 'Chính xác tuyệt đối!' : 'Sai rồi, đáp án đúng:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: correct ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
            if (!correct && solution != null) ...[
              const SizedBox(height: 8),
              Text(
                solution!,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: correct ? AppColors.success : AppColors.error,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
