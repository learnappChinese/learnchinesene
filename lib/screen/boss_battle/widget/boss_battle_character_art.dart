import 'package:flutter/material.dart';

import '../../../core/game/game_art.dart';
import '../../../core/widgets/game_art_image.dart';

enum BossBattleCharacterKind {
  panda,
  dragon,
}

class BossBattleCharacterArt extends StatelessWidget {
  const BossBattleCharacterArt({
    super.key,
    required this.kind,
    this.size = 92,
    this.defeated = false,
  });

  final BossBattleCharacterKind kind;
  final double size;
  final bool defeated;

  String get _asset {
    if (kind == BossBattleCharacterKind.dragon) {
      return GameArt.dragonFire;
    }
    if (defeated) {
      return GameArt.pandaDizzy;
    }
    return GameArt.pandaArcher;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = kind == BossBattleCharacterKind.dragon ? '🐉' : '🐼';

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: size * .16,
              right: size * .16,
              bottom: size * .015,
              height: size * .11,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: size * .08,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: GameArtImage(
                url: _asset,
                fit: BoxFit.contain,
                fallbackEmoji: fallback,
              ),
            ),
            if (defeated && kind == BossBattleCharacterKind.dragon)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .18),
                    backgroundBlendMode: BlendMode.saturation,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
