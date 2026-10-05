import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/word.dart';

class FlashcardFront extends StatelessWidget {
  const FlashcardFront({super.key, required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0E7E5)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.chinese,
              style: const TextStyle(
                fontFamily: 'FZKaiTiPinyin',
                fontSize: 78,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, color: AppColors.muted, size: 20),
                SizedBox(width: 6),
                Text(
                  'Chạm để lật thẻ',
                  style: TextStyle(
                      color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FlashcardBack extends StatelessWidget {
  const FlashcardBack({super.key, required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0E7E5)),
        ),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.chinese,
              style: const TextStyle(
                fontFamily: 'FZKaiTiPinyin',
                fontSize: 32,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              word.vietnamese,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),
            if (word.english.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'English: ${word.english}',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
            const Divider(height: 32),
            const Text(
              'Từ loại & chi tiết:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              word.sectionTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashcardEmptyState extends StatelessWidget {
  const FlashcardEmptyState({super.key, required this.isReview});
  final bool isReview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_outlined,
              size: 72,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy thẻ nào.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isReview
                  ? 'Tuyệt vời! Bạn không còn thẻ nào cần ôn hôm nay.'
                  : 'Không tìm thấy dữ liệu từ vựng cho cấp độ này.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashcardCompletion extends StatelessWidget {
  const FlashcardCompletion({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_rounded,
                    size: 72, color: AppColors.orange),
                const SizedBox(height: 16),
                const Text(
                  '🎉 Hoàn thành session! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn đã ôn hết các thẻ từ vựng trong session này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Ôn tiếp tục'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
