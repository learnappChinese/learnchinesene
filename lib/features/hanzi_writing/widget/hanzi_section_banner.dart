import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../models/hanzi_path_models.dart';

/// Banner tiêu đề cho từng Section trên con đường học tập viết chữ Hán.
class HanziSectionBanner extends StatelessWidget {
  final HanziPathSection section;

  const HanziSectionBanner({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (section.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: section.isUnlocked
              ? [
                  GameVisualTokens.primaryGreenDark,
                  GameVisualTokens.primaryGreen,
                ]
              : [
                  const Color(0xFF64748B),
                  const Color(0xFF94A3B8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: section.isUnlocked
              ? const Color(0xFF38A169)
              : const Color(0xFFCBD5E1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: section.isUnlocked
                ? GameVisualTokens.primaryGreenDark.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Họa tiết trang trí mờ ở góc
          Positioned(
            right: -10,
            bottom: -15,
            child: Opacity(
              opacity: 0.15,
              child: Text(
                '书',
                style: TextStyle(
                  fontSize: 100,
                  fontFamily: 'FZKaiTiPinyin',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag cấp độ và phần
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'HSK ${section.hskLevel} • BÀI ${section.sectionNumber}'
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (section.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GameVisualTokens.imperialGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'HOÀN THÀNH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!section.isUnlocked)
                      const Row(
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 14, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'ĐANG KHÓA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tiêu đề phần học
                Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Mô tả / phụ đề
                Text(
                  'Luyện viết các chữ Hán thuộc chủ đề ${section.title.toLowerCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Thanh tiến độ học viết của Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ: ${section.completedCount}/${section.totalCount} chữ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        color: section.isCompleted
                            ? GameVisualTokens.imperialGold
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: section.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      section.isCompleted
                          ? GameVisualTokens.imperialGold
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ mốc hoàn thành toàn bộ một cấp độ HSK.
class HanziHskMilestoneCard extends StatelessWidget {
  final HanziPathHskLevel hskLevel;

  const HanziHskMilestoneCard({
    super.key,
    required this.hskLevel,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = hskLevel.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone ? GameVisualTokens.imperialGold : const Color(0xFFE2E8F0),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? GameVisualTokens.imperialGold.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? GameVisualTokens.imperialGold
                  : const Color(0xFFF1F5F9),
              boxShadow: [
                BoxShadow(
                  color: isDone
                      ? GameVisualTokens.imperialGold.withValues(alpha: 0.4)
                      : Colors.transparent,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              isDone ? '🏆' : '🎯',
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'MỐC CHINH PHỤC HSK ${hskLevel.level}'.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDone
                  ? GameVisualTokens.primaryGreenDark
                  : const Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDone
                ? 'Tuyệt vời! Bạn đã hoàn thành toàn bộ chữ Hán của HSK ${hskLevel.level}!'
                : 'Hoàn thành tất cả các phần để nhận cúp danh dự HSK ${hskLevel.level}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDone
                  ? const Color(0xFF78350F)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDone
                  ? GameVisualTokens.primaryGreenSoft
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDone ? '🌟' : '📝',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đã thuộc: ${hskLevel.completedCharacters}/${hskLevel.totalCharacters} chữ (${(hskLevel.progress * 100).toInt()}%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDone
                        ? GameVisualTokens.primaryGreenDark
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
