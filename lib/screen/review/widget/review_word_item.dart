import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/word.dart';
import '../../../core/widgets/word_card.dart';

class ReviewWordItem extends StatelessWidget {
  const ReviewWordItem({super.key, required this.word, required this.onTap});
  final Word word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          WordCard(
            word: word,
            onTap: onTap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.error,
                ),
                Text(
                  ' ${word.wrongCount} lần sai',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                const Spacer(),
                Text(
                  '${word.correctCount} lần đúng',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
