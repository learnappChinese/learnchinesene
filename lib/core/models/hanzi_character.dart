class HanziCharacter {
  final int id;
  final String character;
  final String? pinyin;
  final String? meaning;
  final int? hskLevel;
  final String strokePathData;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final int strokeCount;

  HanziCharacter({
    required this.id,
    required this.character,
    this.pinyin,
    this.meaning,
    this.hskLevel,
    required this.strokePathData,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.strokeCount,
  });

  factory HanziCharacter.fromMap(Map<String, Object?> map) {
    return HanziCharacter(
      id: map['id'] as int,
      character: map['character'] as String? ?? '',
      pinyin: map['pinyin'] as String?,
      meaning: map['meaning'] as String?,
      hskLevel: map['hsk_level_id'] as int?,
      strokePathData: map['stroke_paths'] as String? ?? '',
      viewBoxWidth: (map['stroke_width'] as num?)?.toDouble() ?? 110.0,
      viewBoxHeight: (map['stroke_height'] as num?)?.toDouble() ?? 110.0,
      strokeCount: map['stroke_count'] as int? ?? 0,
    );
  }
}
