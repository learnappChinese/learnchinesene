import 'dart:async';

import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../../../core/models/hanzi_character.dart';
import '../models/hanzi_practice_config.dart';

class HanziWritingController extends GetxController {
  HanziWritingController({
    DbHelper? database,
    LearningRewardService? rewardService,
    List<int>? characterSequence,
    this.hskLevel,
    this.unitId,
  })  : _database = database ?? DbHelper.instance,
        _rewardService = rewardService ?? LearningRewardService(),
        characterSequence =
            characterSequence != null ? List.of(characterSequence) : <int>[];

  final DbHelper _database;
  final LearningRewardService _rewardService;
  final List<int> characterSequence;
  final int? hskLevel;
  final int? unitId;
  final learningResult = Rxn<LearningResult>();

  String? _attemptId;
  DateTime? _startedAt;
  int? _activeCharacterId;

  void setSequence(List<int> sequence) {
    characterSequence
      ..clear()
      ..addAll(sequence);
  }

  Future<HanziCharacter?> loadCharacter(int id) async {
    if (isClosed) return null;
    final character = await _database.getCharacterForWritingById(id);
    if (isClosed) return null;

    // Tải trước (prefetch) chữ tiếp theo trong chuỗi nếu có
    if (characterSequence.isNotEmpty) {
      final idx = characterSequence.indexOf(id);
      if (idx >= 0 && idx < characterSequence.length - 1) {
        final nextId = characterSequence[idx + 1];
        unawaited(_database.getCharacterForWritingById(nextId));
      }
    }
    return character;
  }

  Future<void> beginPractice(
    int characterId, {
    LearningSourceContext? sourceContext,
  }) async {
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

    final String? rewardUnitId =
        (sourceContext?.isCurriculum == true) ? sourceContext!.duoUnitId : null;
    final String? rewardLevelId =
        (sourceContext?.isCurriculum == true) ? sourceContext!.levelId : null;

    await _rewardService.startHanziAttempt(
      characterId: characterId,
      attemptId: _attemptId!,
      unitId: rewardUnitId,
      levelId: rewardLevelId,
    );
  }

  Future<void> saveProgress(
    int characterId,
    List<HanziRoundResult> rounds, {
    LearningSourceContext? sourceContext,
  }) async {
    if (isClosed) return;
    final totalScore = rounds.fold(0.0, (sum, round) => sum + round.score);
    final averageScore = rounds.isEmpty ? 0.0 : totalScore / rounds.length;
    final attempts = rounds.fold(0, (sum, round) => sum + round.attemptCount);
    try {
      final attemptId = _attemptId ??
          'hanzi_${characterId}_${DateTime.now().microsecondsSinceEpoch}';

      final String? rewardUnitId = (sourceContext?.isCurriculum == true)
          ? sourceContext!.duoUnitId
          : null;
      final String? rewardLevelId =
          (sourceContext?.isCurriculum == true) ? sourceContext!.levelId : null;

      learningResult.value = await _rewardService.processHanziReward(
        characterId: characterId,
        attemptId: attemptId,
        bestScore: averageScore,
        attempts: attempts,
        unitId: rewardUnitId,
        levelId: rewardLevelId,
        durationSeconds:
            DateTime.now().difference(_startedAt ?? DateTime.now()).inSeconds,
      );
    } catch (_) {
      // The user can retry completion with the same idempotent attempt id.
    }
  }

  /// Chuyển chữ kế tiếp mà KHÔNG tải lại toàn bộ từ điển hay toàn bộ chữ Hán.
  Future<({int? id, bool hasCharacters})> nextCharacter(int currentId) async {
    if (isClosed) return (id: null, hasCharacters: false);

    // 1. Nếu có chuỗi sequence định trước (từ Unit hoặc HSK screen) -> tra cứu O(1)
    if (characterSequence.isNotEmpty) {
      final index = characterSequence.indexOf(currentId);
      if (index >= 0 && index < characterSequence.length - 1) {
        return (id: characterSequence[index + 1], hasCharacters: true);
      }
      return (id: null, hasCharacters: true);
    }

    // 2. Tra cứu giới hạn theo Unit
    if (unitId != null) {
      final chars = await _database.getCharactersForWriting(unitId: unitId);
      if (isClosed) return (id: null, hasCharacters: false);
      final index = chars.indexWhere((c) => c.id == currentId);
      return (
        id: index >= 0 && index < chars.length - 1 ? chars[index + 1].id : null,
        hasCharacters: chars.isNotEmpty,
      );
    }

    // 3. Tra cứu giới hạn theo cấp HSK
    if (hskLevel != null) {
      final chars = await _database.getCharactersForWriting(hskLevel: hskLevel);
      if (isClosed) return (id: null, hasCharacters: false);
      final index = chars.indexWhere((c) => c.id == currentId);
      return (
        id: index >= 0 && index < chars.length - 1 ? chars[index + 1].id : null,
        hasCharacters: chars.isNotEmpty,
      );
    }

    // 4. Dự phòng: danh sách chữ Hán (đã tối ưu hóa qua cache)
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
