import '../database/duo_db_helper.dart';

class ProgressRepository {
  ProgressRepository({
    DuoDbHelper? database,
  }) : _database = database ?? DuoDbHelper.instance;

  final DuoDbHelper _database;

  Future<void> completeLevel({
    required int gameId,
    required String levelId,
    required int score,
    required int stars,
    required bool passed,
    int? nextGameId,
    String? nextLevelId,
  }) async {
    await _database.saveLevelProgress(
      gameId,
      levelId,
      score,
      stars,
      passed,
    );

    if (!passed || nextGameId == null || nextLevelId == null) return;

    await _database.unlockLevel(
      nextGameId,
      nextLevelId,
    );
  }
}
