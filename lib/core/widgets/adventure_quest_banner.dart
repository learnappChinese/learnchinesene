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
  final Color accent;
  final bool compact;

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
            colors: [Color(0xFFFFFBEB), Color(0xFFFFEBC7)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: GameVisualTokens.imperialGold.withValues(alpha: .66),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F6B421A),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: -34,
              top: -38,
              child: Icon(
                Icons.cloud_rounded,
                size: 150,
                color: Color(0x1A0F766E),
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
                compact ? 16 : 20,
                compact ? 14 : 18,
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
                      _StatusPill(
                        label: eyebrow.toUpperCase(),
                        color: accent,
                        solid: true,
                      ),
                      if (statusLabel != null && statusLabel!.isNotEmpty)
                        _StatusPill(label: statusLabel!, color: accent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: GameVisualTokens.ink,
                      fontSize: compact ? 19 : 23,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameVisualTokens.muted,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (effectiveProgress != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: effectiveProgress,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: .75),
                              color: accent,
                            ),
                          ),
                        ),
                        if (progressLabel != null) ...[
                          const SizedBox(width: 9),
                          Text(
                            progressLabel!,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10),
                    if (compact)
                      FilledButton(
                        onPressed: onAction,
                        style: _actionStyle(),
                        child: Text(
                          actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: onAction,
                        style: _actionStyle(),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(
                          actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
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

  ButtonStyle _actionStyle() => FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.solid = false,
  });

  final String label;
  final Color color;
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: solid ? color : color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .36)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: solid ? Colors.white : color,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      );
}
