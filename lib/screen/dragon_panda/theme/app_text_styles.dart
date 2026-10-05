import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle gameTitleLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 0.5,
    shadows: [
      Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 8),
    ],
  );

  static const TextStyle gameTitleMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [
      Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  static const TextStyle chineseHanziHero = TextStyle(
    fontSize: 88,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
  );

  static const TextStyle chineseHanziQuestion = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
  );

  static const TextStyle pinyinText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 0.3,
    shadows: [
      Shadow(color: Colors.black38, offset: Offset(0, 1.5), blurRadius: 3),
    ],
  );

  static const TextStyle floatingDamageGold = TextStyle(
    fontSize: 46,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryGold,
    shadows: [
      Shadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 10),
      Shadow(color: Color(0xFFFF9F1C), offset: Offset(0, 0), blurRadius: 16),
    ],
  );

  static const TextStyle floatingDamageRed = TextStyle(
    fontSize: 46,
    fontWeight: FontWeight.w900,
    color: AppColors.dangerRed,
    shadows: [
      Shadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 10),
      Shadow(color: Color(0xFFFF1744), offset: Offset(0, 0), blurRadius: 16),
    ],
  );
}
