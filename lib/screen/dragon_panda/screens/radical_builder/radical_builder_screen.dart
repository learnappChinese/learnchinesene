import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/models/hanzi_character.dart';
import 'widget/radical_builder_options.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';

class RadicalBuilderScreen extends StatefulWidget {
  final VoidCallback onBack;

  const RadicalBuilderScreen({super.key, required this.onBack});


  @override
  State<RadicalBuilderScreen> createState() => _RadicalBuilderScreenState();
}

class _RadicalQuestion {
  final String character;
  final String pinyin;
  final String meaning;
  final String correctRadical;
  final List<String> options;

  _RadicalQuestion({
    required this.character,
    required this.pinyin,
    required this.meaning,
    required this.correctRadical,
    required this.options,
  });
}

class _RadicalBuilderScreenState extends State<RadicalBuilderScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = true;
  List<_RadicalQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  String? _selectedRadical;
  bool _answered = false;


  final Map<String, List<String>> _characterDecompositions = {
    '好': ['女', '子'],
    '妈': ['女', '马'],
    '明': ['日', '月'],
    '休': ['亻', '木'],
    '语': ['讠', '吾'],
    '话': ['讠', '舌'],
    '饭': ['饣', '反'],
    '吃': ['口', '乞'],
    '喝': ['口', '曷'],
    '男': ['田', '力'],
    '林': ['木', '木'],
    '爸': ['父', '巴'],
    '听': ['口', '斤'],
    '唱': ['口', '昌'],
    '问': ['门', '口'],
    '现': ['王', '见'],
    '他': ['亻', '也'],
    '你': ['亻', '尔'],
    '草': ['艹', '早'],
    '花': ['艹', '化'],
    '谢': ['讠', '射'],
    '家': ['宀', '豕'],
    '字': ['宀', '子'],
    '学': ['⺌', '子'],
    '江': ['氵', '工'],
    '河': ['氵', '可'],
    '海': ['氵', '每'],
  };

  final List<String> _commonRadicals = [
    '女', '子', '亻', '木', '日', '月', '讠', '饣',
    '口', '田', '力', '父', '门', '王', '艹', '宀',
    '氵', '火', '心', '扌', '纟', '辶', '阝', '金',
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

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);
    final random = Random();
    List<_RadicalQuestion> loadedQuestions = [];

    try {
      // 1. Fetch characters from database
      final List<HanziCharacter> dbChars =
          await DbHelper.instance.getCharactersForWriting();

      for (final char in dbChars) {
        final targetChar = char.character;
        final decomp = _characterDecompositions[targetChar];

        if (decomp != null && decomp.isNotEmpty) {
          final rad = decomp.first;
          // Generate 3 distractors
          final distractors = _commonRadicals.where((r) => r != rad).toList()
            ..shuffle(random);
          final options = [rad, ...distractors.take(3)]..shuffle(random);

          loadedQuestions.add(_RadicalQuestion(
            character: targetChar,
            pinyin: char.pinyin ?? '',
            meaning: char.meaning ?? '',
            correctRadical: rad,
            options: options,
          ));
        }

        if (loadedQuestions.length >= 10) break;
      }
    } catch (_) {}


    // Fallback if needed
    if (loadedQuestions.length < 5) {
      final fallbackEntries = _characterDecompositions.entries.toList()
        ..shuffle(random);

      for (final entry in fallbackEntries) {
        final char = entry.key;
        final correctRad = entry.value.first;
        final distractors =
            _commonRadicals.where((r) => r != correctRad).toList()
              ..shuffle(random);
        final options = [correctRad, ...distractors.take(3)]..shuffle(random);

        loadedQuestions.add(_RadicalQuestion(
          character: char,
          pinyin: '',
          meaning: 'Bộ thủ cấu thành',
          correctRadical: correctRad,
          options: options,
        ));

        if (loadedQuestions.length >= 10) break;
      }
    }

    if (mounted) {
      setState(() {
        _questions = loadedQuestions;
        _isLoading = false;
        _currentIndex = 0;
        _score = 0;
        _combo = 0;
      });

      if (_questions.isNotEmpty) {
        _speak(_questions[0].character);
      }
    }
  }

  void _handleSelectRadical(String radical) {
    if (_answered || _questions.isEmpty) return;

    final curr = _questions[_currentIndex];
    final isRight = (radical == curr.correctRadical);

    setState(() {
      _selectedRadical = radical;
      _answered = true;
      if (isRight) {
        _combo++;
        _score += 100 + (_combo * 10);
      } else {
        _combo = 0;
      }
    });

    _speak(curr.character);

    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_currentIndex + 1 < _questions.length) {
        setState(() {
          _currentIndex++;
          _selectedRadical = null;
          _answered = false;
        });
        _speak(_questions[_currentIndex].character);

      } else {
        _showVictoryDialog();
      }
    });
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF1FBF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            '🎉 Hoàn thành!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bạn đã hoàn thành thử thách Xây Chữ Hán!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐ Điểm số: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
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
                    color: Color(0xFF0F766E))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
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
              'assets/images/backgrounds/radical_builder_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F4C3A)),
            ),
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

  Widget _buildRoundProgress() {
    final total = _questions.length;
    final current = (_currentIndex + 1).clamp(1, total);
    final progress = total > 0 ? current / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 12,
                color: Colors.black.withOpacity(0.35),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.orangeGoldGradient,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$current / $total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold, width: 1),
            ),
            child: Text(
              '$_score pts',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard() {
    final curr = _questions[_currentIndex];

    return GestureDetector(
      onTap: () => _speak(curr.character),
      child: Container(
        width: 230,
        height: 230,
        decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.cardCreamBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              curr.character,
              style: const TextStyle(
                fontSize: 95,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            if (curr.pinyin.isNotEmpty)
              Text(
                curr.pinyin,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            if (curr.meaning.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  curr.meaning,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadicalTray() {
    final curr = _questions[_currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF8).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Chọn bộ thủ tạo nên chữ trên:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: curr.options.map((radical) {
              final bool isSelected = _selectedRadical == radical;
              bool? isCorrect;
              bool isWrong = false;

              if (_answered) {
                if (radical == curr.correctRadical) {
                  isCorrect = true;
                } else if (isSelected) {
                  isWrong = true;
                }
              }

              return RadicalOptionTile(
                radical: radical,
                isCorrect: isCorrect,
                isWrong: isWrong,
                onTap: () => _handleSelectRadical(radical),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    return SafeArea(
      child: Column(
        children: [
          // Top App Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GameScreenHeader(
              title: 'Xây chữ Hán',
              onBack: widget.onBack,
              onSettings: () {},
              titleShadowColor: Colors.black87,
            ),
          ),

          // Progress Bar
          _buildRoundProgress(),
          const Spacer(),

          // Main Chinese Character Card
          _buildCharacterCard(),
          const Spacer(),

          // Radical / Component Selection Tray
          _buildRadicalTray(),
        ],
      ),
    );
  }
}
