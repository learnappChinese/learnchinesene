# PANDARIN — MASTER IMPLEMENTATION PROMPT
## Local-first, no login, HSK curriculum, Hanzi writing and Flashcards/SRS

**Mode:** Senior Flutter Architect + Learning Experience Designer + SQLite/Drift Data Architect + Migration Engineer + QA Lead.

**Goal:** Implement the next safe development stage of the existing Pandarin Flutter app using evidence from the actual repository and database. Preserve existing lessons, game/learning semantics, stable IDs and user progress. Turn the app into a **no-login local-first** Chinese learning product focused on **HSK lessons, Hanzi writing and Flashcards/SRS**. Keep a pathway for future opt-in account-based sync, but **do not implement user cloud sync or login now**.

**Language of all reports and user-facing UI:** Vietnamese. Code/style conventions follow the repository.

---

## 0. Source-of-truth rules — mandatory

Read all 14 reports in `docs/architecture_audit/00_...md` through `13_...md` as leads, NOT as unquestionable truth. Re-open the real Flutter source code, current migrations and the real Supabase schema; evidence from implementation and current database overrides reports. The audit files contradict each other in paths, table names, controllers and navigation trees, especially `11_MERMAID_DIAGRAMS.md`, `12_RECOMMENDATIONS.md`, and `13_EVIDENCE_INDEX.md` versus earlier reports. Do not copy hypothetical classes or code from them. Verify each symbol before editing.

A read-only verification of Supabase project `hrlahralknhijnkypjix` on **2026-10-20** established:

- `lexicon_hsk_levels`: **4 actual rows**, HSK 1–4. There is no verified content for HSK 5–6 in this table.
- `lexicon_units`: **130**; HSK 1: 10 units, HSK 2: 30, HSK 3: 30, HSK 4: 60.
- `lexicon_words`: **2,205**; split across HSK 1–4: 116 / 637 / 531 / 921. There was 1 word with empty Pinyin, 0 with empty Vietnamese meaning, and 2,205 nonempty `tts_url` strings; the URLs were NOT tested for reachability.
- `lexicon_examples`: **7,925**; `lexicon_word_units`: **2,299**; `lexicon_characters`: **935**, all with nonempty stroke paths.
- `duo_sections`: **8**; `duo_units`: **310**; `duo_levels`: **310**; `duo_sessions`: **1,536**; `duo_challenges`: **64,828**; `duo_flashcards`: **12,101**.
- `duo_flashcards`: **3,468** missing Pinyin, **643** missing meaning, **3,320** missing TTS URL. All 12,101 `word` entries were distinct in the query; do not assume they match the 2,205 lexicon words.
- Real challenge `type` values include: `translate`, `dialogue`, `match`, `listenTap`, `assist`, `gapFill`, `tapComplete`, `select`, `orderTapComplete`, `patternTapComplete`. Audit reports use some differing labels: verify parsers and mappings.
- Actual cloud table names have the `duo_` prefix (`duo_courses`, `duo_sections`, `duo_units`, `duo_levels`, `duo_sessions`, `duo_challenges`), not bare `courses`, `sections`, `units`, `levels`, `sessions`, `challenges`.
- No foreign key was found directly connecting `duo_units` to `lexicon_units`. Eight Duo path sections are **NOT equivalent** to eight HSK levels. Sample Duo sections are named `Path Section 0` etc. **Never map section number to HSK level without verified curriculum data.**
- There is a `content_sync_manifest` table for content import bookkeeping. Review whether to reuse its concept for versioned local packs.
- Cloud user tables (`learning_attempts`, `learning_xp_events`, `app_user_stats`, and related progress tables) were empty in the queried project. This does **not** prove that local guest progress is empty.

Before implementation repeat critical metadata queries read-only to ensure no changes since the snapshot. Never put a `service_role`/secret key in Flutter. Do not modify, drop or replace tables/functions/policies in live Supabase, do not delete existing learning content or cloud authentication infrastructure.

## 1. Product direction and non-negotiables

1. No login/register/social sign-in/password, no auth gate, no guest sign-in RPC or `AuthController.continueAsGuest()` requirement in any startup, navigation or learning path. App first frame must work without Supabase initialization or network.
2. Generate a stable random local profile UUID on first run and persist it on device. It is a **local identity**, not `auth.users.id` and not a pseudo-auth token. One local learner profile is enough for v1; preserve multi-profile extensibility without exposing it.
3. **All mutable learner data stored in transactional SQLite**, NOT solely SharedPreferences or RAM: stages, progress, SRS, writing, quiz/review attempts, XP, history, streak, boss if exposed, bookmarks and session checkpoints.
4. SharedPreferences only for lightweight UI settings (theme, audio preference, onboarding flags); NOT source of truth for study progress.
5. Content can originate from existing Supabase and old assets but must be made available through a **versioned local content database/packs** to support offline study. No network for the core learning loop. Keep `Supabase` only as an optional, nonblocking, read-only content-update source for future versioned packs, not as an authority for learner progress.
6. Do not rewrite GetX, Flutter UI, challenge engine, existing character stroke validator or existing reward business rules unless a measured defect requires targeted refactoring. Preserve stable content/source IDs and attempt IDs.
7. Hide all features requiring generative AI (Gemini chat, AI dictionary/generation/analysis, AI conversations, AI-generated HSK exams, AI history entries, AI CTA and AI paywall/quota). Remove links from navigation and shortcuts; preserve code behind **default-OFF compile-time/release feature flags** for later. Do not delete historical AI files or push them anywhere. Distinguish native OS TTS/audio playback from generative AI; TTS can stay.
8. Prioritize a coherent study loop rather than expanding games: **choose HSK level → choose unit → learn vocabulary/examples → practice character writing → answer lesson questions → add/review flashcards → see local progress**.
9. Preserve prior guest data during migration. Never silently reset old users' XP, completions or SRS. Do not create fake histories/stars to cover missing data.
10. In HSK selector, show verified HSK 1–4. HSK 5–6 may appear only as clearly disabled “Chưa có nội dung” if product design calls for it; do not fabricate lessons or progression.

## 2. Phase A — re-audit and freeze an implementation contract (must deliver before code edits)

- Inspect the live repository, routes, bindings, DI, `SplashController`, `AppBootstrap`, `AuthController`, guest store, `DbHelper`, `DuoDbHelper`, current `LearningRewardService`, `LearningProgressSyncService`, `LearningSessionComposer`, writing, flashcards, review, home/profile/stats and AI surfaces.
- Document **exact current data flow** for each of: lesson list; unit/stage unlock; complete stage; boss victory; flashcard grading; due review; writing result; reward and history. For each give path: UI → Controller → Service → Repository → local/cloud table → UI refresh.
- Identify migrations and serialization formats of `GuestLearningProgressStore` and keys like `guest_learning_completed_stages_v1`, `guest_learning_completed_bosses_v1`, `guest_learning_xp_events_v2`, `guest_learning_attempts_v2`, `duo_game_session_v2_*` and any other keys discovered from code.
- Audit existing data mapping: `UnitBridgeResolver`, `lexicon_word_units`, `lexicon_examples`, `duo_levels`, `duo_sessions`, `duo_challenges`, `duo_flashcards`, `boss_stages`. Mark all mappings VERIFIED / AMBIGUOUS / MISSING. Do not guess by similar titles alone.
- Analyze content quality per HSK/unit, missing Pinyin/meaning/audio/stroke paths, duplicate/nonnormalized terms, out-of-level questions, inaccessible units, broken prerequisites. Respect actual data, not expected HSK textbook word counts.
- Write `docs/local_first/00_AS_IS_GAPS_AND_DECISIONS.md` with evidence (real paths/methods/SQL) and a changed-files plan. If a premise is not verifiable, mark it and choose a conservative safe option; continue implementation of verified parts.

## 3. Phase B — local database schema, source of truth and curriculum mapping

**Technical default:** SQLite via `drift` (with `sqlite3_flutter_libs` or currently supported platform-backed package confirmed from real project dependencies), using explicit versioned migrations and transactions. If a mature equivalent SQLite layer is already present, compare before introducing a new dependency. Prefer one managed SQLite database with **content tables** and **user tables clearly separated by naming/repositories** to avoid cross-file attach complexity. Do not store 64k question payloads as 64k independent SharedPreferences keys.

### 3.1 Content/curriculum tables (read-only in app business layer)

Create/import versioned local equivalents, with original stable source IDs and types:

- `content_packs(pack_id, version, checksum, content_schema_version, imported_at, status, ...)`: manifest and verified import history.
- `hsk_levels`, `lexicon_units`, `lexicon_words`, `lexicon_examples`, `lexicon_characters`, `lexicon_word_units` — preserve actual lexicon relationships, keys, Pinyin, meaning, original HSK attribution, stroke geometry, and audio paths.
- `duo_sections`, `duo_units`, `duo_levels`, `duo_sessions`, `duo_challenges`; `duo_flashcards` imported separately as supplementary data, **not automatically declared mastered or assigned a HSK level**.
- `curriculum_unit_bridge(duo_unit_id, lexicon_unit_id, source, confidence, verification_status, content_version, ...)`: explicit source-backed mapping, potentially multiple mappings. Any unmatched Duo/lexicon unit stays unmatched and available in its validated standalone pathway rather than being force-joined.
- Optional `lesson_word_map(unit_namespace, unit_id, word_id, source, sort_order, ...)`: derive only from verified links / curated reviewed mappings. Keep a distinguishable namespace for Duo vs Lexicon IDs to avoid collision.
- Optional `lesson_prerequisites`, `lesson_activity_plan` for the local learning sequence (vocabulary → writing → lesson exercises → review). Distinguish curriculum content from learner progress.
- Optional indexed `word_search` FTS5 if truly needed for offline dictionary search; otherwise use relevant indexed filters. Avoid unnecessary FTS/index complexity on v1.

**IMPORTANT:** Do not rewrite imported `duo_challenges.type` values to report-invented names without a reversible mapping layer. Validate existing `ChallengeGameplayResolver` compatibility and exclude unsupported challenge types with explicit counts and UI fallback, not crashes.

### 3.2 User/progress tables (write only local, transactional)

Suggested normalized entities; adjust fields to real domain types, but preserve semantics:

- `local_profiles(local_id TEXT PK, created_at, locale, profile_schema_version, ...)`.
- `activity_attempts(attempt_id TEXT PK, local_id, activity_type, source_namespace, source_id, unit_id, level_id, started_at, finished_at, status, score, accuracy, correct_count, wrong_count, duration_seconds, stars, metadata_json, ...)`.
- `active_sessions(session_key TEXT PK, attempt_id, activity_type, source_id, state_json, updated_at)` for robust pause/resume, including question order, answered state, counters and version.
- `stage_progress(local_id, level_id, status, best_score, best_stars, completed_at, last_attempt_id, PRIMARY KEY(local_id,level_id))`.
- `unit_progress(local_id, unit_namespace, unit_id, completed_at, last_opened_at, ...)` only if useful as a rebuildable read model; never use it to contradict stages/requirements.
- `word_srs(local_id, word_id, familiarity_stage, ease_factor, interval_days, repetition_count, due_at, last_reviewed_at, correct_count, wrong_count, ...)`; unique `(local_id,word_id)`. The word ID must be from a known dictionary; supplementary Duo cards need explicit stable namespace or mapping.
- `srs_reviews(review_id TEXT PK, attempt_id, local_id, word_namespace, word_id, grade, reviewed_at, previous_due_at, next_due_at, ...)` for auditability/history where justified.
- `hanzi_progress(local_id, character_id, attempts, best_accuracy, completed_strokes, last_practiced_at, ...)`, keyed by known lexicon character ID.
- `xp_events(event_id TEXT PK, event_key TEXT UNIQUE, local_id, attempt_id, activity_type, source_id, base_xp, bonus_xp, xp_amount, earned_at, rule_version, ...)`. Immutable ledger; total XP calculated by sum or maintained as a transactional, rebuildable aggregate.
- `study_days(local_id, study_date_local, qualifying_attempt_id, PRIMARY KEY(local_id,study_date_local))` or derive from attempts/XP; never calculate streak from `DateTime.now()` pretending user studied.
- `app_settings` / `local_favorites` only as needed. Optional `sync_outbox(event_id PK, entity_type, entity_id, action, payload_json, local_revision, created_at, status)` is allowed for future sync; **never upload now**.

Key schema rules: SQLite foreign keys ON; required indexes for `(hsk_level, sort_order)`, unit-word lookup, `(local_id, due_at)`, attempts by time, stage lookup, XP date; unique event key; UTC timestamps plus chosen calendar timezone for streaks; `schema_version`/`content_version` tracking. No remote `auth.uid()` requirement, no auth-dependent DAO methods. Use bounded queries and lazy loading for large catalog. Document rules for content ID stability, upgrade/version conflicts and resolving removed IDs.

### 3.3 Local engine and repository boundary

Existing Flutter views/controllers should call interfaces (with names adapted to real code), such as:

- `CurriculumRepository`: load HSK, ordered units, content, playable lesson stages, prerequisites.
- `LearningProgressRepository`: start/resume/finish attempt, mark stage complete, calculate unlock state, boss result.
- `WordReviewRepository`: enroll words, due reviews, review grade, summary.
- `HanziRepository`: current unit's characters, stroke data, writing result.
- `LearningHistoryRepository`: attempts, XP ledger, streak, stats, profile.

Implement **local** repositories and route ALL production UI consumers to the same stores; retain cloud read-only content-fetch adapters behind content infrastructure if necessary. Preserve typed `LearningDomainEvent` / `LearningProgressSyncService` so Home, Profile, Journey, History, Review, Writing all refresh after transaction commits.

### 3.4 Atomic commit / idempotency

One successful completed attempt → one SQLite transaction updating activity attempt + stage/boss progress + eligible words/SRS + XP event + study day as appropriate. Use unique `attempt_id` and `event_key`, handle double-tap, crash/retry and replay safely. Preserve verified existing `LearningRulesService` scoring and boss unlock policies; if Guest and signed-in rules disagree, document and define one local rule set explicitly instead of accidentally relaxing requirements. XP bonus for first-clear must not be issued twice. In-memory widgets are NOT authoritative state.

## 4. Phase C — migrate pre-existing Guest progress safely

- On first local DB initialization, detect known `SharedPreferences` guest keys and map them into normalized tables in an **idempotent migration transaction**, recording migration ID, source snapshot hash, migrated row counts, warnings, completion timestamp.
- Preserve existing stable IDs. If a referenced old level/source ID is missing from local content pack, keep an `unresolved_legacy_progress` record for later reconciliation; do not delete it.
- Never wipe/overwrite original SharedPreferences keys during the first migration. Keep them for rollback until independent verification and a future explicit retention policy.
- Do not award XP again for imported guest completions. Reconstruct XP ledger from previous actual guest events using stable event keys; if only an aggregate is available, track provenance as a migration adjustment rather than inventing fake gameplay events.
- Verify one-time migration, repeated launch, app update, intermittent crash, local backup/restore, date/daytime normalization. Report unmatched keys and manual-review entries.

## 5. Phase D — core UX, clear lesson navigation and progression

**Suggested simple primary navigation:** `Hôm nay` · `Lộ trình HSK` · `Luyện viết` · `Flashcards`, with stats/settings/profile accessible from an icon/screen. Adapt to existing `HomeScreen` architecture rather than replacing navigation wholesale if costly. De-emphasize Game Hub until persistence and content scoping are verified.

### Screen 1: Today / Home
- Today's goal: continue current HSK unit; XP, streak, learned words, due cards read from **local** stores. Single prominent **Tiếp tục học** CTA. Link to current unit's writing and its review queue.
- No misleading 0 XP profile. No AI, login, cloud-dependent splash or inaccessible quick actions.

### Screen 2: HSK Path
- Display actual available HSK 1–4, unit order and learning objectives from verified schema. HSK 5–6: disabled/nonexistent with an honest label, never a playable placeholder.
- Unit view shows words/examples, available writing characters, real challenge types and progress, prerequisites, clear next action. Unlock sequentially based on the current rule; completed lessons remain replayable.
- **Previous lessons** must stay accessible for revision with correct original scores and progress, and exercises should not introduce vocab beyond the selected unit/learned HSK scope except where explicitly explained.
- Duo path units and lexicon units remain distinct when mapping is unknown. A bridging/curation screen or report can assist content mapping; no automatic joins from titles or section number.

### Screen 3: Hanzi writing
- Choose HSK → unit → characters from its vocabulary. Show Hanzi, Pinyin, meaning, stroke animation/order, practice canvas, retry, next character, mastered history.
- Load character IDs and stroke geometry in a bounded query, parse/cache per character, and prefetch a few next characters. **Never download/reload all lexicon words on every `nextCharacter()`**.
- Persist actual writing performance locally, not just UI animation. No random out-of-unit characters in a unit-specific writing session. Graceful fallback for missing/invalid paths.

### Screen 4: Flashcards + SRS
- Entry points: `Mới học`, `Cần ôn hôm nay`, `Đã thuộc`, optionally filter HSK/unit and bookmark.
- Front shows Hanzi (optional audio); back reveals Pinyin, Vietnamese meaning, an existing example and its translation. Give controls `Quên`, `Khó`, `Tốt`, `Dễ` (or confirmed existing options) whose effect is a central, documented SRS scheduling policy. **Do not count a flip as a successful review.**
- On vocabulary completion, enroll the actual newly learned word IDs into SRS. Review schedule and next due time survive app restart. Repeated grades must not create duplicate word rows.
- Do not combine all 12,101 Duo flashcards with HSK 1–4 vocabulary without verified mapping/coverage. Enrich missing values from verified lexicon matches only when safe and logged; otherwise omit/flag incomplete cards.

### Other existing features
- Keep conventional existing static listening/quiz/exercise flows that work offline and are scoped to current unit; gamification/boss is secondary. For the broken Game Hub Boss flow, either disable launch in release or make it use a single transactional local reward/progress service before exposing it.
- Preserve OS TTS and local audio. Centralize TTS/audio focus; when `tts_url` is missing/unreachable use available language-checked `zh-CN` engine if supported, report instructions if not, and avoid concurrent `FlutterTts` instances. Remote audio links may need offline asset caching; label content needing internet rather than claiming fully offline sound when not cached.
- Remove all AI widgets/tabs/quick actions and indirect deep links from release. Verify no default Gemini Edge Function requests in startup, screens or background calls.

## 6. Phase E — size, performance and offline content strategy

64,828 Duo challenges + 12,101 Duo flashcards could materially affect app package size and local query memory. Benchmark a **representative export before deciding content packaging**. Prefer compressed/versioned content packs or bundling only validated first-launch core content while keeping optional packs for additional verified HSK levels. For any HSK level claimed to be offline-available, its promised lessons, examples, stroke data and required question types must genuinely be on device. No unannounced dependence on cloud after splash.

- Export content from Supabase in batches (read-only) in a development/admin environment. Preserve types (including JSONB) and primary keys. Do not embed secret keys or ship admin credentials.
- Add content import checks: row counts, checksum, foreign keys, per-level unit/word counts, missing audio/pinyin/meaning, supported question types, 1→N mapping coverage and no duplicate IDs.
- Content updates must never delete `local_profiles`, `word_srs`, `stage_progress`, `activity_attempts`, `xp_events`, `hanzi_progress` or `active_sessions`. Import into staging tables transactionally, validate and swap on success. On failure keep last good content.
- Benchmark warm/cold launch, HSK list, unit load, 20-card review, `nextCharacter()`, and 10-question lesson on low-end Android device. Avoid any `SELECT *` catalog load or global re-fetch on each tap.

## 7. Phase F — prepare future opt-in sync, do NOT activate it now

Persist local UUIDs/IDs, local event history, immutable XP events and content version references so a future account-linking flow can export/import deterministically. Build a documented abstraction only, not a real network uploader. Define future behaviors for identity mapping, idempotent upload, conflict resolution (max stage achievements, latest SRS grade with causal event order, immutable XP events without duplication), backup/restore and revocation. No login page or background upload in v1.

Privacy: local data may be lost upon app uninstallation/device failure. Add user-facing disclosure in Settings and consider **optional explicit local encrypted backup/export/import** if feasible; do not promise automatic recovery.

## 8. Minimum acceptance tests (blocking release)

1. Fresh install in airplane mode → reaches Home without account and loads at least the promised bundled HSK learning content.
2. Existing Guest with stage completions/XP → update app → same visible completed stages, XP, history and unlock state; opening repeatedly does not duplicate awards.
3. Start HSK 1 Unit 1 → finish vocabulary/lesson → SRS word enrollments exist → Due queue and Home/Profile update from same SQLite database.
4. Finish a stage, kill app and relaunch → progress retained; finish same attempt twice → one XP event.
5. Review Flashcard `Quên/Khó/Tốt/Dễ` → timestamps and due queue update correctly; day boundary/timezone tested.
6. Write 10 characters sequentially → `nextCharacter()` no full lexicon/cloud reload, UI responsive, results retained after force close.
7. Test previously completed unit replay, sequential unlock, boss first-clear and next-unit Back stack behavior.
8. Test missing/invalid Pinyin, meaning, audio and stroke data and unsupported Duo challenge types without crash.
9. Test switching tabs / app resumed → stats, XP, review count and stage progress stay consistent, no duplicated getters/API reload storms.
10. Login/Register/AI routes, CTA, bottom tabs, shortcuts, deep links inaccessible in release. No Gemini request or auth required when offline.
11. SQLite foreign keys, migrations, indexes, local UUID, integrity checks and content pack rollback pass tests.
12. Unit tests for pure rules/repositories, widget tests for study/review/writing, integration tests for migration and offline launch; run `flutter analyze` and `flutter test`, report actual results (do not fabricate success).

## 9. Delivery protocol — implement in safe vertical slices

Work on a dedicated branch. First produce docs/decisions, then implement and test in this order:

**Slice 1 — Local boot + storage contract:** remove auth gate and mandatory cloud bootstrap; create SQLite schema/repositories/DI; bundle a minimal verified local curriculum and test offline startup. Preserve old guest prefs.

**Slice 2 — Migration + coherent progress:** migrate Guest prefs idempotently; implement central atomic reward/attempt/XP/streak logic and shared local progress reads; fix Home/Profile inconsistency and navigation bug.

**Slice 3 — HSK curriculum/data mapping:** import validated Lexicon and Duo catalogs; ordered HSK 1–4 units; bridge map with confidence; session challenge conversion, safe content-pack integrity and performance.

**Slice 4 — Flashcards/SRS:** local due queue, unit enrollment, review events, progress dashboards and thorough tests.

**Slice 5 — Writing:** per-HSK/unit character sessions, indexed bounded stroke queries, cache, persistence and responsive screen UX.

**Slice 6 — Release cleanup:** AI default-OFF flags, hide all AI/login entry points, address broken Game Hub Boss (fix or hide), centralize TTS, performance/QA audit and final regression suite.

For each slice output: changed file paths, important code diffs, schema migrations, reasoning, test command and actual outcomes, unresolved issues and rollback instructions. Do not claim complete while core test cases fail. No production Supabase schema mutation. If a big rewrite appears necessary, prefer an adapter/strangler migration and prove it with tests.

### Required documentation outputs

- `docs/local_first/00_AS_IS_GAPS_AND_DECISIONS.md`
- `docs/local_first/01_DATABASE_SCHEMA.md` (full SQLite DDL/Drift schema + indexes + FK, ERD Mermaid)
- `docs/local_first/02_CONTENT_MAPPING_AND_QUALITY.md` (HSK coverage, verified unit bridge map and missing data)
- `docs/local_first/03_LOCAL_MIGRATION_PLAN.md` (old Guest pref keys → tables, rollback)
- `docs/local_first/04_NEW_NAVIGATION_AND_SCREEN_FLOWS.md` (click-to-data flow for learning, writing, flashcards)
- `docs/local_first/05_PROGRESS_REWARD_SRS_RULES.md`
- `docs/local_first/06_FUTURE_SYNC_CONTRACT_NOT_IMPLEMENTED.md`
- `docs/local_first/07_QA_PERFORMANCE_REPORT.md`
- `docs/local_first/08_RELEASE_FLAGS_AND_HIDDEN_FEATURES.md`

**Begin with actual files and schema; do not reply only with generic advice. Deliver Slice 1 and its verification, then proceed through safe slices as supported by context. Prioritize correct learner data and old lessons over decorative UI or adding new AI/game features.**
