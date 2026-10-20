import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_decorations.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final homeSelected = currentIndex == 0;
    final homeColor = homeSelected ? homeGreen : const Color(0xFFF0F2EC);
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(22.w, 0, 22.w, 16.w),
      child: SizedBox(
        height: 86.w,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _buildDestinations(context),
            _buildHomeDestination(homeSelected, homeColor),
          ],
        ),
      ),
    );
  }

  Widget _destination(
      BuildContext context, int index, IconData icon, String label,
      {bool isComingSoon = false}) {
    final selected = !isComingSoon && currentIndex == index;
    const primary = homeGreen;
    final color = isComingSoon
        ? const Color(0xFF94A3B8)
        : (selected ? primary : const Color(0xFF666E60));

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 2.w),
        Text(
          isComingSoon ? 'Sắp ra mắt' : label,
          maxLines: 1,
          style: TextStyle(
            fontSize: isComingSoon ? 8.sp : 9.sp,
            height: 1,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (isComingSoon) {
      content = Opacity(
        opacity: 0.45,
        child: content,
      );
    }

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: isComingSoon ? '$label - Sắp ra mắt' : label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28.r),
            onTap: () {
              if (isComingSoon) {
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
              } else {
                onSelected(index);
              }
            },
            child: Ink(
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: .12)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? primary.withValues(alpha: .3)
                      : Colors.transparent,
                  width: 1.w,
                ),
                borderRadius: BorderRadius.circular(28.r),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinations(BuildContext context) {
    return Container(
      height: 63.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34.r),
        border: Border.all(color: const Color(0xFFC0D4BB), width: 1.5.w),
        boxShadow: [
          BoxShadow(
              color: const Color(0x33334E35),
              blurRadius: 18.r,
              spreadRadius: 1.w,
              offset: Offset(0, 5.w))
        ],
      ),
      child: Row(children: [
        _destination(context, 1, Icons.menu_book_rounded, 'Học tập'),
        _destination(context, 2, Icons.sports_esports_rounded, 'Trò chơi', isComingSoon: true),
        const Expanded(child: SizedBox()),
        _destination(context, 3, Icons.bar_chart_rounded, 'Tiến độ'),
        _destination(context, 4, Icons.person_rounded, 'Cá nhân'),
      ]),
    );
  }

  Widget _buildHomeDestination(bool homeSelected, Color homeColor) {
    return Positioned(
      bottom: 0,
      child: SizedBox(
        width: 92.w,
        height: 86.w,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
                left: 0,
                bottom: 17.w,
                child: HomeLeaves(size: 35.w, flip: true)),
            Positioned(right: 0, bottom: 17.w, child: HomeLeaves(size: 35.w)),
            Positioned(
                bottom: 48.w,
                child: ExcludeSemantics(
                    child: Image.asset(homeNavPandaAsset,
                        width: 59.w,
                        height: 54.w,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high))),
            Positioned(
                bottom: 9.w,
                child: Semantics(
                  label: 'Trang chủ',
                  button: true,
                  selected: currentIndex == 0,
                  child: Tooltip(
                    message: 'Trang chủ',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onSelected(0),
                        child: Ink(
                          width: 58.w,
                          height: 58.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.lerp(homeColor, Colors.white, .12)!,
                                  homeColor,
                                ]),
                            border: Border.all(color: Colors.white, width: 3.w),
                            boxShadow: [
                              BoxShadow(
                                  color: homeSelected
                                      ? homeGreen.withValues(alpha: .24)
                                      : const Color(0x22334E35),
                                  blurRadius: 5.r,
                                  offset: Offset(0, 3.w))
                            ],
                          ),
                          child: Icon(Icons.home_rounded,
                              color: homeSelected
                                  ? Colors.white
                                  : const Color(0xFF666E60),
                              size: 31.sp),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
