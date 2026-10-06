import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import 'package:flash_learn_chinese/screen/dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/services/tts_service.dart';
import '../home/controller/home_controller.dart';
import '../dragon_panda/screens/boss_battle/widgets/boss_battle_gameplay_widgets.dart';
import 'controller/boss_battle_controller.dart';
import 'data/boss_battle_repository.dart';
import 'model/boss_battle_question.dart';
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
  const BossBattleScreen({
    super.key,
    this.stage,
  });

  final BossBattleStage? stage;

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen>
    with SingleTickerProviderStateMixin {
  static int _nextControllerId = 0;

  late final String _controllerTag;
  late final BossBattleController controller;
  late final Worker _phaseWorker;
  late final TtsService _tts;
  late final AnimationController _ticker;

  _ActorState pandaState = _ActorState.idle;
  _ActorState dragonState = _ActorState.idle;

  bool isArrowActive = false;
  double arrowProgress = 0.0;
  bool isFireActive = false;
  double fireProgress = 0.0;
  double dragonMouthGlow = 0.0;
  double screenFlashAlpha = 0.0;
  Offset cameraShakeOffset = Offset.zero;

  final List<_FloatingDamage> _floatingDamages = <_FloatingDamage>[];
  Timer? battleTimer;
  Timer? _damageTimer;
  double _gameTime = 0.0;

  ui.Image? _bgImage;
  ui.Image? _pandaImage;
  ui.Image? _dragonImage;

  bool? _wonResult;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();

    _tts = Get.find<TtsService>();
    _controllerTag =
        'boss-battle-${widget.stage?.id ?? 'free'}-${_nextControllerId++}';

    final repository = BossBattleRepository();
    controller = Get.put(
      BossBattleController(
        source: repository,
        progressSink: repository,
        stage: widget.stage,
      ),
      tag: _controllerTag,
    );

    _phaseWorker = ever<BossBattlePhase>(
      controller.phase,
      _handlePhase,
    );

    _loadImages();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (!mounted) return;
        setState(() => _gameTime += .035);
      });
    _ticker.repeat();
  }

  Future<void> _loadImages() async {
    try {
      final results = await Future.wait<ui.Image>([
        _loadUiImage('assets/images/backgrounds/boss_battle_bg.png'),
        _loadUiImage('assets/images/characters/panda_archer.png'),
        _loadUiImage('assets/images/characters/dragon_fire.png'),
      ], cleanUp: (image) => image.dispose());

      if (!mounted) {
        for (final image in results) {
          image.dispose();
        }
        return;
      }

      setState(() {
        _bgImage = results[0];
        _pandaImage = results[1];
        _dragonImage = results[2];
      });
    } catch (_) {
      // Canvas has a dark fallback while assets are unavailable.
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  void _handlePhase(BossBattlePhase phase) {
    if (!mounted) return;

    switch (phase) {
      case BossBattlePhase.question:
        battleTimer?.cancel();
        setState(() {
          pandaState = _ActorState.idle;
          dragonState = _ActorState.idle;
          isArrowActive = false;
          isFireActive = false;
          arrowProgress = 0;
          fireProgress = 0;
        });
        break;
      case BossBattlePhase.playerAttack:
        _animatePlayerAttack(controller.lastBossDamage.value);
        break;
      case BossBattlePhase.bossAttack:
        _animateBossAttack(controller.lastPlayerDamage.value);
        break;
      case BossBattlePhase.won:
      case BossBattlePhase.reward:
        _wonResult = true;
        setState(() {
          pandaState = _ActorState.victory;
          dragonState = _ActorState.defeated;
        });
        break;
      case BossBattlePhase.lost:
        _wonResult = false;
        setState(() {
          pandaState = _ActorState.defeated;
          dragonState = _ActorState.victory;
        });
        break;
      case BossBattlePhase.result:
        if (!_resultShown) {
          _resultShown = true;
          unawaited(_openResult());
        }
        break;
      default:
        break;
    }
  }

  void _animatePlayerAttack(int damage) {
    battleTimer?.cancel();
    setState(() {
      pandaState = _ActorState.attacking;
      dragonState = _ActorState.idle;
      isArrowActive = false;
      arrowProgress = 0;
    });

    // Bow-draw/readiness beat before projectile release.
    battleTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted ||
          controller.phase.value != BossBattlePhase.playerAttack) {
        return;
      }

      setState(() => isArrowActive = true);

      const steps = 20;
      var step = 0;
      battleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted ||
            controller.phase.value != BossBattlePhase.playerAttack) {
          timer.cancel();
          return;
        }

        step += 1;
        if (step >= steps) {
          timer.cancel();
          setState(() {
            isArrowActive = false;
            arrowProgress = 1;
            pandaState = _ActorState.idle;
            dragonState = _ActorState.hurt;
          });
          _addFloatingDamage(
            '-$damage',
            const Color(0xFFFFD54F),
            true,
          );
          _runCameraShake(7, 180);

          Timer(const Duration(milliseconds: 170), () {
            if (!mounted) return;
            setState(() => dragonState = _ActorState.idle);
          });
        } else {
          setState(() => arrowProgress = step / steps);
        }
      });
    });
  }

  void _animateBossAttack(int damage) {
    battleTimer?.cancel();
    setState(() {
      dragonMouthGlow = .82;
      dragonState = _ActorState.attacking;
      pandaState = _ActorState.idle;
      isFireActive = false;
      fireProgress = 0;
    });

    battleTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted ||
          controller.phase.value != BossBattlePhase.bossAttack) {
        return;
      }

      setState(() {
        dragonMouthGlow = 0;
        isFireActive = true;
        screenFlashAlpha = .25;
      });

      const steps = 20;
      var step = 0;
      battleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted ||
            controller.phase.value != BossBattlePhase.bossAttack) {
          timer.cancel();
          return;
        }

        step += 1;
        if (step >= steps) {
          timer.cancel();
          setState(() {
            isFireActive = false;
            fireProgress = 1;
            dragonState = _ActorState.idle;
            pandaState = _ActorState.hurt;
          });
          _addFloatingDamage(
            '-$damage',
            const Color(0xFFFF5252),
            false,
          );
          _runCameraShake(10, 190);
          _decayScreenFlash();

          Timer(const Duration(milliseconds: 170), () {
            if (!mounted) return;
            setState(() => pandaState = _ActorState.idle);
          });
        } else {
          setState(() => fireProgress = step / steps);
        }
      });
    });
  }

  void _runCameraShake(double amplitude, int durationMs) {
    final steps = math.max(1, (durationMs / 25).round());
    var current = 0;

    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      current += 1;
      if (current >= steps || !mounted) {
        timer.cancel();
        if (mounted) {
          setState(() => cameraShakeOffset = Offset.zero);
        }
        return;
      }

      final decay = 1 - (current / steps);
      final random = math.Random();
      final x = (random.nextDouble() * 2 - 1) * amplitude * decay;
      final y = (random.nextDouble() * 2 - 1) * amplitude * decay;
      setState(() => cameraShakeOffset = Offset(x, y));
    });
  }

  void _decayScreenFlash() {
    var step = 0;
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      step += 1;
      if (step >= 10 || !mounted) {
        timer.cancel();
        if (mounted) setState(() => screenFlashAlpha = 0);
        return;
      }
      setState(() {
        screenFlashAlpha =
            (.25 * (1 - step / 10)).clamp(0.0, .25).toDouble();
      });
    });
  }

  void _addFloatingDamage(String text, Color color, bool isBoss) {
    final damage = _FloatingDamage(
      id: DateTime.now().microsecondsSinceEpoch,
      text: text,
      color: color,
      isBoss: isBoss,
    );
    _floatingDamages.add(damage);

    var step = 0;
    _damageTimer?.cancel();
    _damageTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      step += 1;
      if (step >= 24 || !mounted) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _floatingDamages.removeWhere((item) => item.id == damage.id);
          });
        }
        return;
      }

      final progress = step / 24;
      setState(() {
        damage.y = -45 * progress;
        damage.alpha = (1 - progress).clamp(0.0, 1.0);
        damage.scale = 1.25 - progress * .25;
      });
    });
  }

  Future<void> _speakQuestion(BossBattleQuestion question) {
    return _tts.playUrlOrSpeak(
      url: question.audioUrl,
      text: question.correctAnswer,
    );
  }

  Future<void> _handleAnswer(int index) async {
    final question = controller.currentQuestion;
    if (!controller.canAnswer ||
        question == null ||
        index < 0 ||
        index >= question.answers.length) {
      return;
    }

    final answer = question.answers[index];
    unawaited(_tts.speakChinese(answer));
    await controller.answer(answer);
  }

  Future<void> _openResult() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().refreshStats();
    }
    if (!mounted) return;

    final won = _wonResult ?? controller.bossHp.value <= 0;
    if (won) {
      Get.off(
        () => BossBattleVictoryScreen(
          onContinue: () => Get.back<void>(),
          onBackToHub: () => Get.back<void>(),
        ),
      );
    } else {
      Get.off(
        () => BossBattleDefeatScreen(
          onRetry: () {
            Get.off(() => BossBattleScreen(stage: widget.stage));
          },
          onBackToHub: () => Get.back<void>(),
        ),
      );
    }
  }

  @override
  void dispose() {
    battleTimer?.cancel();
    _damageTimer?.cancel();
    _phaseWorker.dispose();
    _ticker.dispose();
    _bgImage?.dispose();
    _pandaImage?.dispose();
    _dragonImage?.dispose();
    unawaited(_tts.stop());

    if (Get.isRegistered<BossBattleController>(tag: _controllerTag)) {
      Get.delete<BossBattleController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140B18),
      body: Obx(() {
        final phase = controller.phase.value;

        if (phase == BossBattlePhase.loading) {
          return _buildLoading();
        }
        if (phase == BossBattlePhase.error) {
          return _buildError();
        }
        if (phase == BossBattlePhase.intro) {
          return _buildIntro();
        }

        final question = controller.currentQuestion;
        if (question == null) return _buildLoading();

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBattleLayout(question),
            if (screenFlashAlpha > .01)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.red.withValues(
                      alpha: screenFlashAlpha.clamp(0.0, .4),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildLoading() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/backgrounds/boss_battle_bg.png',
          fit: BoxFit.cover,
        ),
        const ColoredBox(color: Color(0x66000000)),
        const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFC653),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/backgrounds/boss_battle_bg.png',
          fit: BoxFit.cover,
        ),
        const ColoredBox(color: Color(0x99000000)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/characters/panda_dizzy.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 14),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.startBattle,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tải lại trận đấu'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/backgrounds/boss_intro_bg.png',
          fit: BoxFit.cover,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Color(0xB3120811),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Spacer(),
                Text(
                  controller.stageLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD36C),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.bossName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${controller.questions.length} câu hỏi lấy trực tiếp từ Unit này',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: controller.beginBattle,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD73627),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(220, 56),
                  ),
                  icon: const Icon(Icons.local_fire_department_rounded),
                  label: const Text(
                    'BẮT ĐẦU CHIẾN',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattleLayout(BossBattleQuestion question) {
    return Column(
      children: [
        BossBattleTopBar(
          bossHp: controller.bossHp.value,
          maxBossHp: controller.bossHpMax,
          level: controller.bossLevel,
          bossName: controller.bossName,
          onExit: () => Get.back<void>(),
          onSpeak: () => _speakQuestion(question),
        ),
        _buildArena(),
        _buildQuestionPanel(question),
      ],
    );
  }

  Widget _buildArena() {
    return Expanded(
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
          BossBattleArenaHud(
            playerHp: controller.playerHp.value,
            maxPlayerHp: controller.playerHpMax,
            combo: controller.combo.value,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPanel(BossBattleQuestion question) {
    final correctIndex = question.answers.indexOf(question.correctAnswer);
    final selected = controller.selectedAnswer.value;
    final selectedIndex =
        selected == null ? null : question.answers.indexOf(selected);

    return Expanded(
      flex: 10,
      child: BossBattleQuestionPanel(
        prompt: question.prompt,
        hanziPrompt: question.correctAnswer,
        options: question.answers
            .map(
              (answer) => <String, dynamic>{
                'hanzi': answer,
                'pinyin': '',
              },
            )
            .toList(growable: false),
        correctIndex: correctIndex < 0 ? 0 : correctIndex,
        selectedAnswerIndex:
            selectedIndex == null || selectedIndex < 0 ? null : selectedIndex,
        feedbackText: controller.lastAnswerCorrect.value == null
            ? null
            : controller.lastAnswerCorrect.value == true
                ? 'Chính xác!'
                : controller.feedbackText,
        onSpeak: (_) => _speakQuestion(question),
        onAnswer: _handleAnswer,
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

    final bowWorldPos =
        pandaOrigin + Offset(pandaBox.width * 0.91, pandaBox.height * 0.32);
    final pandaHitPos =
        pandaOrigin + Offset(pandaBox.width * 0.50, pandaBox.height * 0.50);
    final dragonMouthPos = dragonOrigin +
        Offset(dragonBox.width * 0.13, dragonBox.height * 0.37 + dragonBob);
    final dragonHitPos =
        dragonOrigin + Offset(dragonBox.width * 0.46, dragonBox.height * 0.54);

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
          ).createShader(
              Rect.fromCircle(center: dragonMouthPos, radius: radius)),
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
        final trailAlpha = ((1.0 - (i / trailPoints)) * 0.75).clamp(0.0, 1.0);

        canvas.drawCircle(
          Offset(tx, ty),
          (4.5 * (1.0 - (i / trailPoints))).clamp(1.0, 4.5),
          Paint()..color = const Color(0xFFFFD54F).withOpacity(trailAlpha),
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

          final wave = math.sin(gameTime * 20.0 + i * 1.5) * (8.0 + 25.0 * t);
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
          final spread = (math.sin(e * 37.0 + gameTime * 5.0)) * 32.0 * eT;
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
