import 'package:flutter/material.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/quiz_question.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/quiz_option_button.dart';

class QuizQuestionView extends StatelessWidget {
  const QuizQuestionView(
      {super.key,
      required this.q,
      required this.index,
      required this.questionCount,
      required this.selected,
      required this.onPlayAudio,
      required this.onChoose,
      required this.onNext});
  final QuizQuestion q;
  final int index;
  final int questionCount;
  final String? selected;
  final VoidCallback onPlayAudio;
  final ValueChanged<String> onChoose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: ResponsiveHelper.contentMaxWidth(context)),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.horizontalPadding(context),
                    4,
                    ResponsiveHelper.horizontalPadding(context),
                    20,
                  ),
                  children: [
                    _buildQuestionProgress(),
                    const SizedBox(height: 28),
                    Text(
                      _label(q.type),
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q.question,
                      style: const TextStyle(
                        fontSize: 25,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (q.type == QuizType.listening) ...[
                      const SizedBox(height: 18),
                      _buildAudioControl(),
                    ],
                    const SizedBox(height: 26),
                    ...q.options.asMap().entries.map(_buildAnswerOption),
                    if (selected != null) _buildAnswerFeedback(),
                  ],
                ),
              ),
            ),
          ),
          if (selected != null) _buildNextAction(),
        ],
      );
  String _label(QuizType t) => switch (t) {
        QuizType.listening => 'NGHE HIỂU',
        QuizType.chineseToPinyin => 'PINYIN',
        _ => 'NGHĨA CỦA TỪ',
      };

  Widget _buildQuestionProgress() {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: (index + 1) / questionCount,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${index + 1}/$questionCount',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioControl() {
    return Center(
      child: InkWell(
        onTap: onPlayAudio,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.red, AppColors.orange],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.volume_up_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(MapEntry<int, String> e) {
    final state = selected == null
        ? QuizOptionState.idle
        : e.value == q.correctAnswer
            ? QuizOptionState.correct
            : selected == e.value
                ? QuizOptionState.wrong
                : QuizOptionState.idle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: QuizOptionButton(
        text: e.value,
        index: e.key,
        state: state,
        enabled: selected == null,
        onPressed: () => onChoose(e.value),
      ),
    );
  }

  Widget _buildAnswerFeedback() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected == q.correctAnswer
            ? const Color(0xFFE7F7F0)
            : const Color(0xFFFFE9E7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            selected == q.correctAnswer
                ? Icons.celebration_rounded
                : Icons.lightbulb_rounded,
            color: selected == q.correctAnswer
                ? AppColors.success
                : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selected == q.correctAnswer
                  ? 'Xuất sắc! Bạn đã trả lời đúng.'
                  : 'Đáp án đúng là ${q.correctAnswer}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAction() {
    return BottomActionBar(
      child: PrimaryButton(
        label: index + 1 == questionCount ? 'Xem kết quả' : 'Câu tiếp theo',
        onPressed: onNext,
      ),
    );
  }
}

class QuizResultView extends StatelessWidget {
  const QuizResultView(
      {super.key,
      required this.score,
      required this.questionCount,
      required this.onRetry,
      required this.onReview});
  final int score;
  final int questionCount;
  final VoidCallback onRetry;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final percent = (score / questionCount * 100).round();
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: ResponsiveHelper.contentMaxWidth(context)),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.horizontalPadding(context),
            vertical: 24,
          ),
          children: [
            const SizedBox(height: 20),
            _buildScoreSummary(percent),
            const SizedBox(height: 24),
            Text(
              percent >= 80
                  ? '太棒了! Bạn làm rất tốt.'
                  : 'Cố gắng tốt lắm — luyện tập sẽ giúp bạn tiến bộ.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mỗi câu trả lời đều giúp ghi nhớ tốt hơn. Hãy tiếp tục nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Làm lại',
              icon: Icons.replay_rounded,
              onPressed: onRetry,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Ôn lại câu sai'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSummary(int percent) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redDark, AppColors.red, AppColors.orange],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 58,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Đúng $score/$questionCount câu',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
