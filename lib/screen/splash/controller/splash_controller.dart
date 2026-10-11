import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/controller/auth_controller.dart';
import '../../../core/database/db_helper.dart';
import '../../auth/welcome_screen.dart';
import '../../home/home_screen.dart';

class SplashController extends GetxController {
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    start();
  }

  Future<void> start() async {
    error.value = null;
    try {
      await Future.wait([
        DbHelper.instance.database,
        Future<void>.delayed(const Duration(milliseconds: 900)),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final hasSeenWelcome = prefs.getBool('has_seen_welcome_v1') ?? false;
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      final isSignedIn = auth?.isSignedIn ?? false;

      if (!hasSeenWelcome && !isSignedIn) {
        Get.off(() => const WelcomeScreen());
      } else {
        Get.off(() => const HomeScreen());
      }
    } catch (_) {
      error.value =
          'Không thể kết nối máy chủ học liệu. Hãy kiểm tra Internet và thử lại.';
    }
  }
}
