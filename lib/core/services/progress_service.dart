import '../database/db_helper.dart';
import '../models/word.dart';

class ProgressService {
  final DbHelper _dbHelper;

  ProgressService({DbHelper? dbHelper})
      : _dbHelper = dbHelper ?? DbHelper.instance;

  Future<void> submitAnswer({
    required int wordId,
    required bool isCorrect,
    int level = 1,
  }) {
    return _dbHelper.upsertProgress(
      wordId: wordId,
      isCorrect: isCorrect,
      level: level,
    );
  }

  Future<void> markLearned(int wordId) {
    return _dbHelper.markLearned(wordId);
  }

  Future<List<Word>> getReviewWords() {
    return _dbHelper.getReviewWords();
  }
}
