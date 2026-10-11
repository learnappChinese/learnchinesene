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

- `lib/core/learning/data/learning_journey_repository.dart`: authoritative Section/Unit/current-action/stage queries and `getCurrentStageForActivities` / `getCurrentStageForActivity`.
- `lib/screen/game_hub/game_hub_screen.dart`: routes skill cards (Speaking, Listening, Hanzi, Sentence) to matching current curriculum stage before Quick Practice fallback.
- `test/screen/game_hub/game_hub_navigation_test.dart`: tests for stage resolution priority, curriculum routing, and Quick Practice fallbacks.
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

- RESOLVED — `lib/screen/game_hub/game_hub_screen.dart`: skill cards (Speaking, Listening, Hanzi, Sentence) route to matching current available/in-progress curriculum stage before Quick Practice fallback.
- MEDIUM — `supabase/migrations/20261010094500_learning_sections_source_of_truth.sql`: Section completion currently assumes Unit completion through Boss clears. Next fix: support a future Unit without a Boss by falling back to required-stage completion.
- LOW — project-wide analyzer baseline: 143 warnings/info (deprecated APIs, unused fields/imports, prints) outside this vertical slice. Next fix: address incrementally without mixing into progression commits.

## Tests

- Format: PASS.
- Analyze: PASS with `--no-fatal-infos --no-fatal-warnings`; 0 errors.
- Focused tests: PASS (24/24 passed across `unit_overview_test.dart`, `unit_complete_screen_test.dart`, `game_hub_navigation_test.dart`, `vocabulary_adventure_test.dart`).
- Full tests: PASS in bounded batches.
- Build: PASS.

## Adventure Game Flow Alignment (Mermaid Source of Truth)

The end-to-end learning adventure progression flow strictly conforms to the Mermaid diagram:
`HOME -> Learning Hub -> World Map -> Section -> Unit -> Stage -> Challenge -> Result -> Unit -> Boss Gate -> Boss Battle -> Boss Result -> Unit Complete -> Next Unit`

1. **Next Unit Resolution (`LearningJourneyRepository`):**
   - Added `Future<LearningUnitViewModel?> getNextUnit(String currentUnitId);` to `LearningJourneyRepository` and implemented it in `SupabaseLearningJourneyRepository`.
   - Traverses units in section order; advances to subsequent section when completing the final unit of a section.

2. **Unit Progression State (`UnitOverviewController`):**
   - Added `nextUnit`, `hasBoss`, `isBossDefeated`, `isUnitCompleted`, `isBossReady`.
   - Automatically loads `nextUnit` upon unit completion.

3. **Celebratory Unit Complete Screen (`UnitCompleteScreen`):**
   - Created `lib/screen/unit_overview/page/unit_complete_screen.dart`.
   - Victory Panda Companion, 3-star ranking, rewards (+50 XP, 100% Mastery).
   - Primary Action: "BÀI HỌC TIẾP THEO: [Tên Bài]" -> navigates to next unit.
   - Secondary Action: "Xem lại bài học vừa hoàn thành" -> returns to Unit Overview.

4. **Boss Battle Transition (`BossBattleScreen`):**
   - Fixed infinite victory loop: Victory screen continues to `UnitCompleteScreen`.
   - Defeat screen returns `result: false` back to Unit Overview.

5. **Stage Runner Return Pass Result (`DuoGameRunnerScreen`):**
   - `MissionCompleteOverlay` passes `result: true` / `result: result.passed` back to Unit Overview so stage progression immediately refreshes with feedback SnackBars.

6. **Boss Gate Presentation (`UnitOverviewScreen`):**
   - Added Boss Gate Card and interactive modal dialog (`_openBossGateModal`) displaying boss stats (HP 100 vs Player HP 100, question count).
   - Dynamic primary CTA seamlessly adapts:
     - "BÀI TIẾP THEO: [Title]" (when completed)
     - "KHIÊU CHIẾN BOSS" (when boss ready)
     - "BẮT ĐẦU ẢI [X]: [Title]" / "TIẾP TỤC ẢI [X]: [Title]" (in progress).

7. **Responsive & Navigation Fixes:**
   - `GameScreenHeader`: Wrapped title text in `Expanded` to prevent horizontal RenderFlex overflow across narrow device widths.
   - Hierarchy linking: `HskScreen` added "Phần học" action button to `LearningSectionsScreen`; `HomeLearningTab` links directly to `LearningSectionsScreen`.

## Git State

- Working tree: clean of untracked test/source files; untracked screenshot/emulator files preserved.
- Branch: `feature/learning-pro-ui-flow`.

## NEXT STEP

- Monitor CI/CD run on push.
- Review boss battle difficulty curve and rewards balancing in production telemetry.

## DO NOT REDO

- Do not repeat the schema/product audit.
- Do not reintroduce client-side unlock inference or arbitrary index+1 progression.
- Do not reintroduce default `sec_1_unit_1` runtime data.
- Do not chunk stages into a fixed number of challenges.
- Do not create duplicate XP/attempt tables or bypass `complete_learning_activity_v2`.
- Do not stage or delete the untracked emulator/screenshots owned by the user.
