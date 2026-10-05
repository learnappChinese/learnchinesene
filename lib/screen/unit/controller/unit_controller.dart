import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/unit_model.dart';

class UnitController extends GetxController {
  UnitController({DbHelper? database})
      : _database = database ?? DbHelper.instance;

  final DbHelper _database;
  int _loadRequest = 0;
  String title = 'Bài học';
  final units = <UnitModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  final _metrics = <int, Future<Map<String, int>>>{};

  Future<Map<String, int>> metricsFor(int id) =>
      _metrics.putIfAbsent(id, () => _database.getUnitMetrics(id));

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    title = 'Lộ trình ${args?['hskTitle'] ?? 'HSK'}';
    loadUnits((args?['hskLevelId'] as int?) ?? 0);
  }

  Future<void> loadUnits(int hskLevelId) async {
    final request = ++_loadRequest;
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await _database.getUnitsByLevel(hskLevelId);
      if (isClosed || request != _loadRequest) return;
      _metrics.clear();
      units.value = res;
    } catch (e) {
      if (isClosed || request != _loadRequest) return;
      hasError.value = true;
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }
}
