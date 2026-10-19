import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/unit_model.dart';
import '../../../core/learning/data/learning_journey_repository.dart';
import '../../../core/learning/model/learning_journey_models.dart';

class UnitController extends GetxController {
  UnitController({
    DbHelper? database,
    LearningJourneyRepository? journeyRepository,
  })  : _database = database ?? DbHelper.instance,
        _journeyRepository = journeyRepository;

  final DbHelper _database;
  final LearningJourneyRepository? _journeyRepository;
  int _loadRequest = 0;
  String title = 'Bài học';
  int sectionNumber = 1;
  final units = <UnitModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  final _metrics = <int, Future<Map<String, int>>>{};
  final _journeyUnits = <int, Future<LearningUnitViewModel?>>{};

  Future<Map<String, int>> metricsFor(int id) =>
      _metrics.putIfAbsent(id, () => _database.getUnitMetrics(id));

  Future<LearningUnitViewModel?> journeyUnitFor(int unitNumber) =>
      _journeyUnits.putIfAbsent(unitNumber, () async {
        final repository =
            _journeyRepository ?? SupabaseLearningJourneyRepository();
        final sections = await repository.getSections();
        final section = sections
            .where((item) => item.sectionNumber == sectionNumber)
            .firstOrNull;
        if (section == null) return null;
        final units = await repository.getUnits(section.id);
        return units.where((item) => item.unitNumber == unitNumber).firstOrNull;
      });

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    title = 'Lộ trình ${args?['hskTitle'] ?? 'HSK'}';
    sectionNumber = (args?['hskOrder'] as num?)?.toInt() ?? 1;
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
      _journeyUnits.clear();
      units.value = res;
    } catch (e) {
      if (isClosed || request != _loadRequest) return;
      hasError.value = true;
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }
}
