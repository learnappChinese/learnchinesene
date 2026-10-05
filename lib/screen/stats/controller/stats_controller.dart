import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';

class StatsController extends GetxController {
  final stats = <String, num>{}.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    final res = await DbHelper.instance.getStats();
    stats.value = res;
    isLoading.value = false;
  }
}
