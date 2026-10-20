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
        onDestinationSelected: (idx) {
          if (idx == 2) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Tính năng Trò chơi đang được nâng cấp và sắp ra mắt bạn nhé! 🎮',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF334E35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          }
          onSelected(idx);
        },
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
            icon: Opacity(
              opacity: 0.45,
              child: Icon(Icons.sports_esports_outlined, color: Color(0xFF94A3B8)),
            ),
            selectedIcon: Opacity(
              opacity: 0.45,
              child: Icon(Icons.sports_esports_rounded, color: Color(0xFF94A3B8)),
            ),
            label: Opacity(
              opacity: 0.45,
              child: Text('Sắp ra mắt', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
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
