import 'package:flutter/material.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';
import '../../widgets/answer_button.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/quick_answer_bg.png
class QuickAnswerScreen extends StatelessWidget {
  final VoidCallback onBack;

  const QuickAnswerScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 0: PURE PURPLE/BLUE NIGHT FANTASY BACKGROUND
          // REQUIRED ASSET: assets/images/backgrounds/quick_answer_bg.png
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/quick_answer_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Night Atmospheric Vignette
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.38),
            ),
          ),

          // ==========================================
          // LAYER 1: FLUTTER GAMEPLAY UI
          // ==========================================
          _buildGameContent(),
        ],
      ),
    );
  }

  Widget _buildScoreAndTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold, width: 1.5),
            ),
            child: Row(
              children: const [
                Text('⏱️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('15s',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white30, width: 1.2),
            ),
            child: Row(
              children: const [
                Text('🏆', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('10',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardCreamBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: const [
          Icon(Icons.volume_up_rounded, color: AppColors.primaryBlue, size: 36),
          SizedBox(height: 8),
          Text(
            '电脑',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'diàn nǎo',
            style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerRows() {
    return [
// 2x2 Answer Grid
      Row(
        children: [
          AnswerButton(
            text: 'máy tính',
            state: AnswerButtonState.correct,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          AnswerButton(
            text: 'điện thoại',
            state: AnswerButtonState.idle,
            onTap: () {},
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          AnswerButton(
            text: 'màn hình',
            state: AnswerButtonState.idle,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          AnswerButton(
            text: 'bàn phím',
            state: AnswerButtonState.idle,
            onTap: () {},
          ),
        ],
      ),
    ];
  }

  Widget _buildGameContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // App Bar
            GameScreenHeader(
                title: 'Trả lời nhanh', onBack: onBack, onSettings: () {}),

            // Timer & Score Pills
            _buildScoreAndTimer(),
            const Spacer(),

            // Question Card
            _buildQuestionCard(),
            const Spacer(),

            ..._buildAnswerRows(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
