import 'package:flutter/material.dart';
import '../../../screen/home/widgets/home_bottom_navigation.dart';
import '../../../screen/home/widgets/home_dashboard.dart';
import '../../../screen/home/widgets/home_decorations.dart';

/// The standalone game preview uses the same artwork and widgets as the app.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigateToGameHub});
  final VoidCallback onNavigateToGameHub;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: homePageBackground,
        extendBody: true,
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
        bottomNavigationBar: HomeBottomNavigation(
          currentIndex: 0,
          onSelected: (index) {
            if (index != 0) onNavigateToGameHub();
          },
        ),
      );
}
