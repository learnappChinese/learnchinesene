import 'package:flutter/material.dart';
import '../../../core/models/hanzi_character.dart';
import 'svg_stroke_parser.dart';

/// Bộ nhớ đệm (In-memory LRU cache) cho các đối tượng Path và HanziCharacter.
/// Giúp loại bỏ hoàn toàn việc phân tích cú pháp SVG nhiều lần và tải lại dữ liệu khi chuyển nét/chuyển chữ.
class HanziStrokeCache {
  HanziStrokeCache._();
  static final HanziStrokeCache instance = HanziStrokeCache._();

  static const int maxCacheSize = 300;

  final Map<int, List<Path>> _pathCache = {};
  final Map<int, HanziCharacter> _characterCache = {};

  /// Lấy danh sách Path đã phân tích cú pháp cho chữ Hán.
  List<Path>? getPaths(int characterId) => _pathCache[characterId];

  /// Lưu danh sách Path vào cache.
  void putPaths(int characterId, List<Path> paths) {
    if (_pathCache.length >= maxCacheSize) {
      _pathCache.remove(_pathCache.keys.first);
    }
    _pathCache[characterId] = paths;
  }

  /// Lấy thông tin HanziCharacter từ cache.
  HanziCharacter? getCharacter(int characterId) => _characterCache[characterId];

  /// Lưu HanziCharacter vào cache.
  void putCharacter(HanziCharacter character) {
    if (_characterCache.length >= maxCacheSize) {
      _characterCache.remove(_characterCache.keys.first);
    }
    _characterCache[character.id] = character;
  }

  /// Tải trước (Prefetch) và phân tích cú pháp sẵn danh sách chữ Hán.
  void prefetch(List<HanziCharacter> characters) {
    for (final char in characters) {
      putCharacter(char);
      if (char.strokePathData.trim().isNotEmpty && !_pathCache.containsKey(char.id)) {
        final paths = SvgStrokeParser.parseStrokesToPaths(char.strokePathData);
        if (paths.isNotEmpty) {
          putPaths(char.id, paths);
        }
      }
    }
  }

  /// Xóa cache thông tin chữ Hán khi có cập nhật tiến độ (vẫn giữ path strokes để vẽ nhanh).
  void invalidateCharacter(int characterId) {
    _characterCache.remove(characterId);
  }

  /// Xóa toàn bộ bộ nhớ đệm (dùng trong kiểm thử hoặc khi đổi tài khoản).
  void clear() {
    _pathCache.clear();
    _characterCache.clear();
  }
}
