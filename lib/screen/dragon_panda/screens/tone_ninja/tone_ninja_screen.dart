import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/models/speaking_practice_item.dart';
import 'widget/tone_ninja_options.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';

class ToneNinjaScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ToneNinjaScreen({super.key, required this.onBack});


  @override
  State<ToneNinjaScreen> createState() => _ToneNinjaScreenState();
}

class _ToneQuestion {
  final String hanzi;
  final String correctPinyin;
  final int correctTone; // 1, 2, 3, 4
  final List<String> toneOptions; // 4 options for tones 1..4

  _ToneQuestion({
    required this.hanzi,
    required this.correctPinyin,
    required this.correctTone,
    required this.toneOptions,
  });
}

class _ToneNinjaScreenState extends State<ToneNinjaScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = true;
  List<_ToneQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _lives = 3;
  int? _selectedToneIndex;
  bool _answered = false;

  final List<Map<String, dynamic>> _fallbackWords = [
    {'hanzi': '妈', 'pinyin': 'mā', 'tone': 1, 'base': 'ma'},
    {'hanzi': '麻', 'pinyin': 'má', 'tone': 2, 'base': 'ma'},
    {'hanzi': '马', 'pinyin': 'mǎ', 'tone': 3, 'base': 'ma'},
    {'hanzi': '骂', 'pinyin': 'mà', 'tone': 4, 'base': 'ma'},
    {'hanzi': '八', 'pinyin': 'bā', 'tone': 1, 'base': 'ba'},
    {'hanzi': '拔', 'pinyin': 'bá', 'tone': 2, 'base': 'ba'},
    {'hanzi': '把', 'pinyin': 'bǎ', 'tone': 3, 'base': 'ba'},
    {'hanzi': '爸', 'pinyin': 'bà', 'tone': 4, 'base': 'ba'},
    {'hanzi': '好', 'pinyin': 'hǎo', 'tone': 3, 'base': 'hao'},
    {'hanzi': '号', 'pinyin': 'hào', 'tone': 4, 'base': 'hao'},
    {'hanzi': '书', 'pinyin': 'shū', 'tone': 1, 'base': 'shu'},
    {'hanzi': '水', 'pinyin': 'shuǐ', 'tone': 3, 'base': 'shui'},
    {'hanzi': '睡', 'pinyin': 'shuì', 'tone': 4, 'base': 'shui'},
    {'hanzi': '吃', 'pinyin': 'chī', 'tone': 1, 'base': 'chi'},
    {'hanzi': '茶', 'pinyin': 'chá', 'tone': 2, 'base': 'cha'},
    {'hanzi': '学', 'pinyin': 'xué', 'tone': 2, 'base': 'xue'},
    {'hanzi': '谢', 'pinyin': 'xiè', 'tone': 4, 'base': 'xie'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadGameData();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  int _detectTone(String pinyin) {
    if (RegExp(r'[āēīōūǖ]').hasMatch(pinyin)) return 1;
    if (RegExp(r'[áéíóúǘ]').hasMatch(pinyin)) return 2;
    if (RegExp(r'[ǎěǐǒǔǚ]').hasMatch(pinyin)) return 3;
    if (RegExp(r'[àèìòùǜ]').hasMatch(pinyin)) return 4;
    return 1;
  }

  List<String> _generateToneVariants(String pinyin, int tone) {
    // Standard replacement map for vowels
    final vowelTones = {
      'a': ['ā', 'á', 'ǎ', 'à'],
      'e': ['ē', 'é', 'ě', 'è'],
      'i': ['ī', 'í', 'ǐ', 'ì'],
      'o': ['ō', 'ó', 'ǒ', 'ò'],
      'u': ['ū', 'ú', 'ǔ', 'ù'],
      'v': ['ǖ', 'ǘ', 'ǚ', 'ǜ'],
      'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ'],
    };

    // Normalize pinyin to base vowel
    String normalized = pinyin
        .replaceAll(RegExp(r'[āáǎà]'), 'a')
        .replaceAll(RegExp(r'[ēéěè]'), 'e')
        .replaceAll(RegExp(r'[īíǐì]'), 'i')
        .replaceAll(RegExp(r'[ōóǒò]'), 'o')
        .replaceAll(RegExp(r'[ūúǔù]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜ]'), 'ü');

    // Pick vowel to tone
    String targetVowel = 'a';
    if (normalized.contains('a')) {
      targetVowel = 'a';
    } else if (normalized.contains('o')) {
      targetVowel = 'o';
    } else if (normalized.contains('e')) {
      targetVowel = 'e';
    } else if (normalized.contains('iu')) {
      targetVowel = 'u';
    } else if (normalized.contains('ui')) {
      targetVowel = 'i';
    } else if (normalized.contains('i')) {
      targetVowel = 'i';
    } else if (normalized.contains('u')) {
      targetVowel = 'u';
    } else if (normalized.contains('ü')) {
      targetVowel = 'ü';
    }

    final tones = vowelTones[targetVowel] ?? ['a', 'a', 'a', 'a'];
    final List<String> variants = [];
    for (int t = 1; t <= 4; t++) {
      final accented = tones[t - 1];
      final variantStr = normalized.replaceFirst(targetVowel, accented);
      variants.add('$variantStr ($t)');
    }
    return variants;
  }

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);
    List<_ToneQuestion> loaded = [];

    try {
      final List<SpeakingPracticeItem> items =
          await DbHelper.instance.getRandomSpeakingItems(limit: 30);

      for (final item in items) {
        final hanzi = item.targetText;
        final pinyin = item.pinyin;
        if (hanzi.isNotEmpty && pinyin.isNotEmpty && !hanzi.contains(' ')) {
          final firstPinyin = pinyin.split(' ').first;
          final firstHanzi = hanzi.characters.first;
          final tone = _detectTone(firstPinyin);
          final options = _generateToneVariants(firstPinyin, tone);

          loaded.add(_ToneQuestion(
            hanzi: firstHanzi,
            correctPinyin: firstPinyin,
            correctTone: tone,
            toneOptions: options,
          ));
        }
        if (loaded.length >= 10) break;
      }
    } catch (_) {}

    if (loaded.length < 5) {
      for (final fb in _fallbackWords) {
        final pinyin = fb['pinyin'] as String;
        final tone = fb['tone'] as int;
        final options = _generateToneVariants(pinyin, tone);

        loaded.add(_ToneQuestion(
          hanzi: fb['hanzi'] as String,
          correctPinyin: pinyin,
          correctTone: tone,
          toneOptions: options,
        ));
        if (loaded.length >= 10) break;
      }
    }

    if (mounted) {
      setState(() {
        _questions = loaded..shuffle(Random());
        _isLoading = false;
        _currentIndex = 0;
        _score = 0;
        _combo = 0;
        _lives = 3;
        _selectedToneIndex = null;
        _answered = false;
      });

      if (_questions.isNotEmpty) {
        _speak(_questions[0].hanzi);
      }
    }
  }

  void _handleSelectTone(int toneIndex) {
    if (_answered || _questions.isEmpty) return;

    final curr = _questions[_currentIndex];
    final bool isRight = (toneIndex + 1 == curr.correctTone);

    setState(() {
      _selectedToneIndex = toneIndex;
      _answered = true;
      if (isRight) {
        _combo++;
        _score += 100 + (_combo * 15);
      } else {
        _combo = 0;
        _lives = (_lives - 1).clamp(0, 3);
      }
    });

    _speak(curr.hanzi);

    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_lives <= 0) {
        _showGameOverDialog();
        return;
      }

      if (_currentIndex + 1 < _questions.length) {
        setState(() {
          _currentIndex++;
          _selectedToneIndex = null;
          _answered = false;
        });
        _speak(_questions[_currentIndex].hanzi);
      } else {
        _showVictoryDialog();
      }
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            '💔 Hết tim!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5252),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đừng nản lòng, hãy thử lại để thành thạo 4 thanh điệu nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Text(
              'Điểm đạt được: $_score',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadGameData();
            },
            child: const Text('Chơi lại',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8845F7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8845F7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBack();
            },
            child: const Text('Về Menu',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            '🥷 Ninja Đại Tài!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Xuất sắc! Bạn đã vượt qua tất cả các thử thách thanh điệu!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGold, width: 1.5),
              ),
              child: Text(
                '⭐ Điểm số: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadGameData();
            },
            child: const Text('Chơi lại',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8845F7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8845F7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBack();
            },
            child: const Text('Về Menu',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/tone_ninja_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1B0B2E)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Colors.white))
          else if (_questions.isEmpty)
            Center(
              child: ElevatedButton(
                onPressed: _loadGameData,
                child: const Text('Thử lại'),
              ),
            )
          else
            _buildGameContent(),
        ],
      ),
    );
  }

  Widget _buildScoreAndLives() {
    final total = _questions.length;
    final current = (_currentIndex + 1).clamp(1, total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '⭐ $current / $total  ($_score pts)',
            style: const TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  i < _lives ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPinyin() {
    final curr = _questions[_currentIndex];

    return GestureDetector(
      onTap: () => _speak(curr.hanzi),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up_rounded,
                color: AppColors.primaryBlue, size: 32),
            const SizedBox(width: 12),
            Text(
              curr.hanzi,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneOptions() {
    final curr = _questions[_currentIndex];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: List.generate(curr.toneOptions.length, (index) {
        final toneText = curr.toneOptions[index];
        final toneNum = index + 1;
        final bool isSelected = _selectedToneIndex == index;
        final bool isTargetCorrect = (toneNum == curr.correctTone);

        bool isCorrect = false;
        bool isWrong = false;

        if (_answered) {
          if (isTargetCorrect) {
            isCorrect = true;
          } else if (isSelected) {
            isWrong = true;
          }
        }

        return ToneOptionCard(
          text: toneText,
          isCorrect: isCorrect,
          isWrong: isWrong,
          onTap: () => _handleSelectTone(index),
        );
      }),
    );
  }

  Widget _buildGameContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // App Bar
            GameScreenHeader(
              title: 'Tone Ninja',
              onBack: widget.onBack,
              onSettings: () {},
            ),

            // Score & 3 Hearts
            _buildScoreAndLives(),
            const Spacer(),

            // Ninja Panda Character Overlay
            SizedBox(
              width: 140,
              height: 140,
              child: Image.asset(
                'assets/images/characters/panda_ninja.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🥷🐼', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Target Hanzi + Speaker
            _buildTargetPinyin(),
            const Spacer(),

            // 4 Tone Options
            _buildToneOptions(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
