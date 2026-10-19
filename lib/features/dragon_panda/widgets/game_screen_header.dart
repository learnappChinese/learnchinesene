import 'package:flutter/material.dart';

import '../../../core/widgets/app_back_button.dart';

class GameScreenHeader extends StatelessWidget {
  const GameScreenHeader(
      {super.key,
      required this.title,
      required this.onBack,
      required this.onSettings,
      this.titleSize = 22,
      this.titleShadowColor = Colors.black});
  final String title;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final double titleSize;
  final Color titleShadowColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppBackButton(onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: titleShadowColor, blurRadius: 6)],
              ),
            ),
          ),
          AppHudIconButton(
            icon: Icons.settings_rounded,
            tooltip: 'Cài đặt',
            onPressed: onSettings,
          ),
        ],
      );
}
