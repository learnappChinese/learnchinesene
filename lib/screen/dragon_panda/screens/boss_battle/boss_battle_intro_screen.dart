import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'widgets/boss_battle_introduction.dart';
import '../../widgets/game_button.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/boss_intro_bg.png
/// 2. Characters: assets/images/characters/dragon_fire.png
///                assets/images/characters/panda_archer.png
class BossBattleIntroScreen extends StatelessWidget {
  final VoidCallback onStartGame;
  final VoidCallback onBack;

  const BossBattleIntroScreen({
    Key? key,
    required this.onStartGame,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 0: PURE EPIC BATTLEFIELD BACKGROUND (NO CHARACTERS, NO UI)
          // REQUIRED ASSET: assets/images/backgrounds/boss_intro_bg.png
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/boss_intro_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ==========================================
          // LAYER 1: FOREGROUND CHARACTERS
          // ==========================================
          ..._buildBattleCharacters(),
          // ==========================================
          // LAYER 2: FLUTTER UI & INFO CARD
          // ==========================================
          _buildIntroductionContent(),
        ],
      ),
    );
  }

  List<Widget> _buildBattleCharacters() {
    return [
      // 1. Fire Dragon on Upper Right
      Positioned(
        top: 70,
        right: -25,
        width: 270,
        height: 270,
        child: Image.asset(
          'assets/images/characters/dragon_fire.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Center(child: Text('🐲🔥', style: TextStyle(fontSize: 80))),
        ),
      ),

      // 2. Panda Archer on Lower Left
      Positioned(
        bottom: 220,
        left: 10,
        width: 210,
        height: 210,
        child: Image.asset(
          'assets/images/characters/panda_archer.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Center(child: Text('🐼🏹', style: TextStyle(fontSize: 70))),
        ),
      ),
    ];
  }

  Widget _buildIntroductionContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                  child: Column(
                children: [
                  BossBattleIntroHeader(onBack: onBack),
                  const Spacer(),

                  // Bottom Info Card (3 Bullet Points)
                  const BossBattleIntroductionCard(),
                  const SizedBox(height: 20),

                  // Start Button
                  GameButton(
                    text: '⚔️ Bắt đầu chơi',
                    gradient: AppColors.orangeGoldGradient,
                    height: 56,
                    borderRadius: 24,
                    onTap: onStartGame,
                  ),
                  const SizedBox(height: 16),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}
