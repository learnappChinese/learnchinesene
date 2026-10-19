import 'package:get/get.dart';

import '../../../core/auth/controller/auth_controller.dart';
import '../../../core/database/db_helper.dart';
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

      // App không có đăng nhập: luôn vào thẳng với định danh khách.
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      if (auth != null && !auth.isSignedIn && !auth.isGuest) {
        await auth.continueAsGuest();
      }
      Get.off(() => const HomeScreen());
    } catch (_) {
      error.value =
          'Không thể kết nối máy chủ học liệu. Hãy kiểm tra Internet và thử lại.';
    }
  }
}
