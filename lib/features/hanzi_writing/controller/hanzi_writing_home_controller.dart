import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/hanzi_character.dart';
import '../services/hanzi_progress_snapshot_service.dart';

class HanziWritingHomeController extends GetxController {
  HanziWritingHomeController({
    DbHelper? database,
    HanziProgressSnapshotService? progressService,
  })  : _database = database ?? DbHelper.instance,
        _progressService =
            progressService ?? HanziProgressSnapshotService();
  final DbHelper _database;
  final HanziProgressSnapshotService _progressService;
  final characters = <HanziCharacter>[].obs;
  final isLoading = true.obs;
  int _request = 0;

  void invalidateSearch() => _request++;

  Future<void> loadCharacters({required String keyword, int? hskLevel}) async {
    if (isClosed) return;
    final request = ++_request;
    isLoading.value = true;
    try {
      final result = await _database.getCharactersForWriting(
          keyword: keyword.isEmpty ? null : keyword, hskLevel: hskLevel);
      final snapshots = await _progressService.loadForCharacters(
        result.map((character) => character.id),
      );
      if (isClosed || request != _request) return;
      characters.assignAll(
        result.map((character) {
          final progress = snapshots[character.id];
          if (progress == null) return character;
          return character.copyWithProgress(
            practiceCount: progress.practiceCount,
            bestScore: progress.bestScore,
            lastScore: progress.lastScore,
            nextReviewAt: progress.nextReviewAt,
          );
        }),
      );
    } catch (_) {
      // Preserve the existing empty/previous list on a failed search.
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }
}
