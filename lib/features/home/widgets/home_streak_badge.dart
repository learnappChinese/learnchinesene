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
    final radius = BorderRadius.circular(22.r);
    return Container(
      // Cao 44 bằng ô biểu tượng bên trái header.
      width: 100.w,
      height: 44.w,
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
                  width: 24.w,
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('🔥',
                          style: TextStyle(fontSize: 24.sp, height: 1)),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    // Số và chữ "ngày" cỡ khác nhau: dùng Row căn giữa dọc
                    // thay vì TextSpan (TextSpan căn theo chân chữ).
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('$streak',
                            style: TextStyle(
                                color: const Color(0xFFEF4B20),
                                fontSize: 18.sp,
                                height: 1,
                                fontWeight: FontWeight.w900)),
                        SizedBox(width: 4.w),
                        Text('ngày',
                            style: TextStyle(
                                color: const Color(0xFFAF6039),
                                fontSize: 12.5.sp,
                                height: 1,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
