import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_decorations.dart';

/// Compact pinned header shared by the Learning, Games, Progress and Personal tabs.
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

  /// Optional trailing words of the title drawn in the brand green.
  final String? accentTitle;
  final Widget? trailing;

  /// Visual size of [trailing]. It is centred in a slot as tall as the icon
  /// badge, so a large action never makes this header taller than others.
  final double trailingSize;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.viewPaddingOf(context).top;
    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, safeTop + 10.w, 16.w, 14.w),
        child: Row(children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6BD12A), homeGreen],
              ),
              boxShadow: [
                BoxShadow(
                    color: homeGreen.withValues(alpha: .28),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.w)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 25.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
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
                            style: const TextStyle(color: Color(0xFF2E8F12))),
                    ]),
                    maxLines: 1,
                    style: TextStyle(
                        color: homeInk,
                        fontSize: 24.sp,
                        height: 1.1,
                        letterSpacing: -.4.w,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(height: 3.w),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: const Color(0xFF7A6E5D),
                        fontSize: 12.5.sp,
                        height: 1.2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 4.w),
            SizedBox(
              width: trailingSize,
              height: 46.w,
              child: OverflowBox(
                minWidth: trailingSize,
                maxWidth: trailingSize,
                minHeight: trailingSize,
                maxHeight: trailingSize,
                child: trailing,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
