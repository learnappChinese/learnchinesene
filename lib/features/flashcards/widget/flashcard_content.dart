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
      shadowColor: const Color(0x24635D3B),
      child: Container(
        decoration: BoxDecoration(
          color: GameVisualTokens.parchment,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFF1E6CF),
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: GameVisualTokens.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: GameVisualTokens.primaryGreen.withValues(alpha: 0.3),
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
                        color: GameVisualTokens.primaryGreenDark,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
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
              ),
              const SizedBox(height: 18),
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
      shadowColor: const Color(0x24635D3B),
      child: Container(
        decoration: BoxDecoration(
          color: GameVisualTokens.parchment,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFF1E6CF),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word.chinese,
                style: const TextStyle(
                  fontFamily: 'FZKaiTiPinyin',
                  fontSize: 32,
                  color: AppColors.ink,
                ),
              ),
              if (word.pinyin.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  word.pinyin,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: GameVisualTokens.primaryGreenDark,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                word.vietnamese,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: GameVisualTokens.crimson,
                ),
              ),
              if (word.english.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'English: ${word.english}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
              const Divider(height: 24),
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
                  word.sectionTitle.isNotEmpty ? word.sectionTitle : 'Từ vựng',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GameVisualTokens.templeWood,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashcardEmptyState extends StatelessWidget {
  const FlashcardEmptyState({
    super.key,
    required this.isReview,
    this.isUnavailable = false,
  });

  final bool isReview;
  final bool isUnavailable;

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
              Text(
                isUnavailable
                    ? 'Giáo trình đang biên soạn'
                    : 'Không tìm thấy thẻ nào.',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUnavailable
                    ? 'Giáo trình HSK 5 & 6 đang được biên soạn. Bạn hãy hoàn thành HSK 1–4 trước nhé!'
                    : isReview
                        ? 'Tuyệt vời! Bạn không còn thẻ nào cần ôn hôm nay. Bạn có thể chọn HSK 1–4 để ôn thêm nhé!'
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
  const FlashcardCompletion({
    super.key,
    required this.onContinue,
    this.onBackHome,
    this.cardsReviewed = 0,
    this.correctCards = 0,
    this.xpEarned = 0,
  });

  final VoidCallback onContinue;
  final VoidCallback? onBackHome;
  final int cardsReviewed;
  final int correctCards;
  final int xpEarned;

  @override
  Widget build(BuildContext context) {
    final accuracyPercent = cardsReviewed > 0
        ? ((correctCards / cardsReviewed) * 100).round()
        : 100;

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
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PandaCompanion(
                  mood: PandaMood.victory,
                  size: 88,
                  animate: false,
                ),
                const SizedBox(height: 14),
                const Text(
                  '🎉 Hoàn thành session! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: GameVisualTokens.crimsonDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bạn đã hoàn thành lượt ôn tập này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),

                // Statistics row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1E6CF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        label: 'Đã ôn',
                        value: '$cardsReviewed',
                        icon: Icons.style_rounded,
                        color: GameVisualTokens.primaryGreenDark,
                      ),
                      Container(height: 32, width: 1, color: Colors.grey[200]),
                      _buildMetric(
                        label: 'Độ chính xác',
                        value: '$accuracyPercent%',
                        icon: Icons.check_circle_outline_rounded,
                        color: GameVisualTokens.crimson,
                      ),
                      Container(height: 32, width: 1, color: Colors.grey[200]),
                      _buildMetric(
                        label: 'XP nhận',
                        value: '+$xpEarned',
                        icon: Icons.bolt_rounded,
                        color: GameVisualTokens.imperialGold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    if (onBackHome != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onBackHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: Color(0xFFD4C8B0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Về trang chủ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: GameVisualTokens.crimson,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: const Text(
                          'Ôn tiếp tục',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
