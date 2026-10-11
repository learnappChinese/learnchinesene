import 'package:get/get.dart';
import 'duo_game_repository.dart';

class DuoGamePathController extends GetxController {
  final int gameId;
  final String gameCode;
  DuoGamePathController({required this.gameId, required this.gameCode});

  final isLoading = true.obs;
  final levels = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadLevels();
  }

  Future<void> loadLevels() async {
    isLoading.value = true;
    try {
      final list =
          await DuoGameRepository.instance.getGameLevels(gameId, gameCode);
      levels.assignAll(list);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải Lộ trình Game: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
