import 'package:flash_learn_chinese/screen/boss_battle/animation/boss_battle_rive_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Boss Battle motion states stay stable for the UI state machine', () {
    expect(BossBattleCharacterMotion.values,
        contains(BossBattleCharacterMotion.attack));
    expect(BossBattleCharacterMotion.values,
        contains(BossBattleCharacterMotion.hit));
    expect(BossBattleCharacterMotion.values,
        contains(BossBattleCharacterMotion.victory));
    expect(BossBattleCharacterMotion.values,
        contains(BossBattleCharacterMotion.defeat));
  });
}
