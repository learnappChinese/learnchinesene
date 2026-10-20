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

      final allLevels = [...res];
      if (!allLevels.any((l) => l.order == 5)) {
        allLevels.add(const HskLevel(id: 5, title: 'HSK 5 (Chưa mở)', order: 5));
      }
      if (!allLevels.any((l) => l.order == 6)) {
        allLevels.add(const HskLevel(id: 6, title: 'HSK 6 (Chưa mở)', order: 6));
      }
      levels.value = allLevels;
    } catch (e) {
      if (isClosed || request != _loadRequest) return;
      hasError.value = true;
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }
}
