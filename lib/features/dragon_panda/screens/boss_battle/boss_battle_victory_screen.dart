import 'package:flutter/material.dart';
import 'widgets/boss_victory_content.dart';
import 'package:pandarin/core/widgets/centered_scroll_view.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/victory_bg.png
/// 2. Character:  assets/images/characters/panda_victory.png
class BossBattleVictoryScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBackToHub;
  final int xpEarned;
  final int stars;
  final int score;
  final int accuracy;
  final int bestCombo;

  const BossBattleVictoryScreen({
    super.key,
    required this.onContinue,
    required this.onBackToHub,
    this.xpEarned = 0,
    this.stars = 3,
    this.score = 0,
    this.accuracy = 0,
    this.bestCombo = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ..._buildBackgroundLayers(),
          // ==========================================
          // LAYER 1: FLUTTER CELEBRATION UI
          // ==========================================
          _buildResultContent(),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundLayers() {
    return [
      // ==========================================
      // LAYER 0: PURE GOLDEN TREASURE BACKGROUND
      // REQUIRED ASSET: assets/images/backgrounds/victory_bg.png
      // ==========================================
      Positioned.fill(
        child: Image.asset(
          'assets/images/backgrounds/victory_bg.png',
          fit: BoxFit.cover,
        ),
      ),

      // Warm Ambient Glow
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4),
              ],
              radius: 0.9,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildResultContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: CenteredScrollView(
            child: BossVictoryContent(
          onContinue: onContinue,
          onBackToHub: onBackToHub,
          xpEarned: xpEarned,
          stars: stars,
          score: score,
          accuracy: accuracy,
          bestCombo: bestCombo,
        )),
      ),
    );
  }
}
