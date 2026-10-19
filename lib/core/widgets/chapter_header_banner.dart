import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';
import 'panda_companion.dart';

/// Thẻ đầu trang của một bài/chương theo theme kem + xanh lá của Home.
class ChapterHeaderBanner extends StatelessWidget {
  const ChapterHeaderBanner({
    super.key,
    required this.chapterNumber,
    required this.chineseTitle,
    required this.vietnameseTitle,
    this.badgeLabel,
    this.objectives = const [],
    this.footer,
  });

  final int chapterNumber;
  final String chineseTitle;
  final String vietnameseTitle;
  final String? badgeLabel;
  final List<String> objectives;

  /// Nội dung phụ hiển thị cuối thẻ (ví dụ thanh tiến độ).
  final Widget? footer;

  static const _ink = Color(0xFF342E10);
  static const _brown = Color(0xFF57300A);
  static const _muted = Color(0xFF5D5C54);

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    // Mục tiêu trùng tên bài thì không cần lặp lại.
    final visibleObjectives = objectives
        .where((o) =>
            o.trim().isNotEmpty &&
            o.trim().toLowerCase() != vietnameseTitle.trim().toLowerCase())
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
        ),
        borderRadius: BorderRadius.circular(26),
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
            right: -6,
            top: -36,
            child: Text(
              '学',
              style: TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8B5E1A).withValues(alpha: 0.06),
              ),
            ),
          ),
          if (!largeText)
            const Positioned(
              right: 0,
              top: 18,
              child: ExcludeSemantics(
                child: PandaCompanion(mood: PandaMood.happy, size: 96),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: largeText ? 0 : 92),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                          badgeLabel ?? 'BÀI $chapterNumber',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        chineseTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _brown,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vietnameseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (visibleObjectives.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'MỤC TIÊU PHIÊU LƯU',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: _brown,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: visibleObjectives.map((obj) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1E6CF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: GameVisualTokens.primaryGreen, size: 14),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                obj,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 14),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
