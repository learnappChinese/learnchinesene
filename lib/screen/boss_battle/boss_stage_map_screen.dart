import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/game_visual_tokens.dart';
import 'data/boss_battle_repository.dart';
import 'controller/boss_stage_map_controller.dart';
import 'model/boss_battle_stage.dart';
import 'widget/boss_battle_character_art.dart';
import '../unit_path/binding/unit_path_binding.dart';
import '../unit_path/page/unit_path_screen.dart';

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
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final next =
                      index < stages.length - 1 ? stages[index + 1] : null;
                  return _StagePathItem(
                    stage: stage,
                    next: next,
                    index: index,
                    onTap: () => Get.to(
                      () => UnitPathScreen(stage: stage),
                      binding: UnitPathBinding(unitId: stage.unitId),
                    ),
                  );
                },
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
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xB5261925),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x44FFD271)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xAA241822),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Get.back<void>(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hành trình Rồng Lửa',
                  style: TextStyle(
                    color: Color(0xFFFFD273),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xAA000000), blurRadius: 8),
                    ],
                  ),
                ),
                Text(
                  '$stageCount cửa ải lấy trực tiếp từ database',
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

class _StagePathItem extends StatelessWidget {
  const _StagePathItem({
    required this.stage,
    required this.next,
    required this.index,
    required this.onTap,
  });

  final BossBattleStage stage;
  final BossBattleStage? next;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final left = index.isEven;
    final accent = _themeColor(stage.themeCode);
    final bossGate = stage.stageOrder % 7 == 0;

    return SizedBox(
      height: bossGate ? 170 : 150,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StageConnectorPainter(
                left: left,
                hasNext: next != null,
                accent: accent,
              ),
            ),
          ),
          Align(
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .76,
              child: Material(
                color: const Color(0xF8FFF9EF),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accent.withValues(alpha: .62),
                        width: bossGate ? 2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: .18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStageBadge(accent),
                        const SizedBox(width: 11),
                        _buildStageDetails(accent, bossGate),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9C8176),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _themeColor(String theme) {
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

  Widget _buildStageBadge(Color accent) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            Color.lerp(
              accent,
              const Color(0xFF2A1720),
              .45,
            )!,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD985),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${stage.stageOrder}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStageDetails(Color accent, bool bossGate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  stage.label,
                  style: const TextStyle(
                    color: AppColors.redDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (bossGate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0D8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'BOSS GATE',
                    style: TextStyle(
                      color: Color(0xFFD9473F),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            stage.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              _StageMeta(
                icon: Icons.local_fire_department_rounded,
                text: stage.difficultyLabel,
                color: accent,
              ),
              _StageMeta(
                icon: Icons.quiz_rounded,
                text: '${stage.questionCount} câu',
                color: const Color(0xFF327FC4),
              ),
              _StageMeta(
                icon: Icons.favorite_rounded,
                text: '${stage.bossHp} HP',
                color: const Color(0xFFD84A43),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageMeta extends StatelessWidget {
  const _StageMeta({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StageConnectorPainter extends CustomPainter {
  const _StageConnectorPainter({
    required this.left,
    required this.hasNext,
    required this.accent,
  });

  final bool left;
  final bool hasNext;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasNext) return;
    final x = left ? size.width * .18 : size.width * .82;
    final nextX = left ? size.width * .82 : size.width * .18;
    final path = Path()
      ..moveTo(x, size.height * .72)
      ..cubicTo(
        x,
        size.height * .94,
        nextX,
        size.height * .88,
        nextX,
        size.height,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x66FFD071)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: .42)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StageConnectorPainter oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.hasNext != hasNext ||
      oldDelegate.accent != accent;
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
