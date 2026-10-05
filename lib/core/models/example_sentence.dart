class ExampleSentence {
  final int id;
  final int wordId;
  final String chinese;
  final String pinyin;
  final String vietnamese;
  final int order;

  const ExampleSentence({
    required this.id,
    required this.wordId,
    required this.chinese,
    required this.pinyin,
    required this.vietnamese,
    required this.order,
  });

  factory ExampleSentence.fromMap(Map<String, dynamic> map) {
    return ExampleSentence(
      id: (map['id'] as num?)?.toInt() ?? 0,
      wordId: (map['word_id'] as num?)?.toInt() ?? 0,
      chinese: '${map['chinese'] ?? ''}',
      pinyin: '${map['pinyin'] ?? ''}',
      vietnamese: '${map['vietnamese'] ?? ''}',
      order: (map['order_index'] as num?)?.toInt() ?? 0,
    );
  }
}
