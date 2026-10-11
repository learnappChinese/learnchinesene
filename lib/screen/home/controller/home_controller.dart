import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/data/learning_history_repository.dart';
import '../../../core/learning/service/learning_mastery_service.dart';
import '../data/home_journey_repository.dart';
import '../model/home_journey.dart';
import '../../review/data/review_repository.dart';
import '../../review/model/review_item.dart';

class HomeController extends GetxController {
  HomeController({
    HomeJourneyRepository? journeyRepository,
    ReviewRepository? reviewRepository,
    LearningHistoryRepository? historyRepository,
    LearningMasteryService? masteryService,
  })  : _journeyRepository = journeyRepository ?? CloudHomeJourneyRepository(),
        _reviewRepository = reviewRepository ?? SupabaseReviewRepository(),
        _historyRepo = historyRepository ?? SupabaseLearningHistoryRepository(),
        _masteryService = masteryService ?? DefaultLearningMasteryService();

  final HomeJourneyRepository _journeyRepository;
  final ReviewRepository _reviewRepository;
  final LearningHistoryRepository _historyRepo;
  final LearningMasteryService _masteryService;

  final currentIndex = 0.obs;
  final stats = <String, num>{}.obs;
  final journey = Rxn<HomeJourney>();
  final reviewSummary = Rxn<ReviewSummary>();
  final isJourneyLoading = true.obs;
  final journeyError = RxnString();

  final todayXp = 0.obs;
  final lifetimeXp = 0.obs;
  final streak = 0.obs;
  final masteryProfile = const SkillMasteryProfile().obs;
  final sevenDayXp = <Map<String, dynamic>>[].obs;
  final recentTimeline = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshStats();
  }

  Future<void> refreshStats() async {
    if (isJourneyLoading.value && journey.value != null) return;
    isJourneyLoading.value = true;
    journeyError.value = null;
    try {
      final results = await Future.wait<dynamic>([
        DbHelper.instance.getStats(),
        _journeyRepository.loadJourney(),
        _reviewRepository.loadReviewSummary(),
        _historyRepo.fetchTodayXp(),
        _historyRepo.fetch7DayXpActivity(),
        _historyRepo.fetchRecentTimeline(limit: 8),
        _masteryService.getOverallSkillMastery(),
      ]);
      if (isClosed) return;
      final dbStats = results[0] as Map<String, num>;
      stats.value = dbStats;
      journey.value = results[1] as HomeJourney?;
      reviewSummary.value = results[2] as ReviewSummary;
      todayXp.value = results[3] as int;
      sevenDayXp.assignAll(results[4] as List<Map<String, dynamic>>);
      recentTimeline.assignAll(results[5] as List<Map<String, dynamic>>);
      masteryProfile.value = results[6] as SkillMasteryProfile;

      lifetimeXp.value = dbStats['totalExp']?.toInt() ?? 0;
      streak.value = dbStats['streak']?.toInt() ?? 0;
    } catch (_) {
      if (!isClosed) {
        journeyError.value = 'Không thể mở bản đồ hành trình.';
      }
    } finally {
      if (!isClosed) isJourneyLoading.value = false;
    }
  }

  void setIndex(int index) {
    currentIndex.value = index;
  }
}
