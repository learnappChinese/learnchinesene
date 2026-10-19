import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/word.dart';
import '../../../core/models/example_sentence.dart';

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
    return Container(
      padding: const EdgeInsets.all(28),
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
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30B4232C),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (word.sectionTitle.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                word.sectionTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            word.chinese,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 58,
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
          Text(
            word.vietnamese,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: onPlayAudio,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.red,
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: onSpeak,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.red,
                ),
                icon: const Icon(Icons.mic_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WordExampleCard extends StatelessWidget {
  const WordExampleCard(
      {super.key,
      required this.example,
      required this.number,
      required this.onSpeak});
  final ExampleSentence example;
  final int number;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9E5),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.chinese,
                  style: const TextStyle(
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
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      example.vietnamese,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSpeak,
            icon: const Icon(
              Icons.mic_none_rounded,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
