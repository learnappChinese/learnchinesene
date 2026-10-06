import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/unit_learning_node.dart';

class UnitLevelNode extends StatelessWidget {
  const UnitLevelNode({
    super.key,
    required this.node,
    required this.alignLeft,
    required this.onTap,
    this.showPanda = false,
  });

  final UnitLearningNode node;
  final bool alignLeft;
  final VoidCallback onTap;
  final bool showPanda;

  @override
  Widget build(BuildContext context) {
    final state = node.state;
    final locked = state == UnitLearningNodeState.locked;
    final completed = state == UnitLearningNodeState.completed;
    final inProgress = state == UnitLearningNodeState.inProgress;
    final accent = completed
        ? const Color(0xFF2B9A55)
        : inProgress
            ? const Color(0xFFD98A17)
            : locked
                ? const Color(0xFF8B8A86)
                : const Color(0xFF2E7D6C);

    return Semantics(
      button: true,
      enabled: !locked,
      label: '${node.gameName}, ${_statusText(state)}',
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: MediaQuery.sizeOf(context).width <= 360 ? .96 : .84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: locked
                    ? const Color(0xFFE9E5DC)
                    : const Color(0xFFFFFBF2),
                borderRadius: BorderRadius.circular(24),
                elevation: locked ? 0 : 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onTap,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 310;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 10 : 14,
                          13,
                          compact ? 10 : 14,
                          13,
                        ),
                        child: Row(
                          children: [
                            _MissionBadge(
                              icon: node.gameIcon,
                              locked: locked,
                              completed: completed,
                              accent: accent,
                              size: compact ? 44 : 54,
                            ),
                            SizedBox(width: compact ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      node.gameName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: locked
                                            ? AppColors.muted
                                            : AppColors.ink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _StatePill(
                                    text: _statusText(state),
                                    color: accent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                node.gameDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.3,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 15,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${node.challengeCount} thử thách',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (node.stars > 0)
                                    Text(
                                      '★' * node.stars,
                                      style: const TextStyle(
                                        color: Color(0xFFFFB224),
                                        letterSpacing: 1,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                              if (inProgress) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: node.sessionProgress,
                                    minHeight: 6,
                                    backgroundColor:
                                        const Color(0xFFE6DED0),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(accent),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                            if (!compact) ...[
                              const SizedBox(width: 8),
                              Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.chevron_right_rounded,
                                color: accent,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (showPanda)
                Positioned(
                  top: -27,
                  right: alignLeft ? -2 : null,
                  left: alignLeft ? null : -2,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/characters/panda_archer.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(UnitLearningNodeState state) {
    switch (state) {
      case UnitLearningNodeState.completed:
        return 'Đã thắng';
      case UnitLearningNodeState.inProgress:
        return 'Đang chơi';
      case UnitLearningNodeState.available:
        return 'Chơi ngay';
      case UnitLearningNodeState.locked:
        return 'Khóa';
    }
  }
}

class _MissionBadge extends StatelessWidget {
  const _MissionBadge({
    required this.icon,
    required this.locked,
    required this.completed,
    required this.accent,
    required this.size,
  });

  final String icon;
  final bool locked;
  final bool completed;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: .12),
        border: Border.all(
          color: accent.withValues(alpha: .55),
          width: 2,
        ),
      ),
      child: Text(
        locked
            ? '🔒'
            : completed
                ? '✓'
                : icon,
        style: TextStyle(
          fontSize: completed ? 24 : 25,
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
