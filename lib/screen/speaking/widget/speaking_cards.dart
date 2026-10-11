import 'package:flutter/material.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/models/speaking_practice_item.dart';
import '../../../core/widgets/panda_companion.dart';

class SpeakingResultCard extends StatelessWidget {
  const SpeakingResultCard({
    super.key,
    required this.correct,
    required this.score,
    required this.recognized,
    required this.busy,
    required this.showNext,
    required this.isLast,
    required this.onRetry,
    required this.onNext,
  });

  final bool correct;
  final double score;
  final String recognized;
  final bool busy;
  final bool showNext;
  final bool isLast;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  Widget _buildMetricBadge(String label, int val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '$val',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: GameVisualTokens.ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int pron = score.round();
    final int tone = (score * 0.94).round().clamp(60, 100);
    final int flu = (score * 0.92).round().clamp(60, 100);
    final int acc = (score * 0.98).round().clamp(60, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              correct ? GameVisualTokens.jadeLight : GameVisualTokens.crimson,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (correct ? GameVisualTokens.jade : GameVisualTokens.crimson)
                .withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  gradient: LinearGradient(
                    colors: correct
                        ? [GameVisualTokens.jadeLight, GameVisualTokens.jade]
                        : [
                            GameVisualTokens.crimson,
                            GameVisualTokens.crimsonDark
                          ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6),
                  ],
                ),
                child: Text(
                  '$pron',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
                          ? 'Tuyệt đỉnh! Phát âm rất chuẩn 🎯'
                          : 'Gần đúng rồi — thử lại nhé!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: GameVisualTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Đã nghe: ${recognized.isEmpty ? 'Chưa nhận diện được giọng nói' : recognized}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Game Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBadge('Phát âm', pron, GameVisualTokens.jadeDark),
              _buildMetricBadge('Thanh điệu', tone, const Color(0xFFD97706)),
              _buildMetricBadge('Lưu loát', flu, const Color(0xFF0284C7)),
              _buildMetricBadge('Chính xác', acc, const Color(0xFF7C3AED)),
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (showNext) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(!isLast ? 'Tiếp theo' : 'Hoàn thành'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: GameVisualTokens.jade,
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
}

class SpeakingPromptCard extends StatelessWidget {
  const SpeakingPromptCard({
    super.key,
    required this.item,
    required this.onPlayAudio,
  });

  final SpeakingPracticeItem item;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: GameVisualTokens.gold.withValues(alpha: 0.5),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A461419),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // NPC & Panda Coach Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          GameVisualTokens.imperialGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: GameVisualTokens.gold),
                    ),
                    child: const Center(
                      child: Text('🧓', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Võ Sư Đàm Thoại',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: GameVisualTokens.templeWood,
                    ),
                  ),
                ],
              ),
              const PandaCompanion(
                mood: PandaMood.ninja,
                size: 38,
                animate: false,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Speech Bubble with Chinese text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  item.targetText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: item.targetText.length > 8 ? 28 : 42,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'FZKaiTiPinyin',
                    fontFamilyFallback: const [
                      'FZKaiTiPinyin_1',
                      'PingFang SC',
                      'Heiti SC',
                      'Microsoft YaHei',
                      'Noto Sans SC',
                    ],
                    color: GameVisualTokens.ink,
                  ),
                ),
                if (item.meaning.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (onPlayAudio != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onPlayAudio,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GameVisualTokens.gold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.volume_up_rounded,
                        color: GameVisualTokens.templeWood, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Nghe mẫu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GameVisualTokens.templeWood,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
