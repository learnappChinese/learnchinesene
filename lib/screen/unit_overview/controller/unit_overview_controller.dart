import 'package:get/get.dart';
import '../../../core/learning/data/learning_journey_repository.dart';
import '../../chapter_adventure/model/chapter_adventure.dart';

import '../../../core/learning/model/learning_stage_models.dart';

class UnitOverviewController extends GetxController {
  UnitOverviewController({
    LearningJourneyRepository? journeyRepository,
  }) : _journeyRepo = journeyRepository ?? SupabaseLearningJourneyRepository();

  final LearningJourneyRepository _journeyRepo;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final chapter = Rxn<ChapterAdventure>();
  final stages = <LearningStageViewModel>[].obs;

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
    loadUnitOverview();
  }

  Future<void> loadUnitOverview() async {
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
    } catch (e) {
      errorMessage.value = 'Lỗi kết nối khi tải bài học: $e';
    } finally {
      isLoading.value = false;
    }
  }

  LearningStageViewModel? get nextPlayableStage {
    if (stages.isEmpty) return null;
    return stages.firstWhere(
      (s) => s.isAvailable && !s.isCompleted,
      orElse: () => stages.first,
    );
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
    final c = chapter.value;
    if (c == null) return false;
    return c.bossUnlocked && c.boss != null;
  }
}
