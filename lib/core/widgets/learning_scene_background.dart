import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';

enum LearningSceneTheme {
  bambooVillage, // Cream morning with soft green hills
  lanternTown, // Amber gold & festival lanterns
  shanghaiCity, // Sapphire blue & modern mist
  mountainTemple, // Mystical purple & mountain clouds
  imperialCity, // Royal crimson & imperial gold
  dragonRealm, // Night obsidian & dragon fire
  neutralCream, // Warm parchment default
}

/// Chiều cao vùng đáy (home indicator) mà màn cha đã cắt bằng SafeArea.
///
/// [LearningScaffold] ghi lại giá trị này *trước* khi bọc SafeArea (vì
/// SafeArea xoá cả padding lẫn viewPadding khỏi MediaQuery), để các nền
/// có thể vẽ tràn xuống tận mép màn hình.
class BottomBleedScope extends InheritedWidget {
  const BottomBleedScope({
    super.key,
    required this.bleed,
    required super.child,
  });

  final double bleed;

  @override
  bool updateShouldNotify(BottomBleedScope oldWidget) =>
      oldWidget.bleed != bleed;
}

/// Phần nền cần vẽ tràn xuống dưới vùng an toàn (0 nếu không bị cắt).
double bottomBleed(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<BottomBleedScope>()?.bleed ?? 0;

/// Đưa nội dung (nhất là nút ở đáy) lên trên vùng an toàn phía dưới: home
/// indicator trên iOS và thanh điều hướng trên Android (kể cả chế độ
/// edge-to-edge). Nền dùng [bottomBleed] bên trong vẫn vẽ tràn tới mép màn.
///
/// Dùng cho thân của các `Scaffold` thường; [LearningScaffold] đã tự làm việc
/// này.
class SafeBottomArea extends StatelessWidget {
  const SafeBottomArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BottomBleedScope(
        bleed: MediaQuery.paddingOf(context).bottom,
        child: SafeArea(top: false, left: false, right: false, child: child),
      );
}

/// Reusable multi-layered Chinese Fantasy Adventure background
class LearningSceneBackground extends StatelessWidget {
  const LearningSceneBackground({
    super.key,
    required this.child,
    this.theme = LearningSceneTheme.neutralCream,
    this.showMountains = true,
    this.showMist = true,
  });

  final Widget child;
  final LearningSceneTheme theme;
  final bool showMountains;
  final bool showMist;

  (List<Color>, Color, Color) _getThemeColors() {
    switch (theme) {
      case LearningSceneTheme.bambooVillage:
        // Nền kem đồng bộ với Home, núi xanh lá rất nhạt làm điểm nhấn.
        return (
          [
            const Color(0xFFFFFAF0),
            const Color(0xFFFFF7E8),
            const Color(0xFFFFF1DC)
          ],
          GameVisualTokens.primaryGreen.withValues(alpha: 0.10),
          GameVisualTokens.primaryGreenLight.withValues(alpha: 0.07),
        );
      case LearningSceneTheme.lanternTown:
        return (
          [
            const Color(0xFFFFFBEB),
            const Color(0xFFFEF3C7),
            const Color(0xFFFDE68A)
          ],
          const Color(0xFFD97706).withValues(alpha: 0.12),
          const Color(0xFFEF4444).withValues(alpha: 0.08),
        );
      case LearningSceneTheme.shanghaiCity:
        return (
          [
            const Color(0xFFF0F9FF),
            const Color(0xFFE0F2FE),
            const Color(0xFFBAE6FD)
          ],
          const Color(0xFF0284C7).withValues(alpha: 0.12),
          const Color(0xFF38BDF8).withValues(alpha: 0.08),
        );
      case LearningSceneTheme.mountainTemple:
        return (
          [
            const Color(0xFFFAF5FF),
            const Color(0xFFF3E8FF),
            const Color(0xFFE9D5FF)
          ],
          const Color(0xFF7C3AED).withValues(alpha: 0.12),
          const Color(0xFFA855F7).withValues(alpha: 0.08),
        );
      case LearningSceneTheme.imperialCity:
        return (
          [
            const Color(0xFFFFF1F2),
            const Color(0xFFFFE4E6),
            const Color(0xFFFECDD3)
          ],
          const Color(0xFFBE123C).withValues(alpha: 0.12),
          const Color(0xFFF59E0B).withValues(alpha: 0.08),
        );
      case LearningSceneTheme.dragonRealm:
        return (
          [
            const Color(0xFF1E1035),
            const Color(0xFF2D123D),
            const Color(0xFF180A26)
          ],
          const Color(0xFFFF5252).withValues(alpha: 0.20),
          const Color(0xFFFF9800).withValues(alpha: 0.15),
        );
      case LearningSceneTheme.neutralCream:
        return (
          [
            GameVisualTokens.cream,
            const Color(0xFFFFF4E0),
            const Color(0xFFFFECCC)
          ],
          const Color(0xFFD97706).withValues(alpha: 0.08),
          const Color(0xFF0F766E).withValues(alpha: 0.06),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColors, mountainColor, mistColor) = _getThemeColors();
    // Khi màn bọc SafeArea ở đáy, nền vẫn vẽ tràn xuống vùng home indicator
    // để không lộ vạch cắt; nội dung (child) vẫn nằm trong vùng an toàn.
    final bleed = bottomBleed(context);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // 1. Base scenic gradient
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -bleed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
          ),
        ),

        // 2. Far mountain silhouette & oriental clouds
        if (showMountains)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: -bleed,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OrientalLandscapePainter(
                  mountainColor: mountainColor,
                  mistColor: mistColor,
                ),
              ),
            ),
          ),

        // 3. Child content
        child,
      ],
    );
  }
}

class _OrientalLandscapePainter extends CustomPainter {
  final Color mountainColor;
  final Color mistColor;

  _OrientalLandscapePainter({
    required this.mountainColor,
    required this.mistColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far mountains (gentle sine waves)
    final mountainPaint = Paint()
      ..color = mountainColor
      ..style = PaintingStyle.fill;

    final farPath = Path()..moveTo(0, h * 0.45);
    for (double x = 0; x <= w; x += 10) {
      final y = h * 0.45 +
          math.sin((x / w) * math.pi * 3.5) * (h * 0.04) +
          math.cos((x / w) * math.pi * 1.5) * (h * 0.02);
      farPath.lineTo(x, y);
    }
    farPath.lineTo(w, h);
    farPath.lineTo(0, h);
    farPath.close();
    canvas.drawPath(farPath, mountainPaint);

    // Mid mountains (steeper ridges)
    final midPaint = Paint()
      ..color = mountainColor.withValues(alpha: mountainColor.a * 1.35)
      ..style = PaintingStyle.fill;

    final midPath = Path()..moveTo(0, h * 0.62);
    for (double x = 0; x <= w; x += 12) {
      final y = h * 0.62 +
          math.sin((x / w) * math.pi * 4.2 + 1.2) * (h * 0.05) +
          math.cos((x / w) * math.pi * 2.8) * (h * 0.03);
      midPath.lineTo(x, y);
    }
    midPath.lineTo(w, h);
    midPath.lineTo(0, h);
    midPath.close();
    canvas.drawPath(midPath, midPaint);

    // Subtle mist swirls
    final mistPaint = Paint()
      ..color = mistColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, h * 0.58),
        width: w * 0.75,
        height: h * 0.08,
      ),
      mistPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.75, h * 0.72),
        width: w * 0.65,
        height: h * 0.06,
      ),
      mistPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrientalLandscapePainter oldDelegate) =>
      mountainColor != oldDelegate.mountainColor ||
      mistColor != oldDelegate.mistColor;
}
