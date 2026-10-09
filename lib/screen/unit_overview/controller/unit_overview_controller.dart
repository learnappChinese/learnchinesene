import 'package:get/get.dart';
import '../../../core/learning/data/learning_journey_repository.dart';
import '../../chapter_adventure/model/chapter_adventure.dart';

class UnitOverviewController extends GetxController {
  UnitOverviewController({
    LearningJourneyRepository? journeyRepository,
  }) : _journeyRepo = journeyRepository ?? SupabaseLearningJourneyRepository();

  final LearningJourneyRepository _journeyRepo;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final chapter = Rxn<ChapterAdventure>();

  String unitId = 'sec_1_unit_1';
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
    try {
      final journey = await _journeyRepo.getUnitJourney(unitId);
      if (journey == null) {
        errorMessage.value = 'Không tìm thấy dữ liệu cho bài học này.';
      } else {
        chapter.value = journey;
        if (unitTitle.isEmpty) {
          unitTitle = journey.title;
        }
        sectionNumber = journey.regionNumber;
        unitNumber = journey.chapterNumber;
      }
    } catch (e) {
      errorMessage.value = 'Lỗi kết nối khi tải bài học: $e';
    } finally {
      isLoading.value = false;
    }
  }

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
