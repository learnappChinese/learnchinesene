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
  static const double _rowHeight = 178;

  @override
  Widget build(BuildContext context) {
    final rows = _layoutRows(missions.length);
    final height = rows * _rowHeight + 155;
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
        top: rows * _rowHeight + 8,
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
                mission.state == AdventureNodeState.inProgress ||
                mission.state == AdventureNodeState.failed;
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
                        item.state == AdventureNodeState.inProgress ||
                        item.state == AdventureNodeState.failed),
                rewardPreview: mission.state == AdventureNodeState.locked
                    ? null
                    : 'XP • ⭐',
                progressLabel: _progressLabel(mission),
                ctaLabel: _ctaLabel(mission.state),
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
              title: 'Boss Chương',
              rewardPreview: bossUnlocked ? 'Rương • ⭐⭐⭐' : null,
              progressLabel: bossUnlocked
                  ? 'Sẵn sàng chiến đấu'
                  : 'Hoàn thành các nhiệm vụ',
              ctaLabel: bossUnlocked ? 'CHIẾN ĐẤU' : 'XEM ĐIỀU KIỆN',
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

  String? _progressLabel(ChapterMission mission) {
    switch (mission.state) {
      case AdventureNodeState.inProgress:
        if (mission.currentTotal <= 0) return 'Đang học';
        final answered = mission.currentIndex.clamp(0, mission.currentTotal);
        return '$answered / ${mission.currentTotal} câu';
      case AdventureNodeState.failed:
        return '${mission.bestScore}% • Cần 70%';
      case AdventureNodeState.locked:
        return _lockCopy(mission.lockReason);
      case AdventureNodeState.available:
        return mission.attempts > 0 ? 'Sẵn sàng thử lại' : 'Nhiệm vụ mới';
      case AdventureNodeState.completed:
      case AdventureNodeState.perfect:
        return 'Đã hoàn thành';
    }
  }

  String? _ctaLabel(AdventureNodeState state) {
    switch (state) {
      case AdventureNodeState.available:
        return 'BẮT ĐẦU';
      case AdventureNodeState.inProgress:
        return 'TIẾP TỤC';
      case AdventureNodeState.failed:
        return 'THỬ LẠI';
      case AdventureNodeState.locked:
        return 'XEM ĐIỀU KIỆN';
      case AdventureNodeState.completed:
      case AdventureNodeState.perfect:
        return 'CHƠI LẠI';
    }
  }

  String _lockCopy(String? reason) {
    switch (reason) {
      case 'mastery_too_low':
        return 'Cần nâng mastery';
      case 'boss_required':
        return 'Cần thắng Boss';
      case 'chapter_locked':
        return 'Chương chưa mở';
      default:
        return 'Hoàn thành nhiệm vụ trước';
    }
  }

  _MapPosition _positionFor(int index, double width) {
    if (index == 0) return _MapPosition(left: (width - 150) / 2, top: 8);
    final adjusted = index - 1;
    final row = 1 + adjusted ~/ 2;
    final leftLane = adjusted.isEven;
    final edge = width < 360 ? 0.0 : 12.0;
    return _MapPosition(
      left: leftLane ? edge : width - 150 - edge,
      top: row * _rowHeight,
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
