import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dragon_panda/theme/app_colors.dart';
import '../../dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart';
import '../../dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart';
import '../../dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import '../../dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import '../../dragon_panda/screens/radical_builder/radical_builder_screen.dart';
import '../../dragon_panda/screens/tone_ninja/tone_ninja_screen.dart';
import '../../dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart';
import '../../dragon_panda/screens/quick_answer/quick_answer_screen.dart';
import '../boss_battle/boss_stage_map_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({Key? key}) : super(key: key);

  void _openBossBattle() {
    Get.to(
      () => BossBattleIntroScreen(
        onBack: () => Get.back(),
        onStartGame: () => Get.to(
          () => BossBattleGameplayScreen(
            onExit: () => Get.back(),
            onVictory: () => Get.off(
              () => BossBattleVictoryScreen(
                onContinue: () => Get.off(
                  () => BossBattleGameplayScreen(
                    onExit: () => Get.back(),
                    onVictory: () => Get.off(
                      () => BossBattleVictoryScreen(
                        onContinue: () => Get.back(),
                        onBackToHub: () => Get.back(),
                      ),
                    ),
                    onDefeat: () => Get.off(
                      () => BossBattleDefeatScreen(
                        onRetry: () => Get.back(),
                        onBackToHub: () => Get.back(),
                      ),
                    ),
                  ),
                ),
                onBackToHub: () => Get.back(),
              ),
            ),
            onDefeat: () => Get.off(
              () => BossBattleDefeatScreen(
                onRetry: () => Get.off(
                  () => BossBattleGameplayScreen(
                    onExit: () => Get.back(),
                    onVictory: () => Get.off(
                      () => BossBattleVictoryScreen(
                        onContinue: () => Get.back(),
                        onBackToHub: () => Get.back(),
                      ),
                    ),
                    onDefeat: () => Get.off(
                      () => BossBattleDefeatScreen(
                        onRetry: () => Get.back(),
                        onBackToHub: () => Get.back(),
                      ),
                    ),
                  ),
                ),
                onBackToHub: () => Get.back(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openStageMap() {
    Get.to(() => const BossBattleStageMapScreen());
  }

  void _openRadicalBuilder() {
    Get.to(() => RadicalBuilderScreen(onBack: () => Get.back()));
  }

  void _openToneNinja() {
    Get.to(() => ToneNinjaScreen(onBack: () => Get.back()));
  }

  void _openRestaurant() {
    Get.to(() => ChineseRestaurantScreen(onBack: () => Get.back()));
  }

  void _openQuickAnswer() {
    Get.to(() => QuickAnswerScreen(onBack: () => Get.back()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 0: PURE BACKGROUND ART
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/game_hub_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Atmospheric Dark Tint for Card Contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          // ==========================================
          // LAYER 1: FLUTTER GAME CARDS & NAVIGATION
          // ==========================================
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Trò chơi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Stage Map Icon shortcut
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.map_rounded,
                            color: AppColors.primaryGold,
                            size: 22,
                          ),
                          tooltip: 'Hành trình Ải',
                          onPressed: _openStageMap,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Học tiếng Trung qua những trò chơi thú vị!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 1. BOSS BATTLE (Hero Highlighted Game Card)
                        _buildGameCard(
                          title: 'Boss Battle',
                          description: 'Đánh bại Boss bằng kiến thức tiếng Trung!',
                          assetPath: 'assets/images/icons/boss_battle_thumb.png',
                          badge: 'HOT',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8B0000),
                              Color(0xFFD32F2F),
                              Color(0xFFFF6F00),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: _openBossBattle,
                        ),
                        const SizedBox(height: 14),

                        // 2. XÂY CHỮ HÁN
                        _buildGameCard(
                          title: 'Xây chữ Hán',
                          description: 'Xây chữ Hán từ bộ thủ',
                          assetPath: 'assets/images/icons/radical_builder_thumb.png',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: _openRadicalBuilder,
                        ),
                        const SizedBox(height: 14),

                        // 3. TONE NINJA
                        _buildGameCard(
                          title: 'Tone Ninja',
                          description: 'Luyện thanh điệu như ninja',
                          assetPath: 'assets/images/icons/tone_ninja_thumb.png',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: _openToneNinja,
                        ),
                        const SizedBox(height: 14),

                        // 4. NHÀ HÀNG TRUNG HOA
                        _buildGameCard(
                          title: 'Nhà hàng Trung Hoa',
                          description: 'Phục vụ món ăn bằng tiếng Trung',
                          assetPath: 'assets/images/icons/restaurant_thumb.png',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB45309), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: _openRestaurant,
                        ),
                        const SizedBox(height: 14),

                        // 5. TRẢ LỜI NHANH
                        _buildGameCard(
                          title: 'Trả lời nhanh',
                          description: 'Thử thách phản xạ tiếng Trung',
                          assetPath: 'assets/images/icons/quick_answer_thumb.png',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: _openQuickAnswer,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required String assetPath,
    required Gradient gradient,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Text('🎮', style: TextStyle(fontSize: 28))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7F0000),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF1F5F9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
