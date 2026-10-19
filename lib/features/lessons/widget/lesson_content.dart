import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';

class LessonDialogueTab extends StatelessWidget {
  const LessonDialogueTab(
      {super.key, required this.lines, required this.onSpeak});
  final List<Map<String, String>> lines;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Center(child: Text('Không có dữ liệu hội thoại.'));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final speaker = line['speaker'] ?? 'A';
        final isA = speaker == 'A';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isA ? AppColors.red : AppColors.orange,
                foregroundColor: Colors.white,
                radius: 18,
                child: Text(speaker,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => onSpeak(line['zh'] ?? ''),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line['zh'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                    fontFamily: 'FZKaiTiPinyin',
                                  ),
                                ),
                              ),
                              const Icon(Icons.volume_up_rounded,
                                  size: 20, color: AppColors.red),
                            ],
                          ),
                          const Divider(height: 16),
                          Text(
                            line['vi'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LessonVocabularyTab extends StatelessWidget {
  const LessonVocabularyTab(
      {super.key, required this.items, required this.onSpeak});
  final List<Map<String, String>> items;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Không có từ vựng trọng tâm.'));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['hanzi'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['pinyin'] ?? '',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['meaning_vi'] ?? '',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onSpeak(item['hanzi'] ?? ''),
                  icon:
                      const Icon(Icons.volume_up_rounded, color: AppColors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LessonGrammarTab extends StatelessWidget {
  const LessonGrammarTab(
      {super.key, required this.points, required this.onSpeak});
  final List<Map<String, dynamic>> points;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('Không có điểm ngữ pháp nào.'));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: points.length,
      itemBuilder: (context, index) {
        final gp = points[index];
        final examples = gp['examples'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gp['point'] ?? 'Điểm ngữ pháp',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  gp['explanation_vi'] ?? '',
                  style: const TextStyle(
                      fontSize: 14, height: 1.45, color: AppColors.ink),
                ),
                if (examples.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Câu ví dụ:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  ...examples.map((ex) {
                    final map = ex as Map<String, String>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  map['zh'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink),
                                ),
                              ),
                              IconButton(
                                onPressed: () => onSpeak(map['zh'] ?? ''),
                                icon: const Icon(Icons.volume_up_rounded,
                                    size: 18, color: AppColors.muted),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Text(
                            map['pinyin'] ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            map['vi'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    );
                  }),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class LessonTopicTile extends StatelessWidget {
  const LessonTopicTile(
      {super.key,
      required this.number,
      required this.title,
      required this.description,
      required this.onTap});
  final int number;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameVisualTokens.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GameVisualTokens.imperialGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GameVisualTokens.crimson.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GameVisualTokens.crimson.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: GameVisualTokens.crimsonDark,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: GameVisualTokens.templeWood),
        onTap: onTap,
      ),
    );
  }
}
