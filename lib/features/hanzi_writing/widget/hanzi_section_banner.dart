import 'package:flutter/material.dart';

import '../../../core/presentation/learning_presentation_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../models/hanzi_path_models.dart';

/// Banner tiêu đề cho từng Section trên con đường học tập viết chữ Hán.
///
/// Cùng khung thẻ kem viền trắng như các thẻ ở màn học.
class HanziSectionBanner extends StatelessWidget {
  final HanziPathSection section;

  const HanziSectionBanner({super.key, required this.section});

  /// Dữ liệu cũ có tiêu đề dạng "Section 1, Unit 1"; đổi sang tiếng Việt.
  String get _title =>
      LearningPresentationMapper.sectionUnitLabel(section.title);

  @override
  Widget build(BuildContext context) {
    final progressPercent = (section.progress * 100).toInt();
    final locked = !section.isUnlocked;
    final accent = section.isCompleted
        ? AppColors.imperialGold
        : locked
        ? const Color(0xFF94A3B8)
        : AppColors.homeGreen;

    return Opacity(
      opacity: locked ? .75 : 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E635D3B),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Họa tiết trang trí mờ ở góc
              Positioned(
                right: -6,
                bottom: -22,
                child: Text(
                  '书',
                  style: TextStyle(
                    fontSize: 104,
                    fontFamily: 'FZKaiTiPinyin',
                    fontWeight: FontWeight.bold,
                    color: AppColors.imperialGold.withValues(alpha: .12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: locked
                                  ? const [Color(0xFFB8C0CC), Color(0xFF94A3B8)]
                                  : const [
                                      AppColors.homeGreenLight,
                                      AppColors.homeGreen,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            child: Text(
                              'HSK ${section.hskLevel} • BÀI ${section.sectionNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (section.isCompleted)
                          _StatusChip(
                            icon: Icons.check_circle_rounded,
                            label: 'Hoàn thành',
                            color: AppColors.amberDark,
                            background: AppColors.imperialGold.withValues(
                              alpha: .16,
                            ),
                          )
                        else if (locked)
                          const _StatusChip(
                            icon: Icons.lock_rounded,
                            label: 'Đang khóa',
                            color: Color(0xFF64748B),
                            background: Color(0xFFEFF1F4),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: locked
                            ? const Color(0xFF64748B)
                            : AppColors.homeTitle,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Luyện viết ${section.totalCount} chữ Hán của bài này',
                      style: const TextStyle(
                        color: AppColors.homeBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: section.progress,
                              minHeight: 9,
                              backgroundColor: const Color(0xFFEDE5D6),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${section.completedCount}/${section.totalCount} chữ',
                          style: TextStyle(
                            color: Color.lerp(accent, Colors.black, .2),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (progressPercent > 0 && !section.isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đã xong $progressPercent%',
                        style: const TextStyle(
                          color: AppColors.homeSubtitle,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

/// Thẻ mốc hoàn thành toàn bộ một cấp độ HSK.
class HanziHskMilestoneCard extends StatelessWidget {
  final HanziPathHskLevel hskLevel;

  const HanziHskMilestoneCard({super.key, required this.hskLevel});

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
          color: isDone
              ? GameVisualTokens.imperialGold
              : const Color(0xFFE2E8F0),
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
              color: isDone ? const Color(0xFF78350F) : const Color(0xFF64748B),
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
