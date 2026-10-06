import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/unit_learning_node.dart';

abstract class UnitLearningSource {
  Future<List<UnitLearningNode>> loadUnitPath(String unitId);
}

class UnitLearningRepository implements UnitLearningSource {
  UnitLearningRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<UnitLearningNode>> loadUnitPath(String unitId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'unit_learning_path',
        params: {'p_unit_id': unitId},
      ),
    );

    return rows
        .map(UnitLearningNode.fromMap)
        .where((node) => node.nodeOrder > 0)
        .toList(growable: false)
      ..sort((a, b) => a.nodeOrder.compareTo(b.nodeOrder));
  }
}
