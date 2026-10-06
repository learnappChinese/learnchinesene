import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/duo_db_helper.dart';
import '../model/unit_learning_node.dart';

abstract class UnitLearningSource {
  Future<List<UnitLearningNode>> loadUnitPath(String unitId);
}

class UnitLearningRepository implements UnitLearningSource {
  UnitLearningRepository({
    SupabaseClient? client,
    DuoDbHelper? database,
  })  : _client = client ?? Supabase.instance.client,
        _database = database ?? DuoDbHelper.instance;

  final SupabaseClient _client;
  final DuoDbHelper _database;

  @override
  Future<List<UnitLearningNode>> loadUnitPath(String unitId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'unit_learning_path',
        params: {'p_unit_id': unitId},
      ),
    );

    final nodes = rows
        .map(UnitLearningNode.fromMap)
        .where((node) => node.nodeOrder > 0)
        .toList(growable: false)
      ..sort((a, b) => a.nodeOrder.compareTo(b.nodeOrder));

    if (_client.auth.currentUser != null) return nodes;

    final overlaid = <UnitLearningNode>[];
    for (final node in nodes) {
      final gameId = node.gameId;
      final levelId = node.levelId;
      if (node.isBoss || gameId == null || levelId == null) {
        overlaid.add(node);
        continue;
      }

      final local = await _database.getGuestLevelState(gameId, levelId);
      if (local.isEmpty) {
        overlaid.add(node);
        continue;
      }

      overlaid.add(
        node.copyWith(
          attempts: (local['attempts'] as num?)?.toInt() ?? node.attempts,
          bestScore:
              (local['best_score'] as num?)?.toInt() ?? node.bestScore,
          stars: ((local['stars'] as num?)?.toInt() ?? node.stars)
              .clamp(0, 3)
              .toInt(),
          rawUnlocked:
              local['is_unlocked'] == true || node.rawUnlocked,
          completed: local['is_completed'] == true || node.completed,
          inProgress: local['in_progress'] == true,
          currentIndex:
              (local['current_index'] as num?)?.toInt() ?? node.currentIndex,
        ),
      );
    }

    final allLearningCompleted = overlaid
        .where((node) => !node.isBoss)
        .every((node) => node.completed);

    return overlaid
        .map(
          (node) => node.isBoss && allLearningCompleted
              ? node.copyWith(rawUnlocked: true)
              : node,
        )
        .toList(growable: false);
  }
}
