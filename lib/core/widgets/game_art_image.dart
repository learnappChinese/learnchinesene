import 'package:flutter/material.dart';

class GameArtImage extends StatelessWidget {
  const GameArtImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.fallbackEmoji = '🐼',
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final String fallbackEmoji;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            fallbackEmoji,
            style: TextStyle(fontSize: (height ?? 64) * .42),
          ),
        ),
      ),
    );
  }
}
