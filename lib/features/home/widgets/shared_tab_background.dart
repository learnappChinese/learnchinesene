import 'package:flutter/material.dart';

import '../../../core/widgets/learning_scene_background.dart' show bottomBleed;
import 'home_decorations.dart';

/// The landscape backdrop shared by Learning, Games, Progress and Personal.
class SharedTabBackground extends StatelessWidget {
  const SharedTabBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Nền tràn xuống vùng home indicator nếu màn cha đã bọc SafeArea.
    final bleed = bottomBleed(context);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -bleed,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: homeCream,
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/backgrounds/shared_landscape.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
