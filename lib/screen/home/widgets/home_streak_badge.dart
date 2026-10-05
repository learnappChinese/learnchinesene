import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeStreakBadge extends StatelessWidget {
  const HomeStreakBadge({
    super.key,
    required this.streak,
    required this.onTap,
  });

  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    return Container(
      width: 112.w,
      height: 50.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF5), Color(0xFFFFF5D8)],
        ),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFDDE59A), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x2BA58A3A),
            blurRadius: 6.r,
            offset: Offset(0, 3.w),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
            child: Row(
              children: [
                SizedBox(
                  width: 30.w,
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('🔥',
                          style: TextStyle(fontSize: 29.sp, height: 1)),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$streak',
                            style: TextStyle(
                                color: const Color(0xFFEF4B20),
                                fontSize: 18.sp,
                                height: 1,
                                fontWeight: FontWeight.w900)),
                        SizedBox(height: 2.w),
                        Text('Ngày liên tiếp',
                            style: TextStyle(
                                color: const Color(0xFFAF6039),
                                fontSize: 10.sp,
                                height: 1.1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: const Color(0xFFE67A3C), size: 16.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
