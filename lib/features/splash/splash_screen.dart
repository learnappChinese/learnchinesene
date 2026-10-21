import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controller/splash_controller.dart';
import 'widget/splash_branding.dart';
import 'widget/splash_load_status.dart';
import '../../core/widgets/centered_scroll_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Hiệu ứng xuất hiện logo đã chạy ở màn khởi động ([SplashIntro]) chưa.
  /// Nếu rồi, Splash hiện logo ngay để hai màn nối liền, không nháy lại.
  static bool introPlayed = false;

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
    if (SplashScreen.introPlayed) {
      _animationController.value = 1;
    } else {
      SplashScreen.introPlayed = true;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SplashBackdrop(child: _buildAnimatedBranding());

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

/// Khung chung của màn khởi động và Splash: nền phong cảnh nhạt như các tab
/// ở Home, hai nhành lá ở góc và nội dung căn giữa trong vùng an toàn.
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFAF0),
          body: Stack(
            fit: StackFit.expand,
            children: [
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
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Màn khởi động trước khi app sẵn sàng: giống hệt Splash nhưng chỉ có logo,
/// không có vòng tải. Khi lỗi thì hiện thẻ báo lỗi kèm nút "Thử lại".
class SplashIntro extends StatefulWidget {
  const SplashIntro({super.key, this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _scale = Tween<double>(begin: .8, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    SplashScreen.introPlayed = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SplashBackdrop(
        child: FadeTransition(
          opacity: _opacity,
          child: CenteredScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SplashBranding(scaleAnimation: _scale),
                if (widget.error != null)
                  SplashLoadStatus(
                    error: widget.error,
                    onRetry: widget.onRetry,
                  )
                else
                  // Giữ chỗ đúng bằng dòng trạng thái của Splash (nhưng ẩn)
                  // để logo không bị dịch lên khi chuyển sang Splash.
                  Visibility(
                    visible: false,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: SplashLoadStatus(error: null, onRetry: () {}),
                  ),
              ],
            ),
          ),
        ),
      );
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
