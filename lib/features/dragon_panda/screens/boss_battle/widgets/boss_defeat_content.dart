import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/game_button.dart';

class BossDefeatContent extends StatelessWidget {
  const BossDefeatContent({
    super.key,
    required this.onRetry,
    required this.onBackToHub,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.accuracy = 0,
    this.bossHp = 0,
  });
  final VoidCallback onRetry;
  final VoidCallback onBackToHub;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int accuracy;
  final int bossHp;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Defeat Title
          const Text(
            'Thất bại!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.dangerRed,
              shadows: [
                Shadow(
                    color: Colors.black, blurRadius: 10, offset: Offset(0, 3)),
                Shadow(color: Color(0xFFB62028), blurRadius: 16),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          const Text(
            'Đừng bỏ cuộc!\nHãy luyện tập thêm để mạnh hơn nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFE2E8F0),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),

          // Tired Panda
          SizedBox(
            width: 170,
            height: 170,
            child: Image.asset(
              'assets/images/characters/panda_dizzy.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('🐼💫🥀', style: TextStyle(fontSize: 64))),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                const Text(
                  'BÁO CÁO TRẬN ĐẤU',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _DefeatMetric(label: 'ĐIỂM', value: '$score'),
                    _DefeatMetric(label: 'CHÍNH XÁC', value: '$accuracy%'),
                    _DefeatMetric(
                      label: 'ĐÚNG / SAI',
                      value: '$correctCount / $wrongCount',
                    ),
                    _DefeatMetric(label: 'BOSS CÒN', value: '$bossHp HP'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  accuracy < 60
                      ? 'Gợi ý: ôn lại từ vựng vừa gặp rồi thử lại.'
                      : 'Bạn đã rất gần chiến thắng. Giữ combo để gây nhiều sát thương hơn.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // "Thử lại" Button (Orange)
          GameButton(
            text: 'Thử lại',
            gradient: AppColors.orangeGoldGradient,
            onTap: onRetry,
          ),
          const SizedBox(height: 12),

          // "Về Game Hub" Button (Dark Blue)
          GameButton(
            text: 'Về Game Hub',
            gradient: AppColors.darkBlueGradient,
            shadowColor: const Color(0xFF0F172A),
            onTap: onBackToHub,
          ),
        ],
      );
}

class _DefeatMetric extends StatelessWidget {
  const _DefeatMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}
