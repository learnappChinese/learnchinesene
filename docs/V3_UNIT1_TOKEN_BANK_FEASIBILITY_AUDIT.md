# Unit 1 translation token-bank audit — 2026-10-20

Read-only, grounded in production Supabase records for `sec_1_unit_1` (connected project `hrlahralknhijnkypjix`).

## Actual outcome
- Reviewed programmatically all **63** `translate` challenge JSON payloads from the Unit, using original `id`, `prompt`, `solutions`, and `choices_text`.
- Tested whether a listed solution can be reconstructed by using each available tile at most once, case-insensitively.
- Initial heuristic found **12** apparently unbuildable answers; direct inspection showed **punctuation mismatches** between answers and word tiles (e.g., `Cơm, nước` vs tiles `Cơm`, `nước`, or Chinese `茶、咖啡` vs separate `茶`, `咖啡`).
- After normalizing whitespace **and punctuation**, **0 / 63** answers were found unbuildable by this heuristic. The scanner and tests were updated to avoid these false positives.
- **This does NOT mean the 63 Mandarin↔Vietnamese translations are semantically correct.** Human bilingual review remains mandatory.

## Checks not established
- Whether the *actual Flutter scorer* tolerates all punctuation/case/spacing variants or requires exact punctuation.
- Whether all acceptable alternative translations are recognized.
- Whether the 8 duplicate-looking groups are pedagogically justified.
- Whether audio is correct on real devices, and whether Guest/Boss progression works end-to-end.

## Next action
Trace the actual DuoSentenceBuilder answer validation against the same 63 source IDs, then add scorer-parity tests. Never rewrite production solutions based only on the token-bank heuristic.

The audit was SELECT-only; no source content, progress or XP was modified. PR remains Draft; `hieu` untouched.
