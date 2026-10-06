import 'package:get/get.dart';

import '../data/unit_learning_repository.dart';
import '../model/unit_learning_node.dart';

class UnitPathController extends GetxController {
  UnitPathController({
    required this.unitId,
    required UnitLearningSource repository,
  }) : _repository = repository;

  final String unitId;
  final UnitLearningSource _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final nodes = <UnitLearningNode>[].obs;

  String get unitTitle =>
      nodes.isEmpty ? 'Hành trình học' : nodes.first.unitTitle;

  int get completedMissionCount =>
      nodes.where((node) => !node.isBoss && node.completed).length;

  int get missionCount => nodes.where((node) => !node.isBoss).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await _repository.loadUnitPath(unitId);
      if (isClosed) return;
      nodes.assignAll(_resolveStates(loaded));
    } catch (_) {
      if (isClosed) return;
      errorMessage.value = 'Không thể tải hành trình Unit từ Supabase.';
      nodes.clear();
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  List<UnitLearningNode> _resolveStates(List<UnitLearningNode> loaded) {
    return loaded.map((node) {
      final state = node.completed
          ? UnitLearningNodeState.completed
          : node.inProgress
              ? UnitLearningNodeState.inProgress
              : node.rawUnlocked
                  ? UnitLearningNodeState.available
                  : UnitLearningNodeState.locked;
      return node.copyWith(state: state);
    }).toList(growable: false);
  }

  UnitLearningNode? nextLearningNodeAfter(UnitLearningNode current) {
    final learning = nodes.where((node) => !node.isBoss).toList();
    final index = learning.indexWhere(
      (node) =>
          node.gameId == current.gameId && node.levelId == current.levelId,
    );
    if (index < 0 || index + 1 >= learning.length) return null;
    return learning[index + 1];
  }
}
