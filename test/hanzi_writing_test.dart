import 'package:flash_learn_chinese/core/models/hanzi_character.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HanziCharacter maps Supabase lexicon row correctly', () {
    final character = HanziCharacter.fromMap({
      'id': 7,
      'character': '好',
      'pinyin': 'hǎo',
      'meaning': 'tốt',
      'hsk_level_id': 1,
      'stroke_paths': 'M0 0L1 1',
      'stroke_width': 110.0,
      'stroke_height': 110.0,
      'stroke_count': 6,
    });

    expect(character.id, 7);
    expect(character.character, '好');
    expect(character.pinyin, 'hǎo');
    expect(character.meaning, 'tốt');
    expect(character.hskLevel, 1);
    expect(character.strokeCount, 6);
    expect(character.strokePathData, isNotEmpty);
  });
}
