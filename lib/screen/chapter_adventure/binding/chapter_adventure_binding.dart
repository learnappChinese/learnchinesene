import 'package:get/get.dart';

import '../controller/chapter_adventure_controller.dart';
import '../data/chapter_adventure_repository.dart';

class ChapterAdventureBinding extends Bindings {
  ChapterAdventureBinding({required this.levelId});

  final String levelId;

  @override
  void dependencies() {
    Get.lazyPut<ChapterAdventureRepository>(
      () => SupabaseChapterAdventureRepository(),
    );
    Get.lazyPut<ChapterAdventureController>(
      () => ChapterAdventureController(
        levelId: levelId,
        repository: Get.find<ChapterAdventureRepository>(),
      ),
    );
  }
}
