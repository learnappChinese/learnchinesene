import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/game/game_art.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/theme/game_visual_tokens.dart';
import 'boss_battle_screen.dart';
import 'data/boss_battle_repository.dart';
import 'controller/boss_stage_map_controller.dart';
import 'model/boss_battle_stage.dart';
import 'widget/boss_battle_character_art.dart';

class BossBattleStageMapScreen extends StatefulWidget {
  const BossBattleStageMapScreen({super.key});

  @override
  State<BossBattleStageMapScreen> createState() =>
      _BossBattleStageMapScreenState();
}

class _BossBattleStageMapScreenState extends State<BossBattleStageMapScreen> {
  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final BossStageMapController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'boss-stage-map-${_nextControllerId++}';
    controller = Get.put(
      BossStageMapController(loadStages: BossBattleRepository().loadStages),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<BossStageMapController>(tag: _controllerTag);
    super.dispose();
  }

  void _retry() {
    setState(controller.reload);
  }

  bool _startsChapter(List<BossBattleStage> stages, int index) {
    final section = stages[index].sectionNumber;
    if (section <= 0) return false;
    return index == 0 || stages[index - 1].sectionNumber != section;
  }

  Future<void> _openStage(BossBattleStage stage) async {
    final start = await _StageDetailSheet.show(context, stage);
    if (start && mounted) {
      Get.to(() => BossBattleScreen(stage: stage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameVisualTokens.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _StageWorldPainter()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x55150D15),
                  Color(0xE6150D15),
                ],
                stops: [0, .42, 1],
              ),
            ),
          ),
          SafeArea(
            child: _buildStageCatalog(),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCatalog() {
    return FutureBuilder<List<BossBattleStage>>(
      future: controller.stages,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StageLoading();
        }
        if (snapshot.hasError) {
          return _StageError(onRetry: _retry);
        }

        final stages = snapshot.data ?? const <BossBattleStage>[];
        if (stages.isEmpty) {
          return _StageError(
            onRetry: _retry,
            message: 'Supabase chưa có cửa ải Boss Battle.',
          );
        }

        return Column(
          children: [
            _StageHeader(stageCount: stages.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 40),
                itemCount: stages.length,
                itemBuilder: (context, index) => _MapStageRow(
                  stage: stages[index],
                  index: index,
                  showChapter: _startsChapter(stages, index),
                  nextShowsChapter: index + 1 < stages.length &&
                      _startsChapter(stages, index + 1),
                  isFirst: index == 0,
                  isLast: index == stages.length - 1,
                  onTap: () => _openStage(stages[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.stageCount});

  final int stageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xE62C1A2A), Color(0xE6170D19)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x88FFD271), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          AppBackButton(onPressed: () => Get.back<void>()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hành trình Rồng Lửa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFFFD273),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xAA000000), blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$stageCount cửa ải • Chạm vào cửa để khiêu chiến',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const BossBattleCharacterArt(
            kind: BossBattleCharacterKind.panda,
            size: 56,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bản đồ: mỗi cửa ải là một hàng có chiều cao cố định, con đường được vẽ
// nối tâm các nút liên tiếp nên trông như một đường mòn liền mạch.
// ---------------------------------------------------------------------------

const double _kMapRowHeight = 156;
const double _kMapNodeOffset = 62;
const double _kChapterBannerHeight = 64;

double _nodeXFraction(int index) => .5 + .27 * math.sin(index * .85);

bool _isBossGate(BossBattleStage stage) => stage.stageOrder % 7 == 0;

Color _stageAccent(String theme) {
  switch (theme) {
    case 'spring':
      return const Color(0xFFD95473);
    case 'night':
      return const Color(0xFF5C63C7);
    case 'inferno':
      return const Color(0xFFE24A32);
    default:
      return const Color(0xFFE68A2E);
  }
}

const _mapDecorations = ['🏯', '🌸', '🏮', '🎋', '⛩️', '🌲', '🪷', '🗻'];

class _MapStageRow extends StatelessWidget {
  const _MapStageRow({
    required this.stage,
    required this.index,
    required this.showChapter,
    required this.nextShowsChapter,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final BossBattleStage stage;
  final int index;
  final bool showChapter;
  final bool nextShowsChapter;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bannerHeight = showChapter ? _kChapterBannerHeight : 0.0;
    final rowHeight = bannerHeight + _kMapRowHeight;
    final centerY = bannerHeight + _kMapNodeOffset;
    final xFraction = _nodeXFraction(index);
    final nodeX = width * xFraction;
    final boss = _isBossGate(stage);
    final accent = _stageAccent(stage.themeCode);
    final nodeSize = boss ? 92.0 : 72.0;
    const labelWidth = 160.0;

    return SizedBox(
      height: rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapRoadPainter(
                xFraction: xFraction,
                centerY: centerY,
                prevXFraction: isFirst ? null : _nodeXFraction(index - 1),
                prevCenterY: _kMapNodeOffset - _kMapRowHeight,
                nextXFraction: isLast ? null : _nodeXFraction(index + 1),
                nextCenterY: rowHeight +
                    (nextShowsChapter ? _kChapterBannerHeight : 0) +
                    _kMapNodeOffset,
              ),
            ),
          ),
          if (showChapter)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: bannerHeight,
              child: Center(
                child: _ChapterBanner(section: stage.sectionNumber),
              ),
            ),
          if (index.isEven)
            Positioned(
              left: (xFraction > .5 ? width * .13 : width * .87) - 22,
              top: centerY - 22,
              child: _MapDecoration(
                emoji: _mapDecorations[(index ~/ 2) % _mapDecorations.length],
              ),
            ),
          Positioned(
            left: nodeX - nodeSize / 2,
            top: centerY - nodeSize / 2,
            child: _StageNode(
              stage: stage,
              accent: accent,
              size: nodeSize,
              boss: boss,
              onTap: onTap,
            ),
          ),
          Positioned(
            left: (nodeX - labelWidth / 2).clamp(8.0, width - labelWidth - 8),
            width: labelWidth,
            top: centerY + nodeSize / 2 + 10,
            child: _StageLabel(title: stage.title, accent: accent),
          ),
        ],
      ),
    );
  }
}

class _MapRoadPainter extends CustomPainter {
  const _MapRoadPainter({
    required this.xFraction,
    required this.centerY,
    required this.prevXFraction,
    required this.prevCenterY,
    required this.nextXFraction,
    required this.nextCenterY,
  });

  final double xFraction;
  final double centerY;
  final double? prevXFraction;
  final double prevCenterY;
  final double? nextXFraction;
  final double nextCenterY;

  Path _segment(Offset from, Offset to) {
    final dy = to.dy - from.dy;
    return Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx,
        from.dy + dy * .5,
        to.dx,
        to.dy - dy * .5,
        to.dx,
        to.dy,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final current = Offset(size.width * xFraction, centerY);
    final road = Path();
    if (prevXFraction case final prev?) {
      road.addPath(
        _segment(Offset(size.width * prev, prevCenterY), current),
        Offset.zero,
      );
    }
    if (nextXFraction case final next?) {
      road.addPath(
        _segment(current, Offset(size.width * next, nextCenterY)),
        Offset.zero,
      );
    }

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
        road.shift(const Offset(0, 5)), stroke(const Color(0x55000000), 30));
    canvas.drawPath(road, stroke(const Color(0xFF6B4423), 30));
    canvas.drawPath(road, stroke(const Color(0xFFE2BC7E), 22));
    canvas.drawPath(road, stroke(const Color(0xFFF1D7A4), 10));

    final dash = stroke(const Color(0xFFB58349), 3.5);
    for (final metric in road.computeMetrics()) {
      for (var d = 14.0; d < metric.length; d += 20) {
        canvas.drawPath(metric.extractPath(d, d + 8), dash);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapRoadPainter oldDelegate) =>
      oldDelegate.xFraction != xFraction ||
      oldDelegate.centerY != centerY ||
      oldDelegate.prevXFraction != prevXFraction ||
      oldDelegate.prevCenterY != prevCenterY ||
      oldDelegate.nextXFraction != nextXFraction ||
      oldDelegate.nextCenterY != nextCenterY;
}

class _StageNode extends StatefulWidget {
  const _StageNode({
    required this.stage,
    required this.accent,
    required this.size,
    required this.boss,
    required this.onTap,
  });

  final BossBattleStage stage;
  final Color accent;
  final double size;
  final bool boss;
  final VoidCallback onTap;

  @override
  State<_StageNode> createState() => _StageNodeState();
}

class _StageNodeState extends State<_StageNode> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final face = widget.boss ? const Color(0xFFD9342B) : widget.accent;
    final base = Color.lerp(face, const Color(0xFF1A0D12), .5)!;
    const depth = 6.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: SizedBox(
        width: size,
        height: size + depth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Đế 3D
            Positioned(
              top: depth,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: base,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.boss
                          ? const Color(0xAAFF3D00)
                          : Colors.black.withValues(alpha: .45),
                      blurRadius: widget.boss ? 26 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            // Mặt nút
            AnimatedPositioned(
              duration: const Duration(milliseconds: 90),
              top: _pressed ? depth - 1 : 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(face, Colors.white, .22)!,
                      face,
                      Color.lerp(face, const Color(0xFF2A1720), .35)!,
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD985),
                    width: widget.boss ? 4 : 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.boss ? _buildBossFace(size) : _buildNumber(),
              ),
            ),
            if (widget.boss)
              Positioned(
                left: 0,
                right: 0,
                bottom: -8,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC533), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFF7D1D24)),
                    ),
                    child: Text(
                      'BOSS ${widget.stage.stageOrder}',
                      style: const TextStyle(
                        color: Color(0xFF4A1000),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumber() {
    return Stack(
      children: [
        Positioned(
          left: widget.size * .18,
          top: widget.size * .1,
          child: Container(
            width: widget.size * .34,
            height: widget.size * .16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${widget.stage.stageOrder}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBossFace(double size) {
    return Padding(
      padding: EdgeInsets.all(size * .06),
      child: Image.asset(
        GameArt.dragonFire,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Text('🐉', style: TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xE0201420),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: .6)),
        ),
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MapDecoration extends StatelessWidget {
  const _MapDecoration({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 44,
        height: 48,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 34,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Positioned(
              bottom: 2,
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterBanner extends StatelessWidget {
  const _ChapterBanner({required this.section});

  final int section;

  @override
  Widget build(BuildContext context) {
    Widget line(Alignment begin, Alignment end) => Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: const [Color(0x00FFD273), Color(0xCCFFD273)],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          line(Alignment.centerLeft, Alignment.centerRight),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB4232C), Color(0xFF7F1520)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD273), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'CHƯƠNG $section',
              style: const TextStyle(
                color: Color(0xFFFFD273),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          line(Alignment.centerRight, Alignment.centerLeft),
        ],
      ),
    );
  }
}

class _StageDetailSheet extends StatelessWidget {
  const _StageDetailSheet({required this.stage});

  final BossBattleStage stage;

  static Future<bool> show(BuildContext context, BossBattleStage stage) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .55),
      builder: (_) => _StageDetailSheet(stage: stage),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final chapter =
        stage.sectionNumber > 0 ? ' · CHƯƠNG ${stage.sectionNumber}' : '';

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1A2A), Color(0xFF170D19)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFC533).withValues(alpha: .55),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const BossBattleCharacterArt(
                  kind: BossBattleCharacterKind.dragon,
                  size: 84,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stage.label.toUpperCase()}$chapter',
                        style: const TextStyle(
                          color: Color(0xFFFFD273),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stage.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đối thủ: ${stage.bossName}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StageStat(
                  icon: Icons.local_fire_department_rounded,
                  color: _stageAccent(stage.themeCode),
                  value: stage.difficultyLabel,
                  caption: 'Độ khó',
                ),
                const SizedBox(width: 8),
                _StageStat(
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF38BDF8),
                  value: '${stage.questionCount}',
                  caption: 'Câu hỏi',
                ),
                const SizedBox(width: 8),
                _StageStat(
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFFF5252),
                  value: '${stage.bossHp}',
                  caption: 'HP Boss',
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9F1C), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: .4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 22),
                  label: const Text(
                    'Khiêu chiến',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageStat extends StatelessWidget {
  const _StageStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageWorldPainter extends CustomPainter {
  const _StageWorldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF263D75),
            Color(0xFF70436E),
            Color(0xFFCE684D),
            Color(0xFF1A1018),
          ],
        ).createShader(rect),
    );

    final moonCenter = Offset(size.width * .72, size.height * .15);
    canvas.drawCircle(
      moonCenter,
      size.width * .17,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFFFEDB3),
            Color(0x55FFD25E),
            Color(0x00FFD25E),
          ],
        ).createShader(
          Rect.fromCircle(
            center: moonCenter,
            radius: size.width * .2,
          ),
        ),
    );

    final mountain = Paint()..color = const Color(0xBB25313D);
    final path = Path()
      ..moveTo(0, size.height * .42)
      ..lineTo(size.width * .18, size.height * .2)
      ..lineTo(size.width * .34, size.height * .4)
      ..lineTo(size.width * .54, size.height * .17)
      ..lineTo(size.width * .7, size.height * .39)
      ..lineTo(size.width * .88, size.height * .22)
      ..lineTo(size.width, size.height * .4)
      ..lineTo(size.width, size.height * .58)
      ..lineTo(0, size.height * .58)
      ..close();
    canvas.drawPath(path, mountain);

    final sparkle = Paint()..color = const Color(0x88FFD680);
    for (var i = 0; i < 18; i++) {
      final x = ((i * 71) % 100) / 100 * size.width;
      final y = size.height * (.08 + ((i * 37) % 38) / 100);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 2), sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _StageWorldPainter oldDelegate) => false;
}

class _StageLoading extends StatelessWidget {
  const _StageLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFFFB52D),
      ),
    );
  }
}

class _StageError extends StatelessWidget {
  const _StageError({
    required this.onRetry,
    this.message = 'Không tải được danh sách cửa ải.',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFFFB52D),
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
