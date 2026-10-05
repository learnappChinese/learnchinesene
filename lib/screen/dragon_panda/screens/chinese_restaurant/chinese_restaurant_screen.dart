import 'package:flutter/material.dart';
import 'widget/chinese_restaurant_options.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';

/// REQUIRED ASSETS:
/// 1. Background: assets/images/backgrounds/restaurant_bg.png
/// 2. Character:  assets/images/characters/panda_chef.png
/// 3. Foods:      assets/images/foods/noodles.png
///                assets/images/foods/rice.png
///                assets/images/foods/dumplings.png
class ChineseRestaurantScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ChineseRestaurantScreen({Key? key, required this.onBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 0: PURE RESTAURANT INTERIOR BACKGROUND
          // REQUIRED ASSET: assets/images/backgrounds/restaurant_bg.png
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/restaurant_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ==========================================
          // LAYER 1: FLUTTER GAMEPLAY UI & PANDA CHEF
          // ==========================================
          _buildGameContent(),
        ],
      ),
    );
  }

  Widget _buildCustomerOrder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: const [
          Text(
            '请给我一碗面。',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          SizedBox(height: 2),
          Text(
            '(Làm ơn cho tôi một bát mì.)',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodChoices() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RestaurantFoodCard(
              hanzi: '面',
              vietnamese: 'Mì',
              assetPath: 'assets/images/foods/noodles.png',
              fallbackEmoji: '🍜',
              onTap: () {}),
          RestaurantFoodCard(
              hanzi: '米饭',
              vietnamese: 'Cơm',
              assetPath: 'assets/images/foods/rice.png',
              fallbackEmoji: '🍚',
              onTap: () {}),
          RestaurantFoodCard(
              hanzi: '饺子',
              vietnamese: 'Sủi cảo',
              assetPath: 'assets/images/foods/dumplings.png',
              fallbackEmoji: '🥟',
              onTap: () {}),
        ],
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
                title: 'Nhà hàng Trung Hoa',
                onBack: onBack,
                onSettings: () {},
                titleSize: 20),
          ),

          // Customer Speech Bubble
          _buildCustomerOrder(),

          // Progress Indicator 4/10
          Container(
            width: 140,
            height: 10,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Panda Chef Behind Counter
          SizedBox(
            width: 190,
            height: 190,
            child: Image.asset(
              'assets/images/characters/panda_chef.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('🐼🍜👨‍🍳', style: TextStyle(fontSize: 70))),
            ),
          ),
          const Spacer(),

          // 3 Food Choice Cards Tray
          _buildFoodChoices(),
        ],
      ),
    );
  }
}
