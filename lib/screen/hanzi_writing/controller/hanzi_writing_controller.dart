import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../../../core/models/hanzi_character.dart';
import '../../home/controller/home_controller.dart';
import '../models/hanzi_practice_config.dart';

class HanziWritingController extends GetxController {
  HanziWritingController(
      {DbHelper? database, LearningRewardService? rewardService})
      : _database = database ?? DbHelper.instance,
        _rewardService = rewardService ?? LearningRewardService();

  final DbHelper _database;
  final LearningRewardService _rewardService;

  Future<HanziCharacter?> loadCharacter(int id) async {
    if (isClosed) return null;
    final character = await _database.getCharacterForWritingById(id);
    return isClosed ? null : character;
  }

  Future<void> saveProgress(
      int characterId, List<HanziRoundResult> rounds) async {
    if (isClosed) return;
    final totalScore = rounds.fold(0.0, (sum, round) => sum + round.score);
    final averageScore = rounds.isEmpty ? 0.0 : totalScore / rounds.length;
    final attempts = rounds.fold(0, (sum, round) => sum + round.attemptCount);
    try {
      await _database.saveHanziWritingProgress(
        characterId: characterId,
        score: averageScore,
        attempts: attempts,
      );

      final attId =
          'hanzi_${characterId}_${DateTime.now().millisecondsSinceEpoch}';
      await _rewardService.processHanziReward(
        characterId: characterId,
        attemptId: attId,
        bestScore: averageScore,
        attempts: attempts,
      );

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshStats();
      }
    } catch (_) {
      // Session completion remains available when saving fails.
    }
  }

  Future<({int? id, bool hasCharacters})> nextCharacter(int currentId) async {
    if (isClosed) return (id: null, hasCharacters: false);
    final characters = await _database.getCharactersForWriting();
    if (isClosed) return (id: null, hasCharacters: false);
    final index =
        characters.indexWhere((character) => character.id == currentId);
    return (
      id: index >= 0 && index < characters.length - 1
          ? characters[index + 1].id
          : null,
      hasCharacters: characters.isNotEmpty,
    );
  }
}
