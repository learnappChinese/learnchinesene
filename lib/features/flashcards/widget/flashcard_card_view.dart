import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../models/flashcard_models.dart';
import 'hanzi_writing_link_sheet.dart';

/// Khung thẻ 3D hai mặt của Flashcard (Mặt trước - Mặt sau) theo 3 chế độ học:
/// Trung → Việt, Việt → Trung, Nghe → Đoán.
class FlashcardCardView extends StatelessWidget {
  final FlashcardItem item;
  final bool isFlipped;
  final Animation<double> flipAnimation;
  final VoidCallback onFlip;
  final VoidCallback onPlayAudio;

  const FlashcardCardView({
    super.key,
    required this.item,
    required this.isFlipped,
    required this.flipAnimation,
    required this.onFlip,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: AnimatedBuilder(
        animation: flipAnimation,
        builder: (context, child) {
          final angle = flipAnimation.value * math.pi;
          final isBack = angle >= math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(context),
                  )
                : _buildFront(context),
          );
        },
      ),
    );
  }

  Widget _buildCardFrame({required Widget child, Color? borderColor}) {
    // Khung kem viền trắng như thẻ ở các màn học.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          const BoxShadow(
            color: Color(0x2E635D3B),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child,
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final word = item.word;
    final direction = item.direction;

    return _buildCardFrame(
      borderColor: GameVisualTokens.primaryGreenLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge chủ đề / HSK
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    GameVisualTokens.primaryGreenLight,
                    GameVisualTokens.primaryGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'HSK ${word.hskLevelId} • ${item.direction.label}'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),

            // Nội dung chính mặt trước tùy theo hướng học
            if (direction == FlashcardDirection.zhToVi) ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.chinese,
                  style: const TextStyle(
                    fontFamily: 'FZKaiTiPinyin',
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: GameVisualTokens.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hãy nhớ cách đọc và nghĩa của từ này',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D5C54),
                ),
              ),
            ] else if (direction == FlashcardDirection.viToZh) ...[
              Text(
                word.vietnamese,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.ink,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hãy nhớ chữ Hán và Pinyin tương ứng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D5C54),
                ),
              ),
            ] else ...[
              // Nghe -> Đoán
              InkWell(
                onTap: onPlayAudio,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: GameVisualTokens.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GameVisualTokens.primaryGreenDark
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Bấm loa để nghe và nhớ nghĩa của từ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D5C54),
                ),
              ),
            ],

            const Spacer(),

            // Nút bấm gợi ý lật thẻ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFE8E1D6), width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 16, color: GameVisualTokens.primaryGreenDark),
                  SizedBox(width: 6),
                  Text(
                    'Chạm vào thẻ để xem đáp án',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: GameVisualTokens.primaryGreenDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final word = item.word;

    return _buildCardFrame(
      borderColor: GameVisualTokens.imperialGold,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Từ vựng chữ Hán to rõ
            Center(
              child: Text(
                word.chinese,
                style: const TextStyle(
                  fontFamily: 'FZKaiTiPinyin',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: GameVisualTokens.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Pinyin và nút loa phát âm thanh
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word.pinyin,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: GameVisualTokens.primaryGreenDark,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onPlayAudio,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: GameVisualTokens.primaryGreenDark,
                    size: 24,
                  ),
                  tooltip: 'Nghe phát âm',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nghĩa tiếng Việt
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GameVisualTokens.imperialGold.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                word.vietnamese,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Câu ví dụ nếu có trong database
            if (item.examples.isNotEmpty) ...[
              const Divider(color: Color(0xFFE2E8F0)),
              const Text(
                'CÂU VÍ DỤ:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              ...item.examples.take(2).map((ex) {
                final exCn = ex['chinese'] as String? ?? '';
                final exPy = ex['pinyin'] as String? ?? '';
                final exVi = ex['vietnamese'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exCn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: GameVisualTokens.ink,
                        ),
                      ),
                      if (exPy.isNotEmpty)
                        Text(
                          exPy,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: GameVisualTokens.primaryGreenDark,
                          ),
                        ),
                      Text(
                        exVi,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 10),

            // Nút tiện ích: Luyện viết chữ Hán liên quan
            OutlinedButton.icon(
              onPressed: () {
                HanziWritingLinkSheet.show(
                  context,
                  word: word.chinese,
                  characters: item.characters,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: GameVisualTokens.primaryGreenDark,
                side: const BorderSide(
                  color: GameVisualTokens.primaryGreen,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text(
                'Luyện viết chữ Hán ✏️',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
