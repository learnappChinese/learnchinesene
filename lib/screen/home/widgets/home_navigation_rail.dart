import 'package:flutter/material.dart';

class HomeNavigationRail extends StatelessWidget {
  const HomeNavigationRail(
      {super.key,
      required this.index,
      required this.onSelected,
      this.extended = false});
  final int index;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) => NavigationRail(
        selectedIndex: index,
        onDestinationSelected: onSelected,
        extended: extended,
        labelType: extended ? null : NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: Text('Trang chủ'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: Text('Học tập'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: Text('Trò chơi'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: Text('Tiến độ'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: Text('Cá nhân'),
          ),
        ],
      );
}
