import 'dart:async';

import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/model/learning_result.dart';
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
  final learningResult = Rxn<LearningResult>();

  String? _attemptId;
  DateTime? _startedAt;
  int? _activeCharacterId;

  Future<HanziCharacter?> loadCharacter(int id) async {
    if (isClosed) return null;
    final character = await _database.getCharacterForWritingById(id);
    return isClosed ? null : character;
  }

  Future<void> beginPractice(int characterId) async {
    if (_attemptId != null && learningResult.value == null) {
      await _rewardService.abandonAttempt(
        _attemptId!,
        metadata: const <String, dynamic>{'reason': 'character_changed'},
      );
    }
    _attemptId =
        'hanzi_${characterId}_${DateTime.now().microsecondsSinceEpoch}';
    _startedAt = DateTime.now();
    _activeCharacterId = characterId;
    learningResult.value = null;
    await _rewardService.startHanziAttempt(
      characterId: characterId,
      attemptId: _attemptId!,
    );
  }

  Future<void> saveProgress(
      int characterId, List<HanziRoundResult> rounds) async {
    if (isClosed) return;
    final totalScore = rounds.fold(0.0, (sum, round) => sum + round.score);
    final averageScore = rounds.isEmpty ? 0.0 : totalScore / rounds.length;
    final attempts = rounds.fold(0, (sum, round) => sum + round.attemptCount);
    try {
      final attemptId = _attemptId ??
          'hanzi_${characterId}_${DateTime.now().microsecondsSinceEpoch}';
      learningResult.value = await _rewardService.processHanziReward(
        characterId: characterId,
        attemptId: attemptId,
        bestScore: averageScore,
        attempts: attempts,
        durationSeconds:
            DateTime.now().difference(_startedAt ?? DateTime.now()).inSeconds,
      );

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshStats();
      }
    } catch (_) {
      // The user can retry completion with the same idempotent attempt id.
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

  @override
  void onClose() {
    if (_attemptId != null && learningResult.value == null) {
      unawaited(
        _rewardService.abandonAttempt(
          _attemptId!,
          metadata: <String, dynamic>{
            'reason': 'hanzi_closed',
            if (_activeCharacterId != null) 'character_id': _activeCharacterId,
          },
        ),
      );
    }
    super.onClose();
  }
}
