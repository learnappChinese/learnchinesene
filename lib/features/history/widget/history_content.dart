import 'package:flutter/material.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';

const _kTileBorder = Color(0xFFEFE7E1);

BoxDecoration _tileDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _kTileBorder),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF7F1520).withValues(alpha: .05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.muted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Một lượt học trong lịch sử.
class LearningAttemptTile extends StatelessWidget {
  const LearningAttemptTile({
    super.key,
    required this.attempt,
    required this.timeLabel,
  });

  final Map<String, dynamic> attempt;
  final String timeLabel;

  static const _line = Color(0xFFE8E1D6);

  static (IconData, Color) _visualFor(String activityType) {
    switch (activityType) {
      case 'boss':
        return (Icons.local_fire_department_rounded, GameVisualTokens.crimson);
      case 'vocabulary':
        return (Icons.menu_book_rounded, AppColors.homeGreen);
      case 'listening':
        return (Icons.headphones_rounded, GameVisualTokens.blue);
      case 'speaking':
        return (Icons.mic_rounded, GameVisualTokens.orange);
      case 'hanzi':
        return (Icons.draw_rounded, AppColors.imperialGold);
      case 'sentence':
      case 'dialogue':
        return (Icons.chat_bubble_rounded, Color(0xFF8B5CF6));
      case 'quiz':
        return (Icons.bolt_rounded, GameVisualTokens.gold);
      default:
        return (Icons.star_rounded, AppColors.homeGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${attempt['title'] ?? 'Bài học'}';
    final activityType =
        '${attempt['activityType'] ?? attempt['activity_type'] ?? ''}';
    final (icon, color) = _visualFor(activityType);
    final xp =
        (attempt['xpEarned'] ?? attempt['xp_amount'] as num?)?.toInt() ?? 0;
    final stars = ((attempt['stars'] as num?)?.toInt() ?? 0).clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x14635D3B), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, .25)!, color],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.homeTitle,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (timeLabel.isNotEmpty)
                        Flexible(child: _TimeLabel(timeLabel)),
                      if (stars > 0) ...[
                        const SizedBox(width: 8),
                        for (var i = 0; i < 3; i++)
                          Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: AppColors.imperialGold,
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (xp > 0) ...[const SizedBox(width: 8), _XpPill(xp: xp)],
          ],
        ),
      ),
    );
  }
}

/// Nhãn "+n XP" phẳng màu cam nhạt.
class _XpPill extends StatelessWidget {
  const _XpPill({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GameVisualTokens.orange.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '+$xp XP',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.amberDark,
          fontSize: 12,
        ),
      ),
    );
  }
}

class HistoryItemTile extends StatelessWidget {
  const HistoryItemTile({
    super.key,
    required this.item,
    required this.timeLabel,
    required this.onTap,
  });
  final HistoryItem item;
  final String timeLabel;
  final VoidCallback onTap;

  (Color, IconData) _style() {
    switch (item.type) {
      case 'Dịch thuật':
        return (const Color(0xFF2E93E8), Icons.translate_rounded);
      case 'Từ điển':
        return (AppColors.red, Icons.menu_book_rounded);
      case 'Hội thoại':
        return (AppColors.orange, Icons.chat_bubble_rounded);
      case 'Thi HSK':
        return (AppColors.success, Icons.assignment_turned_in_rounded);
      case 'Trắc nghiệm HSK':
        return (AppColors.redDark, Icons.quiz_rounded);
      default:
        return (const Color(0xFF7C5CC4), Icons.auto_awesome_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _tileDecoration(),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (timeLabel.isNotEmpty)
                            Flexible(child: _TimeLabel(timeLabel)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet({
    super.key,
    required this.type,
    required this.content,
  });
  final String type;
  final Map<String, dynamic> content;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Chừa thanh home indicator / thanh điều hướng ở đáy.
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
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
                color: AppColors.ink,
              ),
            ),
            const Divider(height: 24),
            if (type == 'Dịch thuật') ...[
              Text(
                'Nguồn: ${content['source_lang']} ➔ Đích: ${content['target_lang']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nội dung dịch:',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                content['hanzi'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              if (content['pinyin'] != null)
                Text(
                  content['pinyin'],
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Nghĩa tiếng Việt:',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                content['vi_meaning'] ?? '',
                style: const TextStyle(fontSize: 15, color: AppColors.ink),
              ),
            ] else if (type == 'Hội thoại') ...[
              Text(
                'Chủ đề: ${content['topic']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 12),
              ...((content['lines'] as List<dynamic>? ?? []).map((line) {
                final speaker = (line['turn'] as int? ?? 1) % 2 == 1
                    ? 'A'
                    : 'B';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speaker $speaker:',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        line['zh'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        line['pinyin'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.orange,
                        ),
                      ),
                      Text(
                        line['vi'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ] else if (type == 'Thi HSK') ...[
              Text(
                'Điểm số: ${content['score']}/${content['total']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 12),
              if (content['analysis'] != null) ...[
                const Text(
                  'Nhận xét giáo viên:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content['analysis']['overall_assessment'] ?? '',
                  style: const TextStyle(height: 1.4, color: AppColors.ink),
                ),
              ],
            ] else if (type == 'Trắc nghiệm HSK') ...[
              Text(
                'Kết quả: ${content['score']}/${content['total']} câu đúng',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
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
