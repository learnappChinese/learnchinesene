import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class HistoryItem {
  final String id;
  final String type; // 'Dịch thuật', 'Từ điển', 'Hội thoại', 'Thi HSK'
  final String timestamp;
  final String summary;
  final Map<String, dynamic> content;

  HistoryItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.summary,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp,
      'summary': summary,
      'content': content,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      content: Map<String, dynamic>.from(map['content'] ?? {}),
    );
  }
}

class HistoryService {
  static const String _fileName = 'history_logs.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<HistoryItem>> getHistory() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);
      return list
          .map((item) => HistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(HistoryItem item) async {
    try {
      final list = await getHistory();
      // Add at beginning (newest first)
      list.insert(0, item);
      final file = await _file;
      await file.writeAsString(jsonEncode(list.map((e) => e.toMap()).toList()));
    } catch (_) {
      // Ignore save error
    }
  }

  Future<void> clearHistory() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
