import 'package:get/get.dart';

import '../data/unit_learning_repository.dart';
import '../model/unit_learning_node.dart';

class UnitPathController extends GetxController {
  UnitPathController({
    required this.unitId,
    required UnitLearningRepository repository,
  }) : _repository = repository;

  final String unitId;
  final UnitLearningRepository _repository;

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
    final result = <UnitLearningNode>[];
    var allPreviousLearningCompleted = true;
    var firstLearningSeen = false;

    for (final node in loaded) {
      if (node.isBoss) {
        final unlocked = node.completed ||
            node.rawUnlocked ||
            (firstLearningSeen && allPreviousLearningCompleted);
        result.add(
          node.copyWith(
            state: node.completed
                ? UnitLearningNodeState.completed
                : unlocked
                    ? UnitLearningNodeState.available
                    : UnitLearningNodeState.locked,
          ),
        );
        continue;
      }

      final unlocked =
          node.rawUnlocked || (firstLearningSeen && allPreviousLearningCompleted);
      final state = node.completed
          ? UnitLearningNodeState.completed
          : node.inProgress
              ? UnitLearningNodeState.inProgress
              : unlocked
                  ? UnitLearningNodeState.available
                  : UnitLearningNodeState.locked;

      result.add(node.copyWith(state: state));
      firstLearningSeen = true;
      if (!node.completed) allPreviousLearningCompleted = false;
    }

    return result;
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
