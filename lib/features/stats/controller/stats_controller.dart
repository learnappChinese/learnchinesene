import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';

class StatsController extends GetxController {
  StatsController({LearningProgressSyncService? syncService})
      : _syncService = syncService ?? _registeredSyncService();

  final LearningProgressSyncService? _syncService;
  LearningSyncRegistration? _syncRegistration;
  int _loadRequest = 0;

  static LearningProgressSyncService? _registeredSyncService() {
    if (!Get.isRegistered<LearningProgressSyncService>()) return null;
    return Get.find<LearningProgressSyncService>();
  }

  final stats = <String, num>{}.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _syncRegistration = _syncService?.registerRefresher(
      owner: 'stats',
      domains: const <LearningDomain>{
        LearningDomain.stats,
        LearningDomain.identity,
      },
      refresh: (event) async {
        if (event.type == LearningDomainEventType.identityChanged) {
          stats.clear();
        }
        await loadStats();
      },
    );
    loadStats();
  }

  Future<void> loadStats() async {
    final request = ++_loadRequest;
    isLoading.value = stats.isEmpty;
    try {
      final res = await DbHelper.instance.getStats();
      if (!isClosed && request == _loadRequest) stats.value = res;
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _loadRequest++;
    _syncRegistration?.dispose();
    super.onClose();
  }
}
