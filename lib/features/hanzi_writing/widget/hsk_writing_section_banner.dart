import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../models/writing_path_models.dart';

class HskWritingSectionBanner extends StatelessWidget {
  const HskWritingSectionBanner({
    super.key,
    required this.hskName,
    required this.section,
  });

  final String hskName;
  final WritingPathSection section;

  @override
  Widget build(BuildContext context) {
    final total = section.requiredCount;
    final done = section.completedCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: section.unlocked
                ? const [Color(0xFF55B948), Color(0xFF2E8B43)]
                : const [Color(0xFFB8C2CC), Color(0xFF94A3B8)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F166534),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$hskName • SECTION ${section.order}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress.clamp(0, 1),
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$done/$total chữ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (!section.unlocked) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white70, size: 15),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hoàn thành Section trước để mở khóa.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WritingHskMilestone extends StatelessWidget {
  const WritingHskMilestone({
    super.key,
    required this.path,
  });

  final WritingHskPath path;

  @override
  Widget build(BuildContext context) {
    final completed = path.completed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? GameVisualTokens.imperialGold
                  : const Color(0xFFE2E8F0),
              boxShadow: completed
                  ? const [
                      BoxShadow(
                        color: Color(0x339A6700),
                        blurRadius: 18,
                        offset: Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              completed ? Icons.emoji_events_rounded : Icons.flag_rounded,
              color: completed ? Colors.white : const Color(0xFF94A3B8),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completed
                ? 'Hoàn thành ${path.catalog.name}'
                : 'Mốc ${path.catalog.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: GameVisualTokens.templeWood,
            ),
          ),
          Text(
            '${path.completedCount}/${path.requiredCount} chữ đã vượt qua',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
