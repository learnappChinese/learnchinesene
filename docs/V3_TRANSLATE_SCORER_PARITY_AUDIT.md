# V3 audit — scoring consistency vs teaching quality (2026-10-20)

## Live Supabase, read-only evidence
- **36,344 / 36,344** `translate` challenges checked against the actual `DuoSentenceBuilderWidget` score rule: `choices_correct` must rank the selected word-bank items 1..N.
- **0** invalid ranked-answer sequences.
- **0** ranked-token result vs `solutions` mismatches, after punctuation/whitespace/case normalization used **for audit only**.
- All **36,344** have matching lengths for `choices_text` and `choices_correct`, with no null ranking.
- Unit `sec_1_unit_1`: 63/63 translation answers pass parity; 12 initial false positives were due solely to punctuation and were eliminated by Unicode punctuation normalization.
- Reproducible SQL: `supabase/audits/v3_1_translate_scorer_parity.sql`. New Python scanner `scripts/v3_quality_check.py` checks matching rank/solutions for offline NDJSON exports; dedicated fixtures ensure broken rank order triggers candidate review.

**What this proves:** original translation choices and stored solutions are internally consistent with the game's scoring convention. It does **not** prove natural/correct Vietnamese, Mandarin semantics, correct alternatives, pinyin or audio.

## Priorities for the next stage
1. Build a bilingual per-challenge review queue anchored by exact source IDs and full surrounding lesson context.
2. Review alternative valid translations that exact-ranking scoring might reject; implement changes only after product agreement and server/Flutter scorer tests.
3. Do Android debug learner sessions Unit1→Stage2→Boss→Next Unit with Guest data; record screenshots and content feedback.
4. Approve edits as V3 correction drafts; never bulk-overwrite 36,344 production rows from machine translation.
5. Stage and measure V3 read RPC, then canary Unit1; do not merge into `hieu` before actual evidence.

Source database was only read; legacy challenge IDs, XP/progress and current translations remain unchanged.
