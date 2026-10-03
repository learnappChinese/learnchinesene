import 'package:flutter/material.dart';

class GameAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final String fallbackEmoji;

  const GameAssetImage({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
    this.fallbackEmoji = '🎮',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (fallback != null) return fallback!;
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: Text(
            fallbackEmoji,
            style: TextStyle(fontSize: (height != null) ? (height! * 0.5) : 32),
          ),
        );
      },
    );
  }
}
