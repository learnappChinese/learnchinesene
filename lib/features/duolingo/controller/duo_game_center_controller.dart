import 'package:get/get.dart';
import 'duo_game_repository.dart';

class DuoGameCenterController extends GetxController {
  final isLoading = true.obs;
  final games = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadGames();
  }

  Future<void> loadGames() async {
    isLoading.value = true;
    try {
      final list = await DuoGameRepository.instance.getGames();
      games.assignAll(list);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải Game Center: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
