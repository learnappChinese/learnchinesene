import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class HskExamSetup extends StatelessWidget {
  const HskExamSetup(
      {super.key,
      required this.selectedLevel,
      required this.onLevelChanged,
      required this.onStart});
  final int selectedLevel;
  final ValueChanged<int> onLevelChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_rounded, size: 90, color: AppColors.red),
          const SizedBox(height: 20),
          const Text(
            'Luyện thi HSK thông minh',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đề thi được tạo ngẫu nhiên dựa trên chuẩn HSK. Sau khi nộp bài, bạn sẽ nhận được đánh giá chi tiết điểm mạnh, điểm yếu và lộ trình cải thiện từ giáo viên AI.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 40),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Chọn cấp độ HSK:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedLevel,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: List.generate(6, (index) {
                        final lvl = index + 1;
                        return DropdownMenuItem(
                          value: lvl,
                          child: Text('HSK $lvl',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          onLevelChanged(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          PrimaryButton(
            label: 'Bắt đầu làm bài',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class HskExamQuestions extends StatelessWidget {
  const HskExamQuestions(
      {super.key,
      required this.selectedLevel,
      required this.questions,
      required this.answers,
      required this.onSpeak,
      required this.onSelect});
  final int selectedLevel;
  final List<Map<String, dynamic>> questions;
  final List<String?> answers;
  final ValueChanged<String> onSpeak;
  final void Function(int, String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.orange.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            'Bài thi HSK $selectedLevel - Số câu: ${questions.length}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.orange),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: _buildExamQuestion,
          ),
        ),
      ],
    );
  }

  Widget _buildExamQuestion(BuildContext context, int index) {
    final q = questions[index];
    final section = q['section'] ?? '';
    final isListening = section == 'Nghe hiểu';
    final options = q['options'] as List<String>? ?? [];
    final userAns = answers[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Câu ${index + 1} ($section)',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red),
                  ),
                ),
                if (isListening && q['audio_script'] != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onSpeak(q['audio_script']),
                    icon: const Icon(Icons.volume_up_rounded,
                        color: AppColors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              q['question_text'] ?? '',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            // Options list
            ...options.map((opt) {
              final isSelected = userAns == opt;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onSelect(index, opt),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppColors.red.withOpacity(0.08)
                        : Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.red
                          : AppColors.muted.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? AppColors.red : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class HskExamResult extends StatelessWidget {
  const HskExamResult(
      {super.key,
      required this.score,
      required this.questions,
      required this.answers,
      required this.analysisLoading,
      required this.assessment,
      required this.strengths,
      required this.weaknesses,
      required this.suggestions});
  final int score;
  final List<Map<String, dynamic>> questions;
  final List<String?> answers;
  final bool analysisLoading;
  final String assessment;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final pct = (score / questions.length * 100).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score summary card
          _buildExamScore(pct),
          const SizedBox(height: 16),

          // Detailed AI review
          if (analysisLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải phản hồi từ giáo viên AI...',
                        style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Đánh giá từ Giáo viên AI',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
            ),
            _buildTeacherReview(),
          ],

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Xem chi tiết đáp án',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
          ),

          // Detail Answers review list
          ...List.generate(questions.length, _buildAnswerReview),
        ],
      ),
    );
  }

  Widget _buildExamScore(int pct) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('KẾT QUẢ BÀI THI',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted)),
            const SizedBox(height: 12),
            Text(
              '$score/${questions.length}',
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.red),
            ),
            Text('Độ chính xác: $pct%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: score / questions.length,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherReview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assessment.isNotEmpty) ...[
              const Text('Nhận xét tổng quan:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.orange)),
              const SizedBox(height: 6),
              Text(assessment,
                  style: const TextStyle(height: 1.45, color: AppColors.ink)),
              const Divider(height: 32),
            ],
            if (strengths.isNotEmpty) ...[
              const Text('Điểm mạnh của bạn:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.success)),
              const SizedBox(height: 6),
              ...strengths.map((str) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(str,
                                style: const TextStyle(color: AppColors.ink))),
                      ],
                    ),
                  )),
              const Divider(height: 32),
            ],
            if (weaknesses.isNotEmpty) ...[
              const Text('Điểm cần cải thiện:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 6),
              ...weaknesses.map((weak) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(weak,
                                style: const TextStyle(color: AppColors.ink))),
                      ],
                    ),
                  )),
              const Divider(height: 32),
            ],
            if (suggestions.isNotEmpty) ...[
              const Text('Gợi ý học tập:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.red)),
              const SizedBox(height: 6),
              ...suggestions.map((sug) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_rounded,
                            size: 18, color: AppColors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(sug,
                                style: const TextStyle(color: AppColors.ink))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerReview(int index) {
    final q = questions[index];
    final userAns = answers[index];
    final correct = q['correct_answer'];
    final isCorrect = userAns?.trim().toLowerCase() ==
        correct.toString().trim().toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Câu ${index + 1}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(q['question_text'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Đáp án của bạn: ${userAns ?? "Chưa trả lời"}',
                style: TextStyle(
                    color: isCorrect ? AppColors.success : AppColors.error)),
            Text('Đáp án đúng: $correct',
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Text('Giải thích: ${q['explanation']}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
