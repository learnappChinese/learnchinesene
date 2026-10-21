import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/home_controller.dart';
import 'home_decorations.dart';
import 'home_streak_badge.dart';

/// Header ghim trên cùng của các tab Học tập, Trò chơi, Tiến độ và Cá nhân.
///
/// Cùng bố cục với header màn Home: biểu tượng tròn nền kem viền vàng bên
/// trái, tiêu đề + mô tả ở giữa, huy hiệu chuỗi ngày học bên phải.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentTitle,
    this.trailing,
    this.trailingSize = 0,
  });

  final IconData icon;
  final String title, subtitle;

  /// Kiểu chữ tiêu đề header, dùng chung với header màn Home.
  static TextStyle titleStyle() => TextStyle(
        color: homeInk,
        fontSize: 21.sp,
        height: 1.1,
        letterSpacing: -.3.w,
        fontWeight: FontWeight.w900,
      );

  /// Kiểu chữ dòng mô tả dưới tiêu đề, dùng chung với header màn Home.
  static TextStyle subtitleStyle() => TextStyle(
        color: AppColors.homeSubtitle,
        fontSize: 11.5.sp,
        height: 1.2,
        fontWeight: FontWeight.w600,
      );

  /// Khoảng cách giữa tiêu đề và dòng mô tả.
  static double get titleGap => 3.w;

  /// Optional trailing words of the title drawn in the brand green.
  final String? accentTitle;

  /// Phần tử thay cho huy hiệu chuỗi ngày học ở bên phải.
  final Widget? trailing;

  /// Visual size of [trailing]. It is centred in a slot as tall as the icon
  /// badge, so a large action never makes this header taller than others.
  final double trailingSize;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.viewPaddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, safeTop + 12.w, 15.w, 12.w),
      child: Row(children: [
        _buildIconBadge(),
        SizedBox(width: 10.w),
        Expanded(child: _buildTitles()),
        SizedBox(width: 8.w),
        if (trailing != null)
          SizedBox(
            width: trailingSize,
            height: 44.w,
            child: OverflowBox(
              minWidth: trailingSize,
              maxWidth: trailingSize,
              minHeight: trailingSize,
              maxHeight: trailingSize,
              child: trailing,
            ),
          )
        else
          const _StreakSlot(),
      ]),
    );
  }

  /// Vòng tròn nền kem viền vàng như ô panda ở header màn Home.
  Widget _buildIconBadge() => Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF5), Color(0xFFFFF3C7)],
          ),
          border: Border.all(color: const Color(0xFFFFDB87), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24956A23),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: homeGreen, size: 23.sp),
      );

  Widget _buildTitles() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: title),
                if (accentTitle != null)
                  TextSpan(
                    text: ' $accentTitle',
                    style: const TextStyle(color: AppColors.homeGreenText),
                  ),
              ]),
              maxLines: 1,
              style: titleStyle(),
            ),
          ),
          SizedBox(height: titleGap),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle(),
          ),
        ],
      );
}

/// Huy hiệu chuỗi ngày học giống góc phải màn Home; chạm để mở tab Tiến độ.
class _StreakSlot extends StatelessWidget {
  const _StreakSlot();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomeController>()) return const SizedBox.shrink();
    final controller = Get.find<HomeController>();
    return Obx(() {
      final streak = controller.streak.value > 0
          ? controller.streak.value
          : (controller.stats['streak']?.toInt() ?? 0);
      return HomeStreakBadge(
        streak: streak,
        onTap: () => controller.setIndex(3),
      );
    });
  }
}
