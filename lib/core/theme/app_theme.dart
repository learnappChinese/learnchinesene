import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_back_button.dart';
import 'app_colors.dart';
import 'game_visual_tokens.dart';

/// Theme chuẩn của app, lấy theo giao diện màn Home: nền kem, xanh lá
/// [AppColors.homeGreen] cho hành động chính, chữ mực nâu đậm.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.homeGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.homeGreen,
          onPrimary: Colors.white,
          primaryContainer: AppColors.homeGreenSoft,
          onPrimaryContainer: AppColors.homeGreenText,
          secondary: AppColors.imperialGold,
          error: AppColors.crimson,
          surface: AppColors.homePage,
          onSurface: AppColors.homeTitle,
          onSurfaceVariant: AppColors.homeSubtitle,
          outline: AppColors.homeBorder,
          outlineVariant: AppColors.homeCardLine,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'sans-serif',
      splashFactory: InkSparkle.splashFactory,
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const AppBackButtonFace(size: 40),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.homeInk,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.homeInk,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.homeShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameVisualTokens.radiusL),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.homeGreen.withValues(alpha: .12),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.homeGreen
                : AppColors.homeIconMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.homeGreen
                : AppColors.homeIconMuted,
            size: 24,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.homeGreen.withValues(alpha: .12),
        selectedIconTheme: const IconThemeData(color: AppColors.homeGreen),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.homeIconMuted,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.homeGreen,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.homeIconMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _raisedGreenStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _raisedGreenStyle),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.homeGreen,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFCF4),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Colors.white, width: 3),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.homeTitle,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.homeBody,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFCF4),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.homeGreenLink,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      // Nút phụ phẳng; chỉ nút chính (Filled/Elevated) mới nổi khối.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.homeGreenLink,
          disabledForegroundColor: AppColors.homeSubtitle,
          side: const BorderSide(color: AppColors.homeBorder, width: 1.5),
          shape: _buttonShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.homeGreenSoft,
        checkmarkColor: AppColors.homeGreenText,
        side: const BorderSide(color: AppColors.homeBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameVisualTokens.radiusS),
        ),
        labelStyle: const TextStyle(
          color: AppColors.homeInk,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.homeSubtitle),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GameVisualTokens.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GameVisualTokens.radiusM),
          borderSide: const BorderSide(color: AppColors.homeBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GameVisualTokens.radiusM),
          borderSide: const BorderSide(color: AppColors.homeGreen, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.homeSnackBar,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.homeGreen,
        linearTrackColor: AppColors.homeTrack,
      ),
      dividerColor: AppColors.homeCardLine,
    );
  }

  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(GameVisualTokens.radiusM)),
  );

  /// Nút chính: xanh lá nổi khối giống `HomeGreenButton` ở màn Home.
  static final _raisedGreenStyle =
      FilledButton.styleFrom(
        backgroundColor: AppColors.homeGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.homeGreenDisabled,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: _buttonShape,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Color(0x33000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ).copyWith(
        backgroundBuilder: _raisedBackground(
          face: AppColors.homeGreen,
          disabledFace: AppColors.homeGreenDisabled,
        ),
      );

  /// Vẽ nền nổi khối như màn Home: gờ đáy sậm màu, mặt gradient, viền sáng.
  ///
  /// Màu nền, viền và shape mà từng nút tự đặt qua `style` vẫn được giữ, chỉ
  /// thay cách vẽ. Nút có nền trong suốt thì giữ nguyên dạng phẳng.
  static ButtonLayerBuilder _raisedBackground({
    required Color face,
    required Color disabledFace,
  }) {
    return (context, states, child) {
      final widget = context.widget;
      final own = widget is ButtonStyleButton ? widget.style : null;
      final disabled = states.contains(WidgetState.disabled);
      final pressed = states.contains(WidgetState.pressed);

      var color =
          own?.backgroundColor?.resolve(states) ??
          (disabled ? disabledFace : face);
      if (color.a == 0) return child ?? const SizedBox.shrink();
      if (pressed) color = Color.lerp(color, Colors.black, .08)!;

      final shape = own?.shape?.resolve(states) ?? _buttonShape;
      final edge = Color.lerp(color, Colors.black, .24)!;

      return DecoratedBox(
        decoration: ShapeDecoration(
          color: edge,
          shape: shape.copyWith(side: BorderSide.none),
          shadows: disabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: pressed ? .18 : .28),
                    blurRadius: 8,
                    offset: Offset(0, pressed ? 2 : 5),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .55, 1],
                colors: [
                  Color.lerp(color, Colors.white, .12)!,
                  color,
                  Color.lerp(color, Colors.black, .06)!,
                ],
              ),
              shape: shape.copyWith(
                side: BorderSide(
                  color: Color.lerp(color, Colors.white, .32)!,
                  width: 1.5,
                ),
              ),
            ),
            child: child,
          ),
        ),
      );
    };
  }
}
