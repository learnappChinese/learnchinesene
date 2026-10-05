import 'package:flutter/material.dart';

import 'package:flash_learn_chinese/screen/game_hub/view/game_hub_view.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_tab_scaffold.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_decorations.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({
    super.key,
    required this.onSelectBossBattle,
    required this.onSelectRadicalBuilder,
    required this.onSelectToneNinja,
    required this.onSelectRestaurant,
    required this.onSelectQuickAnswer,
    required this.onBackToHome,
  });

  final VoidCallback onSelectBossBattle, onSelectRadicalBuilder;
  final VoidCallback onSelectToneNinja, onSelectRestaurant, onSelectQuickAnswer;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) => HomeTabScaffold(
        backgroundColor: homeCream,
        body: GameHubView(
          onBossBattle: onSelectBossBattle,
          onRadicalBuilder: onSelectRadicalBuilder,
          onToneNinja: onSelectToneNinja,
          onRestaurant: onSelectRestaurant,
          onQuickAnswer: onSelectQuickAnswer,
        ),
        currentIndex: 2,
        onTabSelected: _handleTabSelected,
      );

  void _handleTabSelected(int index) {
    if (index != 2) onBackToHome();
  }
}
