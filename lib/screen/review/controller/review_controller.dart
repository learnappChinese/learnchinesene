import 'package:get/get.dart';
import '../../../core/models/word.dart';
import '../../../core/services/progress_service.dart';

class ReviewController extends GetxController {
  final progressService = ProgressService();
  final words = <Word>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWords();
  }

  Future<void> loadWords() async {
    isLoading.value = true;
    final res = await progressService.getReviewWords();
    words.value = res;
    isLoading.value = false;
  }
}
