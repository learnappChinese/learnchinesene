import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../data/home_journey_repository.dart';
import '../model/home_journey.dart';
import '../../review/data/review_repository.dart';
import '../../review/model/review_item.dart';

class HomeController extends GetxController {
  HomeController({
    HomeJourneyRepository? journeyRepository,
    ReviewRepository? reviewRepository,
  })  : _journeyRepository = journeyRepository ?? CloudHomeJourneyRepository(),
        _reviewRepository = reviewRepository ?? SupabaseReviewRepository();

  final HomeJourneyRepository _journeyRepository;
  final ReviewRepository _reviewRepository;
  final currentIndex = 0.obs;
  final stats = <String, num>{}.obs;
  final journey = Rxn<HomeJourney>();
  final reviewSummary = Rxn<ReviewSummary>();
  final isJourneyLoading = true.obs;
  final journeyError = RxnString();

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
      ]);
      if (isClosed) return;
      stats.value = results[0] as Map<String, num>;
      journey.value = results[1] as HomeJourney?;
      reviewSummary.value = results[2] as ReviewSummary;
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
