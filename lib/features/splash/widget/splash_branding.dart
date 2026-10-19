import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';

class SplashBranding extends StatelessWidget {
  const SplashBranding({super.key, required this.scaleAnimation});
  final Animation<double> scaleAnimation;

  static const _ink = Color(0xFF342E10);
  static const _brown = Color(0xFF57300A);

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: GameVisualTokens.primaryGreen.withValues(alpha: .35),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Color(0x24635D3B),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31),
              child: Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Panda'),
            TextSpan(
              text: 'rin',
              style: TextStyle(color: GameVisualTokens.primaryGreen),
            ),
          ]),
          style: TextStyle(
            fontSize: 40,
            color: _ink,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Học tiếng Trung cùng Panda',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _brown,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFF1E6CF)),
          ),
          child: const Text(
            '每天进步一点点 · Mỗi ngày tiến bộ một chút',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5D5C54),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]);
}
