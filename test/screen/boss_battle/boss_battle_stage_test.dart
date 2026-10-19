import 'package:pandarin/features/boss_battle/model/boss_battle_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BossBattleStage parses Supabase catalog rows', () {
    final stage = BossBattleStage.fromMap({
      'id': 7,
      'unit_id': 'sec_2_unit_4',
      'stage_order': 3,
      'section_number': 2,
      'unit_number': 4,
      'title': 'Dùng câu mệnh lệnh',
      'question_count': 8,
      'difficulty': 2,
      'boss_name': 'Rồng Hỏa Sơn',
      'boss_hp': 124,
      'player_hp': 100,
      'theme_code': 'sunset',
    });

    expect(stage.id, 7);
    expect(stage.label, 'Cửa 3');
    expect(stage.questionCount, 8);
    expect(stage.difficulty, 2);
    expect(stage.bossHp, 124);
    expect(stage.bossName, 'Rồng Hỏa Sơn');
  });
}
