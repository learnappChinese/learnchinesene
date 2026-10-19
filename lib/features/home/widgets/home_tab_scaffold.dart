import 'package:flutter/material.dart';

import 'home_bottom_navigation.dart';

/// Shared chrome for standalone screens using the home tab navigation.
class HomeTabScaffold extends StatelessWidget {
  const HomeTabScaffold({
    super.key,
    required this.backgroundColor,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final Color backgroundColor;
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        extendBody: true,
        body: body,
        bottomNavigationBar: HomeBottomNavigation(
          currentIndex: currentIndex,
          onSelected: onTabSelected,
        ),
      );
}
