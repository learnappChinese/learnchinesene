import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pandarin/features/hanzi_writing/services/hanzi_progress_snapshot_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<HanziProgressSnapshotService> guestService(
    List<Map<String, dynamic>> attempts,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HanziProgressSnapshotService.guestAttemptsKey: jsonEncode(attempts),
    });
    final prefs = await SharedPreferences.getInstance();
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    return HanziProgressSnapshotService(
      client: client,
      preferences: Future.value(prefs),
    );
  }

  test('Guest Hanzi progress aggregates real local attempt history', () async {
    final service = await guestService([
      {
        'id': 'a1',
        'activity_type': 'hanzi',
        'source_type': 'character',
        'source_id': '7',
        'score': 68.0,
        'completed_at': '2026-10-20T01:00:00Z',
        'metadata': {'practice_attempts': 4},
      },
      {
        'id': 'a2',
        'activity_type': 'hanzi',
        'source_type': 'character',
        'source_id': '7',
        'score': 82.0,
        'completed_at': '2026-10-20T02:00:00Z',
        'metadata': {'practice_attempts': 3},
      },
      {
        'id': 'other',
        'activity_type': 'speaking',
        'source_type': 'character',
        'source_id': '7',
        'score': 99.0,
        'metadata': {'practice_attempts': 99},
      },
    ]);

    final progress = await service.loadForCharacter(7);
    expect(progress.practiceCount, 7);
    expect(progress.bestScore, 82);
    expect(progress.lastScore, 82);
  });

  test('duplicate Guest attempt id cannot inflate writing practice count',
      () async {
    final duplicated = {
      'id': 'same-attempt',
      'activity_type': 'hanzi',
      'source_type': 'character',
      'source_id': '2',
      'score': 75.0,
      'completed_at': '2026-10-20T03:00:00Z',
      'metadata': {'practice_attempts': 5},
    };
    final service = await guestService([
      duplicated,
      Map<String, dynamic>.from(duplicated),
    ]);

    final progress = await service.loadForCharacter(2);
    expect(progress.practiceCount, 5);
    expect(progress.bestScore, 75);
  });

  test('snapshot only exposes requested character ids', () async {
    final service = await guestService([
      {
        'id': 'a1',
        'activity_type': 'hanzi',
        'source_type': 'character',
        'source_id': '1',
        'score': 88.0,
        'metadata': {'practice_attempts': 1},
      },
      {
        'id': 'a2',
        'activity_type': 'hanzi',
        'source_type': 'character',
        'source_id': '99',
        'score': 100.0,
        'metadata': {'practice_attempts': 1},
      },
    ]);

    final progress = await service.loadForCharacters([1]);
    expect(progress.keys, [1]);
    expect(progress[1]!.bestScore, 88);
  });

  test('malformed Guest local JSON fails closed to empty progress', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HanziProgressSnapshotService.guestAttemptsKey: '{broken',
    });
    final prefs = await SharedPreferences.getInstance();
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    final service = HanziProgressSnapshotService(
      client: client,
      preferences: Future.value(prefs),
    );

    expect(await service.loadForCharacters([1, 2]), isEmpty);
  });
}
