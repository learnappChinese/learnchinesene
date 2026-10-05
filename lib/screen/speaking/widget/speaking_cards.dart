import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/speaking_practice_item.dart';

class SpeakingResultCard extends StatelessWidget {
  const SpeakingResultCard(
      {super.key,
      required this.correct,
      required this.score,
      required this.recognized,
      required this.busy,
      required this.showNext,
      required this.isLast,
      required this.onRetry,
      required this.onNext});
  final bool correct;
  final double score;
  final String recognized;
  final bool busy;
  final bool showNext;
  final bool isLast;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: correct ? const Color(0xFFE7F7F0) : const Color(0xFFFFE9E7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: correct ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${score.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct
                            ? 'Phát âm rất tốt!'
                            : 'Gần đúng rồi — thử lại nhé',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Đã nhận diện: ${recognized.isEmpty ? 'Không nghe thấy giọng nói' : recognized}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? null : onRetry,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Luyện lại'),
                  ),
                ),
                if (showNext) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        !isLast ? 'Tiếp theo' : 'Hoàn thành',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
}

class SpeakingPromptCard extends StatelessWidget {
  const SpeakingPromptCard(
      {super.key, required this.item, required this.onPlayAudio});
  final SpeakingPracticeItem item;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C461419),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            item.targetText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: item.targetText.length > 8 ? 32 : 46,
              height: 1.2,
              fontWeight: FontWeight.w400,
              fontFamily: 'FZKaiTiPinyin',
              fontFamilyFallback: const [
                'FZKaiTiPinyin_1',
                'PingFang SC',
                'Heiti SC',
                'Microsoft YaHei',
                'Noto Sans SC',
              ],
            ),
          ),
          if (item.meaning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.muted,
              ),
            ),
          ],
          if (item.audioUrl != null && item.audioUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            IconButton(
              onPressed: onPlayAudio,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.red,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFE9E5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
