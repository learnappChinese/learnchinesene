import 'package:flutter/material.dart';

class AppColors {
  // Main Theme Colors
  static const Color primaryBlue = Color(0xFF2F80ED);
  static const Color darkBlue = Color(0xFF163B70);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Warm Fantasy Palette
  static const Color primaryOrange = Color(0xFFFF9F1C);
  static const Color primaryGold = Color(0xFFFFC533);
  static const Color lightGold = Color(0xFFFFF275);
  static const Color amberDark = Color(0xFFB45309);

  // Status & Combat Colors
  static const Color successGreen = Color(0xFF20D66B);
  static const Color jadeGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFF04444);
  static const Color darkRed = Color(0xFFB62028);
  static const Color crimsonBlood = Color(0xFF8B0000);

  // Surface & Text
  static const Color cardCream = Color(0xFFFFF7E8);
  static const Color cardCreamBorder = Color(0xFFFFE0B2);
  static const Color backgroundLight = Color(0xFFF7F5F0);
  static const Color textDark = Color(0xFF1E1E24);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Colors.white;

  // Glossy Game Gradients
  static const LinearGradient orangeGoldGradient = LinearGradient(
    colors: [Color(0xFFFFC533), Color(0xFFFF9F1C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF69F0AE), Color(0xFF20D66B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFF04444)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkBlueGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF163B70)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient fireDragonGradient = LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient comboFlameGradient = LinearGradient(
    colors: [Color(0xFFFF3D00), Color(0xFFFF9100)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
