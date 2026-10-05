import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flash_learn_chinese/core/theme/app_colors.dart';
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
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.redDark, AppColors.red, AppColors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildAnimatedBranding(),
              ),
            ),
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
