import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../../dragon_panda/theme/app_colors.dart';
import '../../dragon_panda/widgets/answer_button.dart';
import '../../dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import '../../dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import 'model/boss_battle_stage.dart';

enum _ActorState { idle, attacking, hurt, victory, defeated }

class _FloatingDamage {
  final int id;
  final String text;
  final Color color;
  final bool isBoss;
  double y;
  double alpha;
  double scale;

  _FloatingDamage({
    required this.id,
    required this.text,
    required this.color,
    required this.isBoss,
    this.y = 0.0,
    this.alpha = 1.0,
    this.scale = 1.25,
  });
}

class BossBattleScreen extends StatefulWidget {
  final BossBattleStage? stage;

  const BossBattleScreen({
    Key? key,
    this.stage,
  }) : super(key: key);

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen>
    with SingleTickerProviderStateMixin {
  late int bossHp;
  late int maxBossHp;
  late int playerHp;
  final int maxPlayerHp = 200;
  int combo = 3;
  int maxCombo = 3;
  int score = 0;
  int correctCount = 0;
  int currentQuestionIndex = 0;

  bool isAnimating = false;
  String? feedbackText;
  int? selectedAnswerIndex;

  _ActorState pandaState = _ActorState.idle;
  _ActorState dragonState = _ActorState.idle;

  bool isArrowActive = false;
  double arrowProgress = 0.0;
  bool isFireActive = false;
  double fireProgress = 0.0;
  double dragonMouthGlow = 0.0;
  double screenFlashAlpha = 0.0;
  Offset cameraShakeOffset = Offset.zero;

  final List<_FloatingDamage> _floatingDamages = [];

  Timer? battleTimer;
  Timer? _damageTimer;
  late final AnimationController _ticker;
  double _gameTime = 0.0;

  ui.Image? _bgImage;
  ui.Image? _pandaImage;
  ui.Image? _dragonImage;
  bool _assetsLoaded = false;

  final FlutterTts _tts = FlutterTts();

  late List<_BattleQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _initQuestions();
    maxBossHp = widget.stage != null ? widget.stage!.bossHp : 500;
    bossHp = widget.stage != null ? (widget.stage!.bossHp * 0.64).toInt() : 320;
    playerHp = widget.stage != null ? widget.stage!.playerHp : 180;
    _initTts();
    _loadImages();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _gameTime += 0.035;
        });
      });
    _ticker.repeat();
  }

  Future<void> _loadImages() async {
    try {
      final results = await Future.wait([
        _loadUiImage('assets/images/backgrounds/boss_battle_bg.png'),
        _loadUiImage('assets/images/characters/panda_archer.png'),
        _loadUiImage('assets/images/characters/dragon_fire.png'),
      ]);
      if (mounted) {
        setState(() {
          _bgImage = results[0];
          _pandaImage = results[1];
          _dragonImage = results[2];
          _assetsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _assetsLoaded = true);
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _initQuestions() {
    _questions = [
      const _BattleQuestion(
        prompt: 'nước lọc',
        answers: [
          _BattleAnswer(hanzi: '果汁', pinyin: 'guǒzhī'),
          _BattleAnswer(hanzi: '水', pinyin: 'shuǐ'),
          _BattleAnswer(hanzi: '茶', pinyin: 'chá'),
          _BattleAnswer(hanzi: '可乐', pinyin: 'kělè'),
        ],
        correctIndex: 1,
      ),
      const _BattleQuestion(
        prompt: 'uống trà',
        answers: [
          _BattleAnswer(hanzi: '喝茶', pinyin: 'hē chá'),
          _BattleAnswer(hanzi: '吃饭', pinyin: 'chī fàn'),
          _BattleAnswer(hanzi: '看书', pinyin: 'kàn shū'),
          _BattleAnswer(hanzi: '睡觉', pinyin: 'shuì jiào'),
        ],
        correctIndex: 0,
      ),
      const _BattleQuestion(
        prompt: 'ăn cơm',
        answers: [
          _BattleAnswer(hanzi: '喝水', pinyin: 'hē shuǐ'),
          _BattleAnswer(hanzi: '跑步', pinyin: 'pǎo bù'),
          _BattleAnswer(hanzi: '吃饭', pinyin: 'chī fàn'),
          _BattleAnswer(hanzi: '说话', pinyin: 'shuō huà'),
        ],
        correctIndex: 2,
      ),
      const _BattleQuestion(
        prompt: 'đọc sách',
        answers: [
          _BattleAnswer(hanzi: '听音乐', pinyin: 'tīng yīnyuè'),
          _BattleAnswer(hanzi: '看书', pinyin: 'kàn shū'),
          _BattleAnswer(hanzi: '写字', pinyin: 'xiě zì'),
          _BattleAnswer(hanzi: '买东西', pinyin: 'mǎi dōngxi'),
        ],
        correctIndex: 1,
      ),
      const _BattleQuestion(
        prompt: 'cà phê',
        answers: [
          _BattleAnswer(hanzi: '咖啡', pinyin: 'kāfēi'),
          _BattleAnswer(hanzi: '牛奶', pinyin: 'niúnǎi'),
          _BattleAnswer(hanzi: '果汁', pinyin: 'guǒzhī'),
          _BattleAnswer(hanzi: '绿茶', pinyin: 'lǜchá'),
        ],
        correctIndex: 0,
      ),
    ];
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

  _BattleQuestion get _currentQuestion =>
      _questions[currentQuestionIndex % _questions.length];

  void _handleAnswer(int index) {
    if (isAnimating) return;

    final q = _currentQuestion;
    final bool isCorrect = (index == q.correctIndex);

    _speak(q.answers[index].hanzi);

    setState(() {
      isAnimating = true;
      selectedAnswerIndex = index;
    });

    if (isCorrect) {
      // PANDA SHOOTS ARROW TO DRAGON (-120)
      setState(() {
        combo += 1;
        if (combo > maxCombo) maxCombo = combo;
        correctCount += 1;
        score += 100 + (combo * 20);
        feedbackText = 'Chính xác!';
        pandaState = _ActorState.attacking;
      });

      Timer(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        setState(() {
          isArrowActive = true;
          arrowProgress = 0.0;
        });

        const int steps = 24;
        int currentStep = 0;
        battleTimer?.cancel();
        battleTimer =
            Timer.periodic(const Duration(milliseconds: 18), (timer) {
          currentStep++;
          if (currentStep >= steps) {
            timer.cancel();
            setState(() {
              arrowProgress = 1.0;
              isArrowActive = false;
              pandaState = _ActorState.idle;
              dragonState = _ActorState.hurt;
              bossHp = (bossHp - 120).clamp(0, maxBossHp);
              _addFloatingDamage('-120', const Color(0xFFFFD54F), true);
            });

            _runCameraShake(7.0, 200);

            // Reset Dragon Hurt after 380ms
            Timer(const Duration(milliseconds: 380), () {
              if (!mounted) return;
              setState(() {
                dragonState = _ActorState.idle;
              });
            });

            Timer(const Duration(milliseconds: 950), () {
              if (!mounted) return;
              if (bossHp <= 0) {
                _onVictory();
              } else {
                setState(() {
                  isAnimating = false;
                  feedbackText = null;
                  arrowProgress = 0.0;
                  selectedAnswerIndex = null;
                  currentQuestionIndex++;
                });
              }
            });
          } else {
            setState(() {
              arrowProgress = currentStep / steps;
            });
          }
        });
      });
    } else {
      // DRAGON BREATHES FIRE TO PANDA (-30)
      setState(() {
        combo = 0;
        feedbackText = 'Sai rồi!';
        dragonMouthGlow = 0.8;
      });

      // Dragon Charge -> Fire Stream
      Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          dragonMouthGlow = 0.0;
          dragonState = _ActorState.attacking;
          isFireActive = true;
          fireProgress = 0.0;
          screenFlashAlpha = 0.28;
        });

        const int steps = 25;
        int currentStep = 0;
        battleTimer?.cancel();
        battleTimer =
            Timer.periodic(const Duration(milliseconds: 18), (timer) {
          currentStep++;
          if (currentStep >= steps) {
            timer.cancel();
            setState(() {
              fireProgress = 1.0;
              isFireActive = false;
              dragonState = _ActorState.idle;
              pandaState = _ActorState.hurt;
              playerHp = (playerHp - 30).clamp(0, maxPlayerHp);
              _addFloatingDamage('-30', const Color(0xFFFF5252), false);
            });

            _runCameraShake(11.0, 220);
            _decayScreenFlash();

            // Reset Panda hurt
            Timer(const Duration(milliseconds: 380), () {
              if (!mounted) return;
              setState(() {
                pandaState = _ActorState.idle;
              });
            });

            Timer(const Duration(milliseconds: 950), () {
              if (!mounted) return;
              if (playerHp <= 0) {
                _onDefeat();
              } else {
                setState(() {
                  isAnimating = false;
                  feedbackText = null;
                  fireProgress = 0.0;
                  selectedAnswerIndex = null;
                  currentQuestionIndex++;
                });
              }
            });
          } else {
            setState(() {
              fireProgress = currentStep / steps;
            });
          }
        });
      });
    }
  }

  void _runCameraShake(double amplitude, int durationMs) {
    final int steps = (durationMs / 25).toInt();
    int current = 0;
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      current++;
      if (current >= steps || !mounted) {
        timer.cancel();
        if (mounted) setState(() => cameraShakeOffset = Offset.zero);
      } else {
        final decay = 1.0 - (current / steps);
        final rx = (math.Random().nextDouble() * 2.0 - 1.0) * amplitude * decay;
        final ry = (math.Random().nextDouble() * 2.0 - 1.0) * amplitude * decay;
        if (mounted) setState(() => cameraShakeOffset = Offset(rx, ry));
      }
    });
  }

  void _decayScreenFlash() {
    int step = 0;
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      step++;
      if (step >= 10 || !mounted) {
        timer.cancel();
        if (mounted) setState(() => screenFlashAlpha = 0.0);
      } else {
        if (mounted) {
          setState(() {
            screenFlashAlpha = (0.28 * (1.0 - (step / 10.0))).clamp(0.0, 0.28);
          });
        }
      }
    });
  }

  void _addFloatingDamage(String text, Color color, bool isBoss) {
    final dmg = _FloatingDamage(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      color: color,
      isBoss: isBoss,
      scale: 1.25,
      alpha: 1.0,
      y: 0.0,
    );
    _floatingDamages.add(dmg);

    int step = 0;
    _damageTimer?.cancel();
    _damageTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      step++;
      if (step >= 24 || !mounted) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _floatingDamages.removeWhere((d) => d.id == dmg.id);
          });
        }
      } else {
        final progress = step / 24.0;
        if (mounted) {
          setState(() {
            dmg.y = -45.0 * progress;
            dmg.alpha = (1.0 - progress).clamp(0.0, 1.0);
            dmg.scale = 1.25 - (progress * 0.25);
          });
        }
      }
    });
  }

  void _onVictory() {
    Get.off(
      () => BossBattleVictoryScreen(
        onContinue: () {
          Get.off(() => BossBattleScreen(stage: widget.stage));
        },
        onBackToHub: () {
          Get.back();
        },
      ),
    );
  }

  void _onDefeat() {
    Get.off(
      () => BossBattleDefeatScreen(
        onRetry: () {
          Get.off(() => BossBattleScreen(stage: widget.stage));
        },
        onBackToHub: () {
          Get.back();
        },
      ),
    );
  }

  @override
  void dispose() {
    battleTimer?.cancel();
    _damageTimer?.cancel();
    _ticker.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final int level = widget.stage?.stageOrder ?? 3;

    return Scaffold(
      backgroundColor: const Color(0xFF140B18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. COLUMN LAYOUT
          Column(
            children: [
              // 1. TOP BAR
              SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Pause Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.pause_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () => Get.back(),
                        ),
                      ),

                      // Boss Info & Animated Red/Orange HP Bar
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Lv. $level',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4A1000),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.stage?.bossName ?? 'Rồng Lửa',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black, blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$bossHp/$maxBossHp',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFCC80),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Boss Animated HP Bar
                              Container(
                                width: double.infinity,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0x66FF8A65),
                                    width: 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor:
                                      (bossHp / maxBossHp).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFF1744),
                                          Color(0xFFFF5252),
                                          Color(0xFFFF8A65),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Speaker Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.volume_up_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () {
                            final correctHanzi =
                                q.answers[q.correctIndex].hanzi;
                            _speak(correctHanzi);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. BATTLE ARENA CANVAS
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _BattleArenaCanvasPainter(
                        bgImage: _bgImage,
                        pandaImage: _pandaImage,
                        dragonImage: _dragonImage,
                        pandaState: pandaState,
                        dragonState: dragonState,
                        isArrowActive: isArrowActive,
                        arrowProgress: arrowProgress,
                        isFireActive: isFireActive,
                        fireProgress: fireProgress,
                        dragonMouthGlow: dragonMouthGlow,
                        cameraShakeOffset: cameraShakeOffset,
                        floatingDamages: _floatingDamages,
                        gameTime: _gameTime,
                      ),
                    ),

                    // Arena Bottom Overlay: Player HP Badge & Combo Badge
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Player Panda HP Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xB3181124),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.24),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGold,
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/images/characters/panda_avatar.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text('🐼',
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$playerHp / $maxPlayerHp',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 80,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: (playerHp / maxPlayerHp)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF00E676),
                                                Color(0xFF69F0AE),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),

                          // Combo Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF3D00).withOpacity(0.55),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  'Combo x$combo',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. QUIZ & ANSWER PANEL (BOTTOM HALF)
              Expanded(
                flex: 10,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F6F0),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Feedback Banner
                      if (feedbackText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: feedbackText == 'Chính xác!'
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            feedbackText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Question Prompt Row: Speaker Circle Icon + Vietnamese Word
                      InkWell(
                        onTap: () {
                          final correctHanzi =
                              q.answers[q.correctIndex].hanzi;
                          _speak(correctHanzi);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                q.prompt,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Text(
                        'Hãy chọn đáp án đúng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF757575),
                        ),
                      ),

                      // 2x2 Answer Grid with Hanzi + Pinyin
                      Row(
                        children: [
                          if (q.answers.isNotEmpty)
                            AnswerButton(
                              text: q.answers[0].hanzi,
                              subtitle: q.answers[0].pinyin,
                              state: selectedAnswerIndex == 0
                                  ? (0 == q.correctIndex
                                      ? AnswerButtonState.correct
                                      : AnswerButtonState.wrong)
                                  : AnswerButtonState.idle,
                              onTap: () => _handleAnswer(0),
                            ),
                          const SizedBox(width: 10),
                          if (q.answers.length > 1)
                            AnswerButton(
                              text: q.answers[1].hanzi,
                              subtitle: q.answers[1].pinyin,
                              state: selectedAnswerIndex == 1
                                  ? (1 == q.correctIndex
                                      ? AnswerButtonState.correct
                                      : AnswerButtonState.wrong)
                                  : AnswerButtonState.idle,
                              onTap: () => _handleAnswer(1),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          if (q.answers.length > 2)
                            AnswerButton(
                              text: q.answers[2].hanzi,
                              subtitle: q.answers[2].pinyin,
                              state: selectedAnswerIndex == 2
                                  ? (2 == q.correctIndex
                                      ? AnswerButtonState.correct
                                      : AnswerButtonState.wrong)
                                  : AnswerButtonState.idle,
                              onTap: () => _handleAnswer(2),
                            ),
                          const SizedBox(width: 10),
                          if (q.answers.length > 3)
                            AnswerButton(
                              text: q.answers[3].hanzi,
                              subtitle: q.answers[3].pinyin,
                              state: selectedAnswerIndex == 3
                                  ? (3 == q.correctIndex
                                      ? AnswerButtonState.correct
                                      : AnswerButtonState.wrong)
                                  : AnswerButtonState.idle,
                              onTap: () => _handleAnswer(3),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Red Screen Flash
          if (screenFlashAlpha > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.red.withOpacity(screenFlashAlpha.clamp(0.0, 0.4)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BattleArenaCanvasPainter extends CustomPainter {
  final ui.Image? bgImage;
  final ui.Image? pandaImage;
  final ui.Image? dragonImage;
  final _ActorState pandaState;
  final _ActorState dragonState;
  final bool isArrowActive;
  final double arrowProgress;
  final bool isFireActive;
  final double fireProgress;
  final double dragonMouthGlow;
  final Offset cameraShakeOffset;
  final List<_FloatingDamage> floatingDamages;
  final double gameTime;

  _BattleArenaCanvasPainter({
    required this.bgImage,
    required this.pandaImage,
    required this.dragonImage,
    required this.pandaState,
    required this.dragonState,
    required this.isArrowActive,
    required this.arrowProgress,
    required this.isFireActive,
    required this.fireProgress,
    required this.dragonMouthGlow,
    required this.cameraShakeOffset,
    required this.floatingDamages,
    required this.gameTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final canvasW = size.width;
    final canvasH = size.height;

    // 1. Draw Background
    if (bgImage != null) {
      _drawArt(canvas, bgImage!, Offset.zero, Size(canvasW, canvasH),
          cover: true);
    } else {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF140B18),
      );
    }

    // Apply Camera Shake
    canvas.save();
    canvas.translate(cameraShakeOffset.dx, cameraShakeOffset.dy);

    final groundY = canvasH * 0.82;

    // Actor Boxes scaling with arena
    final pandaBox = Size(canvasW * 0.38, canvasH * 0.53);
    final pandaOrigin = Offset(canvasW * 0.015, groundY - pandaBox.height);
    final pandaBob = pandaState == _ActorState.idle
        ? math.sin(gameTime * 3.2) * canvasH * 0.006
        : 0.0;
    final pandaKnock = pandaState == _ActorState.hurt
        ? math.sin(gameTime * 24.0) * canvasW * 0.018
        : 0.0;

    final dragonBox = Size(canvasW * 0.57, canvasH * 0.84);
    final dragonOrigin = Offset(canvasW * 0.43, groundY - dragonBox.height);
    final dragonBob = math.sin(gameTime * 2.2) * canvasH * 0.015;
    final dragonKnock = dragonState == _ActorState.hurt
        ? math.sin(gameTime * 25.0) * canvasW * 0.015
        : 0.0;

    final bowWorldPos = pandaOrigin +
        Offset(pandaBox.width * 0.91, pandaBox.height * 0.32);
    final pandaHitPos =
        pandaOrigin + Offset(pandaBox.width * 0.50, pandaBox.height * 0.50);
    final dragonMouthPos = dragonOrigin +
        Offset(dragonBox.width * 0.13, dragonBox.height * 0.37 + dragonBob);
    final dragonHitPos = dragonOrigin +
        Offset(dragonBox.width * 0.46, dragonBox.height * 0.54);

    // 2. Draw Dragon Actor
    if (dragonImage != null) {
      _drawArt(
        canvas,
        dragonImage!,
        dragonOrigin + Offset(dragonKnock, dragonBob),
        dragonBox,
        flash: dragonState == _ActorState.hurt,
      );
    }

    // 3. Draw Panda Actor
    if (pandaImage != null) {
      canvas.save();
      final tilt = pandaState == _ActorState.attacking ? -0.08 : 0.0;
      canvas.translate(pandaHitPos.dx, pandaHitPos.dy);
      canvas.rotate(tilt);
      canvas.translate(-pandaHitPos.dx, -pandaHitPos.dy);
      _drawArt(
        canvas,
        pandaImage!,
        pandaOrigin + Offset(pandaKnock, pandaBob),
        pandaBox,
        flash: pandaState == _ActorState.hurt,
      );
      canvas.restore();
    }

    // Dragon Mouth Glow
    if (dragonMouthGlow > 0) {
      final radius = canvasW * 0.08;
      canvas.drawCircle(
        dragonMouthPos,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(dragonMouthGlow),
              const Color(0xFFFF9800)
                  .withOpacity((dragonMouthGlow * 0.7).clamp(0.0, 1.0)),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: dragonMouthPos, radius: radius)),
      );
    }

    // 4. Draw Arrow Projectile (Exact Quadratic Bézier Curve)
    if (isArrowActive && arrowProgress > 0 && arrowProgress <= 1.0) {
      final p0 = bowWorldPos;
      final p2 = dragonHitPos;
      final p1 = Offset(
        (p0.dx + p2.dx) * 0.5,
        (p0.dy + p2.dy) * 0.5 - (canvasH * 0.28),
      );

      final t = arrowProgress;
      final arrowX =
          (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
      final arrowY =
          (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

      final dx = 2 * (1 - t) * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx);
      final dy = 2 * (1 - t) * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy);
      final angle = math.atan2(dy, dx);

      // Trailing Glowing Golden Particles (14 points)
      const trailPoints = 14;
      for (int i = 1; i <= trailPoints; i++) {
        final subT = (t - (i * 0.014)).clamp(0.0, 1.0);
        final tx = (1 - subT) * (1 - subT) * p0.dx +
            2 * (1 - subT) * subT * p1.dx +
            subT * subT * p2.dx;
        final ty = (1 - subT) * (1 - subT) * p0.dy +
            2 * (1 - subT) * subT * p1.dy +
            subT * subT * p2.dy;
        final trailAlpha =
            ((1.0 - (i / trailPoints)) * 0.75).clamp(0.0, 1.0);

        canvas.drawCircle(
          Offset(tx, ty),
          (4.5 * (1.0 - (i / trailPoints))).clamp(1.0, 4.5),
          Paint()
            ..color = const Color(0xFFFFD54F).withOpacity(trailAlpha),
        );
      }

      // Rotating Arrow Sprite
      canvas.save();
      canvas.translate(arrowX, arrowY);
      canvas.rotate(angle);

      // Golden Beam
      canvas.drawLine(
        const Offset(-22, 0),
        const Offset(22, 0),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFFE082), Colors.white],
          ).createShader(const Rect.fromLTWH(-25, -3, 50, 6))
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      // Wooden Shaft
      canvas.drawLine(
        const Offset(-20, 0),
        const Offset(16, 0),
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );

      // Arrowhead
      final headPath = Path()
        ..moveTo(26, 0)
        ..lineTo(14, -6)
        ..lineTo(16, 0)
        ..lineTo(14, 6)
        ..close();
      canvas.drawPath(
        headPath,
        Paint()..color = const Color(0xFFFFC107),
      );

      // Tip Glow
      canvas.drawCircle(
        const Offset(22, 0),
        6.5,
        Paint()..color = const Color(0xFFFFF176).withOpacity(0.85),
      );

      // Red Feathers
      canvas.drawLine(
        const Offset(-22, -5),
        const Offset(-16, 0),
        Paint()
          ..color = const Color(0xFFE53935)
          ..strokeWidth = 2.5,
      );
      canvas.drawLine(
        const Offset(-22, 5),
        const Offset(-16, 0),
        Paint()
          ..color = const Color(0xFFE53935)
          ..strokeWidth = 2.5,
      );

      canvas.restore();
    }

    // 5. Draw Torrential Fire Breath Stream (Exact Remix Multi-layered Gradients)
    if (isFireActive && fireProgress > 0 && fireProgress <= 1.0) {
      final p0 = dragonMouthPos;
      final p1 = pandaHitPos;
      final fireX = p0.dx + (p1.dx - p0.dx) * fireProgress;
      final fireY = p0.dy + (p1.dy - p0.dy) * fireProgress;

      final dx = fireX - p0.dx;
      final dy = fireY - p0.dy;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist >= 10) {
        final normalX = -dy / dist;
        final normalY = dx / dist;

        const flameLayers = 8;
        for (int i = 0; i <= flameLayers; i++) {
          final t = (i / flameLayers) * fireProgress;
          final cx = p0.dx + dx * t;
          final cy = p0.dy + dy * t;

          final wave =
              math.sin(gameTime * 20.0 + i * 1.5) * (8.0 + 25.0 * t);
          final flameRadius = 14.0 + (55.0 * t);
          final posX = cx + normalX * wave;
          final posY = cy + normalY * wave;

          // Outer smoke/red heat
          canvas.drawCircle(
            Offset(posX, posY),
            flameRadius * 1.35,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  const Color(0xFFE53935).withOpacity(0.55),
                  const Color(0xFFFF5722).withOpacity(0.35),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(posX, posY),
                  radius: flameRadius * 1.35,
                ),
              ),
          );

          // Middle flame orange
          canvas.drawCircle(
            Offset(posX, posY),
            flameRadius,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  const Color(0xFFFF9800).withOpacity(0.85),
                  const Color(0xFFFF3D00).withOpacity(0.65),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(posX, posY),
                  radius: flameRadius,
                ),
              ),
          );

          // Inner white-hot plasma
          canvas.drawCircle(
            Offset(posX, posY),
            flameRadius * 0.52,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFFFEB3B).withOpacity(0.85),
                  const Color(0xFFFF9100).withOpacity(0.5),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(posX, posY),
                  radius: flameRadius * 0.52,
                ),
              ),
          );
        }

        // 16 Flying Embers
        final emberCount = (16 * fireProgress).toInt().clamp(4, 16);
        for (int e = 0; e < emberCount; e++) {
          final eT = (e / emberCount) * fireProgress;
          final spread =
              (math.sin(e * 37.0 + gameTime * 5.0)) * 32.0 * eT;
          final ex = p0.dx + dx * eT + normalX * spread;
          final ey = p0.dy +
              dy * eT +
              normalY * spread +
              math.sin(gameTime * 25.0 + e) * 8.0;
          final emberColor =
              e % 2 == 0 ? const Color(0xFFFFD54F) : const Color(0xFFFF5722);
          final emberRadius = 3.0 + (math.sin(e * 13.0).abs() * 3.5);

          canvas.drawCircle(
            Offset(ex, ey),
            emberRadius,
            Paint()..color = emberColor.withOpacity(0.85),
          );
        }
      }
    }

    // 6. Draw Floating Damage Text
    for (final dmg in floatingDamages) {
      final hitPos = dmg.isBoss ? dragonHitPos : pandaHitPos;
      final textPainter = TextPainter(
        text: TextSpan(
          text: dmg.text,
          style: TextStyle(
            color: dmg.color.withOpacity(dmg.alpha),
            fontSize: 42 * dmg.scale,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(dmg.alpha),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          hitPos.dx - textPainter.width / 2,
          hitPos.dy - 50 + dmg.y,
        ),
      );
    }

    canvas.restore();
  }

  void _drawArt(
    Canvas canvas,
    ui.Image image,
    Offset origin,
    Size box, {
    bool cover = false,
    bool flash = false,
  }) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    if (imgW == 0 || imgH == 0) return;

    final sx = box.width / imgW;
    final sy = box.height / imgH;
    final factor = cover ? math.max(sx, sy) : math.min(sx, sy);
    final width = imgW * factor;
    final height = imgH * factor;

    final dstRect = Rect.fromLTWH(
      origin.dx + (box.width - width) / 2,
      origin.dy + (box.height - height) / 2,
      width,
      height,
    );

    final paint = Paint();
    if (flash) {
      paint.colorFilter = const ColorFilter.mode(
        Color(0xFFFFEEEE),
        BlendMode.modulate,
      );
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgW, imgH),
      dstRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BattleArenaCanvasPainter oldDelegate) {
    return true;
  }
}

class _BattleQuestion {
  final String prompt;
  final List<_BattleAnswer> answers;
  final int correctIndex;

  const _BattleQuestion({
    required this.prompt,
    required this.answers,
    required this.correctIndex,
  });
}

class _BattleAnswer {
  final String hanzi;
  final String pinyin;

  const _BattleAnswer({
    required this.hanzi,
    required this.pinyin,
  });
}
