import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';

class BossGateCard extends StatelessWidget {
  const BossGateCard({
    super.key,
    required this.bossName,
    this.bossLevel = 1,
    this.vocabMastery = 0.8,
    this.listeningMastery = 0.7,
    this.speakingMastery = 0.6,
    this.isUnlocked = true,
    required this.onFight,
  });

  final String bossName;
  final int bossLevel;
  final double vocabMastery;
  final double listeningMastery;
  final double speakingMastery;
  final bool isUnlocked;
  final VoidCallback onFight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0B2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GameVisualTokens.crimson, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: GameVisualTokens.crimson.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // Dark Dragon Aura background
            Positioned(
              right: -30,
              bottom: -20,
              width: 180,
              height: 180,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/characters/dragon_fire.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🐉🔥', style: TextStyle(fontSize: 60)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GameVisualTokens.crimson,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CỔNG TRÙM CUỐI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        'Lv. $bossLevel',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: GameVisualTokens.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Boss: $bossName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Độ thuần thục đề xuất để khiêu chiến:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequirementBar('Từ vựng', vocabMastery, 0.8),
                  const SizedBox(height: 6),
                  _buildRequirementBar('Luyện nghe', listeningMastery, 0.7),
                  const SizedBox(height: 6),
                  _buildRequirementBar('Luyện nói', speakingMastery, 0.6),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnlocked
                            ? GameVisualTokens.crimson
                            : const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: isUnlocked ? 6 : 0,
                      ),
                      onPressed: isUnlocked ? onFight : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUnlocked ? Icons.sports_martial_arts_rounded : Icons.lock_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUnlocked ? '⚔️ CHIẾN ĐẤU BOSS' : 'Hoàn thành nhiệm vụ còn lại',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRequirementBar(String label, double value, double required) {
    final bool isMet = value >= required;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                isMet ? GameVisualTokens.jadeLight : GameVisualTokens.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isMet ? GameVisualTokens.jadeLight : Colors.white70,
          ),
        ),
      ],
    );
  }
}
