import 'package:get/get.dart';

import '../controller/vocabulary_adventure_controller.dart';
import '../data/vocabulary_adventure_repository.dart';
import '../service/vocabulary_audio_service.dart';

class VocabularyAdventureBinding extends Bindings {
  VocabularyAdventureBinding({
    required this.levelId,
    required this.gameId,
    required this.gameName,
  });

  final String levelId;
  final int gameId;
  final String gameName;

  @override
  void dependencies() {
    Get.lazyPut<VocabularyAdventureRepository>(
      SupabaseVocabularyAdventureRepository.new,
    );
    Get.lazyPut<VocabularyAudioService>(FlutterVocabularyAudioService.new);
    Get.lazyPut<VocabularyAdventureController>(
      () => VocabularyAdventureController(
        levelId: levelId,
        gameId: gameId,
        gameName: gameName,
        repository: Get.find<VocabularyAdventureRepository>(),
        audioService: Get.find<VocabularyAudioService>(),
      ),
    );
  }
}
