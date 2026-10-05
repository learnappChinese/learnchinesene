import 'package:flutter/material.dart';
import '../responsive/responsive_layout.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar(
      {super.key,
      required this.child,
      this.verticalPadding = 12,
      this.shadowBlur = 16,
      this.shadowOffset = -4});
  final Widget child;
  final double verticalPadding;
  final double shadowBlur;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: EdgeInsets.fromLTRB(
            ResponsiveHelper.horizontalPadding(context),
            verticalPadding,
            ResponsiveHelper.horizontalPadding(context),
            verticalPadding + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: const Color(0x14000000),
              blurRadius: shadowBlur,
              offset: Offset(0, shadowOffset))
        ]),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context)),
            child: child),
      );
}
