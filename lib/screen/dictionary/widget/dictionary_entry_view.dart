import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DictionaryEntryView extends StatelessWidget {
  const DictionaryEntryView(
      {super.key, required this.entry, required this.onPlayAudio});
  final Map<String, dynamic> entry;
  final ValueChanged<String> onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final hanzi = entry['hanzi'] ?? '';
    final pinyin = entry['pinyin'] ?? '';
    final viMeaning = entry['vi_meaning'] ?? '';
    final examples = entry['examples'] as List<dynamic>? ?? [];
    final grammarNotes = entry['grammar_notes'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Word Card
        _buildWordCard(hanzi, pinyin, viMeaning),
        const SizedBox(height: 24),

        // Examples
        if (examples.isNotEmpty) ...[
          const Text(
            'Ví dụ đặt câu:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...examples.map(_buildExample),
        ],

        const SizedBox(height: 16),

        // Grammar / synonyms
        if (grammarNotes.isNotEmpty) ...[
          const Text(
            'Ghi chú / Từ liên quan:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _buildGrammarNotes(grammarNotes),
        ],
      ],
    );
  }

  Widget _buildWordCard(dynamic hanzi, dynamic pinyin, dynamic viMeaning) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.redDark,
              AppColors.red,
              AppColors.orange,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hanzi,
                  style: const TextStyle(
                    fontFamily: 'FZKaiTiPinyin',
                    fontSize: 52,
                    color: Colors.white,
                  ),
                ),
                IconButton.filled(
                  onPressed: () => onPlayAudio(hanzi),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.red,
                  ),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
            Text(
              pinyin,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viMeaning,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(dynamic ex) {
    final zh = ex['zh'] ?? '';
    final py = ex['pinyin'] ?? '';
    final vi = ex['vi'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zh,
                    style: const TextStyle(
                      fontFamily: 'FZKaiTiPinyin',
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    py,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vi,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onPlayAudio(zh),
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarNotes(List<dynamic> grammarNotes) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grammarNotes.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      note.toString(),
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
