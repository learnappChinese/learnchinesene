import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/word.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    this.onTap,
    this.hero = false,
  });
  final Word word;
  final VoidCallback? onTap;
  final bool hero;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.all(hero ? 28 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF0E7E5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A461419),
                  blurRadius: 20,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: hero ? _heroContent() : _rowContent(),
          ),
        ),
      );

  Widget _heroContent() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (word.sectionTitle.isNotEmpty) _tag(word.sectionTitle),
          const Spacer(),
          Text(
            word.chinese,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 62,
              height: 1.1,
              fontWeight: FontWeight.w400,
              fontFamily: 'FZKaiTiPinyin',
              fontFamilyFallback: [
                'FZKaiTiPinyin_1',
                'PingFang SC',
                'Heiti SC',
                'Microsoft YaHei',
                'Noto Sans SC'
              ],
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            word.vietnamese,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 19, height: 1.4, color: AppColors.ink),
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 17, color: AppColors.muted),
              SizedBox(width: 5),
              Text(
                'Chạm để xem câu mẫu và luyện tập',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ],
      );

  Widget _rowContent() => Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E5),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              word.chinese,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                fontFamily: 'FZKaiTiPinyin',
                fontFamilyFallback: [
                  'FZKaiTiPinyin_1',
                  'PingFang SC',
                  'Heiti SC',
                  'Microsoft YaHei',
                  'Noto Sans SC'
                ],
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.vietnamese,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      );

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EC),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.red,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
