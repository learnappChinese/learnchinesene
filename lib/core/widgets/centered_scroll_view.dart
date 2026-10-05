import 'package:flutter/material.dart';

/// Centers short content and allows it to scroll when the viewport is smaller.
class CenteredScrollView extends StatelessWidget {
  const CenteredScrollView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      );
}
