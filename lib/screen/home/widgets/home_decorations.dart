import 'package:flutter/material.dart';

const homeCream = Color(0xFFFFFAF0);
const homePageBackground = Color(0xFFFFFEF9);
const homeInk = Color(0xFF201E16);
const homeGreen = Color(0xFF45BC09);
const homePandaPeekAsset = 'assets/images/characters/home_panda_peek.png';
const homeTitlePandaAsset = 'assets/images/characters/home_title_panda.png';
const homeNavPandaAsset = 'assets/images/characters/home_nav_panda.png';
const homeSceneAsset = 'assets/images/backgrounds/home_garden.png';
const homeLeafSprigAsset = 'assets/images/effects/home_leaf_sprig.png';

/// A small matte leaf fan shared by the card corners and home button.
class HomeLeaves extends StatelessWidget {
  const HomeLeaves({
    super.key,
    this.size = 34,
    this.flip = false,
    this.rotation = 0,
  });

  final double size;
  final bool flip;
  final double rotation;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
          child: Transform.rotate(
            angle: rotation,
            child: Transform.flip(
              flipX: flip,
              child: Image.asset(
                homeLeafSprigAsset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      );
}

class HomePandaFace extends StatelessWidget {
  const HomePandaFace({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * .035),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFD8C9B5),
              width: size * .035,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x2B6B5238),
                blurRadius: size * .12,
                offset: Offset(0, size * .07),
              ),
            ],
          ),
          child: ClipOval(
            child: Transform.scale(
              scale: 1.24,
              child: Image.asset(
                homeTitlePandaAsset,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.12),
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      );
}
