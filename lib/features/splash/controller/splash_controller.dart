import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
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
      // 1. Đảm bảo Database SQLite cục bộ đã sẵn sàng
      if (!AppDatabase.instance.isOpen) {
        await AppDatabase.instance.init();
      }
      await AppDatabase.instance.ensureContentPackSeeded();

      // 2. Chờ hiệu ứng splash mượt mà
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // 3. Vào thẳng màn hình chính (Local-First, không cần đăng nhập)
      Get.off(() => const HomeScreen());
    } catch (e) {
      debugPrint('Lỗi khởi động Splash: $e');
      // Vẫn vào HomeScreen để không chặn người dùng
      Get.off(() => const HomeScreen());
    }
  }
}
