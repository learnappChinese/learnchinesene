import 'package:flutter/material.dart';

enum BossBattleAnswerVisualState {
  idle,
  correct,
  wrong,
  disabled,
}

class BossBattleAnswerButton extends StatefulWidget {
  const BossBattleAnswerButton({
    super.key,
    required this.answer,
    required this.index,
    required this.state,
    required this.onTap,
  });

  final String answer;
  final int index;
  final BossBattleAnswerVisualState state;
  final VoidCallback? onTap;

  @override
  State<BossBattleAnswerButton> createState() => _BossBattleAnswerButtonState();
}

class _BossBattleAnswerButtonState extends State<BossBattleAnswerButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.state);
    final enabled = widget.onTap != null;
    final label = String.fromCharCode(65 + widget.index.clamp(0, 25));

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Đáp án $label: ${widget.answer}',
      child: AnimatedScale(
        scale: _pressed && enabled ? .965 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: enabled ||
                  widget.state == BossBattleAnswerVisualState.correct ||
                  widget.state == BossBattleAnswerVisualState.wrong
              ? 1
              : .72,
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: palette.glow,
                  blurRadius: widget.state == BossBattleAnswerVisualState.idle
                      ? 10
                      : 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown:
                    enabled ? (_) => setState(() => _pressed = true) : null,
                onTapUp:
                    enabled ? (_) => setState(() => _pressed = false) : null,
                onTapCancel:
                    enabled ? () => setState(() => _pressed = false) : null,
                splashColor: palette.border.withValues(alpha: .12),
                highlightColor: palette.border.withValues(alpha: .06),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _buildAnswerContent(palette, label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AnswerPalette _paletteFor(BossBattleAnswerVisualState state) {
    switch (state) {
      case BossBattleAnswerVisualState.correct:
        return const _AnswerPalette(
          background: Color(0xFFE8F8EC),
          border: Color(0xFF20A866),
          foreground: Color(0xFF154C32),
          badge: Color(0xFFD3F1DD),
          glow: Color(0x4420A866),
        );
      case BossBattleAnswerVisualState.wrong:
        return const _AnswerPalette(
          background: Color(0xFFFFEAEA),
          border: Color(0xFFD94747),
          foreground: Color(0xFF742525),
          badge: Color(0xFFFFD5D5),
          glow: Color(0x44D94747),
        );
      case BossBattleAnswerVisualState.disabled:
        return const _AnswerPalette(
          background: Color(0xFFF2EEE9),
          border: Color(0xFFD4CCC3),
          foreground: Color(0xFF80766D),
          badge: Color(0xFFE7E0D8),
          glow: Color(0x11000000),
        );
      case BossBattleAnswerVisualState.idle:
        return const _AnswerPalette(
          background: Color(0xFFFFFDF8),
          border: Color(0xFFE2A842),
          foreground: Color(0xFF2D251E),
          badge: Color(0xFFFFEBC4),
          glow: Color(0x22000000),
        );
    }
  }

  Widget _buildAnswerBadge(_AnswerPalette palette, String label) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.badge,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: palette.border.withValues(alpha: .55),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildAnswerContent(_AnswerPalette palette, String label) {
    return Row(
      children: [
        _buildAnswerBadge(palette, label),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.answer,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.foreground,
              fontSize: widget.answer.length <= 4 ? 24 : 16,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StateIcon(state: widget.state),
      ],
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state});

  final BossBattleAnswerVisualState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BossBattleAnswerVisualState.correct:
        return const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF1F9A63),
          size: 22,
        );
      case BossBattleAnswerVisualState.wrong:
        return const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFD94848),
          size: 22,
        );
      default:
        return const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFB89A6A),
          size: 22,
        );
    }
  }
}

class _AnswerPalette {
  const _AnswerPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.badge,
    required this.glow,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color badge;
  final Color glow;
}
