import 'package:flutter/material.dart';
import 'widgets/boss_defeat_content.dart';
import 'package:flash_learn_chinese/core/widgets/centered_scroll_view.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/defeat_bg.png
/// 2. Character:  assets/images/characters/panda_dizzy.png
class BossBattleDefeatScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBackToHub;

  const BossBattleDefeatScreen({
    Key? key,
    required this.onRetry,
    required this.onBackToHub,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ..._buildBackgroundLayers(),
          // ==========================================
          // LAYER 1: FLUTTER UI & CHARACTERS
          // ==========================================
          _buildResultContent(),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundLayers() {
    return [
      // ==========================================
      // LAYER 0: PURE DARK DAMAGED BATTLEFIELD
      // REQUIRED ASSET: assets/images/backgrounds/defeat_bg.png
      // ==========================================
      Positioned.fill(
        child: Image.asset(
          'assets/images/backgrounds/defeat_bg.png',
          fit: BoxFit.cover,
        ),
      ),

      // Dark Smoky Vignette
      Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.4),
        ),
      ),
    ];
  }

  Widget _buildResultContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: CenteredScrollView(
            child:
                BossDefeatContent(onRetry: onRetry, onBackToHub: onBackToHub)),
      ),
    );
  }
}
