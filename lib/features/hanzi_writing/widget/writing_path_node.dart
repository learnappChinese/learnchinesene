import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../models/writing_path_models.dart';

class WritingPathNodeWidget extends StatelessWidget {
  const WritingPathNodeWidget({
    super.key,
    required this.node,
    required this.index,
    required this.isLast,
    required this.onTap,
  });

  final WritingPathNode node;
  final int index;
  final bool isLast;
  final VoidCallback onTap;

  static double alignmentFor(int index) {
    switch (index % 4) {
      case 1:
        return -0.62;
      case 2:
        return 0.62;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = alignmentFor(index);
    final nextX = alignmentFor(index + 1);
    final completed = node.state == WritingPathNodeState.completed;
    final current = node.state == WritingPathNodeState.current;
    final locked = node.state == WritingPathNodeState.locked;
    final unavailable = node.state == WritingPathNodeState.unavailable;
    final diameter = current ? 86.0 : 76.0;

    final Color fill = switch (node.state) {
      WritingPathNodeState.completed => GameVisualTokens.primaryGreen,
      WritingPathNodeState.current => GameVisualTokens.primaryGreen,
      WritingPathNodeState.available => const Color(0xFFB9E56B),
      WritingPathNodeState.locked => const Color(0xFFE5E7EB),
      WritingPathNodeState.unavailable => const Color(0xFFF1F5F9),
    };
    final foreground =
        locked || unavailable ? const Color(0xFF94A3B8) : Colors.white;

    return SizedBox(
      height: 126,
      child: CustomPaint(
        painter: _WritingConnectorPainter(
          x: x,
          nextX: nextX,
          show: !isLast,
          completed: completed,
        ),
        child: Align(
          alignment: Alignment(x, -0.02),
          child: Semantics(
            button: true,
            enabled: !locked && !unavailable,
            label:
                'Chữ ${node.character}, trạng thái ${node.state.name}',
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: current
                        ? GameVisualTokens.imperialGold
                        : Colors.white,
                    width: current ? 4 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fill.withValues(alpha: current ? 0.34 : 0.20),
                      blurRadius: current ? 20 : 10,
                      offset: const Offset(0, 7),
                    ),
                    if (current)
                      BoxShadow(
                        color: GameVisualTokens.imperialGold
                            .withValues(alpha: 0.24),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      node.character,
                      style: TextStyle(
                        fontFamily: 'FZKaiTiPinyin',
                        fontSize: current ? 34 : 31,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    Positioned(
                      right: 5,
                      bottom: 5,
                      child: _StateBadge(
                        state: node.state,
                        foreground: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    required this.state,
    required this.foreground,
  });

  final WritingPathNodeState state;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      WritingPathNodeState.completed => Icons.check_rounded,
      WritingPathNodeState.current => Icons.edit_rounded,
      WritingPathNodeState.available => Icons.play_arrow_rounded,
      WritingPathNodeState.locked => Icons.lock_rounded,
      WritingPathNodeState.unavailable => Icons.warning_amber_rounded,
    };
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 15,
        color: state == WritingPathNodeState.completed ||
                state == WritingPathNodeState.current
            ? GameVisualTokens.primaryGreenDark
            : foreground,
      ),
    );
  }
}

class _WritingConnectorPainter extends CustomPainter {
  const _WritingConnectorPainter({
    required this.x,
    required this.nextX,
    required this.show,
    required this.completed,
  });

  final double x;
  final double nextX;
  final bool show;
  final bool completed;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final start = Offset(
      size.width * (0.5 + x * 0.34),
      78,
    );
    final end = Offset(
      size.width * (0.5 + nextX * 0.34),
      size.height + 14,
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx,
        start.dy + 34,
        end.dx,
        end.dy - 34,
        end.dx,
        end.dy,
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = completed
          ? GameVisualTokens.primaryGreenLight
          : const Color(0xFFD7DEE8);

    if (completed) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      const dash = 8.0;
      const gap = 7.0;
      for (double distance = 0;
          distance < metric.length;
          distance += dash + gap) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + dash, metric.length),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WritingConnectorPainter oldDelegate) {
    return oldDelegate.x != x ||
        oldDelegate.nextX != nextX ||
        oldDelegate.show != show ||
        oldDelegate.completed != completed;
  }
}
