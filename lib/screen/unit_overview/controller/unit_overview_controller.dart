import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/learning/data/learning_journey_repository.dart';
import '../../../core/learning/model/learning_journey_models.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';
import '../../chapter_adventure/model/chapter_adventure.dart';

import '../../../core/learning/model/learning_stage_models.dart';

class UnitOverviewController extends GetxController {
  UnitOverviewController({
    LearningJourneyRepository? journeyRepository,
    LearningProgressSyncService? syncService,
  })  : _journeyRepo = journeyRepository ?? SupabaseLearningJourneyRepository(),
        _syncService = syncService ?? _registeredSyncService();

  final LearningJourneyRepository _journeyRepo;
  final LearningProgressSyncService? _syncService;
  LearningSyncRegistration? _syncRegistration;
  int _loadRequest = 0;

  static LearningProgressSyncService? _registeredSyncService() {
    if (!Get.isRegistered<LearningProgressSyncService>()) return null;
    return Get.find<LearningProgressSyncService>();
  }

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final chapter = Rxn<ChapterAdventure>();
  final stages = <LearningStageViewModel>[].obs;
  final nextUnit = Rxn<LearningUnitViewModel>();

  String unitId = '';
  String unitTitle = '';
  int sectionNumber = 1;
  int unitNumber = 1;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      unitId = args['unitId'] as String? ?? unitId;
      unitTitle = args['unitTitle'] as String? ?? '';
      sectionNumber = (args['sectionNumber'] as num?)?.toInt() ?? 1;
      unitNumber = (args['unitNumber'] as num?)?.toInt() ?? 1;
    }
    _syncRegistration = _syncService?.registerRefresher(
      owner: 'unit-overview:$unitId',
      domains: const <LearningDomain>{
        LearningDomain.unitPath,
        LearningDomain.journey,
        LearningDomain.identity,
      },
      refresh: (event) async {
        if (event.type == LearningDomainEventType.identityChanged) {
          chapter.value = null;
          stages.clear();
          nextUnit.value = null;
        }
        await loadUnitOverview(rethrowFailure: true);
      },
    );
    loadUnitOverview();
  }

  Future<void> loadUnitOverview({bool rethrowFailure = false}) async {
    final request = ++_loadRequest;
    isLoading.value = true;
    errorMessage.value = null;
    if (unitId.trim().isEmpty) {
      errorMessage.value = 'Không xác định được bài học cần mở.';
      isLoading.value = false;
      return;
    }
    try {
      final results = await Future.wait([
        _journeyRepo.getUnitJourney(unitId),
        _journeyRepo.getUnitStages(unitId),
      ]);

      final journey = results[0] as ChapterAdventure?;
      final loadedStages = results[1] as List<LearningStageViewModel>;

      if (isClosed || request != _loadRequest) return;

      stages.assignAll(loadedStages);

      if (journey == null && loadedStages.isEmpty) {
        errorMessage.value = 'Không tìm thấy dữ liệu cho bài học này.';
      } else {
        if (journey != null) {
          chapter.value = journey;
          if (unitTitle.isEmpty) {
            unitTitle = journey.title;
          }
          sectionNumber = journey.regionNumber;
          unitNumber = journey.chapterNumber;
        } else if (loadedStages.isNotEmpty) {
          final boss = loadedStages
              .where((s) => s.bossStage != null)
              .firstOrNull
              ?.bossStage;
          final allReqDone = loadedStages
              .where((s) => s.isRequired)
              .every((s) => s.isCompleted);
          final avgMastery =
              loadedStages.map((s) => s.mastery).reduce((a, b) => a + b) /
                  loadedStages.length;
          chapter.value = ChapterAdventure(
            levelId: unitId,
            unitId: unitId,
            regionNumber: sectionNumber,
            chapterNumber: unitNumber,
            title: unitTitle.isNotEmpty ? unitTitle : 'Bài học tiếng Trung',
            objective: loadedStages.firstOrNull?.learningObjective ??
                'Nắm vững kiến thức trong bài học.',
            missions: const [],
            overallMastery: avgMastery,
            bossUnlocked: allReqDone && boss != null,
            boss: boss,
          );
        }
      }

      if (isUnitCompleted) {
        try {
          final loadedNextUnit = await _journeyRepo.getNextUnit(unitId);
          if (!isClosed && request == _loadRequest) {
            nextUnit.value = loadedNextUnit;
          }
        } catch (e) {
          debugPrint('[UnitOverviewController] getNextUnit failed: $e');
        }
      } else {
        nextUnit.value = null;
      }
    } catch (e) {
      if (!isClosed && request == _loadRequest) {
        errorMessage.value = 'Lỗi kết nối khi tải bài học: $e';
      }
      if (rethrowFailure) rethrow;
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

  bool get hasBoss =>
      stages.any((s) =>
          s.activityType == LearningStageActivityType.boss ||
          s.bossStage != null) ||
      chapter.value?.boss != null;

  bool get isBossDefeated {
    final bossStage = stages
        .where((s) =>
            s.activityType == LearningStageActivityType.boss ||
            s.bossStage != null)
        .firstOrNull;
    if (bossStage != null) {
      return bossStage.isCompleted;
    }
    return false;
  }

  bool get isUnitCompleted {
    if (stages.isNotEmpty) {
      if (hasBoss) {
        return isBossDefeated;
      }
      return areRequiredStagesCompleted && completedStageCount > 0;
    }
    final c = chapter.value;
    if (c == null) return false;
    return c.missions.isNotEmpty && c.completedMissions >= c.missions.length;
  }

  LearningStageViewModel? get nextPlayableStage {
    if (stages.isEmpty) return null;
    final nonBossStages = stages
        .where((s) => s.activityType != LearningStageActivityType.boss)
        .toList();
    if (nonBossStages.isEmpty) return stages.first;
    return nonBossStages.firstWhere(
      (s) => s.isAvailable && !s.isCompleted,
      orElse: () => nonBossStages.firstWhere(
        (s) => !s.isCompleted,
        orElse: () => nonBossStages.first,
      ),
    );
  }

  int get nextPlayableStageNumber {
    final next = nextPlayableStage;
    if (next == null) return 1;
    final idx = stages.indexOf(next);
    return idx >= 0 ? idx + 1 : 1;
  }

  int get completedStageCount => stages.where((s) => s.isCompleted).length;
  int get totalStageCount => stages.length;

  bool get areRequiredStagesCompleted =>
      stages.where((s) => s.isRequired).every((s) => s.isCompleted);

  ChapterMission? get nextPlayableMission {
    final c = chapter.value;
    if (c == null || c.missions.isEmpty) return null;
    return c.missions.firstWhere(
      (m) => !m.isCompleted,
      orElse: () => c.missions.first,
    );
  }

  bool get isBossReady {
    if (isUnitCompleted) return false;
    final bossStage = stages
        .where((s) =>
            s.activityType == LearningStageActivityType.boss ||
            s.bossStage != null)
        .firstOrNull;
    if (bossStage != null) {
      return bossStage.isAvailable && !bossStage.isCompleted;
    }
    final c = chapter.value;
    if (c == null) return false;
    return c.bossUnlocked && c.boss != null;
  }
}
