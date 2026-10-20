import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug-only learner experience audit, completely separate from XP/Guest
/// learning state. Feedback stays local until the tester explicitly copies it.
/// Never collect user identifiers, speech recordings, or answer histories.
class V3LearnerFeedbackStore {
  static const storageKey = 'v3_learning_experience_feedback_v1';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: true);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> save(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await load();
    entries.add(entry);
    // Capped local queue; never touch existing learning/XP prefs.
    final bounded = entries.length > 200
        ? entries.sublist(entries.length - 200)
        : entries;
    final ok = await prefs.setString(storageKey, jsonEncode(bounded));
    if (!ok) throw StateError('Could not save local feedback');
  }

  static Future<void> copyAll() async {
    final entries = await load();
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(entries)),
    );
  }
}

const _issueCategories = <String, String>{
  'lesson_ok': 'Bài học hợp lý, không phát hiện vấn đề',
  'missing_lesson_content': 'Thiếu từ vựng, ví dụ hoặc ngữ pháp',
  'wrong_translation': 'Bản dịch / nghĩa chưa đúng',
  'wrong_answer': 'Đáp án hoặc lựa chọn không hợp lý',
  'missing_audio': 'Âm thanh thiếu / không phát',
  'poor_sequence': 'Thứ tự học hoặc độ khó chưa hợp lý',
  'missing_explanation': 'Thiếu giải thích / kiến thức',
  'locked_progress': 'Hoàn thành rồi nhưng ải vẫn khóa',
  'other': 'Vấn đề khác',
};

/// Can be called from a lesson or a specific question. It never modifies
/// learning completion, scores, inventory, or server content.
Future<void> showV3LearnerFeedbackSheet(
  BuildContext context, {
  required String unitId,
  required String screen,
  String? levelId,
  String? gameCode,
  String? challengeId,
  int? challengeIndex,
}) async {
  var notes = '';
  var category = screen == 'unit_overview' ? 'lesson_ok' : 'wrong_translation';
  var lessonRating = 3.0;
  var submitting = false;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 10, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Kiểm tra chất lượng bài học',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Bài: $unitId'
                      '${levelId == null ? "" : " • Ải: $levelId"}'
                      '${challengeId == null ? "" : " • Câu: $challengeId"}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  if (screen == 'unit_overview') ...[
                    Text('Mức độ hợp lý của toàn bài: ${lessonRating.toInt()}/5'),
                    Slider(
                      value: lessonRating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${lessonRating.toInt()}/5',
                      onChanged: submitting ? null : (value) {
                        setSheetState(() => lessonRating = value);
                      },
                    ),
                  ],
                  const Text('Đánh giá hoặc báo nội dung chưa hợp lý:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: category,
                    isExpanded: true,
                    items: _issueCategories.entries.map((item) {
                      return DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: submitting ? null : (value) {
                      if (value != null) setSheetState(() => category = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => notes = value,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả lỗi và cách sửa đề xuất',
                      hintText: 'Ví dụ: nghĩa đúng phải theo ngữ cảnh...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Text(
                    'Chỉ lưu trên máy kiểm thử. Không gửi dữ liệu lên server '
                    'và không thay đổi XP hoặc kết quả học.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu đánh giá'),
                    onPressed: submitting ? null : () async {
                      setSheetState(() => submitting = true);
                      try {
                        await V3LearnerFeedbackStore.save(<String, dynamic>{
                          'schema_version': 1,
                          'created_at': DateTime.now().toUtc().toIso8601String(),
                          'unit_id': unitId,
                          'screen': screen,
                          if (levelId != null) 'level_id': levelId,
                          if (gameCode != null) 'game_code': gameCode,
                          if (challengeId != null) 'challenge_id': challengeId,
                          if (challengeIndex != null)
                            'challenge_index': challengeIndex,
                          'category': category,
                          if (screen == 'unit_overview')
                            'lesson_rating': lessonRating.toInt(),
                          'notes': notes.trim(),
                          'review_status': 'needs_review',
                        });
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu đánh giá trên máy')),
                          );
                        }
                      } catch (_) {
                        if (sheetContext.mounted) {
                          setSheetState(() => submitting = false);
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('Không lưu được đánh giá')),
                          );
                        }
                      }
                    },
                  ),
                  TextButton.icon(
                    onPressed: submitting ? null : () async {
                      await V3LearnerFeedbackStore.copyAll();
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép báo cáo để gửi kiểm duyệt')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Sao chép toàn bộ báo cáo kiểm thử'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}
