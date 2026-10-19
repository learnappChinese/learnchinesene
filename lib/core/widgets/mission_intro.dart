import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

/// Thẻ giới thiệu nhiệm vụ trước khi bắt đầu chơi (theme kem + xanh lá).
class MissionIntro extends StatelessWidget {
  const MissionIntro({
    super.key,
    required this.title,
    required this.objective,
    required this.rewardText,
    required this.onStart,
    this.eyebrow = 'NHIỆM VỤ HỌC TẬP',
    this.coachText = 'Sẵn sàng cho thử thách tiếp theo chứ?',
  });

  final String title;
  final String objective;
  final String rewardText;
  final VoidCallback onStart;
  final String eyebrow;
  final String coachText;

  static const _ink = Color(0xFF342E10);
  static const _muted = Color(0xFF5D5C54);
  static const _line = Color(0xFFF1E6CF);

  @override
  Widget build(BuildContext context) {
    // Mục tiêu trùng tên nhiệm vụ thì không lặp lại.
    final showObjective = objective.trim().isNotEmpty &&
        objective.trim().toLowerCase() != title.trim().toLowerCase();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E635D3B),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -40,
                  child: Text(
                    '学',
                    style: TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B5E1A).withValues(alpha: .06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              GameVisualTokens.primaryGreenLight,
                              GameVisualTokens.primaryGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          eyebrow,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (showObjective) ...[
                        const SizedBox(height: 6),
                        Text(
                          objective,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 14.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      PandaCompanion(
                        mood: PandaMood.encourage,
                        size: 118,
                        speechText: coachText,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: _line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: GameVisualTokens.gold, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                rewardText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF57300A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StartButton(onTap: onStart),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút bắt đầu xanh lá nổi khối, cùng kiểu với nút chính ở Home.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = GameVisualTokens.primaryGreen;
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Color.lerp(primary, Colors.black, .24),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: .3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            height: 52,
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
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                    SizedBox(width: 6),
                    Text(
                      'BẮT ĐẦU PHIÊU LƯU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
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
