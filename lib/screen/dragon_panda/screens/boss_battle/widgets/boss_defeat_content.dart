import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/game_button.dart';

class BossDefeatContent extends StatelessWidget {
  const BossDefeatContent(
      {super.key, required this.onRetry, required this.onBackToHub});
  final VoidCallback onRetry;
  final VoidCallback onBackToHub;

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
          const SizedBox(height: 38),

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
