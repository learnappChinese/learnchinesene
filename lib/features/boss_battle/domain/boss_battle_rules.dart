class BossBattleRules {
  const BossBattleRules();

  int scoreForCorrect(int combo) {
    final safeCombo = combo < 1 ? 1 : combo;
    return 100 + ((safeCombo - 1) * 20);
  }

  int damageToBoss(int combo) {
    final safeCombo = combo < 1 ? 1 : combo;
    final damage = 22 + ((safeCombo - 1) * 2);
    return damage > 30 ? 30 : damage;
  }

  int damageToPlayer() => 25;
}
