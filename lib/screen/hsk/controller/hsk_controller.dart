import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/hsk_level.dart';

class HskController extends GetxController {
  HskController({DbHelper? database})
      : _database = database ?? DbHelper.instance;

  final DbHelper _database;
  int _loadRequest = 0;
  final levels = <HskLevel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  final _metrics = <int, Future<List<Object>>>{};

  Future<List<Object>> metricsFor(int id) => _metrics.putIfAbsent(
      id,
      () => Future.wait<Object>([
            _database.getUnitCountForLevel(id),
            _database.getLevelProgress(id)
          ]));

  @override
  void onInit() {
    super.onInit();
    loadLevels();
  }

  Future<void> loadLevels() async {
    final request = ++_loadRequest;
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await _database.getHskLevels();
      if (isClosed || request != _loadRequest) return;
      _metrics.clear();
      levels.value = res;
    } catch (e) {
      if (isClosed || request != _loadRequest) return;
      hasError.value = true;
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }
}
