import 'package:flutter/material.dart';
import 'widget/radical_builder_options.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/radical_builder_bg.png
class RadicalBuilderScreen extends StatelessWidget {
  final VoidCallback onBack;

  const RadicalBuilderScreen({Key? key, required this.onBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 0: PURE PEACEFUL CHINESE GARDEN BACKGROUND
          // REQUIRED ASSET: assets/images/backgrounds/radical_builder_bg.png
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/radical_builder_bg.png',
              fit: BoxFit.cover,
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

  Widget _buildRoundProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 12,
                color: Colors.black.withOpacity(0.35),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.orangeGoldGradient,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '6 / 10',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard() {
    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.cardCreamBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '好',
          style: TextStyle(
            fontSize: 105,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildRadicalTray() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF8).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['女', '子', '丿', '一'].map((radical) {
          return RadicalOptionTile(radical: radical, onTap: () {});
        }).toList(),
      ),
    );
  }

  Widget _buildGameContent() {
    return SafeArea(
      child: Column(
        children: [
          // Top App Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GameScreenHeader(
                title: 'Xây chữ Hán',
                onBack: onBack,
                onSettings: () {},
                titleShadowColor: Colors.black87),
          ),

          // Progress Bar: 6 / 10
          _buildRoundProgress(),
          const Spacer(),

          // Main Chinese Character Card (好)
          _buildCharacterCard(),
          const Spacer(),

          // Radical / Component Selection Tray
          _buildRadicalTray(),
        ],
      ),
    );
  }
}
