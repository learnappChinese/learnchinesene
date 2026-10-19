import 'package:flutter/material.dart';

/// Unified Chinese Fantasy Adventure design tokens.
///
/// Palette conventions:
/// - Background: warm parchment / cream.
/// - Brand jade: primary progression, success/action.
/// - Gold: XP / stars / rare reward.
/// - Deep red / crimson: Boss, danger, strong emphasis.
/// - Ink black: primary text, outline.
abstract final class AppColors {
  // Core Brand Tokens
  static const red = Color(0xFFB4232C);
  static const redDark = Color(0xFF7F1520);
  static const orange = Color(0xFFF58A45);
  static const background = Color(0xFFFFFAF0);
  static const ink = Color(0xFF241F20);
  static const muted = Color(0xFF756C6E);
  static const success = Color(0xFF26956A);
  static const error = Color(0xFFD64545);
  static const card = Colors.white;

  // Chinese Fantasy Tokens
  static const Color jade = Color(0xFF2E8A04);
  static const Color jadeDark = Color(0xFF1F6B02);
  static const Color jadeGreen = Color(0xFF45BC09);
  static const Color jadeLight = Color(0xFF45BC09);
  static const Color jadeMint = Color(0xFFE3F7D3);
  static const Color imperialGold = Color(0xFFF59E0B);
  static const Color primaryGold = Color(0xFFFFC533);
  static const Color lightGold = Color(0xFFFFF275);
  static const Color amberDark = Color(0xFFB45309);
  static const Color crimson = Color(0xFFDC2626);
  static const Color crimsonBlood = Color(0xFF8B0000);
  static const Color dangerRed = Color(0xFFF04444);
  static const Color darkRed = Color(0xFFB62028);

  // Surface & Text Tokens
  static const Color cream = Color(0xFFFFF8ED);
  static const Color creamStrong = Color(0xFFFFEED4);
  static const Color parchment = Color(0xFFFFFBEB);
  static const Color cardCream = Color(0xFFFFF7E8);
  static const Color cardCreamBorder = Color(0xFFFFE0B2);
  static const Color backgroundLight = Color(0xFFF7F5F0);
  static const Color textDark = Color(0xFF1E1E24);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Colors.white;

  // Dark & Combat Theme Colors
  static const Color primaryBlue = Color(0xFF2F80ED);
  static const Color darkBlue = Color(0xFF163B70);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color successGreen = Color(0xFF20D66B);
  static const Color primaryOrange = Color(0xFFFF9F1C);

  // Glossy Game Gradients
  static const LinearGradient orangeGoldGradient = LinearGradient(
    colors: [Color(0xFFFFC533), Color(0xFFFF9F1C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient jadeGradient = LinearGradient(
    colors: [Color(0xFF6BD12A), Color(0xFF45BC09)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient crimsonGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB4232C)],
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

  static const LinearGradient battleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2C4A83),
      Color(0xFF8A4260),
      Color(0xFFF07B45),
      Color(0xFF211521),
    ],
    stops: [0, .42, .72, 1],
  );
}
