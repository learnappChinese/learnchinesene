import 'package:flutter/material.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_colors.dart';

class LearningAttemptTile extends StatelessWidget {
  const LearningAttemptTile({
    super.key,
    required this.attempt,
    required this.timeLabel,
  });

  final Map<String, dynamic> attempt;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final title = '${attempt['title'] ?? 'Bài học'}';
    final icon = '${attempt['icon'] ?? '⭐'}';
    final xp =
        (attempt['xpEarned'] ?? attempt['xp_amount'] as num?)?.toInt() ?? 0;
    final stars = (attempt['stars'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Tiến độ chính thức',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                  if (stars > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '⭐' * stars.clamp(1, 3),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (xp > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$xp XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HistoryItemTile extends StatelessWidget {
  const HistoryItemTile(
      {super.key,
      required this.item,
      required this.timeLabel,
      required this.onTap});
  final HistoryItem item;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color tagColor = AppColors.red;
    if (item.type == 'Hội thoại') tagColor = AppColors.orange;
    if (item.type == 'Thi HSK') tagColor = AppColors.success;
    if (item.type == 'Trắc nghiệm HSK') tagColor = AppColors.redDark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'AI Tiện ích: ${item.type}',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                timeLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            item.summary,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
                fontSize: 14),
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}

class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet(
      {super.key, required this.type, required this.content});
  final String type;
  final Map<String, dynamic> content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$type - Chi tiết tiện ích AI',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink),
            ),
            const Divider(height: 24),
            if (type == 'Dịch thuật') ...[
              Text(
                  'Nguồn: ${content['source_lang']} ➔ Đích: ${content['target_lang']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Nội dung dịch:',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(content['hanzi'] ?? '',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              if (content['pinyin'] != null)
                Text(content['pinyin'],
                    style: const TextStyle(
                        color: AppColors.orange, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              const Text('Nghĩa tiếng Việt:',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              Text(content['vi_meaning'] ?? '',
                  style: const TextStyle(fontSize: 15, color: AppColors.ink)),
            ] else if (type == 'Hội thoại') ...[
              Text('Chủ đề: ${content['topic']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.orange)),
              const SizedBox(height: 12),
              ...((content['lines'] as List<dynamic>? ?? []).map((line) {
                final speaker =
                    (line['turn'] as int? ?? 1) % 2 == 1 ? 'A' : 'B';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Speaker $speaker:',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.muted)),
                      Text(line['zh'] ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink)),
                      Text(line['pinyin'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.orange)),
                      Text(line['vi'] ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                );
              })),
            ] else if (type == 'Thi HSK') ...[
              Text('Điểm số: ${content['score']}/${content['total']}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.red)),
              const SizedBox(height: 12),
              if (content['analysis'] != null) ...[
                const Text('Nhận xét giáo viên:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.orange)),
                const SizedBox(height: 4),
                Text(content['analysis']['overall_assessment'] ?? '',
                    style: const TextStyle(height: 1.4, color: AppColors.ink)),
              ],
            ] else if (type == 'Trắc nghiệm HSK') ...[
              Text('Kết quả: ${content['score']}/${content['total']} câu đúng',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.red)),
              const SizedBox(height: 8),
              Text(
                'Luyện tập trắc nghiệm cấp độ HSK ${content['level'] ?? 1}. Chế độ luyện tập tự do không tính điểm kinh nghiệm lộ trình.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
