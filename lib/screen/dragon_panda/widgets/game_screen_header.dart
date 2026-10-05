import 'package:flutter/material.dart';

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
          Container(
            decoration: BoxDecoration(
                color: const Color(0x59000000), shape: BoxShape.circle),
            child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: onBack),
          ),
          Text(title,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: titleShadowColor, blurRadius: 6)])),
          Container(
            decoration: BoxDecoration(
                color: const Color(0x59000000), shape: BoxShape.circle),
            child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                onPressed: onSettings),
          ),
        ],
      );
}
