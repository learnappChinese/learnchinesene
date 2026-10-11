class LearningPresentationMapper {
  const LearningPresentationMapper._();

  static const _sectionNames = <int, String>{
    1: 'Giao tiếp cơ bản',
    2: 'Đời sống & Du lịch thường nhật',
    3: 'Trải nghiệm & Hoạt động xã hội',
    4: 'Nhịp sống & Giao tiếp mở rộng',
    5: 'Kỹ năng & Khám phá chuyên sâu',
    6: 'Ứng xử & Bày tỏ quan điểm',
    7: 'Xã hội & Thảo luận chủ đề',
    8: 'Giao tiếp nâng cao & Thành thạo',
  };

  static String sectionHeading(int number) => 'PHẦN ${_positive(number)}';

  static String sectionName(int number, [Object? raw]) {
    final value = _clean(raw);
    if (!_isTechnical(value)) return value;
    return _sectionNames[_positive(number)] ?? 'Chủ đề ${_positive(number)}';
  }

  static String sectionTitle(Object? raw, int number) {
    final name = sectionName(number, raw);
    final heading = sectionHeading(number);
    return name.isEmpty ? heading : '$heading: $name';
  }

  static String unitHeading(int number) => 'Bài ${_positive(number)}';

  static String unitTitle(Object? raw, int number) {
    final value = _clean(raw);
    if (_isTechnical(value)) return 'Bài ${_positive(number)}';
    return value;
  }

  static String unitFullTitle(Object? raw, int number) {
    final title = unitTitle(raw, number);
    final heading = unitHeading(number);
    if (title.toLowerCase().startsWith(heading.toLowerCase())) return title;
    return '$heading: $title';
  }

  /// Backward-compatible alias for unitTitle
  static String chapterTitle(Object? raw, int number) => unitTitle(raw, number);

  static String missionTitle(Object? raw, String? gameCode, int number) {
    final value = _clean(raw);
    if (!_isTechnical(value)) return value;
    return _gameTitles[gameCode] ?? 'Nhiệm vụ ${_positive(number)}';
  }

  static String missionSubtitle(Object? raw, String? gameCode) {
    final value = _clean(raw);
    if (!_isTechnical(value)) return value;
    return _gameSubtitles[gameCode] ?? 'Hoàn thành thử thách để tiến lên';
  }

  static bool isTechnical(Object? raw) => _isTechnical(_clean(raw));

  static String _clean(Object? raw) => '${raw ?? ''}'.trim();

  static int _positive(int value) => value < 1 ? 1 : value;

  static bool _isTechnical(String value) {
    if (value.isEmpty) return true;
    final normalized = value.toLowerCase().replaceAll('-', '_');
    return RegExp(r'^(path\s+section|section_|unit_|level_|game_|chương\s+\d+$)')
            .hasMatch(normalized) ||
        normalized.startsWith('path section') ||
        normalized.contains('unit_index') ||
        normalized.contains('game_code') ||
        normalized == 'null';
  }

  static const _gameTitles = <String, String>{
    'learn_words': 'Khám phá từ mới',
    'select_answer': 'Chọn đáp án',
    'match_pairs': 'Ghép cặp',
    'word_connect': 'Nối từ',
    'listen_select': 'Luyện nghe',
    'translate': 'Dịch câu',
    'gap_fill': 'Điền vào chỗ trống',
    'tap_complete': 'Hoàn thành câu',
    'dialogue': 'Hội thoại',
    'sentence_order': 'Sắp xếp câu',
    'speaking': 'Luyện phát âm',
    'boss_battle': 'Thử thách Boss',
  };

  static const _gameSubtitles = <String, String>{
    'learn_words': 'Nhận biết và ghi nhớ từ vựng của bài học',
    'select_answer': 'Chọn nghĩa đúng trong ngữ cảnh',
    'match_pairs': 'Ghép từ với nghĩa tương ứng',
    'word_connect': 'Nối từ Trung với nghĩa Việt',
    'listen_select': 'Nghe phát âm và chọn đáp án đúng',
    'translate': 'Hiểu và dịch câu theo ngữ cảnh',
    'gap_fill': 'Chọn từ còn thiếu trong câu',
    'tap_complete': 'Hoàn thiện câu giao tiếp',
    'dialogue': 'Luyện phản xạ qua tình huống giao tiếp',
    'sentence_order': 'Ghép các từ thành câu hoàn chỉnh',
    'speaking': 'Luyện phát âm chuẩn và cải thiện ngữ điệu',
    'boss_battle': 'Đánh bại Boss để kết thúc bài học',
  };
}
