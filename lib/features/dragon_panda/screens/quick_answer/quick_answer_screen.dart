import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/widgets/game_result_dialog.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/models/speaking_practice_item.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';
import '../../widgets/answer_button.dart';
import '../../../../core/learning/service/learning_reward_service.dart';
import '../../../../core/learning/model/learning_activity_submission.dart';

class QuickAnswerScreen extends StatefulWidget {
  final VoidCallback onBack;

  const QuickAnswerScreen({super.key, required this.onBack});

  @override
  State<QuickAnswerScreen> createState() => _QuickAnswerScreenState();
}

class _QuickQuestion {
  final String hanzi;
  final String pinyin;
  final String meaning;
  final List<String> options;
  final int correctIndex;

  _QuickQuestion({
    required this.hanzi,
    required this.pinyin,
    required this.meaning,
    required this.options,
    required this.correctIndex,
  });
}

class _QuickAnswerScreenState extends State<QuickAnswerScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = true;
  List<_QuickQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _timeLeft = 15;
  Timer? _timer;
  int? _selectedAnswerIndex;
  bool _answered = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _maxCombo = 0;
  int _earnedXp = 0;

  final List<Map<String, String>> _fallbackVocab = [
    {'hanzi': '电脑', 'pinyin': 'diàn nǎo', 'meaning': 'máy tính'},
    {'hanzi': '手机', 'pinyin': 'shǒu jī', 'meaning': 'điện thoại'},
    {'hanzi': '书', 'pinyin': 'shū', 'meaning': 'sách'},
    {'hanzi': '水', 'pinyin': 'shuǐ', 'meaning': 'nước'},
    {'hanzi': '喝茶', 'pinyin': 'hē chá', 'meaning': 'uống trà'},
    {'hanzi': '吃饭', 'pinyin': 'chī fàn', 'meaning': 'ăn cơm'},
    {'hanzi': '苹果', 'pinyin': 'píng guǒ', 'meaning': 'quả táo'},
    {'hanzi': '学校', 'pinyin': 'xué xiào', 'meaning': 'trường học'},
    {'hanzi': '老师', 'pinyin': 'lǎo shī', 'meaning': 'giáo viên'},
    {'hanzi': '朋友', 'pinyin': 'péng you', 'meaning': 'bạn bè'},
    {'hanzi': '高兴', 'pinyin': 'gāo xìng', 'meaning': 'vui vẻ'},
    {'hanzi': '谢谢', 'pinyin': 'xiè xie', 'meaning': 'cảm ơn'},
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
    List<_QuickQuestion> loaded = [];

    try {
      final List<SpeakingPracticeItem> items =
          await DbHelper.instance.getRandomSpeakingItems(limit: 40);

      final validItems = items
          .where((i) =>
              i.targetText.isNotEmpty &&
              i.meaning.isNotEmpty &&
              i.meaning.length < 30)
          .toList();

      for (int i = 0; i < validItems.length; i++) {
        final target = validItems[i];
        final distractors = validItems
            .where((d) => d.meaning != target.meaning)
            .map((d) => d.meaning)
            .toSet()
            .toList()
          ..shuffle(random);

        if (distractors.length >= 3) {
          final options = [
            target.meaning,
            distractors[0],
            distractors[1],
            distractors[2]
          ]..shuffle(random);
          final correctIdx = options.indexOf(target.meaning);

          loaded.add(_QuickQuestion(
            hanzi: target.targetText,
            pinyin: target.pinyin,
            meaning: target.meaning,
            options: options,
            correctIndex: correctIdx,
          ));
        }

        if (loaded.length >= 10) break;
      }
    } catch (_) {}

    if (loaded.length < 5) {
      final shuffled = List.of(_fallbackVocab)..shuffle(random);
      for (final item in shuffled) {
        final distractors = shuffled
            .where((d) => d['meaning'] != item['meaning'])
            .map((d) => d['meaning']!)
            .toList()
          ..shuffle(random);

        if (distractors.length >= 3) {
          final options = [
            item['meaning']!,
            distractors[0],
            distractors[1],
            distractors[2]
          ]..shuffle(random);
          final correctIdx = options.indexOf(item['meaning']!);

          loaded.add(_QuickQuestion(
            hanzi: item['hanzi']!,
            pinyin: item['pinyin']!,
            meaning: item['meaning']!,
            options: options,
            correctIndex: correctIdx,
          ));
        }

        if (loaded.length >= 10) break;
      }
    }

    if (mounted) {
      setState(() {
        _questions = loaded;
        _isLoading = false;
        _currentIndex = 0;
        _score = 0;
        _combo = 0;
        _correctCount = 0;
        _wrongCount = 0;
        _maxCombo = 0;
        _earnedXp = 0;
      });

      if (_questions.isNotEmpty) {
        _startQuestion();
      }
    }
  }

  void _startQuestion() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 15;
      _selectedAnswerIndex = null;
      _answered = false;
    });

    final curr = _questions[_currentIndex];
    _speak(curr.hanzi);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _combo = 0;
      _wrongCount++;
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _handleAnswer(int index) {
    if (_answered || _questions.isEmpty) return;
    _timer?.cancel();

    final curr = _questions[_currentIndex];
    final bool isRight = (index == curr.correctIndex);

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      if (isRight) {
        _combo++;
        _correctCount++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        _score += 100 + (_timeLeft * 10) + (_combo * 20);
      } else {
        _combo = 0;
        _wrongCount++;
      }
    });

    _speak(curr.hanzi);

    Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
      });
      _startQuestion();
    } else {
      _showVictoryDialog();
    }
  }

  Future<void> _showVictoryDialog() async {
    _timer?.cancel();

    final totalAnswers = _correctCount + _wrongCount;
    final accuracyPct = totalAnswers > 0
        ? ((_correctCount / totalAnswers) * 100).clamp(0.0, 100.0)
        : 0.0;
    final attemptId = 'qa_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await LearningRewardService().completeActivity(
        LearningActivitySubmission(
          activityType: 'quiz',
          sourceType: 'quick_answer',
          sourceId: 'quick_answer_practice',
          attemptId: attemptId,
          score: accuracyPct,
          correctCount: _correctCount,
          wrongCount: _wrongCount,
          bestCombo: _maxCombo,
          metadata: <String, dynamic>{'total_score': _score},
        ),
      );
      if (mounted) {
        setState(() => _earnedXp = result.xpEarned);
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameResultDialog(
        title: '⚡ Phản Xạ Thần Tốc!',
        message:
            'Bạn đã hoàn thành bài thi Trả Lời Nhanh với tốc độ tuyệt vời!',
        score: _score,
        xp: _earnedXp,
        isVictory: true,
        primaryLabel: 'Thử lại',
        onPrimary: () {
          Navigator.pop(ctx);
          _loadGameData();
        },
        secondaryLabel: 'Về Menu',
        onSecondary: () {
          Navigator.pop(ctx);
          widget.onBack();
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              'assets/images/backgrounds/quick_answer_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0B1B3D)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.38)),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
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

  Widget _buildScoreAndTimer() {
    final total = _questions.length;
    final current = (_currentIndex + 1).clamp(1, total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _timeLeft <= 5 ? Colors.redAccent : AppColors.primaryGold,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '${_timeLeft}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _timeLeft <= 5
                        ? Colors.redAccent
                        : AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$current / $total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white30, width: 1.2),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final curr = _questions[_currentIndex];

    return GestureDetector(
      onTap: () => _speak(curr.hanzi),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardCreamBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.volume_up_rounded,
                color: AppColors.primaryBlue, size: 36),
            const SizedBox(height: 8),
            Text(
              curr.hanzi,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              curr.pinyin,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerRows() {
    final curr = _questions[_currentIndex];

    AnswerButtonState getButtonState(int index) {
      if (!_answered) return AnswerButtonState.idle;
      if (index == curr.correctIndex) return AnswerButtonState.correct;
      if (index == _selectedAnswerIndex) return AnswerButtonState.wrong;
      return AnswerButtonState.idle;
    }

    return [
      Row(
        children: [
          AnswerButton(
            text: curr.options[0],
            state: getButtonState(0),
            onTap: () => _handleAnswer(0),
          ),
          const SizedBox(width: 12),
          AnswerButton(
            text: curr.options[1],
            state: getButtonState(1),
            onTap: () => _handleAnswer(1),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          AnswerButton(
            text: curr.options[2],
            state: getButtonState(2),
            onTap: () => _handleAnswer(2),
          ),
          const SizedBox(width: 12),
          AnswerButton(
            text: curr.options[3],
            state: getButtonState(3),
            onTap: () => _handleAnswer(3),
          ),
        ],
      ),
    ];
  }

  Widget _buildGameContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // App Bar
            GameScreenHeader(
              title: 'Trả lời nhanh',
              onBack: widget.onBack,
              onSettings: () {},
            ),

            // Timer & Score Pills
            _buildScoreAndTimer(),
            const Spacer(),

            // Question Card
            _buildQuestionCard(),
            const Spacer(),

            ..._buildAnswerRows(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
