import 'package:flutter/material.dart';

import '../../../screen/game_hub/view/game_hub_view.dart';
import '../../../screen/home/widgets/home_bottom_navigation.dart';
import '../../../screen/home/widgets/home_decorations.dart';

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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: homeCream,
        extendBody: true,
        body: GameHubView(
          onBossBattle: onSelectBossBattle,
          onRadicalBuilder: onSelectRadicalBuilder,
          onToneNinja: onSelectToneNinja,
          onRestaurant: onSelectRestaurant,
          onQuickAnswer: onSelectQuickAnswer,
        ),
        bottomNavigationBar: HomeBottomNavigation(
          currentIndex: 2,
          onSelected: (index) {
            if (index != 2) onBackToHome();
          },
        ),
      );
}
