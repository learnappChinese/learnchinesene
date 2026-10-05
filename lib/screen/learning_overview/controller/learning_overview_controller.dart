import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';

class LearningOverviewController extends GetxController {
  int unitId = 0;
  String title = 'Bài học';
  final metrics = <String, int>{}.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    unitId = (args?['unitId'] as int?) ?? 0;
    title = '${args?['unitTitle'] ?? 'Bài học'}';
    loadMetrics();
  }

  Future<void> loadMetrics() async {
    isLoading.value = true;
    final res = await DbHelper.instance.getUnitMetrics(unitId);
    metrics.value = res;
    isLoading.value = false;
  }
}
