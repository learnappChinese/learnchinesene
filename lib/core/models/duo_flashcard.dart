class DuoFlashcard {
  final int id;
  final String word;
  final String? pinyin;
  final String? meaning;
  final String? ttsUrl;

  DuoFlashcard({
    required this.id,
    required this.word,
    this.pinyin,
    this.meaning,
    this.ttsUrl,
  });

  factory DuoFlashcard.fromMap(Map<String, dynamic> map) {
    return DuoFlashcard(
      id: map['id'] as int,
      word: map['word'] as String,
      pinyin: map['pinyin'] as String?,
      meaning: map['meaning'] as String?,
      ttsUrl: map['tts_url'] as String?,
    );
  }
}
