import 'package:flutter/material.dart';

import '../../../core/models/hsk_level.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/panda_companion.dart';

class HskWorldMeta {
  const HskWorldMeta({
    required this.name,
    required this.vietnameseName,
    required this.landmark,
    required this.pandaMood,
    required this.colors,
    required this.accent,
  });

  final String name;
  final String vietnameseName;
  final IconData landmark;
  final PandaMood pandaMood;
  final List<Color> colors;
  final Color accent;
}

class HskLevelCard extends StatelessWidget {
  const HskLevelCard({
    super.key,
    required this.level,
    required this.index,
    required this.count,
    required this.progress,
    required this.isUnlocked,
    required this.onTap,
  });

  final HskLevel level;
  final int index;
  final int count;
  final double progress;
  final bool isUnlocked;
  final VoidCallback onTap;

  static const worlds = <int, HskWorldMeta>{
    1: HskWorldMeta(
        name: 'Bamboo Village',
        vietnameseName: 'Làng Trúc Xanh',
        landmark: Icons.park_rounded,
        pandaMood: PandaMood.happy,
        colors: [Color(0xFFDBF4D5), Color(0xFF74B98B)],
        accent: Color(0xFF176B52)),
    2: HskWorldMeta(
        name: 'Lantern Town',
        vietnameseName: 'Trấn Đèn Lồng',
        landmark: Icons.festival_rounded,
        pandaMood: PandaMood.chef,
        colors: [Color(0xFFFFE6A7), Color(0xFFE99745)],
        accent: Color(0xFF9A3E24)),
    3: HskWorldMeta(
        name: 'Shanghai',
        vietnameseName: 'Thượng Hải',
        landmark: Icons.location_city_rounded,
        pandaMood: PandaMood.thinking,
        colors: [Color(0xFFD7EDFA), Color(0xFF78A9CA)],
        accent: Color(0xFF195A83)),
    4: HskWorldMeta(
        name: 'Mountain Temple',
        vietnameseName: 'Cổ Tự Mây Ngàn',
        landmark: Icons.temple_buddhist_rounded,
        pandaMood: PandaMood.ninja,
        colors: [Color(0xFFE9DCF5), Color(0xFF9276B5)],
        accent: Color(0xFF513377)),
    5: HskWorldMeta(
        name: 'Imperial City',
        vietnameseName: 'Hoàng Thành',
        landmark: Icons.account_balance_rounded,
        pandaMood: PandaMood.archer,
        colors: [Color(0xFFF8D5CB), Color(0xFFC6554F)],
        accent: Color(0xFF872B2B)),
    6: HskWorldMeta(
        name: 'Dragon Realm',
        vietnameseName: 'Long Giới',
        landmark: Icons.local_fire_department_rounded,
        pandaMood: PandaMood.victory,
        colors: [Color(0xFF423052), Color(0xFF1E152B)],
        accent: GameVisualTokens.imperialGold),
  };

  HskWorldMeta get meta =>
      worlds[level.order] ??
      HskWorldMeta(
        name: 'Chinese Frontier',
        vietnameseName: 'Vùng đất HSK ${level.order}',
        landmark: Icons.explore_rounded,
        pandaMood: PandaMood.idle,
        colors: const [Color(0xFFF3E8CF), Color(0xFFB89C70)],
        accent: GameVisualTokens.templeWood,
      );

  int get stars => progress >= .95
      ? 3
      : progress >= .5
          ? 2
          : progress > 0
              ? 1
              : 0;

  @override
  Widget build(BuildContext context) {
    final world = meta;
    final dark = level.order == 6;
    final foreground = dark ? Colors.white : GameVisualTokens.ink;
    final completed = (count * progress.clamp(0, 1)).round();

    return Semantics(
      button: true,
      enabled: isUnlocked,
      label: '${world.name}, $completed trên $count chương hoàn thành',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUnlocked
                    ? world.colors
                    : const [Color(0xFFD9D6CF), Color(0xFFA9A49B)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: isUnlocked
                      ? world.accent.withValues(alpha: .45)
                      : Colors.black26,
                  width: 1.5),
            ),
            child: Stack(children: [
              Positioned(
                  right: -24,
                  top: -32,
                  child: Icon(world.landmark,
                      size: 170, color: Colors.white.withValues(alpha: .18))),
              Positioned(
                  left: -20,
                  bottom: -42,
                  child: Container(
                      width: 190,
                      height: 90,
                      decoration: BoxDecoration(
                          color: world.accent.withValues(alpha: .12),
                          borderRadius: const BorderRadius.all(
                              Radius.elliptical(190, 90))))),
              Positioned(
                  right: 10,
                  bottom: -4,
                  child: Opacity(
                      opacity: isUnlocked ? 1 : .45,
                      child: PandaCompanion(
                          mood: world.pandaMood, size: 92, animate: false))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 112, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                              color: world.accent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('WORLD ${level.order}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .8)),
                        ),
                        const Spacer(),
                        if (!isUnlocked)
                          const Icon(Icons.lock_rounded,
                              size: 20, color: GameVisualTokens.crimsonDark),
                      ]),
                      const Spacer(),
                      Text(world.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: foreground,
                              fontSize: 21,
                              fontWeight: FontWeight.w900)),
                      Text(world.vietnameseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: foreground.withValues(alpha: .72),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 9),
                      Row(
                          children: List.generate(
                              3,
                              (i) => Icon(
                                  i < stars
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 18,
                                  color: i < stars
                                      ? GameVisualTokens.imperialGold
                                      : foreground.withValues(alpha: .28)))),
                      const SizedBox(height: 7),
                      Text('$completed/$count chương hoàn thành',
                          style: TextStyle(
                              color: foreground.withValues(alpha: .78),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Colors.black12,
                            color: isUnlocked
                                ? world.accent
                                : Colors.grey.shade600),
                      ),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
