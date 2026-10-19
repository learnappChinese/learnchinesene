import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controller/splash_controller.dart';
import 'widget/splash_branding.dart';
import 'widget/splash_load_status.dart';
import '../../core/widgets/centered_scroll_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final SplashController controller = Get.find<SplashController>();
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFAF0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Cùng phông nền phong cảnh nhạt với các tab ở Home.
              const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/backgrounds/shared_landscape.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              const Positioned(
                left: -18,
                bottom: 40,
                child: _Leaf(size: 120, flip: false),
              ),
              const Positioned(
                right: -18,
                bottom: 110,
                child: _Leaf(size: 96, flip: true),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _buildAnimatedBranding(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildAnimatedBranding() {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: CenteredScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SplashBranding(scaleAnimation: _scaleAnimation),
          Obx(() => SplashLoadStatus(
              error: controller.error.value, onRetry: controller.start)),
        ],
      )),
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({required this.size, required this.flip});

  final double size;
  final bool flip;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: .55,
          child: Transform.flip(
            flipX: flip,
            child: Image.asset(
              'assets/images/effects/home_leaf_sprig.png',
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
}
