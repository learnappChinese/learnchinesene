import 'package:flutter/material.dart';

/// Kích thước mặc định của nút back dùng chung.
const double kAppBackButtonSize = 42;

/// Phần hình của nút back: ô vuông bo góc nền tối, viền vàng, mũi tên vàng.
///
/// Được dùng làm icon back mặc định của mọi [AppBar] thông qua
/// `ActionIconThemeData.backButtonIconBuilder` trong theme.
class AppBackButtonFace extends StatelessWidget {
  const AppBackButtonFace({super.key, this.size = kAppBackButtonSize});

  final double size;

  @override
  Widget build(BuildContext context) =>
      AppHudIconFace(icon: Icons.arrow_back_ios_new_rounded, size: size);
}

/// Phần hình dùng chung cho các nút HUD (back, cài đặt, loa...):
/// ô vuông bo góc nền tối, viền vàng, icon vàng nhạt.
class AppHudIconFace extends StatelessWidget {
  const AppHudIconFace({
    super.key,
    required this.icon,
    this.size = kAppBackButtonSize,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2130), Color(0xFF1C1020)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(
          color: const Color(0xFFFFC533).withValues(alpha: .55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: const Color(0xFFFFE7B0),
        size: size * .48,
      ),
    );
  }
}

/// Nút back dùng chung cho các header tự dựng.
///
/// Mặc định gọi [Navigator.maybePop].
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Quay lại',
    this.size = kAppBackButtonSize,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => AppHudIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: tooltip,
        size: size,
        onPressed: onPressed ?? () => Navigator.maybePop(context),
      );
}

/// Nút HUD cùng kiểu với [AppBackButton] nhưng dùng icon bất kỳ.
class AppHudIconButton extends StatelessWidget {
  const AppHudIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = kAppBackButtonSize,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 3);
    return Tooltip(
      message: tooltip,
      child: Stack(
        children: [
          AppHudIconFace(icon: icon, size: size),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              shape: RoundedRectangleBorder(borderRadius: radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onPressed),
            ),
          ),
        ],
      ),
    );
  }
}
