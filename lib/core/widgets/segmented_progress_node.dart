import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';
import 'adventure_node.dart';

/// A circular stage node with a dynamic segmented progress ring.
///
/// - Derives segment count dynamically from [totalSegments] (e.g. 3, 5, 8).
/// - If [totalSegments] > [continuousThreshold], transitions cleanly to a continuous ring.
/// - Shows quality rating in [stars] (0-3) distinctly from progress segments.
class SegmentedProgressNode extends StatelessWidget {
  const SegmentedProgressNode({
    super.key,
    required this.totalSegments,
    required this.completedSegments,
    required this.state,
    this.icon,
    this.customIcon,
    this.progress,
    this.stars = 0,
    this.size = 76.0,
    this.ringWidth = 6.0,
    this.continuousThreshold = 12,
    this.isActive = false,
    this.title,
    this.subtitle,
    this.onTap,
  });

  /// Dynamic total segments (derived from stage.items.length)
  final int totalSegments;

  /// Dynamic completed segments
  final int completedSegments;

  /// Node completion state
  final AdventureNodeState state;

  /// Icon to display in the node center
  final IconData? icon;

  /// Optional custom icon widget
  final Widget? customIcon;

  /// Explicit progress (0.0 to 1.0); if null, derived from completedSegments / totalSegments
  final double? progress;

  /// Quality star rating (0 to 3), independent from segment count
  final int stars;

  /// Diameter of the circular node
  final double size;

  /// Thickness of the progress ring
  final double ringWidth;

  /// Threshold beyond which the segmented ring renders as a continuous ring
  final int continuousThreshold;

  /// Whether this node is the active next milestone
  final bool isActive;

  /// Optional title displayed below the node
  final String? title;

  /// Optional subtitle or progress label displayed below the node
  final String? subtitle;

  /// Tap callback
  final VoidCallback? onTap;

  double get computedProgress {
    if (progress != null) return progress!.clamp(0.0, 1.0);
    if (totalSegments <= 0) return 0.0;
    return (completedSegments / totalSegments).clamp(0.0, 1.0);
  }

  bool get isLocked => state == AdventureNodeState.locked;
  bool get isCompleted =>
      state == AdventureNodeState.completed ||
      state == AdventureNodeState.perfect;
  bool get isInProgress => state == AdventureNodeState.inProgress;

  (Color primaryColor, Color trackColor, Color centerBg, Color glowColor)
      _resolveColors() {
    if (isLocked) {
      return (
        const Color(0xFF94A3B8),
        const Color(0xFFE2E8F0),
        const Color(0xFFF1F5F9),
        Colors.transparent,
      );
    }
    if (state == AdventureNodeState.perfect) {
      return (
        GameVisualTokens.imperialGold,
        GameVisualTokens.goldLight,
        const Color(0xFFFFFBEB),
        GameVisualTokens.imperialGold.withValues(alpha: 0.35),
      );
    }
    if (state == AdventureNodeState.completed) {
      return (
        GameVisualTokens.jade,
        GameVisualTokens.jadeLight.withValues(alpha: 0.3),
        const Color(0xFFECFDF5),
        GameVisualTokens.jade.withValues(alpha: 0.3),
      );
    }
    if (isInProgress || isActive) {
      return (
        GameVisualTokens.blue,
        const Color(0xFFE0F2FE),
        const Color(0xFFF0F9FF),
        GameVisualTokens.blue.withValues(alpha: 0.3),
      );
    }
    if (state == AdventureNodeState.failed) {
      return (
        GameVisualTokens.crimson,
        const Color(0xFFFFE4E6),
        const Color(0xFFFFF1F2),
        GameVisualTokens.crimson.withValues(alpha: 0.25),
      );
    }
    // Available state
    return (
      GameVisualTokens.jade,
      const Color(0xFFE2E8F0),
      Colors.white,
      GameVisualTokens.jade.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (primaryColor, trackColor, centerBg, glowColor) = _resolveColors();

    final nodeWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2 + 8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow when active or in progress
                if (isActive || isInProgress)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                // Dynamic Segmented Progress Ring
                CustomPaint(
                  size: Size(size, size),
                  painter: _SegmentedRingPainter(
                    totalSegments: totalSegments,
                    completedSegments: completedSegments,
                    progress: computedProgress,
                    primaryColor: primaryColor,
                    trackColor: trackColor,
                    ringWidth: ringWidth,
                    continuousThreshold: continuousThreshold,
                    isLocked: isLocked,
                  ),
                ),

                // Center circular disc
                Container(
                  width: size - (ringWidth * 2 + 8),
                  height: size - (ringWidth * 2 + 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: centerBg,
                    border: Border.all(
                      color: isLocked
                          ? const Color(0xFFCBD5E1)
                          : primaryColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildCenterIcon(primaryColor),
                  ),
                ),

                // Completed checkmark overlay (small badge on bottom-right)
                if (isCompleted)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: state == AdventureNodeState.perfect
                            ? GameVisualTokens.imperialGold
                            : GameVisualTokens.jade,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Locked badge overlay
                if (isLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (title == null && subtitle == null && stars == 0) {
      return nodeWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        nodeWidget,
        if (stars > 0) ...[
          const SizedBox(height: 2),
          _buildStarRating(stars),
        ],
        if (title != null) ...[
          const SizedBox(height: 4),
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isLocked ? const Color(0xFF94A3B8) : GameVisualTokens.ink,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCenterIcon(Color primaryColor) {
    if (customIcon != null) return customIcon!;
    if (isLocked) {
      return const Icon(
        Icons.lock_outline_rounded,
        size: 22,
        color: Color(0xFF94A3B8),
      );
    }
    return Icon(
      icon ?? Icons.play_arrow_rounded,
      size: 24,
      color: primaryColor,
    );
  }

  Widget _buildStarRating(int starCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < starCount;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: isFilled ? GameVisualTokens.imperialGold : const Color(0xFFCBD5E1),
        );
      }),
    );
  }
}

/// CustomPainter for painting either a segmented ring or continuous progress ring.
class _SegmentedRingPainter extends CustomPainter {
  const _SegmentedRingPainter({
    required this.totalSegments,
    required this.completedSegments,
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
    required this.ringWidth,
    required this.continuousThreshold,
    required this.isLocked,
  });

  final int totalSegments;
  final int completedSegments;
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  final double ringWidth;
  final int continuousThreshold;
  final bool isLocked;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringWidth) / 2;

    // Fallback: continuous ring if totalSegments is 0, 1, or > continuousThreshold
    final bool useContinuous =
        totalSegments <= 1 || totalSegments > continuousThreshold;

    if (useContinuous) {
      _paintContinuousRing(canvas, center, radius);
    } else {
      _paintSegmentedRing(canvas, center, radius);
    }
  }

  void _paintContinuousRing(Canvas canvas, Offset center, double radius) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0 && !isLocked) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  void _paintSegmentedRing(Canvas canvas, Offset center, double radius) {
    final count = totalSegments;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Dynamic gap angle: scales gracefully with count
    final gapAngle = (count <= 4 ? 0.12 : (count <= 8 ? 0.08 : 0.05));
    final segmentSweep = (2 * math.pi / count) - gapAngle;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      // Start at top (-pi / 2) + offset for gap
      final startAngle =
          -math.pi / 2 + (i * 2 * math.pi / count) + (gapAngle / 2);

      final isSegmentFilled = !isLocked && (i < completedSegments);
      final paint = isSegmentFilled ? activePaint : trackPaint;

      canvas.drawArc(
        rect,
        startAngle,
        segmentSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.totalSegments != totalSegments ||
        oldDelegate.completedSegments != completedSegments ||
        oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.ringWidth != ringWidth;
  }
}
