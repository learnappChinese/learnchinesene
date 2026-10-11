import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class LearningColors {
  static const background = Color(0xFFFFF8ED);
  static const surface = Color(0xFFFFFBF3);
  static const surfaceStrong = Color(0xFFFFEED4);
  static const jade = Color(0xFF0F766E);
  static const jadeDark = Color(0xFF064E3B);
  static const jadeSoft = Color(0xFFD1FAE5);
  static const gold = Color(0xFFF59E0B);
  static const goldDark = Color(0xFF9A6A0A);
  static const goldSoft = Color(0xFFFDE68A);
  static const red = Color(0xFF991B1B);
  static const orange = Color(0xFFF47B2D);
  static const softOrange = Color(0xFFF47B2D);
  static const ink = Color(0xFF231B1B);
  static const inkMuted = Color(0xFF776A67);
  static const muted = Color(0xFF776A67);
  static const locked = Color(0xFF9C958A);
}

abstract final class LearningSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class LearningRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const pill = 999.0;
  static const small = BorderRadius.all(Radius.circular(sm));
  static const card = BorderRadius.all(Radius.circular(lg));
}

abstract final class LearningShadow {
  static const soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x16000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x26064E3B),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ];
  static const card = soft;
}

abstract final class LearningTypography {
  static const screenTitle = TextStyle(
    color: LearningColors.ink,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const sectionTitle = TextStyle(
    color: LearningColors.ink,
    fontSize: 17,
    fontWeight: FontWeight.w900,
  );
  static const title = sectionTitle;
  static const cardTitle = TextStyle(
    color: LearningColors.ink,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );
  static const eyebrow = TextStyle(
    color: LearningColors.jadeDark,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: .9,
  );
  static const label = TextStyle(
    color: LearningColors.jadeDark,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: .7,
  );
  static const body = TextStyle(
    color: LearningColors.muted,
    fontSize: 14,
    height: 1.35,
  );
  static const caption = TextStyle(
    color: LearningColors.muted,
    fontSize: 12,
    height: 1.3,
  );
}

abstract final class LearningSystemUi {
  static const overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: LearningColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}
