import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/controller/home_controller.dart';
import '../home/widgets/home_bottom_navigation.dart';
import '../home/widgets/home_decorations.dart';
import 'view/game_hub_view.dart';
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
  const GameHubScreen({super.key, this.embedded = false});

  final bool embedded;

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
    final menu = GameHubView(
      onBossBattle: _openBossBattle,
      onRadicalBuilder: _openRadicalBuilder,
      onToneNinja: _openToneNinja,
      onRestaurant: _openRestaurant,
      onQuickAnswer: _openQuickAnswer,
      onStageMap: _openStageMap,
    );
    if (embedded) return menu;
    return Scaffold(
      backgroundColor: homeCream,
      extendBody: true,
      body: menu,
      bottomNavigationBar: HomeBottomNavigation(
        currentIndex: 2,
        onSelected: (index) {
          if (index == 2) return;
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().setIndex(index);
          }
          Get.back();
        },
      ),
    );
  }
}
