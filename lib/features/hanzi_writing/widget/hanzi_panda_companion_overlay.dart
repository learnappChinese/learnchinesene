import 'package:flutter/material.dart';

import '../../../core/widgets/panda_companion.dart';

/// Panda linh vật đồng hành xuất hiện bên cạnh con đường uốn lượn để khích lệ người học.
class HanziPathPandaWidget extends StatelessWidget {
  final bool isLeft;
  final String speechText;
  final PandaMood mood;

  const HanziPathPandaWidget({
    super.key,
    required this.isLeft,
    this.speechText = 'Cố lên bạn ơi!',
    this.mood = PandaMood.happy,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? 12 : null,
      right: isLeft ? null : 12,
      top: -8,
      child: SizedBox(
        width: 104,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: PandaCompanion(
            mood: mood,
            size: 56,
            speechText: speechText,
            animate: true,
          ),
        ),
      ),
    );
  }
}
