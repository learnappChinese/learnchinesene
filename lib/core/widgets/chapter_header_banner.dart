import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';

class ChapterHeaderBanner extends StatelessWidget {
  const ChapterHeaderBanner({
    super.key,
    required this.chapterNumber,
    required this.chineseTitle,
    required this.vietnameseTitle,
    this.objectives = const [],
    this.backgroundAsset = 'assets/images/backgrounds/learning_practice.png',
  });

  final int chapterNumber;
  final String chineseTitle;
  final String vietnameseTitle;
  final List<String> objectives;
  final String backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameVisualTokens.imperialGold, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Scenic backdrop
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
            // Chinese cloud vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F172A).withValues(alpha: 0.90),
                      const Color(0xFF1E293B).withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            // Header content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GameVisualTokens.imperialGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CHAPTER $chapterNumber',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF451A03),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Text(
                        '🏮 📜 🐉',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    chineseTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vietnameseTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: GameVisualTokens.goldLight,
                    ),
                  ),
                  if (objectives.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),
                    const Text(
                      'MỤC TIÊU PHIÊU LƯU:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: objectives.map((obj) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: GameVisualTokens.jadeLight, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                obj,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
