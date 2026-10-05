import 'package:flutter/material.dart';

import 'home_decorations.dart';

/// The landscape backdrop shared by Learning, Games, Progress and Personal.
class SharedTabBackground extends StatelessWidget {
  const SharedTabBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: homeCream,
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/shared_landscape.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SizedBox.expand(child: child),
      );
}
