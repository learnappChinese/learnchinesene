# DATABASE V3 — Full redesign based on current Chinese-learning database
**Status: proposed, no production deployment.** Source of truth: Supabase project `hrlahralknhijnkypjix`, branch `hieu` at audit time. No table deletion, user progress mutation, or auto-generated translation publication.

## 1. Existing inventory and observed defects
- 310 Unit, 310 Boss, 64,828 challenges, 2,205 lexicon words, 7,925 examples, 12,101 flashcards.
- 36,344 `translate` challenge; many challenge types put content in different JSON fields: absence of prompt/solutions alone is **not** a defect for `dialogue`, `match`, `gapFill`, etc.
- Word `lexicon_words.id=1925` / `t恤` has null pinyin; example of a demonstrable issue to triage and correct with review.
- Quality of every Vietnamese translation remains **unverified**; never claim all translations wrong or corrected without semantic review.
- Existing primary indexes `duo_challenges(session_id,type)`, `duo_sessions(level_id)`, `lexicon_words(word)` should be reused, not duplicated.
- Current `learning_unit_bundle_v1` fast-read draft PR #25 is independent; its integration has not been merged.

## 2. Target domain model (logical)
**Curriculum layer:** Course → HSK band/world → Section → Unit → Lesson plan → Activities → Boss. Stable legacy unit and challenge IDs, versioned curriculum versions/rollout per Unit.

**Content layer:** canonical Chinese text → lexical meaning/sense → translation variant → example sentence and translation → audio asset metadata → question with type-specific payload → accepted answer(s) and distractors → skill tags → provenance/review/release. IMPORTANT: a word can have multiple senses, multiple pronunciations (polyphones), and translations valid in different contexts. Do not write one unconditional `meaning_vi` for every context.

**User-state layer:** attempts → XP event ledger, Unit/mastery/SRS, boss progression, Guest local persistence, Guest→Cloud idempotent migration. Keep the existing authoritative RPC and immutable IDs; DO NOT move user-state into the static content cache.

**Read model:** one Unit bundle and paginated compact vocabulary endpoint, versioned and cacheable. Static lesson content can be denormalized for reads; normalized editorial source retains quality, references and rollback capability.

## 3. New physical tables, staged migration
Migration `20261020_database_v3_editorial_staging.sql` adds only:
- `content_v3_releases`: release/version lifecycle; no automatic activation.
- `content_v3_revisions`: per-source content corrections; unique (release,source table,source ID), JSON payload for draft, reviewers and source hash to detect stale edits.
- `content_v3_quality_issues`: audit queue with type/severity/evidence/resolution.

Tables have RLS on and no anon/authenticated table access. There is **no Flutter runtime dependence or write path yet**. Avoid allowing clients to read drafts or issue arbitrary patch updates.

Later PRs after validation: add normalized `lexeme_senses_v3` (one-to-many senses, pronunciation and contextual translation), `sentences_v3` (CN/pinyin/VI, source + examples), `question_versions_v3` (typed answer contracts), `lesson_content_links_v3`, `audio_assets_v3`, `unit_publications_v3`. Each addition has an explicit migration, FK/source mapping and verified rollback. Prefer adding the minimum needed after reviewing real data instead of preemptively creating dozens of tables.

## 4. Translation correctness protocol
1. Extract candidate rows and all challenge type payloads with their original IDs, Unit, Chinese source, existing VI translations, pinyin, JSON answer schema and audio. Preserve immutable raw snapshot/checksum.
2. Deterministic QA: missing/invalid Hanzi/pinyin, abnormal UTF, null allowed vs not allowed by `type`, duplicate content, answers not among choices, inconsistent right answers, text/audio mismatch, empty unit content.
3. Linguistic QA: Mandarin meaning **in context**, polyphonic characters, measure words, HSK difficulty, natural Vietnamese, grammar, idiomatic translations and tone. Annotate confidence and evidence; bilingual reviewer approval before publication.
4. Prefer multiple accepted semantically equivalent answers where valid; do not assume string equality. Distinguish simplified/traditional script, Chinese punctuation, word order alternatives.
5. AI suggestions may populate `draft` only, never `approved` / `active` automatically. No production data overwrite from an AI-generated translation.
6. Create per-Unit quality scorecard: words coverage, example coverage, question schema validation, answer review, TTS verified, skill diversity, mission order, Boss coverage.
7. Start with `sec_1_unit_1`, then Units 2–10, and only then batch rollout by verified quality. Preserve HSK taxonomies and content provenance.

## 5. Gameplay and data invariants
- UI remains Chinese Fantasy Adventure; keep World→Section→Unit→Mission→Boss→Next Unit.
- Existing `duo_units.id`, `duo_levels.id`, `duo_challenges.id`, `boss_stages.id` and `lexicon_words.id` do not change during migration. Existing progress references stay valid.
- No XP reward change, Boss mastery threshold change or automatic unlock in a content migration.
- Guest progress remains persistent locally; signed-in progress stays in Supabase RLS. New content cannot cause replay rewards or progress loss.
- Rollout feature flag maps **unit + content release**, never mutates global IDs or replaces signed-in cached progress.
- If new Unit content has invalid or missing references, fall back to reviewed legacy content (not arbitrary different-Unit questions).

## 6. Prioritized implementation PRs
| PR | Scope | Proof before merge |
|---|---|---|
| V3-0 | Private editorial staging tables + documentation | Staging SQL, RLS permission, no active behavior difference |
| V3-1 | Read-only quality scanner by challenge type, candidate issues | Validator fixtures and report for all Units |
| V3-2 | Bilingual review workflow: translation variants, answer logic, pinyin, source hashes | Editorial approval on pilot Unit; no false automatic approvals |
| V3-3 | Typed read model and content publication RPC, index/EXPLAIN | Access controls, content parity, p50/p95 and payload |
| V3-4 | Flutter feature flag + Unit1 content, old-ID mapping, fallback | Guest + Cloud Stage→Boss→Next Unit, XP/SRS idempotency |
| V3-5 | Progressive rollout 2–10 → rest | Per-Unit quality pass, quick rollback and live telemetry |
| V3-6 | Cleanup only after old clients sunset | Backup, references/dependency audit, migration dry run, rollback |

## 7. Database migration controls
- First: backup current schema/data, list applied migrations, check staging resources and privileges. **Do not create paid Supabase branches without approval.**
- All DDL in reviewed migration, no destructive statements on production, no seed content overrides.
- Audit reports should not copy sensitive auth or learner attempts.
- `EXPLAIN (ANALYZE, BUFFERS)` on representative Unit/word lookup; measure database time and end-to-end Flutter network latency separately.
- Each publication is atomic and versioned, with reversible feature flag. Do not remove legacy content before users migrate.
- Run security advisors after deploying, validate RLS and DB RPC EXECUTE permissions.

## 8. Definition of DONE
- A student can learn each published Unit with correct translations, examples, valid answers, clear audio fallback, and accurate difficulty.
- Game runner still accepts old IDs and unlocks correct next mission/Boss/Unit in Guest and Cloud.
- SRS, XP, mastery/streak and history unchanged unless an explicitly tested product policy is approved.
- Reviewers approved source-to-publication audit; Unit migration is independently reversible.
- Flutter format/analyze/tests, staging SQL checks, device E2E, network/performance metrics, code review and merge `hieu`.
- **A report saying test PASS without runtime proof or linguistic quality review is not DONE.**

## 9. Status in this PR
Only the schema **proposal** and rollout plan are committed to GitHub feature branch. The V3 migration has NOT been run on Supabase, and no original tables/data or current Flutter behavior have been changed.
