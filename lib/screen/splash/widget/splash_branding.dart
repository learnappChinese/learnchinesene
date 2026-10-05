import 'package:flutter/material.dart';

class SplashBranding extends StatelessWidget {
  const SplashBranding({super.key, required this.scaleAnimation});
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/logo/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Chinese Master',
          style: TextStyle(
            fontSize: 34,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Mỗi ngày tiến bộ một chút',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 48),
      ]);
}
