import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expand;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final primary =
        enabled ? GameVisualTokens.primaryGreen : const Color(0xFFB9C9AE);
    final radius = BorderRadius.circular(height * .38);

    final content = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.4,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: fontSize + 5),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
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
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Color.lerp(primary, Colors.black, .24),
          borderRadius: radius,
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: primary.withValues(alpha: .3),
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
                colors: [Color.lerp(primary, Colors.white, .14)!, primary],
              ),
              borderRadius: radius,
              border: Border.all(
                color: Color.lerp(primary, Colors.white, .32)!,
                width: 1.5,
              ),
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
