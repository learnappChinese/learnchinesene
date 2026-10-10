# AI HANDOFF

## Repository

- Repo: `learnappChinese/learnchinesene`
- Base branch: `hieu`
- Current branch: `feature/learning-pro-ui-flow`

## Current Goal

Deliver one authoritative vertical slice for the Chinese Learning Adventure flow:
World -> Section -> Unit -> Stage -> Result -> Unlock, backed by live Supabase data.

## Completed Work

- Replaced client-side Unit counts/unlock inference with `learning_units_v2`.
- Replaced raw Section catalog/progression inference with `learning_sections_v2`.
- Corrected Unit ordering from database order fields rather than reversing labels.
- Built canonical stages from `unit_learning_path_v2`; one server path node is one meaningful stage.
- Made segmented stage progress dynamic from the real required challenge count.
- Preserved server states for locked, available, in-progress, failed, completed, and perfect stages.
- Preserved active-session progress and retry state in the Unit stage map.
- Fixed the HSK -> Unit route to resolve the authoritative duo Unit instead of passing a lexicon integer ID.
- Fixed stage launch to pass the real game-definition ID/code instead of a session ID.
- Removed runtime fallback to `sec_1_unit_1` from Unit Overview.
- Made Home and Learning Hub recommendations use current cloud progress and useful zero-due copy.
- Hardened authoritative learning history so authenticated clients can read their rows but cannot mutate XP/attempt ledgers directly.

## Files Changed

- `lib/core/learning/data/learning_journey_repository.dart`: authoritative Section/Unit/current-action/stage queries.
- `lib/core/learning/model/learning_journey_models.dart`: Section/Unit server progression fields.
- `lib/core/learning/model/learning_stage_models.dart`: source game and dependency metadata.
- `lib/core/learning/service/learning_stage_grouping_service.dart`: server-path stage grouping and dynamic segments.
- `lib/screen/home/data/home_journey_repository.dart`: cloud current-Unit journey.
- `lib/screen/home/home_screen.dart`: source-of-truth navigation fallback.
- `lib/screen/home/widgets/home_practice_tab.dart`: useful zero-due states.
- `lib/screen/hsk/hsk_screen.dart`: authoritative HSK order routing.
- `lib/screen/sections/learning_sections_screen.dart`: empty and friendly lock states.
- `lib/screen/unit/controller/unit_controller.dart`: lazy authoritative Unit resolution.
- `lib/screen/unit/unit_screen.dart`: canonical Unit Overview navigation and lock feedback.
- `lib/screen/unit_overview/binding/unit_overview_binding.dart`: required Unit identity.
- `lib/screen/unit_overview/controller/unit_overview_controller.dart`: no mock Unit fallback.
- `lib/screen/unit_overview/page/unit_overview_screen.dart`: correct stage game IDs/codes and lock copy.
- `test/core/learning/learning_stage_grouping_service_test.dart`: dynamic 3/5/6 segments, resume, retry, locks, perfect.
- `test/screen/home/home_practice_tab_test.dart`: zero-due copy.
- `test/screen/unit_overview/unit_overview_test.dart`: explicit test Unit identity.

## Database Changes

- `20261010093000_learning_units_source_of_truth.sql`: creates `learning_units_v2`.
- `20261010094500_learning_sections_source_of_truth.sql`: creates `learning_sections_v2`.
- `20261010095500_optimize_learning_sections_v2.sql`: removes per-Unit nested RPC work from Section projection.
- `20261010101000_harden_learning_history_rls.sql`: SELECT-only client grants and optimized own-row policies for XP/attempt history.
- Live migration versions: `20261010090516`, `20261010091553`, `20261010091728`, `20261010091901`.
- RLS/grants: `learning_attempts` and `learning_xp_events` grant authenticated SELECT only; authoritative writes remain behind narrow SECURITY DEFINER RPCs.
- Applied to live Supabase: **YES** (`hrlahralknhijnkypjix`).

## Current Architecture

World -> Section -> Unit -> Stage -> Item -> Boss

- World: Course / HSK and `lexicon_hsk_levels`.
- Section: `duo_sections`, projected by `learning_sections_v2`.
- Unit: `duo_units` / linked `lexicon_units`, projected by `learning_units_v2`.
- Stage: canonical node from `unit_learning_path_v2`, backed by `duo_levels` + `duo_sessions`.
- Item: required `duo_challenges` belonging to the stage level/game.
- Boss: `boss_stages` scoped to its Unit; progress in `boss_stage_progress`.

## Important Decisions

- Do not use a fixed stage size or arbitrary `take(4)` grouping.
- Segment count comes from real required challenge data.
- XP is reward; mastery is learning ability. They remain separate.
- Boss belongs to a Unit and gates the next Unit.
- Game Hub is practice/replay; it is not a second curriculum progression.
- Supabase is the source of truth; guest state is only a local overlay/fallback.
- Raw backend labels must never reach the UI.
- Do not show 310 levels/cửa ải on primary learning screens.

## Known Bugs

- MEDIUM — `lib/screen/game_hub/game_hub_screen.dart`: skill cards do not yet route to the current matching available curriculum stage in every case. Next fix: resolve by activity type before Quick Practice fallback.
- MEDIUM — `supabase/migrations/20261010094500_learning_sections_source_of_truth.sql`: Section completion currently assumes Unit completion through Boss clears. Next fix: support a future Unit without a Boss by falling back to required-stage completion.
- LOW — project-wide analyzer baseline: 143 warnings/info (deprecated APIs, unused fields/imports, prints) outside this vertical slice. Next fix: address incrementally without mixing into progression commits.

## Tests

- Format: PASS.
- Analyze: PASS with `--no-fatal-infos --no-fatal-warnings`; 0 errors, 143 baseline warnings/info.
- Focused tests: PASS, including dynamic segments, Unit Overview, responsive 320/360/390/440, Home, Review, Game Hub, Boss, progression rules.
- Full tests: PASS in bounded batches. A single monolithic invocation is terminated by the host runner; every affected file/group passed independently.
- Build: PASS; split release APKs produced for arm64-v8a, armeabi-v7a, and x86_64.
- Cloud-only guard: PASS using the equivalent PowerShell checks because Python is unavailable on the Windows host.
- CI: local workflow-equivalent checks PASS; remote workflow status must be checked after push.

## Git State

- Latest implementation commit SHA: `1fab090`.
- Latest handoff/checkpoint commit: resolve with `git log -1 --oneline`.
- Working tree: tracked files clean after the handoff commit; unrelated screenshot artifacts remain untracked and must not be committed.
- Pushed: YES to `origin/feature/learning-pro-ui-flow` after checkpoint completion.
- PR: not created in this session.

## NEXT STEP

Route Game Hub skill cards to the matching current available/in-progress curriculum stage before Quick Practice fallback.

- Likely files: `lib/screen/game_hub/game_hub_screen.dart`, `lib/core/learning/data/learning_journey_repository.dart`, corresponding Game Hub tests.
- Completion condition: Speaking/Listening/Hanzi/Sentence cards open the matching current Unit stage when one exists, otherwise open Quick Practice, with navigation tests passing.

## DO NOT REDO

- Do not repeat the schema/product audit.
- Do not reintroduce client-side unlock inference or arbitrary index+1 progression.
- Do not reintroduce default `sec_1_unit_1` runtime data.
- Do not chunk stages into a fixed number of challenges.
- Do not create duplicate XP/attempt tables or bypass `complete_learning_activity_v2`.
- Do not stage or delete the untracked emulator/screenshots owned by the user.
