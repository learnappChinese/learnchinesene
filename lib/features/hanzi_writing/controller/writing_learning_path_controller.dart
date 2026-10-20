import 'package:get/get.dart';

import '../models/writing_path_models.dart';
import '../services/writing_learning_path_repository.dart';

class WritingLearningPathController extends GetxController {
  WritingLearningPathController({WritingLearningPathRepository? repository})
      : _repository = repository ?? WritingLearningPathRepository();

  final WritingLearningPathRepository _repository;

  final catalog = <WritingHskCatalogItem>[].obs;
  final loadedPaths = <WritingHskPath>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();

  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final items = await _repository.loadHskCatalog();
      if (isClosed || request != _request) return;
      catalog.assignAll(items);
      loadedPaths.clear();
      if (items.isNotEmpty) {
        final first = await _repository.loadHskPath(
          items.first,
          previousLevelCompleted: true,
        );
        if (isClosed || request != _request) return;
        loadedPaths.add(first);
      }
    } catch (error) {
      if (!isClosed && request == _request) {
        errorMessage.value = 'Không tải được lộ trình viết chữ: $error';
      }
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  Future<void> refreshCurrent() async {
    final currentIds = loadedPaths.map((path) => path.catalog.id).toList();
    if (currentIds.isEmpty) {
      await loadInitial();
      return;
    }
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final refreshed = <WritingHskPath>[];
      var previousCompleted = true;
      for (final id in currentIds) {
        final item = catalog.firstWhereOrNull((entry) => entry.id == id);
        if (item == null) continue;
        final path = await _repository.loadHskPath(
          item,
          previousLevelCompleted: previousCompleted,
        );
        if (isClosed || request != _request) return;
        refreshed.add(path);
        previousCompleted = path.completed;
      }
      loadedPaths.assignAll(refreshed);
    } catch (error) {
      if (!isClosed && request == _request) {
        errorMessage.value = 'Không làm mới được tiến độ: $error';
      }
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  Future<void> loadNextHsk() async {
    if (isLoading.value || isLoadingMore.value || catalog.isEmpty) return;
    final nextIndex = loadedPaths.length;
    if (nextIndex >= catalog.length) return;
    isLoadingMore.value = true;
    try {
      final previousCompleted =
          loadedPaths.isEmpty || loadedPaths.last.completed;
      final path = await _repository.loadHskPath(
        catalog[nextIndex],
        previousLevelCompleted: previousCompleted,
      );
      if (!isClosed && loadedPaths.length == nextIndex) {
        loadedPaths.add(path);
      }
    } catch (_) {
      // Keep already loaded path usable; the user can retry by scrolling/refresh.
    } finally {
      if (!isClosed) isLoadingMore.value = false;
    }
  }

  Future<void> jumpToHsk(int hskId) async {
    final target = catalog.indexWhere((entry) => entry.id == hskId);
    if (target < 0) return;
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final next = <WritingHskPath>[];
      var previousCompleted = true;
      for (var i = 0; i <= target; i++) {
        final path = await _repository.loadHskPath(
          catalog[i],
          previousLevelCompleted: previousCompleted,
        );
        if (isClosed || request != _request) return;
        next.add(path);
        previousCompleted = path.completed;
      }
      loadedPaths.assignAll(next);
    } catch (error) {
      if (!isClosed && request == _request) {
        errorMessage.value = 'Không chuyển được tới HSK đã chọn: $error';
      }
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  WritingPathNode? get recommendedNode {
    final now = DateTime.now();
    for (final path in loadedPaths) {
      for (final section in path.sections) {
        for (final node in section.nodes) {
          final due = node.progress.nextReviewAt;
          if (node.state == WritingPathNodeState.completed &&
              due != null &&
              !due.isAfter(now)) {
            return node;
          }
        }
      }
    }
    for (final path in loadedPaths) {
      for (final section in path.sections) {
        for (final node in section.nodes) {
          if (node.state == WritingPathNodeState.current) return node;
        }
      }
    }
    return null;
  }
}
