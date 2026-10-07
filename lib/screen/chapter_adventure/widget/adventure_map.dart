import 'package:flutter/material.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/adventure_node.dart';
import '../model/chapter_adventure.dart';

class AdventureMap extends StatelessWidget {
  const AdventureMap({
    super.key,
    required this.missions,
    required this.bossUnlocked,
    required this.onMissionTap,
    required this.onBossTap,
  });

  final List<ChapterMission> missions;
  final bool bossUnlocked;
  final ValueChanged<ChapterMission> onMissionTap;
  final VoidCallback onBossTap;

  @override
  Widget build(BuildContext context) {
    final rows = _layoutRows(missions.length);
    final height = rows * 154.0 + 135;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final points = <Offset>[];
      final positions = <_MapPosition>[];
      for (var i = 0; i < missions.length; i++) {
        final position = _positionFor(i, width);
        positions.add(position);
        points.add(Offset(position.left + 75, position.top + 40));
      }
      final bossPosition = _MapPosition(
        left: (width - 150) / 2,
        top: rows * 154.0 + 8,
      );
      points.add(Offset(bossPosition.left + 75, bossPosition.top + 43));

      return SizedBox(
        height: height,
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AdventurePathPainter(
                points: points,
                completedSegments:
                    missions.takeWhile((mission) => mission.isCompleted).length,
              ),
            ),
          ),
          ...List.generate(missions.length, (index) {
            final mission = missions[index];
            final position = positions[index];
            final active = mission.state == AdventureNodeState.available ||
                mission.state == AdventureNodeState.inProgress;
            return Positioned(
              left: position.left,
              top: position.top,
              width: 150,
              child: AdventureNode(
                type: mission.type,
                state: mission.state,
                title: mission.title,
                stars: mission.stars,
                isActive: active &&
                    !missions.take(index).any((item) =>
                        item.state == AdventureNodeState.available ||
                        item.state == AdventureNodeState.inProgress),
                rewardPreview: mission.state == AdventureNodeState.locked
                    ? null
                    : 'XP • ⭐',
                onTap: () => onMissionTap(mission),
              ),
            );
          }),
          Positioned(
            left: bossPosition.left,
            top: bossPosition.top,
            width: 150,
            child: AdventureNode(
              type: AdventureNodeType.boss,
              state: bossUnlocked
                  ? AdventureNodeState.available
                  : AdventureNodeState.locked,
              title: 'Chapter Boss',
              rewardPreview: bossUnlocked ? 'Rương • ⭐⭐⭐' : null,
              onTap: onBossTap,
            ),
          ),
          const Positioned(
              left: 8,
              top: 120,
              child: _MapDecoration(icon: Icons.park_rounded)),
          const Positioned(
              right: 8,
              top: 276,
              child: _MapDecoration(icon: Icons.festival_rounded)),
          const Positioned(
              left: 12,
              bottom: 195,
              child: _MapDecoration(icon: Icons.landscape_rounded)),
        ]),
      );
    });
  }

  int _layoutRows(int count) {
    if (count <= 1) return 1;
    return 1 + ((count - 1) / 2).ceil();
  }

  _MapPosition _positionFor(int index, double width) {
    if (index == 0) return _MapPosition(left: (width - 150) / 2, top: 8);
    final adjusted = index - 1;
    final row = 1 + adjusted ~/ 2;
    final leftLane = adjusted.isEven;
    final edge = width < 360 ? 0.0 : 12.0;
    return _MapPosition(
      left: leftLane ? edge : width - 150 - edge,
      top: row * 154.0,
    );
  }
}

class _MapPosition {
  const _MapPosition({required this.left, required this.top});
  final double left;
  final double top;
}

class _MapDecoration extends StatelessWidget {
  const _MapDecoration({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Icon(icon,
            size: 42, color: GameVisualTokens.jade.withValues(alpha: .18)),
      );
}

class _AdventurePathPainter extends CustomPainter {
  const _AdventurePathPainter(
      {required this.points, required this.completedSegments});
  final List<Offset> points;
  final int completedSegments;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    for (var i = 0; i < points.length - 1; i++) {
      final paint = Paint()
        ..color = i < completedSegments
            ? GameVisualTokens.imperialGold
            : const Color(0xFFB7B0A1)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(points[i].dx, points[i].dy + 30);
      final middleY = (points[i].dy + points[i + 1].dy) / 2;
      path.cubicTo(points[i].dx, middleY, points[i + 1].dx, middleY,
          points[i + 1].dx, points[i + 1].dy - 30);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdventurePathPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.completedSegments != completedSegments;
}
