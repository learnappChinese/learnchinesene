import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_layout.dart';

class HomePracticeTab extends StatelessWidget {
  const HomePracticeTab({
    super.key,
    required this.onSpeaking,
    required this.onWriting,
    required this.onFlashcards,
    required this.onLearningPath,
    required this.onQuiz,
    this.onReview,
  });
  final VoidCallback onSpeaking;
  final VoidCallback onWriting;
  final VoidCallback onFlashcards;
  final VoidCallback onLearningPath;
  final VoidCallback onQuiz;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: ResponsiveHelper.contentMaxWidth(context)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Luyện tập & Thực hành',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            if (onReview != null) ...[
              HomePracticeActionTile(
                icon: Icons.history_edu_rounded,
                title: 'Trung tâm Ôn luyện',
                subtitle:
                    'Ôn tập thích ứng 4 kỹ năng: Từ vựng, Nghe, Nói, Hán tự',
                color: AppColors.redDark,
                onTap: onReview!,
              ),
              const SizedBox(height: 12),
            ],
            HomePracticeActionTile(
              icon: Icons.record_voice_over_rounded,
              title: 'Luyện phát âm',
              subtitle: 'Cải thiện phát âm với điểm số tức thì',
              color: AppColors.orange,
              onTap: onSpeaking,
            ),
            const SizedBox(height: 12),
            HomePracticeActionTile(
              icon: Icons.draw_rounded,
              title: 'Luyện viết chữ Hán',
              subtitle: 'Học viết chữ Hán theo thứ tự nét chuẩn',
              color: AppColors.red,
              onTap: onWriting,
            ),
            const SizedBox(height: 12),
            HomePracticeActionTile(
              icon: Icons.style_rounded,
              title: 'Flashcards ôn tập',
              subtitle: 'Ghi nhớ từ vựng với hiệu ứng lật thẻ 3D',
              color: AppColors.success,
              onTap: onFlashcards,
            ),
            const SizedBox(height: 12),
            HomePracticeActionTile(
              icon: Icons.games_rounded,
              title: 'Lộ Trình Học Tập',
              subtitle:
                  'Học tiếng Trung qua các trò chơi tương tác như Duolingo',
              color: Colors.blue,
              onTap: onLearningPath,
            ),
            const SizedBox(height: 12),
            HomePracticeActionTile(
              icon: Icons.quiz_rounded,
              title: 'Trắc nghiệm HSK',
              subtitle: 'Bài tập trắc nghiệm ngẫu nhiên theo cấp độ HSK',
              color: AppColors.redDark,
              onTap: onQuiz,
            ),
          ],
        ),
      ),
    );
  }
}

class HomePracticeActionTile extends StatelessWidget {
  const HomePracticeActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      );
}
