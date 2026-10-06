import '../../screen/duolingo/controller/duo_game_repository.dart';

class ProgressRepository {
  ProgressRepository({
    DuoGameRepository? duoRepository,
  }) : _duoRepository = duoRepository ?? DuoGameRepository.instance;

  final DuoGameRepository _duoRepository;

  Future<void> completeLevel({
    required int gameId,
    required String levelId,
    required int score,
    required int stars,
    required bool passed,
    int? nextGameId,
    String? nextLevelId,
  }) async {
    await _duoRepository.saveProgress(
      gameId,
      levelId,
      score,
      stars,
      passed,
    );

    if (!passed || nextGameId == null || nextLevelId == null) return;

    await _duoRepository.unlockLevel(
      nextGameId,
      nextLevelId,
    );
  }
}
