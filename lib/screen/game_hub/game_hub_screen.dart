import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/quick_answer/quick_answer_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/radical_builder/radical_builder_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/tone_ninja/tone_ninja_screen.dart'
    show ToneNinjaScreen;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/controller/home_controller.dart';
import '../home/widgets/home_tab_scaffold.dart';
import '../home/widgets/home_decorations.dart';
import 'view/game_hub_view.dart';

import '../boss_battle/boss_stage_map_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key, this.embedded = false});

  final bool embedded;

  void _back() => Get.back();

  void _openBossBattle() {
    Get.to(() => BossBattleIntroScreen(
          onBack: _back,
          onStartGame: _openInitialBossGameplay,
        ));
  }

  void _openInitialBossGameplay() {
    Get.to(() => BossBattleGameplayScreen(
          onExit: _back,
          onVictory: _openInitialVictory,
          onDefeat: _openInitialDefeat,
        ));
  }

  void _openInitialVictory() {
    Get.off(() => BossBattleVictoryScreen(
          onContinue: _openReplayBossGameplay,
          onBackToHub: _back,
        ));
  }

  void _openInitialDefeat() {
    Get.off(() => BossBattleDefeatScreen(
          onRetry: _openReplayBossGameplay,
          onBackToHub: _back,
        ));
  }

  void _openReplayBossGameplay() {
    Get.off(() => BossBattleGameplayScreen(
          onExit: _back,
          onVictory: _openReplayVictory,
          onDefeat: _openReplayDefeat,
        ));
  }

  void _openReplayVictory() {
    Get.off(() => BossBattleVictoryScreen(
          onContinue: _back,
          onBackToHub: _back,
        ));
  }

  void _openReplayDefeat() {
    Get.off(() => BossBattleDefeatScreen(
          onRetry: _back,
          onBackToHub: _back,
        ));
  }

  void _selectTab(int index) {
    if (index == 2) return;
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().setIndex(index);
    }
    Get.back();
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
    final menu = _buildGameMenu();
    if (embedded) return menu;
    return HomeTabScaffold(
      backgroundColor: homeCream,
      body: menu,
      currentIndex: 2,
      onTabSelected: _selectTab,
    );
  }

  Widget _buildGameMenu() {
    return GameHubView(
      onBossBattle: _openBossBattle,
      onRadicalBuilder: _openRadicalBuilder,
      onToneNinja: _openToneNinja,
      onRestaurant: _openRestaurant,
      onQuickAnswer: _openQuickAnswer,
      onStageMap: _openStageMap,
    );
  }
}
