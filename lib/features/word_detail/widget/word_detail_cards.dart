import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/models/word.dart';
import '../../../core/models/example_sentence.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_green_button.dart';
import '../../../core/widgets/learning_question_card.dart';
import '../../../core/widgets/panda_companion.dart';

/// Thẻ từ chính, cùng khung với thẻ "Khám phá từ mới" ở các màn học.
class WordPronunciationCard extends StatelessWidget {
  const WordPronunciationCard(
      {super.key,
      required this.word,
      required this.onPlayAudio,
      required this.onSpeak});
  final Word word;
  final VoidCallback? onPlayAudio;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return LearningQuestionCard(
      stageLabel: word.hskLevelId > 0 ? 'HSK ${word.hskLevelId}' : 'TỪ VỰNG',
      instruction: word.sectionTitle.isNotEmpty
          ? word.sectionTitle
          : 'Nghe và luyện phát âm',
      trailing: const PandaCompanion(size: 72),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Text(
            word.chinese,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameVisualTokens.ink,
              fontSize: 54,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (word.pinyin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              word.pinyin,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameVisualTokens.crimsonDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.homeGreenSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Text(
                word.vietnamese,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.homeGreenText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppGreenButton.light(
                  label: 'Nghe',
                  icon: Icons.volume_up_rounded,
                  height: 46,
                  fontSize: 14,
                  onPressed: onPlayAudio,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppGreenButton.light(
                  label: 'Luyện nói',
                  icon: Icons.mic_rounded,
                  height: 46,
                  fontSize: 14,
                  onPressed: onSpeak,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thẻ chứa danh sách câu mẫu, cùng khung với thẻ câu hỏi.
class WordExamplesCard extends StatelessWidget {
  const WordExamplesCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LearningQuestionCard(
        stageLabel: 'CÂU MẪU',
        instruction: 'Câu mẫu theo ngữ cảnh',
        child: child,
      );
}

/// Một câu mẫu: ô trắng viền kem, nhãn số tròn.
class WordExampleCard extends StatelessWidget {
  const WordExampleCard(
      {super.key,
      required this.example,
      required this.number,
      required this.onSpeak});
  final ExampleSentence example;
  final int number;
  final VoidCallback onSpeak;

  static const _line = Color(0xFFE8E1D6);
  static const _ink = Color(0xFF342E10);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x14635D3B), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7E8),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.amberDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example.chinese,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'FZKaiTiPinyin',
                      fontFamilyFallback: [
                        'FZKaiTiPinyin_1',
                        'PingFang SC',
                        'Heiti SC',
                        'Microsoft YaHei',
                        'Noto Sans SC'
                      ],
                    ),
                  ),
                  if (example.vietnamese.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        example.vietnamese,
                        style: const TextStyle(
                          color: GameVisualTokens.primaryGreenDark,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppHudIconButton(
              icon: Icons.mic_rounded,
              tooltip: 'Luyện nói câu này',
              size: 40,
              onPressed: onSpeak,
            ),
          ],
        ),
      ),
    );
  }
}
