import 'package:flutter/material.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_tab_scaffold.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_dashboard.dart';
import 'package:flash_learn_chinese/screen/home/widgets/home_decorations.dart';

/// The standalone game preview uses the same artwork and widgets as the app.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigateToGameHub});
  final VoidCallback onNavigateToGameHub;

  @override
  Widget build(BuildContext context) => HomeTabScaffold(
        backgroundColor: homePageBackground,
        body: SafeArea(
          top: false,
          bottom: false,
          child: HomeDashboard(
            onStartLearning: onNavigateToGameHub,
            onGrammar: onNavigateToGameHub,
            onListening: onNavigateToGameHub,
            onSpeaking: onNavigateToGameHub,
            onChallenge: onNavigateToGameHub,
            onProgress: onNavigateToGameHub,
          ),
        ),
        currentIndex: 0,
        onTabSelected: _handleTabSelected,
      );

  void _handleTabSelected(int index) {
    if (index != 0) onNavigateToGameHub();
  }
}
