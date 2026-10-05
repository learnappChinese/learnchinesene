class Word {
  final int id;
  final String chinese;
  final String pinyin;
  final String vietnamese;
  final String english;
  final String ttsUrl;
  final int hskLevelId;
  final String sectionTitle;
  final String groupSubtitle;
  final int wrongCount;
  final int correctCount;

  const Word({
    required this.id,
    required this.chinese,
    required this.pinyin,
    required this.vietnamese,
    required this.english,
    required this.ttsUrl,
    required this.hskLevelId,
    required this.sectionTitle,
    required this.groupSubtitle,
    this.wrongCount = 0,
    this.correctCount = 0,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: (map['id'] as num?)?.toInt() ?? 0,
      chinese: '${map['chinese'] ?? ''}',
      pinyin: '${map['pinyin'] ?? ''}',
      vietnamese: '${map['vietnamese'] ?? ''}',
      english: '${map['english'] ?? ''}',
      ttsUrl: '${map['tts_url'] ?? ''}',
      hskLevelId: (map['hsk_level_id'] as num?)?.toInt() ?? 0,
      sectionTitle: '${map['section_title'] ?? ''}',
      groupSubtitle: '${map['group_subtitle'] ?? ''}',
      wrongCount: (map['wrong_count'] as num?)?.toInt() ?? 0,
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
    );
  }
}
