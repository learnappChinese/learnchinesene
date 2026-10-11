import 'package:flutter/material.dart';
import '../learning/model/learning_result.dart';
import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

class MissionCompleteOverlay extends StatelessWidget {
  const MissionCompleteOverlay({
    super.key,
    required this.result,
    required this.onNextMission,
    required this.onBackToMap,
  });

  final LearningResult result;
  final VoidCallback onNextMission;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final passed = result.passed;
    final masteryGain = ((result.masteryAfter - result.masteryBefore) * 100)
        .clamp(0, 100)
        .round();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1035),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: GameVisualTokens.imperialGold, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: GameVisualTokens.imperialGold.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i < result.stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    active ? '⭐' : '🖤',
                    style: TextStyle(fontSize: i == 1 ? 46 : 34),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: passed
                      ? const [
                          GameVisualTokens.crimson,
                          GameVisualTokens.imperialGold,
                        ]
                      : const [Color(0xFF9A3412), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                passed ? 'HOÀN THÀNH NHIỆM VỤ' : 'CHƯA ĐẠT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (passed && (result.perfect || result.firstClear)) ...[
              const SizedBox(height: 6),
              const Text(
                '🏆 KỶ LỤC MỚI!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.goldLight,
                  letterSpacing: 1.1,
                ),
              ),
            ],
            const SizedBox(height: 16),

            PandaCompanion(
              size: 110,
              mood: passed ? PandaMood.victory : PandaMood.encourage,
            ),
            if (!passed) ...[
              const SizedBox(height: 8),
              Text(
                result.reason.isNotEmpty
                    ? _reasonCopy(result.reason)
                    : 'Cần ít nhất 70% để mở nhiệm vụ tiếp theo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
            const SizedBox(height: 16),

            // Metrics Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                runAlignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 12,
                children: [
                  _metricItem(
                    'ĐIỂM SỐ',
                    '${result.score.round()}',
                    GameVisualTokens.goldLight,
                  ),
                  _metricItem(
                    'CHÍNH XÁC',
                    '${(result.accuracy * 100).round()}%',
                    GameVisualTokens.jadeLight,
                  ),
                  _metricItem(
                    'XP NHẬN',
                    '+${result.xpEarned}',
                    Colors.amberAccent,
                  ),
                  _metricItem(
                    'MASTERY',
                    '+$masteryGain%',
                    GameVisualTokens.jadeLight,
                  ),
                  if (result.bestCombo > 0)
                    _metricItem(
                      'COMBO',
                      'x${result.bestCombo}',
                      const Color(0xFFFF8A80),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      passed ? GameVisualTokens.green : const Color(0xFFF97316),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                ),
                onPressed: onNextMission,
                child: Text(
                  passed
                      ? (result.unlockedNext
                          ? 'NHIỆM VỤ TIẾP THEO'
                          : 'VỀ CHAPTER')
                      : 'THỬ LẠI',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onBackToMap,
              child: const Text(
                'Về bản đồ phiêu lưu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _reasonCopy(String reason) {
    switch (reason) {
      case 'accuracy_below_threshold':
      case 'score_below_threshold':
      case 'failed':
        return 'Cần ít nhất 70% để mở nhiệm vụ tiếp theo.';
      case 'speaking_pronunciation_below_minimum':
        return 'Phát âm cần đạt ít nhất 60%. Hãy nghe chậm và thử lại.';
      case 'speaking_tone_below_minimum':
        return 'Thanh điệu cần đạt ít nhất 50%. Hãy nói chậm hơn.';
      case 'boss_not_defeated':
        return 'Hãy giữ HP và đưa HP của Boss về 0.';
      default:
        return 'Chỉ cần thêm một chút nữa. Hãy thử lại!';
    }
  }
}
