import 'package:flutter/material.dart';
import '../../vocabulary/data/models/user_stats_model.dart';

class ProfileAchievements extends StatelessWidget {
  const ProfileAchievements({super.key, required this.userStats});
  final UserStats userStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildProfileHeader(theme),
        const SizedBox(height: 32),
        // ⭐ Kinh nghiệm
        StatTile(
          icon: Icons.star,
          title: 'Kinh nghiệm',
          value: '${userStats.totalExp} EXP',
          description: 'Điểm kinh nghiệm tích lũy từ hoạt động học tập.',
        ),
        const SizedBox(height: 16),
        // 🔥 Chuỗi ngày học
        StatTile(
          icon: Icons.local_fire_department,
          title: 'Chuỗi ngày học',
          value: '${userStats.currentStreak} ngày',
          description: 'Giữ nhịp luyện tập mỗi ngày để trí nhớ bền vững.',
        ),
        const SizedBox(height: 16),
        // 📖 Từ thuần thục
        StatTile(
          icon: Icons.auto_awesome,
          title: 'Từ đã thuần thục',
          value: '${userStats.totalWordsMastered}',
          description: 'Số lượng từ đã hoàn thành đủ vòng luyện tập.',
        ),
        const SizedBox(height: 16),
        // ❤️ Câu yêu thích
        StatTile(
          icon: Icons.favorite_outline,
          title: 'Câu ví dụ yêu thích',
          value: '${userStats.totalFavorites}',
          description:
              'Bạn đã đánh dấu ${userStats.totalFavorites} câu để luyện lại.',
        ),
        const SizedBox(height: 32),
        Text(
          'Kỹ năng luyện gõ',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            SkillChip(label: 'Đánh máy pinyin'),
            SkillChip(label: 'Nhập nghĩa tiếng Việt'),
            SkillChip(label: 'Gõ câu hoàn chỉnh'),
            SkillChip(label: 'Phản xạ hội thoại'),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primary.withAlpha(41),
          child: Icon(Icons.emoji_emotions_outlined,
              color: theme.colorScheme.primary, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Học viên HSK',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Hành trình gõ tiếng Trung của bạn được ghi lại tại đây.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(31),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      backgroundColor: theme.colorScheme.primary.withAlpha(26),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
