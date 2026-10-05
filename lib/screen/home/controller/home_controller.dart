import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;
  final stats = <String, num>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refreshStats();
  }

  Future<void> refreshStats() async {
    stats.value = await DbHelper.instance.getStats();
  }

  void setIndex(int index) {
    currentIndex.value = index;
  }
}
