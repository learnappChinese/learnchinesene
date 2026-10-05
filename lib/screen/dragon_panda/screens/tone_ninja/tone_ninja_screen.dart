import 'package:flutter/material.dart';
import 'widget/tone_ninja_options.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/tone_ninja_bg.png
/// 2. Character:  assets/images/characters/panda_ninja.png
class ToneNinjaScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ToneNinjaScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 0: PURE CHINESE VILLAGE AT NIGHT BACKGROUND
          // REQUIRED ASSET: assets/images/backgrounds/tone_ninja_bg.png
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/tone_ninja_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Night Vignette
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // ==========================================
          // LAYER 1: FLUTTER GAMEPLAY UI & NINJA PANDA
          // ==========================================
          _buildGameContent(),
        ],
      ),
    );
  }

  Widget _buildScoreAndLives() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '⭐ 3 / 10',
            style: TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          Row(
            children: [
              Text('❤️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 4),
              Text('❤️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 4),
              Text('❤️', style: TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPinyin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.volume_up_rounded, color: AppColors.primaryBlue, size: 32),
          SizedBox(width: 12),
          Text(
            'mǎ',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneOptions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: [
        const ToneOptionCard(text: 'mǎ (3)', isCorrect: true),
        const ToneOptionCard(text: 'mā (1)'),
        const ToneOptionCard(text: 'má (2)'),
        const ToneOptionCard(text: 'mà (4)'),
      ],
    );
  }

  Widget _buildGameContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // App Bar
            GameScreenHeader(
                title: 'Tone Ninja', onBack: onBack, onSettings: () {}),

            // Score & 3 Hearts
            _buildScoreAndLives(),
            const Spacer(),

            // Ninja Panda Character Overlay
            SizedBox(
              width: 140,
              height: 140,
              child: Image.asset(
                'assets/images/characters/panda_ninja.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                    child: Text('🥷🐼', style: TextStyle(fontSize: 64))),
              ),
            ),
            const SizedBox(height: 14),

            // Speaker Button & Target Pinyin
            _buildTargetPinyin(),
            const Spacer(),

            // 4 Tone Options in 2x2 Grid
            _buildToneOptions(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
