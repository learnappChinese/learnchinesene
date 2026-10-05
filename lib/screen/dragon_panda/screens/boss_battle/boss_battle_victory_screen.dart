import 'package:flutter/material.dart';
import 'widgets/boss_victory_content.dart';
import 'package:flash_learn_chinese/core/widgets/centered_scroll_view.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/victory_bg.png
/// 2. Character:  assets/images/characters/panda_victory.png
class BossBattleVictoryScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBackToHub;

  const BossBattleVictoryScreen({
    Key? key,
    required this.onContinue,
    required this.onBackToHub,
  }) : super(key: key);

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
                onContinue: onContinue, onBackToHub: onBackToHub)),
      ),
    );
  }
}
