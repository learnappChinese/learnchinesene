import 'package:flutter/material.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/models/hanzi_character.dart';

class WritingCharacterTile extends StatelessWidget {
  const WritingCharacterTile({
    super.key,
    required this.char,
    required this.onTap,
  });

  final HanziCharacter char;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasStrokeData = char.strokeCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameVisualTokens.gold.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147A5E2E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: GameVisualTokens.gold,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F855B1B),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              char.character,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                fontFamily: 'FZKaiTiPinyin',
                color: GameVisualTokens.templeWood,
              ),
            ),
          ),
          title: Row(
            children: [
              if (char.pinyin != null && char.pinyin!.isNotEmpty)
                Text(
                  char.pinyin!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: GameVisualTokens.crimsonDark,
                  ),
                ),
              if (char.hskLevel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: GameVisualTokens.jade.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: GameVisualTokens.jadeLight.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'HSK ${char.hskLevel}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: GameVisualTokens.jadeDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              char.meaning ?? '',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🖌️', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${char.strokeCount} nét',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: GameVisualTokens.templeWood,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (!hasStrokeData)
                const Text(
                  'Chưa có nét',
                  style: TextStyle(
                    color: GameVisualTokens.crimson,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GameVisualTokens.gold,
                  size: 18,
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

