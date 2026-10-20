import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../hanzi_writing/screens/hanzi_writing_screen.dart';

/// Modal BottomSheet cho phép người học chọn chữ Hán trong từ vựng để luyện viết nét.
class HanziWritingLinkSheet extends StatelessWidget {
  final String word;
  final List<Map<String, dynamic>> characters;

  const HanziWritingLinkSheet({
    super.key,
    required this.word,
    required this.characters,
  });

  static Future<void> show(
    BuildContext context, {
    required String word,
    required List<Map<String, dynamic>> characters,
  }) {
    if (characters.length == 1) {
      final charId = (characters.first['id'] as num).toInt();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HanziWritingScreen(
            characterId: charId,
          ),
        ),
      );
      return Future.value();
    }

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HanziWritingLinkSheet(
        word: word,
        characters: characters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Luyện viết các chữ trong "$word"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.ink,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn một chữ Hán để xem thứ tự nét và thực hành viết tay:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          if (characters.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu nét viết cho từ này.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...characters.map((c) {
              final charId = (c['id'] as num).toInt();
              final charStr = c['character'] as String? ?? '';
              final strokeCount = (c['stroke_count'] as num?)?.toInt() ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: GameVisualTokens.primaryGreenLight,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        charStr,
                        style: const TextStyle(
                          fontFamily: 'FZKaiTiPinyin',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: GameVisualTokens.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chữ "$charStr"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: GameVisualTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strokeCount > 0 ? '$strokeCount nét' : 'Thư pháp cơ bản',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HanziWritingScreen(
                              characterId: charId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameVisualTokens.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text(
                        'Viết',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
