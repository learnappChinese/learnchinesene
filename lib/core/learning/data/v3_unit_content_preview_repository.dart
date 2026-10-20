import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// V3-4 pilot client, opt-in only. It does not change active learning routing.
/// Never fetch/store XP, mastery, Guest or Cloud progression here.
class V3UnitContentPreviewRepository {
  V3UnitContentPreviewRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const bool enabled = bool.fromEnvironment(
    'V3_UNIT1_CONTENT_PREVIEW',
    defaultValue: false,
  );

  static const String pilotUnitId = 'sec_1_unit_1';

  /// Null signals to the existing learning repository to use legacy reads.
  /// The caller must not switch to V3 until the full Unit is reviewed.
  Future<Map<String, dynamic>?> loadPilotUnit(String unitId) async {
    if (!enabled || unitId != pilotUnitId) return null;
    const pageSize = 100;
    final challenges = <Map<String, dynamic>>[];
    List<Map<String, dynamic>>? pathRows;
    var total = -1;
    try {
      // Bound iteration protects against malformed server pagination loops.
      for (var page = 0; page < 50; page++) {
        final response = await _client.rpc(
          'learning_v3_unit_read_v1',
          params: <String, dynamic>{
            'p_unit_id': unitId,
            'p_offset': challenges.length,
            'p_page_size': pageSize,
          },
        );
        if (response is! Map || response['schema_version'] != 3 ||
            response['unit_id'] != unitId ||
            response['path_rows'] is! List ||
            response['challenges'] is! List) {
          throw const FormatException('Invalid V3 unit content response');
        }
        final rows = (response['path_rows'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList(growable: false);
        pathRows ??= rows;
        final items = (response['challenges'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList(growable: false);
        total = (response['total_challenges'] as num?)?.toInt() ?? -1;
        if (total < 0) throw const FormatException('Missing total count');
        challenges.addAll(items);
        if (challenges.length >= total) {
          if (challenges.length != total) {
            throw const FormatException('V3 pagination count mismatch');
          }
          return <String, dynamic>{
            'unit_id': unitId,
            'path_rows': pathRows,
            'raw_challenges': challenges.map((r) => <String, dynamic>{
                  ...r,
                  '_level_id': r['level_id'],
                }).toList(growable: false),
          };
        }
        if (items.isEmpty) throw const FormatException('V3 pagination stalled');
      }
      throw const FormatException('V3 unit content exceeded page limit');
    } catch (error) {
      debugPrint('[V3UnitContentPreviewRepository] fallback: $error');
      return null;
    }
  }
}
