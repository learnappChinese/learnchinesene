import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/game_button.dart';

class BossVictoryContent extends StatelessWidget {
  const BossVictoryContent({
    super.key,
    required this.onContinue,
    required this.onBackToHub,
    this.xpEarned = 0,
    this.stars = 3,
    this.score = 0,
    this.accuracy = 0,
    this.bestCombo = 0,
  });

  final VoidCallback onContinue;
  final VoidCallback onBackToHub;
  final int xpEarned;
  final int stars;
  final int score;
  final int accuracy;
  final int bestCombo;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Glowing Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stars >= 1 ? '⭐' : '🖤',
                  style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 8),
              Text(stars >= 2 ? '⭐' : '🖤',
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(width: 8),
              Text(stars >= 3 ? '⭐' : '🖤',
                  style: const TextStyle(fontSize: 34)),
            ],
          ),
          const SizedBox(height: 12),

          // Red Ribbon "Chiến thắng!"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.redGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dangerRed.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Chiến thắng!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Happy Cheering Panda
          SizedBox(
            width: 140,
            height: 140,
            child: Image.asset(
              'assets/images/characters/panda_victory.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('🐼🏆✨', style: TextStyle(fontSize: 60))),
            ),
          ),
          const SizedBox(height: 20),

          // Reward Card
          _buildRewards(),
          const SizedBox(height: 12),
          const Text(
            'Panda và bạn đã mở đường sang chặng tiếp theo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 22),

          // Primary "Tiếp tục" Button (Green)
          GameButton(
            text: 'Tiếp tục',
            gradient: AppColors.greenGradient,
            shadowColor: const Color(0xFF15803D),
            onTap: onContinue,
          ),
          const SizedBox(height: 12),

          // Secondary "Về Game Hub" Button (Dark Blue)
          GameButton(
            text: 'Về Game Hub',
            gradient: AppColors.darkBlueGradient,
            shadowColor: const Color(0xFF0F172A),
            onTap: onBackToHub,
          ),
        ],
      );

  Widget _buildRewards() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Kết quả trận đấu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: 12,
              children: [
                _RewardBadge(
                  icon: '⭐',
                  text: '+$xpEarned XP',
                  color: AppColors.primaryBlue,
                ),
                _RewardBadge(
                  icon: '🎯',
                  text: '$accuracy% đúng',
                  color: AppColors.jade,
                ),
                _RewardBadge(
                  icon: '🏆',
                  text: '$score điểm',
                  color: const Color(0xFFD97706),
                ),
                if (bestCombo > 0)
                  _RewardBadge(
                    icon: '🔥',
                    text: 'Combo x$bestCombo',
                    color: AppColors.crimson,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _RewardBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
