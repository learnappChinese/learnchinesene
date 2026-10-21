import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/game_visual_tokens.dart';
import '../theme/learning_theme.dart';

/// Một chặng trên lộ trình: node bên trái nối với nhau bằng một đường dọc,
/// thẻ nội dung bên phải.
class LearningTrailEntry extends StatelessWidget {
  const LearningTrailEntry({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
    required this.node,
    required this.child,
  });

  static const double _railWidth = 64;
  static const double _nodeTop = 10;
  static const double _nodeCenter = _nodeTop + 28;

  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  final Widget node;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showLine = !(isFirst && isLast);
    return Stack(
      children: [
        if (showLine)
          Positioned(
            left: _railWidth / 2 - 2,
            top: isFirst ? _nodeCenter : 0,
            bottom: isLast ? null : 0,
            height: isLast ? _nodeCenter : null,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: _nodeTop),
                  child: Center(child: node),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vỏ thẻ dùng chung cho các ải/nhiệm vụ trên lộ trình.
class LearningTrailCard extends StatelessWidget {
  const LearningTrailCard({
    super.key,
    required this.onTap,
    required this.child,
    this.highlight = false,
    this.completed = false,
    this.locked = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool highlight;
  final bool completed;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final borderColor = highlight
        ? GameVisualTokens.primaryGreen
        : completed
        ? GameVisualTokens.primaryGreen.withValues(alpha: 0.35)
        : const Color(0xFFE9E4DA);

    return Opacity(
      opacity: locked ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFF8F7F4) : Colors.white,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: highlight ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: highlight
                  ? GameVisualTokens.primaryGreen.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: highlight ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class LearningTrailTag extends StatelessWidget {
  const LearningTrailTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: foreground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class LearningTrailMeta extends StatelessWidget {
  const LearningTrailMeta({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: LearningColors.muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: LearningColors.muted,
          ),
        ),
      ],
    );
  }
}

/// Nhãn "Vào học" trên thẻ ải: nút xanh nổi khối thu nhỏ như ở màn Home.
/// Chỉ để trang trí — cả thẻ đã nhận thao tác chạm.
class LearningTrailStartPill extends StatelessWidget {
  const LearningTrailStartPill({super.key, this.label = 'Vào học'});

  final String label;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.homeGreen;
    final radius = BorderRadius.circular(99);
    return Container(
      padding: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.black, .24),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .28),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 6, 13, 6),
        decoration: BoxDecoration(
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
          borderRadius: radius,
          border: Border.all(
            color: Color.lerp(color, Colors.white, .32)!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 17, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Color(0x33000000),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
