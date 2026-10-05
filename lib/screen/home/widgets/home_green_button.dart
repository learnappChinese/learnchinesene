import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_decorations.dart';

class HomeGreenButton extends StatelessWidget {
  const HomeGreenButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.playIcon = false,
      this.chevronIcon = false});
  final String label;
  final VoidCallback onTap;
  final bool playIcon;
  final bool chevronIcon;

  @override
  Widget build(BuildContext context) {
    const primary = homeGreen;
    final radius = 19.w;
    final buttonHeight = (playIcon ? 38 : 36).w;

    return Container(
      padding: EdgeInsets.only(bottom: 3.w),
      decoration: BoxDecoration(
        color: Color.lerp(primary, Colors.black, .24),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .28),
            blurRadius: 8.w,
            offset: Offset(0, 5.w),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: buttonHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .55, 1],
              colors: [
                Color.lerp(primary, Colors.white, .12)!,
                primary,
                Color.lerp(primary, Colors.black, .06)!,
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Color.lerp(primary, Colors.white, .32)!,
              width: 1.5.w,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 9.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (playIcon) ...[
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22.w,
                        ),
                        SizedBox(width: 7.w),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (playIcon ? 14 : 13).sp,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              color: Color(0x33000000),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      if (chevronIcon) ...[
                        SizedBox(width: 2.w),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 17.w),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
