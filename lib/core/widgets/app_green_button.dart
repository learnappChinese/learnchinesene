import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Nút xanh lá nổi khối, cùng kiểu với nút chính ở màn Home.
class AppGreenButton extends StatelessWidget {
  const AppGreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.expand = false,
    this.fontSize = 15,
  }) : light = false;

  /// Nút phụ phẳng: mặt trắng, viền xanh xám, chữ xanh — đi kèm nút xanh
  /// chính. Chỉ nút chính mới nổi khối để hành động chính luôn nổi bật.
  const AppGreenButton.light({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.expand = false,
    this.fontSize = 15,
  }) : light = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expand;
  final double fontSize;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final face = light
        ? Colors.white
        : (enabled ? AppColors.homeGreen : AppColors.homeGreenDisabled);
    final edge =
        light ? AppColors.homeBorder : Color.lerp(face, Colors.black, .24)!;
    final rim =
        light ? AppColors.homeBorder : Color.lerp(face, Colors.white, .32)!;
    final foreground = light
        ? (enabled ? AppColors.homeGreenLink : AppColors.homeSubtitle)
        : Colors.white;
    final radius = BorderRadius.circular(height * .38);

    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              color: foreground,
              strokeWidth: 2.4,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: fontSize + 5),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                    shadows: light
                        ? null
                        : const [
                            Shadow(
                              color: Color(0x33000000),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Container(
        width: expand ? double.infinity : null,
        // Nút phụ không có gờ đáy; giữ khoảng trống 4px để cao bằng nút chính.
        padding: const EdgeInsets.only(bottom: 4),
        decoration: light
            ? null
            : BoxDecoration(
                color: edge,
                borderRadius: radius,
                boxShadow: [
                  if (enabled)
                    BoxShadow(
                      color: face.withValues(alpha: .3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: light
                    ? const [Colors.white, Colors.white]
                    : [Color.lerp(face, Colors.white, .14)!, face],
              ),
              borderRadius: radius,
              border: Border.all(color: rim, width: 1.5),
            ),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
