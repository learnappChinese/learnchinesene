import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class SvgStrokeParser {
  static List<String> parseStrokePaths(String strokePathData) {
    if (strokePathData.trim().isEmpty) return const [];
    return strokePathData
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static Path? parseSvgPath(String pathData) {
    try {
      return parseSvgPathData(pathData);
    } catch (_) {
      return null;
    }
  }

  static List<Path> parseStrokesToPaths(String strokePathData) {
    final rawPaths = parseStrokePaths(strokePathData);
    final List<Path> paths = [];
    for (final raw in rawPaths) {
      final p = parseSvgPath(raw);
      if (p != null) {
        paths.add(p);
      }
    }
    return paths;
  }
}
