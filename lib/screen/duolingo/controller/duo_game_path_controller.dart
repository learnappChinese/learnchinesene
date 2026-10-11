import 'package:get/get.dart';
import 'duo_game_repository.dart';

class DuoGamePathController extends GetxController {
  final int gameId;
  final String gameCode;
  DuoGamePathController({required this.gameId, required this.gameCode});

  final isLoading = true.obs;
  final allLevels = <Map<String, dynamic>>[].obs;
  final selectedSection = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadLevels();
  }

  List<int> get availableSections {
    final set = allLevels
        .map((l) => (l['section_number'] as num?)?.toInt() ?? 1)
        .toSet()
        .toList();
    set.sort();
    return set.isEmpty ? [1] : set;
  }

  List<Map<String, dynamic>> get levels {
    final filtered = allLevels
        .where((l) =>
            (l['section_number'] as num?)?.toInt() == selectedSection.value)
        .toList();
    return filtered.isNotEmpty ? filtered : allLevels;
  }

  Map<String, dynamic>? get currentLevel {
    final currentList = levels;
    if (currentList.isEmpty) return null;
    return currentList.firstWhere(
      (l) => l['is_unlocked'] == 1 && l['is_completed'] != 1,
      orElse: () => currentList.first,
    );
  }

  Future<void> loadLevels() async {
    isLoading.value = true;
    try {
      final list =
          await DuoGameRepository.instance.getGameLevels(gameId, gameCode);
      allLevels.assignAll(list);

      // Auto select current active section
      final active = list.firstWhere(
        (l) => l['is_unlocked'] == 1 && l['is_completed'] != 1,
        orElse: () => list.isNotEmpty ? list.first : <String, dynamic>{},
      );
      if (active.isNotEmpty && active['section_number'] != null) {
        selectedSection.value = (active['section_number'] as num).toInt();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải Lộ trình Game: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectSection(int sec) {
    selectedSection.value = sec;
  }
}
