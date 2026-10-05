import 'package:get/get.dart';

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
      Get.off(() => const HomeScreen());
    } catch (_) {
      error.value =
          'Không thể kết nối máy chủ học liệu. Hãy kiểm tra Internet và thử lại.';
    }
  }
}
