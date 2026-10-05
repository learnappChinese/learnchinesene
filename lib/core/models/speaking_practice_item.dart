class SpeakingPracticeItem {
  final int? wordId;
  final int? exampleId;
  final String targetText;
  final String pinyin;
  final String meaning;
  final String? audioUrl;

  const SpeakingPracticeItem({
    this.wordId,
    this.exampleId,
    required this.targetText,
    required this.pinyin,
    required this.meaning,
    this.audioUrl,
  });

  factory SpeakingPracticeItem.fromMap(Map<String, dynamic> map) {
    return SpeakingPracticeItem(
      wordId: map['word_id'] as int?,
      exampleId: map['example_id'] as int?,
      targetText: (map['target_text'] ??
              map['chinese'] ??
              map['word'] ??
              map['sentence_cn'] ??
              '')
          .toString(),
      pinyin: (map['pinyin'] ?? map['sentence_pinyin'] ?? '').toString(),
      meaning: (map['meaning_vi'] ?? map['meaning'] ?? map['sentence_vi'] ?? '')
          .toString(),
      audioUrl: map['tts_url']?.toString(),
    );
  }
}
