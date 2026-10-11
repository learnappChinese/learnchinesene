import 'package:get/get.dart';
import '../database/db_helper.dart';
import '../learning/service/learning_progress_sync_service.dart';
import '../models/word.dart';

class ProgressService {
  final DbHelper _dbHelper;
  final LearningProgressSyncService? _syncService;

  ProgressService({
    DbHelper? dbHelper,
    LearningProgressSyncService? syncService,
  })  : _dbHelper = dbHelper ?? DbHelper.instance,
        _syncService = syncService ?? _registeredSyncService();

  static LearningProgressSyncService? _registeredSyncService() {
    if (!Get.isRegistered<LearningProgressSyncService>()) return null;
    return Get.find<LearningProgressSyncService>();
  }

  Future<void> submitAnswer({
    required int wordId,
    required bool isCorrect,
    int level = 1,
  }) async {
    await _dbHelper.upsertProgress(
      wordId: wordId,
      isCorrect: isCorrect,
      level: level,
    );
    try {
      await _syncService?.syncAfterLexiconChange();
    } catch (_) {}
  }

  Future<void> markLearned(int wordId) async {
    await _dbHelper.markLearned(wordId);
    try {
      await _syncService?.syncAfterLexiconChange();
    } catch (_) {}
  }

  Future<List<Word>> getReviewWords() {
    return _dbHelper.getReviewWords();
  }
}

