import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/game_visual_tokens.dart';
import '../models/word.dart';
import 'panda_companion.dart';

class WordCard extends StatefulWidget {
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
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.45);
    } catch (_) {}
  }

  Future<void> _speak() async {
    try {
      if (widget.word.chinese.isNotEmpty) {
        await _tts.speak(widget.word.chinese);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: GameVisualTokens.gold.withValues(alpha: 0.55),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F7A5E2E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.all(widget.hero ? 22 : 14),
            child: widget.hero ? _heroContent() : _rowContent(),
          ),
        ),
      ),
    );
  }

  Widget _heroContent() {
    final sectionText = widget.word.sectionTitle.isNotEmpty
        ? widget.word.sectionTitle
        : 'TỪ VỰNG CỐT LÕI';

    return Column(
      children: [
        // Top tag and XP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GameVisualTokens.jade.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GameVisualTokens.jadeLight.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                sectionText,
                style: const TextStyle(
                  color: GameVisualTokens.jadeDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0D4), Color(0xFFFFE0A3)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameVisualTokens.gold),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 14),
                  SizedBox(width: 4),
                  Text(
                    '+10 XP • COMBO x1',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),

        // Large Chinese Character with glowing aura
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: GameVisualTokens.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: GameVisualTokens.gold.withValues(alpha: 0.18),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            widget.word.chinese,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 66,
              height: 1.1,
              fontWeight: FontWeight.w500,
              fontFamily: 'FZKaiTiPinyin',
              fontFamilyFallback: [
                'FZKaiTiPinyin_1',
                'PingFang SC',
                'Heiti SC',
                'Microsoft YaHei',
                'Noto Sans SC',
              ],
              color: GameVisualTokens.templeWood,
              shadows: [
                Shadow(
                  color: Color(0x33B45309),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pinyin with tones
        if (widget.word.pinyin.isNotEmpty)
          Text(
            widget.word.pinyin,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: GameVisualTokens.crimsonDark,
              letterSpacing: 1.1,
            ),
          ),
        const SizedBox(height: 8),

        // Vietnamese Meaning
        Text(
          widget.word.vietnamese,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: GameVisualTokens.ink,
          ),
        ),
        const SizedBox(height: 14),

        // Sound Audio Button
        GestureDetector(
          onTap: _speak,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: GameVisualTokens.jade.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Nghe phát âm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Panda Companion Reaction & Tap Hint
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PandaCompanion(
              mood: PandaMood.happy,
              size: 54,
              animate: false,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: GameVisualTokens.gold.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Chạm để xem câu mẫu & luyện tập 📜',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GameVisualTokens.templeWood,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rowContent() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GameVisualTokens.gold, width: 1.5),
          ),
          child: Text(
            widget.word.chinese,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'FZKaiTiPinyin',
              color: GameVisualTokens.templeWood,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.word.pinyin.isNotEmpty)
                Text(
                  widget.word.pinyin,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: GameVisualTokens.crimsonDark,
                  ),
                ),
              Text(
                widget.word.vietnamese,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GameVisualTokens.ink,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_rounded,
              color: GameVisualTokens.jadeDark, size: 22),
          onPressed: _speak,
        ),
        const Icon(Icons.chevron_right_rounded,
            color: GameVisualTokens.gold, size: 20),
      ],
    );
  }
}

