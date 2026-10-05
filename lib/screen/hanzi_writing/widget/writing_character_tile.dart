import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/hanzi_character.dart';

class WritingCharacterTile extends StatelessWidget {
  const WritingCharacterTile(
      {super.key, required this.char, required this.onTap});
  final HanziCharacter char;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasStrokeData = char.strokeCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E7E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05461419),
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
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              char.character,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                fontFamily: 'FZKaiTiPinyin',
              ),
            ),
          ),
          title: Row(
            children: [
              if (char.hskLevel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HSK ${char.hskLevel}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              char.meaning ?? '',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${char.strokeCount} nét',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              if (!hasStrokeData)
                const Text(
                  'Chưa có nét',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
