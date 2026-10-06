import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

class MissionCompleteOverlay extends StatelessWidget {
  const MissionCompleteOverlay({
    super.key,
    required this.stars,
    required this.score,
    required this.accuracy,
    required this.xpEarned,
    this.bestCombo = 0,
    this.wordsMastered = 0,
    this.isRecord = false,
    required this.onNextMission,
    required this.onBackToMap,
  });

  final int stars; // 1..3
  final int score;
  final int accuracy; // 0..100
  final int xpEarned;
  final int bestCombo;
  final int wordsMastered;
  final bool isRecord;
  final VoidCallback onNextMission;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
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
            // Stars Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i < stars;
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

            // Banner Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [GameVisualTokens.crimson, GameVisualTokens.imperialGold],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'HOÀN THÀNH NHIỆM VỤ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (isRecord) ...[
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

            // Panda Celebration
            const PandaCompanion(
              size: 110,
              mood: PandaMood.victory,
            ),
            const SizedBox(height: 16),

            // Metrics Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('ĐIỂM SỐ', '$score', GameVisualTokens.goldLight),
                  _metricItem('CHÍNH XÁC', '$accuracy%', GameVisualTokens.jadeLight),
                  _metricItem('XP NHẬN', '+$xpEarned', Colors.amberAccent),
                  if (bestCombo > 0)
                    _metricItem('COMBO', 'x$bestCombo', const Color(0xFFFF8A80)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CTA Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameVisualTokens.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                ),
                onPressed: onNextMission,
                child: const Text(
                  '⚔️ MỞ NHIỆM VỤ TIẾP THEO',
                  style: TextStyle(
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
}
