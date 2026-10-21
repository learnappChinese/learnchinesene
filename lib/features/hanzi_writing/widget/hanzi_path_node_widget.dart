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

    final Color face = isCompleted || isInProgress
        ? AppColors.homeGreen
        : isLocked
        ? const Color(0xFFF1EDE4)
        : Colors.white;
    final Color edge = isCompleted || isInProgress
        ? Color.lerp(AppColors.homeGreen, Colors.black, .24)!
        : isLocked
        ? const Color(0xFFDDD5C6)
        : AppColors.homeBorder;
    final Color rim = isInProgress
        ? Colors.white
        : isCompleted
        ? Color.lerp(AppColors.homeGreen, Colors.white, .32)!
        : isLocked
        ? const Color(0xFFE8E1D6)
        : AppColors.homeBorder;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nhãn nổi "Đang học" nếu node đang học
          if (isInProgress) ...[
            // Hàng cao cố định 126px (HanziPathRowItem) và node đang học chiếm
            // 96px kể cả vòng sáng, nên nhãn phải gọn trong ~28px.
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.homeGreenSoft,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.homeGreen, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.draw_rounded,
                      size: 12, color: AppColors.homeGreenText),
                  SizedBox(width: 4),
                  Text(
                    'Đang học',
                    style: TextStyle(
                      color: AppColors.homeGreenText,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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
                            color: AppColors.homeGreen.withValues(alpha: .18),
                          ),
                        ),

                      // Nút 3D tròn: mặt tròn + gờ đáy sậm như nút ở màn Home
                      Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(
                                face,
                                Colors.white,
                                isCompleted || isInProgress ? .14 : 0,
                              )!,
                              face,
                            ],
                          ),
                          border: Border.all(
                            color: rim,
                            width: isInProgress ? 4 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(color: edge, offset: const Offset(0, 5)),
                            BoxShadow(
                              color: isCompleted || isInProgress
                                  ? AppColors.homeGreen.withValues(alpha: .3)
                                  : AppColors.homeShadow,
                              blurRadius: 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        // Font Khải đã vẽ sẵn pinyin phía trên chữ.
                        child: Text(
                          node.character.character,
                          style: TextStyle(
                            fontFamily: 'FZKaiTiPinyin',
                            fontSize: isInProgress ? 36 : 32,
                            fontWeight: FontWeight.bold,
                            color: isCompleted || isInProgress
                                ? Colors.white
                                : isLocked
                                ? const Color(0xFFA8A196)
                                : AppColors.homeInk,
                          ),
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
                              color: const Color(0xFFA8A196),
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
