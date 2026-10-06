import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../boss_battle/boss_battle_screen.dart';
import '../../boss_battle/model/boss_battle_stage.dart';
import '../../duolingo/page/duo_game_runner_screen.dart';
import '../controller/unit_path_controller.dart';
import '../model/unit_learning_node.dart';
import '../widget/unit_boss_node.dart';
import '../widget/unit_level_node.dart';

class UnitPathScreen extends GetView<UnitPathController> {
  const UnitPathScreen({
    super.key,
    required this.stage,
  });

  final BossBattleStage stage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EBD7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/game_hub_bg.png',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: .18),
              colorBlendMode: BlendMode.lighten,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22FFF7DF),
                    Color(0xCCF8ECD6),
                    Color(0xFFF4E6CC),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Obx(() => _buildBody(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D6C)),
      );
    }

    final error = controller.errorMessage.value;
    if (error != null) {
      return _UnitPathError(
        message: error,
        onRetry: controller.load,
      );
    }

    final nodes = controller.nodes;
    if (nodes.isEmpty) {
      return _UnitPathError(
        message: 'Unit này chưa có nhiệm vụ học phù hợp.',
        onRetry: controller.load,
      );
    }

    final activeIndex = nodes.indexWhere(
      (node) =>
          node.state == UnitLearningNodeState.inProgress ||
          node.state == UnitLearningNodeState.available,
    );

    return Column(
      children: [
        _ChapterHeader(
          title: controller.unitTitle,
          sectionNumber: stage.sectionNumber,
          unitNumber: stage.unitNumber,
          completed: controller.completedMissionCount,
          total: controller.missionCount,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.load,
            color: const Color(0xFF2E7D6C),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 46),
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                final node = nodes[index];
                final alignLeft = index.isEven;

                return Column(
                  children: [
                    if (index > 0)
                      _PathConnector(
                        fromLeft: !alignLeft,
                        toLeft: alignLeft,
                      ),
                    if (node.isBoss)
                      UnitBossNode(
                        key: ValueKey('boss-${node.bossStageId}'),
                        node: node,
                        onTap: () => _openBoss(node),
                      )
                    else
                      UnitLevelNode(
                        key: ValueKey(
                          '${node.gameId}-${node.levelId}',
                        ),
                        node: node,
                        alignLeft: alignLeft,
                        showPanda: index == activeIndex,
                        onTap: () => _openLearningNode(node),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLearningNode(UnitLearningNode node) async {
    if (node.isLocked) {
      Get.snackbar(
        'Cổng nhiệm vụ đang khóa',
        'Hoàn thành nhiệm vụ trước để tiếp tục hành trình.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final gameId = node.gameId;
    final levelId = node.levelId;
    if (gameId == null || levelId == null) return;

    final next = controller.nextLearningNodeAfter(node);

    await Get.to(
      () => DuoGameRunnerScreen(
        gameId: gameId,
        gameCode: node.gameCode,
        levelId: levelId,
        gameName: node.gameName,
        unitId: node.unitId,
        nextGameId: next?.gameId,
        nextLevelId: next?.levelId,
      ),
    );

    await controller.load();
  }

  Future<void> _openBoss(UnitLearningNode node) async {
    if (node.isLocked) {
      Get.snackbar(
        'Boss chưa xuất hiện',
        'Hoàn thành toàn bộ nhiệm vụ học trong Chapter này trước.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.to(() => BossBattleScreen(stage: stage));
    await controller.load();
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.title,
    required this.sectionNumber,
    required this.unitNumber,
    required this.completed,
    required this.total,
  });

  final String title;
  final int sectionNumber;
  final int unitNumber;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(8, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF7FFF9EA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x66A47735)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5D3D1F),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFE9D6AA),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: Get.back,
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF65421F),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAPTER $sectionNumber · UNIT $unitNumber',
                  style: const TextStyle(
                    color: Color(0xFF9A5F20),
                    fontSize: 10,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF322719),
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0).toDouble(),
                          minHeight: 7,
                          backgroundColor: const Color(0xFFE5D8BE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E8A61),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        color: Color(0xFF2E6B54),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/characters/panda_avatar.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  const _PathConnector({
    required this.fromLeft,
    required this.toLeft,
  });

  final bool fromLeft;
  final bool toLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: CustomPaint(
        painter: _PathConnectorPainter(
          fromLeft: fromLeft,
          toLeft: toLeft,
        ),
      ),
    );
  }
}

class _PathConnectorPainter extends CustomPainter {
  const _PathConnectorPainter({
    required this.fromLeft,
    required this.toLeft,
  });

  final bool fromLeft;
  final bool toLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final startX = fromLeft ? size.width * .23 : size.width * .77;
    final endX = toLeft ? size.width * .23 : size.width * .77;
    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(
        startX,
        size.height * .42,
        endX,
        size.height * .58,
        endX,
        size.height,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB89A64)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF0C7)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PathConnectorPainter oldDelegate) =>
      oldDelegate.fromLeft != fromLeft || oldDelegate.toLeft != toLeft;
}

class _UnitPathError extends StatelessWidget {
  const _UnitPathError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/characters/panda_dizzy.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5C4B36),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
