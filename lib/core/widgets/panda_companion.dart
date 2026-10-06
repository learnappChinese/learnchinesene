import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/game_visual_tokens.dart';

enum PandaMood {
  idle,
  happy,
  thinking,
  celebrate,
  encourage,
  victory,
  ninja,
  chef,
  archer,
}

class PandaCompanion extends StatefulWidget {
  const PandaCompanion({
    super.key,
    this.mood = PandaMood.idle,
    this.size = 110.0,
    this.speechText,
    this.onTap,
    this.animate = true,
  });

  final PandaMood mood;
  final double size;
  final String? speechText;
  final VoidCallback? onTap;

  final bool animate;

  @override
  State<PandaCompanion> createState() => _PandaCompanionState();
}

class _PandaCompanionState extends State<PandaCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  static bool get _inTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate && !_inTest) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  String _getAssetForMood() {
    switch (widget.mood) {
      case PandaMood.ninja:
        return 'assets/images/characters/panda_ninja.png';
      case PandaMood.chef:
        return 'assets/images/characters/panda_chef.png';
      case PandaMood.archer:
        return 'assets/images/characters/panda_archer.png';
      case PandaMood.victory:
      case PandaMood.celebrate:
        return 'assets/images/characters/panda_victory.png';
      case PandaMood.thinking:
        return 'assets/images/characters/home_panda_peek.png';
      case PandaMood.happy:
      case PandaMood.encourage:
      case PandaMood.idle:
        return 'assets/images/characters/home_title_panda.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _getAssetForMood();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final floatOffset = math.sin(_floatController.value * math.pi) * 4.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.speechText != null && widget.speechText!.isNotEmpty)
                _buildSpeechBubble(widget.speechText!),
              Transform.translate(
                offset: Offset(0, -floatOffset),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/characters/panda_avatar.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('🐼', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpeechBubble(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameVisualTokens.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: GameVisualTokens.ink,
        ),
      ),
    );
  }
}
