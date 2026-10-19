import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../vocabulary/data/models/user_stats_model.dart';

class ProfileAchievements extends StatelessWidget {
  const ProfileAchievements({super.key, required this.userStats});
  final UserStats userStats;

  String _getRankTitle(int exp) {
    if (exp >= 5000) return 'Đại Tông Sư HSK';
    if (exp >= 2000) return 'Trúc Cơ Cao Thủ';
    if (exp >= 800) return 'Luyện Khí Tinh Anh';
    if (exp >= 200) return 'Nhập Môn Hiệp Khách';
    return 'Tân Thủ Giang Hồ';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        _buildIdentityCard(context),
        const SizedBox(height: 20),
        _buildLifetimeMetrics(context),
        const SizedBox(height: 24),
        _buildSectionHeader('DANH HIỆU & CỘT MỐC'),
        const SizedBox(height: 12),
        _buildAchievementList(context),
        const SizedBox(height: 24),
        _buildSectionHeader('NĂNG LỰC NGÔN NGỮ'),
        const SizedBox(height: 12),
        _buildCompetencyBadges(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildIdentityCard(BuildContext context) {
    final exp = userStats.totalExp;
    final rank = _getRankTitle(exp);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameVisualTokens.parchment,
              border: Border.all(color: GameVisualTokens.gold, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/characters/panda_avatar.png',
                fit: BoxFit.contain,
                semanticLabel: 'Panda đồng hành',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                    rank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hiệp Khách Tiếng Trung',
                  style: TextStyle(
                    color: Color(0xFF342E10),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #${userStats.id.toString().padLeft(6, '0')} • Đồng hành cùng Panda',
                  style: const TextStyle(
                    color: Color(0xFF5D5C54),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _MetricCard(
                icon: Icons.military_tech_rounded,
                title: 'Tổng XP',
                value: '${userStats.totalExp}',
                color: GameVisualTokens.imperialGold,
                bgColor: const Color(0xFFFFFBEB),
              ),
              const SizedBox(height: 12),
              _MetricCard(
                icon: Icons.auto_stories_rounded,
                title: 'Từ thuần thục',
                value: '${userStats.totalWordsMastered}',
                color: GameVisualTokens.jade,
                bgColor: const Color(0xFFF0FDF4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _MetricCard(
                icon: Icons.local_fire_department_rounded,
                title: 'Chuỗi ngày',
                value: '${userStats.currentStreak} ngày',
                color: GameVisualTokens.crimson,
                bgColor: const Color(0xFFFEF2F2),
              ),
              const SizedBox(height: 12),
              _MetricCard(
                icon: Icons.favorite_rounded,
                title: 'Mục yêu thích',
                value: '${userStats.totalFavorites}',
                color: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: GameVisualTokens.primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF342E10),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementList(BuildContext context) {
    final exp = userStats.totalExp;
    final streak = userStats.currentStreak;
    final mastered = userStats.totalWordsMastered;

    return Column(
      children: [
        _AchievementTile(
          icon: Icons.explore_rounded,
          title: 'Khởi Đầu Nan',
          description: 'Hoàn thành ải phiêu lưu đầu tiên trên bản đồ.',
          isUnlocked: exp > 0,
          color: GameVisualTokens.jade,
        ),
        const SizedBox(height: 10),
        _AchievementTile(
          icon: Icons.local_fire_department_rounded,
          title: 'Ý Chí Sắt Đá',
          description: 'Duy trì chuỗi học liên tiếp từ 3 ngày trở lên.',
          isUnlocked: streak >= 3,
          progressText: streak >= 3 ? 'Đã đạt' : '$streak/3 ngày',
          color: GameVisualTokens.orange,
        ),
        const SizedBox(height: 10),
        _AchievementTile(
          icon: Icons.shield_rounded,
          title: 'Trảm Long Đoạt Bảo',
          description: 'Vượt qua cổng Boss khiêu chiến của màn chơi.',
          isUnlocked: exp >= 100,
          progressText: exp >= 100 ? 'Đã đạt' : '$exp/100 XP',
          color: GameVisualTokens.crimson,
        ),
        const SizedBox(height: 10),
        _AchievementTile(
          icon: Icons.library_books_rounded,
          title: 'Vạn Từ Tinh Thông',
          description: 'Thuần thục 10 từ vựng cốt lõi trong hệ thống.',
          isUnlocked: mastered >= 10,
          progressText: mastered >= 10 ? 'Đã đạt' : '$mastered/10 từ',
          color: GameVisualTokens.imperialGold,
        ),
      ],
    );
  }

  Widget _buildCompetencyBadges(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _CompetencyChip(label: 'Bộ thủ & Chữ Hán', icon: Icons.draw_rounded),
        _CompetencyChip(
            label: 'Thanh điệu Pinyin', icon: Icons.music_note_rounded),
        _CompetencyChip(
            label: 'Phát âm chuẩn', icon: Icons.record_voice_over_rounded),
        _CompetencyChip(label: 'Ngữ pháp HSK', icon: Icons.menu_book_rounded),
        _CompetencyChip(
            label: 'Phản xạ đàm thoại', icon: Icons.chat_bubble_rounded),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E6CF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: GameVisualTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GameVisualTokens.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.color,
    this.progressText,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final Color color;
  final String? progressText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? color.withValues(alpha: 0.4)
              : const Color(0xFFF1E6CF),
          width: 1.5,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : Colors.black38,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked
                              ? GameVisualTokens.ink
                              : Colors.black45,
                        ),
                      ),
                    ),
                    if (progressText != null)
                      Text(
                        progressText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked ? color : Colors.black38,
                        ),
                      )
                    else if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GameVisualTokens.jadeMint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Đã mở',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: GameVisualTokens.jadeDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? GameVisualTokens.muted : Colors.black38,
                    height: 1.25,
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

class _CompetencyChip extends StatelessWidget {
  const _CompetencyChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFF1E6CF), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GameVisualTokens.jade),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: GameVisualTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}
