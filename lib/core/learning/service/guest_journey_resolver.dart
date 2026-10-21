import '../data/guest_learning_progress_store.dart';
import '../model/learning_journey_models.dart';
import '../model/unit_mastery.dart';

/// Dependency-aware resolver that merges authoritative Curriculum metadata
/// with Guest persistent progress to compute canonical unlock states.
class GuestJourneyResolver {
  const GuestJourneyResolver();

  /// Overlays raw curriculum path rows with Guest persistent state.
  Future<List<Map<String, dynamic>>> overlayUnitPath({
    required String unitId,
    required List<Map<String, dynamic>> pathRows,
    required GuestLearningProgressStore store,
    double overallMastery = 0.0,
    bool isUnitUnlocked = true,
  }) async {
    await store.ensureMigrated();
    if (pathRows.isEmpty) return const [];

    final learningRows = pathRows
        .where((r) => r['node_type'] == 'learning')
        .toList(growable: false)
      ..sort((a, b) =>
          _asInt(a['node_order'], 1).compareTo(_asInt(b['node_order'], 1)));

    final bossRows =
        pathRows.where((r) => r['node_type'] == 'boss').toList(growable: false);

    final passedKeys = await store.getAllPassedStageKeys();
    final updatedLearningRows = <Map<String, dynamic>>[];

    // Pass 1: compute completion and unlock for learning nodes sequentially
    for (int i = 0; i < learningRows.length; i++) {
      final row = learningRows[i];
      final gameId = _asInt(row['game_id']);
      final levelId = '${row['level_id'] ?? ''}'.trim();

      final stageRecord = await store.getStageRecord(gameId, levelId);
      final isCompleted = stageRecord != null && stageRecord['passed'] == true;

      bool isUnlocked;
      String? lockReason;

      if (!isUnitUnlocked) {
        isUnlocked = false;
        lockReason = 'chapter_locked';
      } else if (i == 0) {
        // First learning node in an unlocked unit is always unlocked
        isUnlocked = true;
        lockReason = null;
      } else {
        // Lộ trình tuần tự: Ải i bắt buộc phải hoàn thành Ải i - 1 trước đó
        final prevRow = updatedLearningRows[i - 1];
        final prevCompleted = prevRow['is_completed'] == true;

        if (!prevCompleted) {
          isUnlocked = false;
          lockReason = 'complete_previous';
        } else {
          // Kiểm tra thêm điều kiện tiên quyết nếu có
          final requiredNodeId = row['required_node_id'] as String?;
          if (requiredNodeId != null && requiredNodeId.isNotEmpty) {
            final parts = requiredNodeId.split(':');
            final reqGameId = parts.length >= 2 ? int.tryParse(parts[0]) : null;
            final reqLevelId = parts.length >= 2 ? parts[1] : requiredNodeId;

            final reqPassed = reqGameId != null
                ? await store.isStagePassed(reqGameId, reqLevelId)
                : passedKeys.any((k) => k.endsWith(':$reqLevelId'));

            if (reqPassed) {
              isUnlocked = true;
              lockReason = null;
            } else {
              isUnlocked = false;
              lockReason = 'complete_previous';
            }
          } else {
            isUnlocked = true;
            lockReason = null;
          }
        }
      }

      updatedLearningRows.add(<String, dynamic>{
        ...row,
        'is_unlocked': isUnlocked,
        'is_completed': isCompleted,
        'attempts': stageRecord?['attempts'] ?? row['attempts'] ?? 0,
        'best_score': stageRecord?['score'] ?? row['best_score'] ?? 0,
        'stars': stageRecord?['stars'] ?? row['stars'] ?? 0,
        if (lockReason != null) 'lock_reason': lockReason,
      });
    }

    // Derive effective mastery if overallMastery was not supplied or <= 0
    double effectiveMastery = overallMastery;
    if (effectiveMastery <= 0.0 && updatedLearningRows.isNotEmpty) {
      final completedRows =
          updatedLearningRows.where((r) => r['is_completed'] == true).toList();
      if (completedRows.isNotEmpty) {
        final totalScore = completedRows.fold<double>(
          0.0,
          (sum, r) => sum + ((r['best_score'] as num?)?.toDouble() ?? 70.0),
        );
        effectiveMastery =
            (totalScore / (completedRows.length * 100)).clamp(0.0, 1.0);
      }
    }

    for (int i = 0; i < updatedLearningRows.length; i++) {
      updatedLearningRows[i]['overall_mastery'] = effectiveMastery;
    }

    // Pass 2: compute Boss availability
    final allLearningPassed = updatedLearningRows.isNotEmpty &&
        updatedLearningRows.every((r) => r['is_completed'] == true);

    final updatedBossRows = <Map<String, dynamic>>[];
    for (final bRow in bossRows) {
      final bossRecord = await store.getBossRecord(unitId);
      final isBossWon = bossRecord != null && bossRecord['won'] == true;

      bool isBossUnlocked;
      String? lockReason;

      if (!isUnitUnlocked) {
        isBossUnlocked = false;
        lockReason = 'chapter_locked';
      } else if (!allLearningPassed) {
        isBossUnlocked = false;
        lockReason = 'complete_previous';
      } else if (effectiveMastery < 0.70 && effectiveMastery > 0.0) {
        // All stages done but mastery too low
        isBossUnlocked = false;
        lockReason = 'mastery_too_low';
      } else {
        // All stages done and mastery satisfactory
        isBossUnlocked = true;
        lockReason = null;
      }

      updatedBossRows.add(<String, dynamic>{
        ...bRow,
        'is_unlocked': isBossUnlocked,
        'is_completed': isBossWon,
        'attempts': bossRecord?['attempts'] ?? bRow['attempts'] ?? 0,
        'best_score': bossRecord?['score'] ?? bRow['best_score'] ?? 0,
        'stars': bossRecord?['stars'] ?? bRow['stars'] ?? 0,
        'overall_mastery': effectiveMastery,
        if (lockReason != null) 'lock_reason': lockReason,
      });
    }

    return [...updatedLearningRows, ...updatedBossRows];
  }

  /// Resolves the next playable node after completing a stage.
  Future<
      ({
        String? nextNodeId,
        bool unlockedNext,
        bool bossReady,
        bool unitCompleted,
      })> resolveNextNodeAfterStageCompletion({
    required String unitId,
    required int completedGameId,
    required String completedLevelId,
    required List<Map<String, dynamic>> pathRows,
    required GuestLearningProgressStore store,
    double overallMastery = 0.0,
  }) async {
    final overlaid = await overlayUnitPath(
      unitId: unitId,
      pathRows: pathRows,
      store: store,
      overallMastery: overallMastery,
      isUnitUnlocked: true,
    );

    final learningNodes = overlaid
        .where((r) => r['node_type'] == 'learning')
        .toList(growable: false);
    final bossNode =
        overlaid.where((r) => r['node_type'] == 'boss').firstOrNull;

    final currentIndex = learningNodes.indexWhere(
      (r) =>
          _asInt(r['game_id']) == completedGameId &&
          '${r['level_id'] ?? ''}' == completedLevelId,
    );

    if (currentIndex >= 0 && currentIndex + 1 < learningNodes.length) {
      final nextNode = learningNodes[currentIndex + 1];
      if (nextNode['is_unlocked'] == true) {
        final nGameId = _asInt(nextNode['game_id']);
        final nLevelId = '${nextNode['level_id'] ?? ''}';
        return (
          nextNodeId: '$nGameId:$nLevelId',
          unlockedNext: true,
          bossReady: false,
          unitCompleted: false,
        );
      }
    }

    // If all learning nodes are completed, check if boss is ready
    final allLearningPassed = learningNodes.isNotEmpty &&
        learningNodes.every((r) => r['is_completed'] == true);

    if (allLearningPassed && bossNode != null) {
      final bossStageId = (bossNode['boss_stage_id'] as num?)?.toInt() ??
          (bossNode['id'] as num?)?.toInt() ??
          1;
      final bossUnlocked = bossNode['is_unlocked'] == true;
      return (
        nextNodeId: bossUnlocked ? 'boss:$bossStageId' : null,
        unlockedNext: bossUnlocked,
        bossReady: bossUnlocked,
        unitCompleted: false,
      );
    }

    return (
      nextNodeId: null,
      unlockedNext: false,
      bossReady: false,
      unitCompleted: false,
    );
  }

  /// Overlays a list of units for a section with Guest unlock and completion state.
  Future<List<LearningUnitViewModel>> overlayUnits({
    required String sectionId,
    required List<LearningUnitViewModel> units,
    required GuestLearningProgressStore store,
    required bool isSectionUnlocked,
    String? previousSectionLastUnitId,
    Future<double> Function(String unitId)? masteryLoader,
  }) async {
    if (units.isEmpty) return const [];

    final result = <LearningUnitViewModel>[];
    final wonBossUnits = await store.getAllWonBossUnitIds();
    final masteries = masteryLoader == null
        ? null
        : await Future.wait(
            units.map((unit) async {
              try {
                return await masteryLoader(unit.id);
              } catch (_) {
                return unit.mastery;
              }
            }),
          );

    for (int i = 0; i < units.length; i++) {
      final unit = units[i];
      final isBossWon = wonBossUnits.contains(unit.id);

      bool isUnlocked;
      String? lockReason;

      if (!isSectionUnlocked) {
        // Unit 1 của Section 1 luôn luôn mở cho người học
        if (i == 0 && unit.sectionNumber <= 1) {
          isUnlocked = true;
          lockReason = null;
        } else {
          isUnlocked = false;
          lockReason = 'Phần học này chưa được mở.';
        }
      } else if (i == 0) {
        // Unit 1 in an unlocked section
        if (unit.sectionNumber <= 1) {
          isUnlocked = true;
          lockReason = null;
        } else if (previousSectionLastUnitId != null) {
          isUnlocked = wonBossUnits.contains(previousSectionLastUnitId);
          lockReason = isUnlocked ? null : 'Hoàn thành phần trước để mở.';
        } else {
          isUnlocked = true;
          lockReason = null;
        }
      } else {
        // Unit N in the same section: depends on Unit N-1 boss victory
        final prevUnit = units[i - 1];
        final prevBossWon = wonBossUnits.contains(prevUnit.id);
        isUnlocked = prevBossWon;
        lockReason = isUnlocked
            ? null
            : 'Đánh bại Boss Bài ${prevUnit.unitNumber} để mở khóa.';
      }

      final passedCount = await store.getPassedStageCountForUnit(unit.id);
      final completedCount = isBossWon
          ? unit.missionCount
          : (passedCount > unit.completedMissionCount
              ? passedCount
              : unit.completedMissionCount);
      final bossAvailable = isBossWon ||
          (unit.missionCount > 0 && completedCount >= unit.missionCount);

      final unitState = isBossWon
          ? UnitCompletionState.completed
          : (bossAvailable
              ? UnitCompletionState.bossPending
              : UnitCompletionState.inProgress);

      double unitMastery = masteries?[i] ?? unit.mastery;
      if (unitMastery <= 0.0 && completedCount > 0) {
        unitMastery = 0.70;
      }

      result.add(
        unit.copyWith(
          isUnlocked: isUnlocked,
          bossWon: isBossWon,
          bossAvailable: bossAvailable,
          completedMissionCount: completedCount,
          mastery: unitMastery,
          state: unitState,
          lockReason: lockReason,
        ),
      );
    }

    return result;
  }

  /// Overlays sections with Guest unlock and completion counts.
  Future<List<LearningSectionViewModel>> overlaySections({
    required List<LearningSectionViewModel> sections,
    required GuestLearningProgressStore store,
    required Future<List<LearningUnitViewModel>> Function(String sectionId)
        unitsLoader,
  }) async {
    if (sections.isEmpty) return const [];

    final result = <LearningSectionViewModel>[];
    bool prevSectionCompleted = true;
    final wonBossUnits = await store.getAllWonBossUnitIds();

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      // Chỉ phần học đã mở mới có thể có boss bị đánh bại, nên chỉ tải units
      // khi cần: khách chưa thắng boss nào thì không phải gọi RPC nào cả.
      final units = prevSectionCompleted && wonBossUnits.isNotEmpty
          ? await unitsLoader(section.id)
          : const <LearningUnitViewModel>[];

      final completedCount =
          units.where((u) => wonBossUnits.contains(u.id)).length;
      final isSectionFullyCompleted =
          units.isNotEmpty && completedCount >= units.length;

      bool isUnlocked;
      String? lockReason;

      if (i == 0) {
        isUnlocked = true;
      } else {
        isUnlocked = prevSectionCompleted;
        lockReason = isUnlocked
            ? null
            : 'Hoàn thành Phần ${sections[i - 1].sectionNumber} để mở khóa.';
      }

      result.add(
        section.copyWith(
          isUnlocked: isUnlocked,
          completedUnitCount: completedCount,
          unitCount: units.isNotEmpty ? units.length : section.unitCount,
          lockReason: lockReason,
        ),
      );

      prevSectionCompleted = isSectionFullyCompleted;
    }

    return result;
  }

  int _asInt(Object? value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
