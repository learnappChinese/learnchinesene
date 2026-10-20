import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../models/hanzi_path_models.dart';

class HanziZigzagNodeWidget extends StatefulWidget {
  final HanziPathNode node;
  final VoidCallback onTap;

  const HanziZigzagNodeWidget({
    super.key,
    required this.node,
    required this.onTap,
  });

  @override
  State<HanziZigzagNodeWidget> createState() => _HanziZigzagNodeWidgetState();
}

class _HanziZigzagNodeWidgetState extends State<HanziZigzagNodeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static bool get _inTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.node.state == WritingNodeState.inProgress && !_inTest) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HanziZigzagNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.state == WritingNodeState.inProgress && !_inTest) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isCompleted = node.state == WritingNodeState.completed;
    final isInProgress = node.state == WritingNodeState.inProgress;
    final isLocked = node.state == WritingNodeState.locked;

    // Kích thước nút
    final double buttonSize = isInProgress ? 82.0 : 74.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nhãn nổi "Đang học" nếu node đang học
          if (isInProgress) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: GameVisualTokens.primaryGreenDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✏️', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 4),
                  Text(
                    'ĐANG HỌC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Vòng nút tròn chính
          GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = isInProgress ? _pulseAnimation.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Vòng sáng ngoài cho node đang học
                      if (isInProgress)
                        Container(
                          width: buttonSize + 14,
                          height: buttonSize + 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GameVisualTokens.primaryGreen
                                .withValues(alpha: 0.22),
                          ),
                        ),

                      // Nút 3D tròn
                      Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? GameVisualTokens.primaryGreen
                              : isInProgress
                                  ? GameVisualTokens.primaryGreenDark
                                  : isLocked
                                      ? const Color(0xFFE2E8F0)
                                      : Colors.white,
                          border: Border.all(
                            color: isCompleted
                                ? GameVisualTokens.primaryGreenDark
                                : isInProgress
                                    ? GameVisualTokens.imperialGold
                                    : isLocked
                                        ? const Color(0xFFCBD5E1)
                                        : GameVisualTokens.primaryGreenLight,
                            width: isInProgress ? 3.5 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted
                                  ? GameVisualTokens.primaryGreenDark
                                      .withValues(alpha: 0.4)
                                  : isInProgress
                                      ? GameVisualTokens.primaryGreenDark
                                          .withValues(alpha: 0.5)
                                      : isLocked
                                          ? Colors.black.withValues(alpha: 0.05)
                                          : Colors.black.withValues(alpha: 0.1),
                              blurRadius: isInProgress ? 12 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              node.character.character,
                              style: TextStyle(
                                fontFamily: 'FZKaiTiPinyin',
                                fontSize: isInProgress ? 34 : 30,
                                fontWeight: FontWeight.bold,
                                color: isCompleted || isInProgress
                                    ? Colors.white
                                    : isLocked
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.ink,
                              ),
                            ),
                            if ((node.character.pinyin?.isNotEmpty ?? false) && !isLocked)
                              Text(
                                node.character.pinyin!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted || isInProgress
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Badge hoàn thành (Dấu tích xanh/vàng)
                      if (isCompleted)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GameVisualTokens.imperialGold,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Badge khóa nếu chưa mở
                      if (isLocked)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF94A3B8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
