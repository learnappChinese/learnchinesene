import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache dùng chung cho các query Supabase trong một phiên chạy app.
///
/// - `keep: true`: dữ liệu chỉ phụ thuộc curriculum (hoặc RPC gọi khi chưa
///   đăng nhập, server không có tiến độ) được giữ đến khi app tắt.
/// - `keep: false`: chỉ gộp các request giống nhau đang chạy song song, kết
///   quả không được giữ lại nên dữ liệu tiến độ luôn mới.
///
/// Request lỗi không bao giờ được cache.
abstract final class QueryCache {
  static final Map<String, Future<Object?>> _entries = {};
  static final Set<String> _kept = {};

  static Future<T> run<T>(
    String key,
    Future<T> Function() load, {
    bool keep = false,
  }) {
    final existing = _entries[key];
    if (existing != null) return existing.then(_copy<T>);

    final future = load();
    _entries[key] = future;
    if (keep) _kept.add(key);
    future.then(
      (_) {
        if (!keep && identical(_entries[key], future)) _entries.remove(key);
      },
      onError: (Object _) {
        if (identical(_entries[key], future)) {
          _entries.remove(key);
          _kept.remove(key);
        }
      },
    );
    return future.then(_copy<T>);
  }

  /// Trả bản sao của list để nơi gọi có thể sort/add mà không ảnh hưởng cache.
  static T _copy<T>(Object? value) =>
      (value is List ? value.toList() : value) as T;

  /// Cache cho RPC có trả tiến độ của người học: khi chưa đăng nhập kết quả
  /// là nội dung tĩnh nên được giữ lại, khi đã đăng nhập chỉ gộp request.
  static Future<T> userScoped<T>(
    SupabaseClient client,
    String key,
    Future<T> Function() load,
  ) {
    final userId = client.auth.currentUser?.id;
    return run<T>(
      '${userId ?? 'guest'}|$key',
      load,
      keep: userId == null,
    );
  }

  /// RPC lộ trình của một unit (có tiến độ khi đã đăng nhập).
  static Future<List<Map<String, dynamic>>> unitPathRows(
    SupabaseClient client,
    String unitId,
  ) =>
      userScoped(
        client,
        'unit_learning_path_v2|$unitId',
        () async => List<Map<String, dynamic>>.from(
          await client.rpc(
            'unit_learning_path_v2',
            params: <String, dynamic>{'p_unit_id': unitId},
          ),
        ),
      );

  /// Bỏ các request tiến độ đang chạy để lần tải sau (sau khi vừa ghi tiến
  /// độ) không nhận lại kết quả cũ. Dữ liệu `keep` vẫn được giữ.
  static void dropInflight() =>
      _entries.removeWhere((key, _) => !_kept.contains(key));

  static void clear() {
    _entries.clear();
    _kept.clear();
  }
}
