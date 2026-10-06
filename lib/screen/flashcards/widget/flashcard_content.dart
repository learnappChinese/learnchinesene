import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/models/word.dart';
import '../../../core/widgets/panda_companion.dart';

class FlashcardFront extends StatelessWidget {
  const FlashcardFront({super.key, required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      shadowColor: GameVisualTokens.crimsonDark.withValues(alpha: 0.12),
      child: Container(
        decoration: BoxDecoration(
          color: GameVisualTokens.parchment,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: GameVisualTokens.imperialGold.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GameVisualTokens.imperialGold.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: GameVisualTokens.jade.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: GameVisualTokens.jade.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏮', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 6),
                  Text(
                    'PHONG ẤN TỪ VỰNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: GameVisualTokens.jadeDark,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              word.chinese,
              style: const TextStyle(
                fontFamily: 'FZKaiTiPinyin',
                fontSize: 78,
                color: AppColors.ink,
                shadows: [
                  Shadow(
                    color: Color(0x33B8860B),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
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
                      color: AppColors.muted, fontWeight: FontWeight.w600),
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
      shadowColor: GameVisualTokens.crimsonDark.withValues(alpha: 0.12),
      child: Container(
        decoration: BoxDecoration(
          color: GameVisualTokens.parchment,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: GameVisualTokens.imperialGold.withValues(alpha: 0.45),
            width: 1.5,
          ),
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
                fontSize: 34,
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
                color: GameVisualTokens.crimson,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: GameVisualTokens.imperialGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                word.sectionTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GameVisualTokens.templeWood,
                ),
              ),
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
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: GameVisualTokens.parchment,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: GameVisualTokens.imperialGold.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PandaCompanion(
                mood: PandaMood.thinking,
                size: 84,
                animate: false,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy thẻ nào.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
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
        child: Container(
          decoration: BoxDecoration(
            color: GameVisualTokens.parchment,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: GameVisualTokens.imperialGold.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: GameVisualTokens.imperialGold.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PandaCompanion(
                  mood: PandaMood.victory,
                  size: 96,
                  animate: false,
                ),
                const SizedBox(height: 16),
                const Text(
                  '🎉 Hoàn thành session! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: GameVisualTokens.crimsonDark,
                  ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: GameVisualTokens.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text(
                    'Ôn tiếp tục',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
