import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

/// A production, data-driven journey header shared by learning surfaces.
///
/// The banner deliberately accepts presentation values and callbacks only.
/// Screens remain responsible for adapting their existing controller state.
class AdventureQuestBanner extends StatelessWidget {
  const AdventureQuestBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.progress,
    this.progressLabel,
    this.statusLabel,
    this.actionLabel,
    this.onAction,
    this.mood = PandaMood.happy,
    this.accent = GameVisualTokens.jade,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final double? progress;
  final String? progressLabel;
  final String? statusLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final PandaMood mood;

  /// Giữ để tương thích; thẻ dùng màu chủ đạo xanh lá của Home.
  final Color accent;
  final bool compact;

  static const _ink = Color(0xFF342E10);
  static const _muted = Color(0xFF5D5C54);
  static const _brown = Color(0xFF57300A);
  static const _line = Color(0xFFF1E6CF);

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = progress?.clamp(0.0, 1.0);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return Semantics(
      container: true,
      label: '$eyebrow. $title. $description',
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: compact ? 126 : 154),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24635D3B),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -4,
              top: -34,
              child: Text(
                '学',
                style: TextStyle(
                  fontSize: compact ? 120 : 140,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF8B5E1A).withValues(alpha: .06),
                ),
              ),
            ),
            if (!largeText)
              Positioned(
                right: compact ? -8 : 2,
                bottom: compact ? -16 : -10,
                child: ExcludeSemantics(
                  child: PandaCompanion(
                    mood: mood,
                    size: compact ? 94 : 118,
                    animate: !compact,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 18,
                compact ? 14 : 16,
                largeText ? 16 : (compact ? 92 : 116),
                compact ? 14 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusPill(label: eyebrow.toUpperCase(), solid: true),
                      if (statusLabel != null && statusLabel!.isNotEmpty)
                        _StatusPill(label: statusLabel!),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontSize: compact ? 19 : 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (effectiveProgress != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: effectiveProgress,
                              minHeight: 9,
                              backgroundColor: _line,
                              color: GameVisualTokens.primaryGreen,
                            ),
                          ),
                        ),
                        if (progressLabel != null) ...[
                          const SizedBox(width: 9),
                          Text(
                            progressLabel!,
                            style: const TextStyle(
                              color: GameVisualTokens.primaryGreenDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 14),
                    _GreenActionButton(
                      label: actionLabel!,
                      showArrow: !compact,
                      onTap: onAction!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút xanh lá nổi khối, cùng kiểu với nút chính ở màn Home.
class _GreenActionButton extends StatelessWidget {
  const _GreenActionButton({
    required this.label,
    required this.onTap,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    const primary = GameVisualTokens.primaryGreen;
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      child: Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: Color.lerp(primary, Colors.black, .24),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: .28),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
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
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (showArrow) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.solid = false});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: solid
              ? const LinearGradient(
                  colors: [
                    GameVisualTokens.primaryGreenLight,
                    GameVisualTokens.primaryGreen,
                  ],
                )
              : null,
          color: solid ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: solid ? null : Border.all(color: AdventureQuestBanner._line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: solid ? Colors.white : AdventureQuestBanner._brown,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      );
}
