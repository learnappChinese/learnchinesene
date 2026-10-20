# V3: DATA QUALITY, EDITORIAL REVIEW, FAST UNIT READ & SAFE ROLLOUT
Date: 2026-10-20. Base: `hieu` at `e6d6f6b58200c02c77fd42254e87a4511eb3365c`.
**All work stays on `feature/v3-quality-audit-rollout-20261020`, pending new PR. Do not merge or modify `hieu` automatically.**
**Production Supabase schema, legacy curriculum, XP, Guest and Cloud progress remain unchanged by this PR.**
Connected DB project: `hrlahralknhijnkypjix`.

## Verified database audit (read-only; real rows)
- 310/310 units surveyed, 64,828 challenges, 2,205 lexicon words, 7,925 example sentences.
- Unit challenge range: 90–244; no empty-challenge Units and no Unit with only one challenge type.
- Exactly one lexicon word missing pinyin: ID 1925 `t恤`; candidate `T xù` must be bilingual-reviewed.
- No lexicon word missing Vietnamese meaning, no example missing CN/Pinyin/VI text.
- No challenge with non-array JSON in present `choices_text`, `choices_correct`, `solutions`, `tokens_text` fields (by type).
- All 36,344 `translate` challenges have non-empty `solutions` and `choices_text` arrays.
- Many question types intentionally use JSON payload and have blank `prompt`: **NOT necessarily broken**.
- 15,129 `translate` rows have no direct `tts`; it may be resolved through other audio sources: triage only.
- **Semantic accuracy has NOT yet been verified for every translation/answer.** Automated structure checks cannot establish fluent/correct Chinese↔Vietnamese meaning.

## Actual implementation status
| Phase | Files created on this feature branch | State |
|---|---|---|
| V3-1 | `supabase/audits/v3_1_full_corpus_quality.sql`, `scripts/v3_quality_check.py`, `scripts/test_v3_quality_check.py` | Read-only baseline queries executed on live DB; CLI scanner committed, not yet CI-run |
| V3-2 | `supabase/migrations/20261020085000_v3_editorial_staging_safe.sql`; `content_review/v3_candidates/lexicon_word_1925.json` | Versioned candidate/approval schema and first draft, NOT deployed/published |
| V3-3 | `supabase/migrations/20261020085100_v3_unit_read_api.sql` | Versioned, bounded paginated read API in SQL, NOT deployed |
| V3-4 | `lib/core/learning/data/v3_unit_content_preview_repository.dart` | Pilot adapter, opt-in compile-time flag **OFF**, not wired into active Unit UI; no Unit1 new lesson yet |
| V3-5 | Gated rollout procedure below | NOT started; no Units migrated |
| V3-6 | Cleanup conditions below | NOT started; no tables dropped |

## V3-1 — repeatable full-corpus checking
SQL script scans the full remote corpus with type-aware rules. The offline Python scanner accepts NDJSON exports with each row labeled `source_table`, preserving original ID. It makes no network calls, does not modify DB, and reports structural issue *candidates*, not translation corrections.

Commands from repository root:
```bash
python -m unittest scripts.test_v3_quality_check
python scripts/v3_quality_check.py --input /secure/path/content_export.jsonl --output /secure/path/content_qa_report.json
```
Export only public/static content in limited pages; exclude user attempts/XP/private keys. Reports not containing private data may be reviewed; large/raw content must not be committed blindly.

## V3-2 — real translations, pinyin and answers
Keep original content and stable IDs. Write corrections to a **versioned staging release** with `draft` / `needs_review`, source hash, reviewer reasoning and context. Require human bilingual confirmation of pinyin, polyphonic readings, natural Vietnamese, alternative acceptable answers and game-specific answer schema before `approved`. `content_review/v3_candidates/lexicon_word_1925.json` is **one proposed reading, not published truth**. Never auto-update 64k answers from machine translation.

## V3-3 — fast read model
`learning_v3_unit_read_v1(unit_id, offset, page_size)` returns the existing authoritative unit path and a **bounded page of original challenge IDs/full question payloads**, with total count and schema version. It uses current indexes by `level_id` and `session_id`, preserves all challenge types, and does not write learning state. Query is `SECURITY INVOKER`; requires SQL review and staging validation before application. Test pagination continuity, item counts, JSON equality, p95 and payload sizes vs existing API.

## V3-4 — Unit1 Flutter canary
`V3UnitContentPreviewRepository` will return `null` unless compiled with `--dart-define=V3_UNIT1_CONTENT_PREVIEW=true` AND requested Unit is `sec_1_unit_1`. This is only an **adapter prototype**; it is not attached to the active widget tree or reward pipeline. Do not enable for learners until curriculum content v3 is approved and integrated. Preserve GameRunner/XP/Guest overlay and authoritative Boss/Unit unlock.

## V3-5 — staged 310-Unit migration, STRICT rollout gate
1. Quality review + provenance + approved translations for Unit1; verify original ID mappings.
2. Stage migration and RLS audit; compare question identity, order and answer semantics.
3. Integrate Unit1 through flag with documented legacy fallback and screenshots; run full app on emulator.
4. Guest test: Stage1→Stage2→Boss→Next Unit, relaunch, XP once, SRS. Signed-in staging and Guest→Cloud migration.
5. Measure time-to-interactive/p95, total API requests, payload bytes, crash rate, content errors.
6. Release Unit1 to canary only after reviewer approval; rollback flag on any regression.
7. Expand Unit2–10, then batches of 10–20 with per-Unit approval/metrics. Stop on a broken gate. **No mass activation.**

## V3-6 — cleanup ONLY after rollout verified
Before dropping any old table/column: prove no running clients or backend function, migrations, stored progress foreign keys, SRS references or content tooling require it. Backup/restore test, inventory all dependencies, dual-read sunset, staging dry run and rollback. Favor compatibility views, not destructive changes. A lower physical table count is not a performance metric: measure JOIN cost, number of requests and p95 response.

## Rollout/invariants
- Existing `duo_units.id`, `duo_levels.id`, `duo_challenges.id`, `boss_stages.id` and lexicon IDs remain stable.
- No learning state/XP/migration system changes in this PR.
- No active Flutter app navigation changes; default feature flag is false.
- Do not claim V3-2/V3-4/V3-5 complete just because SQL/files exist.
- Do not deploy SQL against production or merge `hieu` without tests, code review and explicit go/no-go approval.
- Run `flutter analyze`, `flutter test`, Flutter build, Supabase staging migration + RLS checks, and device E2E before merging.
- PR #25, #26, #27 remain separate draft work; this branch is independently based on `hieu`, no need to merge those branches first.
