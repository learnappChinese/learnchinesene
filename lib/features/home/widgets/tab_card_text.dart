import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared typography for action cards on the four main tabs.
class TabCardText extends StatelessWidget {
  const TabCardText({
    super.key,
    required this.title,
    required this.description,
    required this.titleColor,
    this.descriptionColor,
  });

  final String title, description;
  final Color titleColor;
  final Color? descriptionColor;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 18.sp,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 5.w),
          Text(
            description,
            style: TextStyle(
              color: descriptionColor ?? titleColor,
              fontSize: 15.sp,
              height: 1.3,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(color: Color(0xCCFFFFFF), blurRadius: 3),
              ],
            ),
          ),
        ],
      );
}
