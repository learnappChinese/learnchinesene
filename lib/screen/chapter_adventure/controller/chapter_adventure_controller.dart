import 'package:get/get.dart';

import '../data/chapter_adventure_repository.dart';
import '../model/chapter_adventure.dart';

class ChapterAdventureController extends GetxController {
  ChapterAdventureController({
    required this.levelId,
    required ChapterAdventureRepository repository,
  }) : _repository = repository;

  final String levelId;
  final ChapterAdventureRepository _repository;
  final chapter = Rxn<ChapterAdventure>();
  final isLoading = true.obs;
  final errorMessage = RxnString();
  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    loadChapter();
  }

  Future<void> loadChapter() async {
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.loadChapter(levelId);
      if (isClosed || request != _request) return;
      chapter.value = result;
    } catch (_) {
      if (!isClosed && request == _request) {
        errorMessage.value = 'Không thể mở bản đồ Chapter.';
      }
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }
}
