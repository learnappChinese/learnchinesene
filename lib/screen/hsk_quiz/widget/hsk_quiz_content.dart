import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HskQuizSetup extends StatelessWidget {
  const HskQuizSetup(
      {super.key,
      required this.selectedLevel,
      required this.unlockedLevels,
      required this.onLevelSelected,
      required this.onStart});
  final int selectedLevel;
  final Set<int> unlockedLevels;
  final ValueChanged<int> onLevelSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_rounded, size: 80, color: AppColors.red),
          const SizedBox(height: 18),
          const Text(
            'Chọn cấp độ để bắt đầu trắc nghiệm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildLevelChoices(),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text(
              'Bắt đầu học',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChoices() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(6, (i) {
        final level = i + 1;
        final isSelected = selectedLevel == level;
        final isUnlocked = unlockedLevels.contains(level);

        return ChoiceChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HSK $level',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!isUnlocked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_rounded,
                    size: 14, color: AppColors.orange),
              ],
            ],
          ),
          onSelected: (selected) {
            if (selected) onLevelSelected(level);
          },
          selectedColor: AppColors.red.withOpacity(0.2),
          checkmarkColor: AppColors.red,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.red : Colors.black87,
          ),
        );
      }),
    );
  }
}

class HskQuizQuestionView extends StatelessWidget {
  const HskQuizQuestionView(
      {super.key,
      required this.questions,
      required this.currentIndex,
      required this.score,
      required this.selectedAnswer,
      required this.onAnswer,
      required this.onPlayAudio,
      required this.onNext});
  final List<dynamic> questions;
  final int currentIndex;
  final int score;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswer;
  final ValueChanged<String> onPlayAudio;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;
    final options = q['options'] as List<dynamic>;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu hỏi ${currentIndex + 1} / ${questions.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.muted),
              ),
              Text(
                'Đúng: $score',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
            ),
          ),
          const SizedBox(height: 32),

          _buildQuestionCard(q),

          const SizedBox(height: 24),

          // Options Grid
          _buildAnswerOptions(theme, q, options),

          if (selectedAnswer != null) ...[
            const SizedBox(height: 12),
            _buildNextQuestionAction(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic q) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.04),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              q['questionText'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () => onPlayAudio(q['word']['hanzi'] ?? ''),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.red.withOpacity(0.1),
                    foregroundColor: AppColors.red,
                  ),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Phát âm từ vựng',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(
      ThemeData theme, dynamic q, List<dynamic> options) {
    return Expanded(
      child: ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, idx) {
          final opt = options[idx];
          final isSelected = selectedAnswer == opt;
          final isCorrectOpt = opt == q['correctAnswer'];

          Color btnBg = Colors.white;
          Color textCol = Colors.black87;
          BorderSide border =
              BorderSide(color: theme.colorScheme.outline.withOpacity(0.2));

          if (selectedAnswer != null) {
            if (isCorrectOpt) {
              btnBg = const Color(0xFFE7F7F0);
              textCol = AppColors.success;
              border = const BorderSide(color: AppColors.success, width: 2);
            } else if (isSelected) {
              btnBg = const Color(0xFFFFE9E7);
              textCol = AppColors.error;
              border = const BorderSide(color: AppColors.error, width: 2);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: () => onAnswer(opt),
              style: OutlinedButton.styleFrom(
                backgroundColor: btnBg,
                side: border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 16,
                  color: textCol,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextQuestionAction() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onNext,
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentIndex + 1 == questions.length
                  ? 'Xem kết quả'
                  : 'Câu tiếp theo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class HskQuizResultView extends StatelessWidget {
  const HskQuizResultView(
      {super.key,
      required this.questions,
      required this.userAnswers,
      required this.score,
      required this.selectedLevel,
      required this.onRetry,
      required this.onChangeLevel});
  final List<dynamic> questions;
  final List<String?> userAnswers;
  final int score;
  final int selectedLevel;
  final VoidCallback onRetry;
  final VoidCallback onChangeLevel;

  @override
  Widget build(BuildContext context) {
    final percent = (score / questions.length * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildQuizScoreSummary(percent),
          const SizedBox(height: 24),

          // Study Recommendations
          _buildStudyRecommendations(),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onChangeLevel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cấp độ khác',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Làm lại',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScoreSummary(int percent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 72, color: AppColors.orange),
            const SizedBox(height: 16),
            Text(
              '$percent%',
              style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: AppColors.red),
            ),
            const SizedBox(height: 4),
            Text(
              'Bạn đã hoàn thành bài thi HSK $selectedLevel',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Đúng $score / ${questions.length} câu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyRecommendations() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.orange),
                SizedBox(width: 8),
                Text(
                  'Từ vựng cần ôn lại:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (score == questions.length)
              const Text('Tuyệt vời! Bạn đã trả lời đúng tất cả các câu hỏi.')
            else
              ...questions.asMap().entries.map(_buildWordRecommendation),
          ],
        ),
      ),
    );
  }

  Widget _buildWordRecommendation(MapEntry<int, dynamic> entry) {
    final idx = entry.key;
    final q = entry.value;
    final word = q['word'];
    if (userAnswers[idx] == q['correctAnswer']) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black87, fontSize: 15, height: 1.4),
                children: [
                  TextSpan(
                    text: '${word['hanzi']} ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.red),
                  ),
                  TextSpan(
                    text: '(${word['pinyin']}) - ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, color: AppColors.orange),
                  ),
                  TextSpan(text: word['meaning_vi']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
