import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/data/learning_history_repository.dart';
import '../../../core/learning/service/learning_mastery_service.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';
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
    LearningProgressSyncService? syncService,
    Future<Map<String, num>> Function()? statsLoader,
  })  : _journeyRepository = journeyRepository ?? CloudHomeJourneyRepository(),
        _reviewRepository = reviewRepository ?? SupabaseReviewRepository(),
        _historyRepo = historyRepository ?? SupabaseLearningHistoryRepository(),
        _masteryService = masteryService ?? DefaultLearningMasteryService(),
        _syncService = syncService ?? _registeredSyncService(),
        _statsLoader = statsLoader ?? DbHelper.instance.getStats;

  final HomeJourneyRepository _journeyRepository;
  final ReviewRepository _reviewRepository;
  final LearningHistoryRepository _historyRepo;
  final LearningMasteryService _masteryService;
  final LearningProgressSyncService? _syncService;
  final Future<Map<String, num>> Function() _statsLoader;

  LearningSyncRegistration? _syncRegistration;
  int _refreshRequest = 0;
  bool _hasLoaded = false;

  static LearningProgressSyncService? _registeredSyncService() {
    if (!Get.isRegistered<LearningProgressSyncService>()) return null;
    return Get.find<LearningProgressSyncService>();
  }

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
    _syncRegistration = _syncService?.registerRefresher(
      owner: 'home',
      domains: const <LearningDomain>{
        LearningDomain.journey,
        LearningDomain.stats,
        LearningDomain.history,
        LearningDomain.mastery,
        LearningDomain.review,
        LearningDomain.profile,
        LearningDomain.game,
        LearningDomain.session,
        LearningDomain.identity,
      },
      refresh: _handleLearningEvent,
    );
    refreshStats();
  }

  Future<void> _handleLearningEvent(LearningDomainEvent event) async {
    if (event.type == LearningDomainEventType.identityChanged) {
      stats.clear();
      journey.value = null;
      reviewSummary.value = null;
      todayXp.value = 0;
      lifetimeXp.value = 0;
      streak.value = 0;
      sevenDayXp.clear();
      recentTimeline.clear();
      masteryProfile.value = const SkillMasteryProfile();
      _hasLoaded = false;
    }
    await refreshStats(rethrowFailure: true);
  }

  Future<void> refreshStats({bool rethrowFailure = false}) async {
    final request = ++_refreshRequest;
    // Chỉ hiện skeleton ở lần tải đầu, các lần sau làm mới ngầm.
    isJourneyLoading.value = !_hasLoaded;
    journeyError.value = null;
    final failures = <Object>[];
    bool isCurrent() => !isClosed && request == _refreshRequest;

    Future<void> loadSlice<T>(
      Future<T> Function() load,
      void Function(T value) assign,
    ) async {
      try {
        final value = await load();
        if (isCurrent()) assign(value);
      } catch (error) {
        failures.add(error);
      }
    }

    await Future.wait<void>([
      loadSlice<Map<String, num>>(_statsLoader, (dbStats) {
        stats.value = dbStats;
        lifetimeXp.value = dbStats['totalExp']?.toInt() ?? 0;
        streak.value = dbStats['streak']?.toInt() ?? 0;
      }),
      loadSlice<HomeJourney?>(
        _journeyRepository.loadJourney,
        (value) => journey.value = value,
      ),
      loadSlice<ReviewSummary>(
        _reviewRepository.loadReviewSummary,
        (value) => reviewSummary.value = value,
      ),
      loadSlice<int>(
        _historyRepo.fetchTodayXp,
        (value) => todayXp.value = value,
      ),
      loadSlice<List<Map<String, dynamic>>>(
        _historyRepo.fetch7DayXpActivity,
        sevenDayXp.assignAll,
      ),
      loadSlice<List<Map<String, dynamic>>>(
        () => _historyRepo.fetchRecentTimeline(limit: 8),
        recentTimeline.assignAll,
      ),
      loadSlice<SkillMasteryProfile>(
        _masteryService.getOverallSkillMastery,
        (value) => masteryProfile.value = value,
      ),
    ]);

    if (!isCurrent()) return;
    if (failures.isNotEmpty) {
      journeyError.value = failures.length == 1
          ? 'Một phần tiến độ chưa thể cập nhật.'
          : 'Một số dữ liệu tiến độ chưa thể cập nhật.';
    }
    isJourneyLoading.value = false;
    _hasLoaded = true;
    if (failures.isNotEmpty && rethrowFailure) throw failures.first;
  }

  void setIndex(int index) {
    currentIndex.value = index;
  }

  @override
  void onClose() {
    _refreshRequest++;
    _syncRegistration?.dispose();
    super.onClose();
  }
}
