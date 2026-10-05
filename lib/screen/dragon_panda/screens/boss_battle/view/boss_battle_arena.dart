import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

class BossBattleArenaController {
  _BossBattleArenaState? _state;

  void playBearAttack() => _state?._playBearAttack();

  void playDragonAttack() => _state?._playDragonAttack();

  void _attach(_BossBattleArenaState state) => _state = state;

  void _detach(_BossBattleArenaState state) {
    if (identical(_state, state)) _state = null;
  }

  void dispose() => _state = null;
}

class BossBattleArena extends StatefulWidget {
  const BossBattleArena({
    super.key,
    required this.controller,
    required this.fallback,
    required this.cameraShakeOffset,
    this.backgroundAsset =
        'assets/images/backgrounds/boss_battle_bg.png',
    this.riveAsset = 'assets/rive/panda_dragon_battle.riv',
  });

  final BossBattleArenaController controller;
  final Widget fallback;
  final Offset cameraShakeOffset;
  final String backgroundAsset;
  final String riveAsset;

  @override
  State<BossBattleArena> createState() => _BossBattleArenaState();
}

class _BossBattleArenaState extends State<BossBattleArena> {
  rive.File? _riveFile;
  rive.RiveWidgetController? _riveController;
  rive.TriggerInput? _bearAttackTrigger;
  rive.TriggerInput? _dragonAttackTrigger;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _loadRive();
  }

  @override
  void didUpdateWidget(covariant BossBattleArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  Future<void> _loadRive() async {
    rive.File? file;
    rive.RiveWidgetController? controller;

    try {
      final initialized = await rive.RiveNative.init();
      if (!initialized) {
        throw StateError('Không thể khởi tạo Rive renderer');
      }

      file = await rive.File.asset(
        widget.riveAsset,
        riveFactory: rive.Factory.rive,
      );
      if (file == null) {
        throw StateError('Không thể đọc ${widget.riveAsset}');
      }

      controller = rive.RiveWidgetController(
        file,
        stateMachineSelector:
            rive.StateMachineSelector.byName('Combat State Machine'),
      );
      // ignore: deprecated_member_use
      final bearAttack = controller.stateMachine.trigger('bear_attack');
      // ignore: deprecated_member_use
      final dragonAttack = controller.stateMachine.trigger('dragon_attack');
      if (bearAttack == null || dragonAttack == null) {
        throw StateError(
          'Combat State Machine thiếu trigger bear_attack hoặc dragon_attack',
        );
      }

      if (!mounted) {
        controller.dispose();
        file.dispose();
        return;
      }

      setState(() {
        _riveFile = file;
        _riveController = controller;
        _bearAttackTrigger = bearAttack;
        _dragonAttackTrigger = dragonAttack;
      });
    } catch (error, stackTrace) {
      controller?.dispose();
      file?.dispose();
      debugPrint('Boss Battle Rive fallback: $error\n$stackTrace');
    }
  }

  void _playBearAttack() => _bearAttackTrigger?.fire();

  void _playDragonAttack() => _dragonAttackTrigger?.fire();

  @override
  void dispose() {
    widget.controller._detach(this);
    _riveController?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riveController = _riveController;
    if (riveController == null) return widget.fallback;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.backgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        Transform.translate(
          offset: widget.cameraShakeOffset,
          child: IgnorePointer(
            child: rive.RiveWidget(
              key: const ValueKey('boss-battle-rive'),
              controller: riveController,
              fit: rive.Fit.contain,
              alignment: Alignment.center,
            ),
          ),
        ),
      ],
    );
  }
}
