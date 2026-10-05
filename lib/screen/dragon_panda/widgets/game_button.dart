import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Gradient gradient;
  final double height;
  final double? width;
  final Widget? leading;
  final double borderRadius;
  final Color shadowColor;
  final TextStyle? textStyle;

  const GameButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.gradient = AppColors.orangeGoldGradient,
    this.height = 54,
    this.width,
    this.leading,
    this.borderRadius = 22,
    this.shadowColor = const Color(0xFFB45309),
    this.textStyle,
  }) : super(key: key);

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: widget.height,
        width: widget.width ?? double.infinity,
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0, bottom: _isPressed ? 0 : 4),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor.withOpacity(0.6),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    offset: const Offset(0, 6),
                    blurRadius: 10,
                  ),
                ],
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: widget.textStyle ?? AppTextStyles.buttonText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
