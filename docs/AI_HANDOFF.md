# AI Handoff

## Timestamp + repo + branch + HEAD

- Timestamp: 2026-10-11 (Asia/Saigon)
- Repo: `D:\Projects\Flutter_Project\learnchinesene`
- Integration branch: `hieu`
- HEAD: `110740e5e3946546417f2c09afe2cc6fceac9423` (PR 04 merged into `hieu`)
- Merged feature branch: `feature/pr04-auth-guest-cloud-migration`
- Base: `7999332` on `hieu` (contains PR 01, PR 02, PR 03)

## Phase / PR hiện tại

- PR00 baseline/status inventory: complete.
- PR01 `LearningProgressSyncService`: merged into `hieu` via PR #23.
- PR02 `Skill Taxonomy & Unit Mastery`: merged into `hieu` via PR #24 (`19a6118`).
- PR03 `Complete Learning Flow, Unlock & Boss Navigation`: merged into `hieu` via `9b3965e`.
- PR04 `Authentication, Guest Progress & Cloud Migration`: MERGED into `hieu` (`110740e`).
- Next dependency: PR 05 (`Security: IAP Verification & Gemini API Protection`).

## Issue IDs đã xong

- `P0-01` DONE_CODE: typed domain invalidation, one reward success boundary, no gameplay dependency on `HomeController`.
- `P0-02` DONE_CODE: standardized 11 Duo game codes to canonical activity types (`vocabulary`, `listening`, `speaking`, `dialogue`) and 4 skill buckets (`vocabulary`, `listening`, `speaking`, `hanzi`) via `LearningSkillTaxonomy`.
- `P0-03` DONE_CODE: mounted Home/Progress/Game, Unit, Sections/Units, Review, Stats, XP History and Profile owners refresh by domain.
- `P0-05` DONE_CODE: comprehensive Auth & Identity Lifecycle implemented (Guest mode, Sign In, Sign Up, Sign Out, session restore, password recovery, guest-to-cloud migration, and account switching with scoped cache invalidation).
- `P1-01` DONE_CODE: standardized `LearningResult` contract parsing with `boss_ready`, `unit_completed`, `next_unit_id`, and migration `20261011160000_complete_learning_activity_result_contract.sql`.
- `P1-02` DONE_CODE: removed hardcoded XP (`50` in Unit Complete, `+100 XP` in Boss Victory), dynamically rendering server reward.
- `P1-03` DONE_CODE: standardized navigation outcome with typed `LearningNavigationOutcome` (`completed`, `failed`, `paused`, `abandoned`, `cancelled`, `retry`, `nextMission`, `fightBoss`, `nextUnit`).
- `P1-04` DONE_CODE: guest mode level unlock now follows `reward.nextNodeId` / path dependencies rather than linear index guessing.
- `P1-05` DONE_CODE: Home slice-wise refresh with partial success and stale-response protection.
- `P1-08` DONE_CODE: review, flashcard and mark-learned invalidation.
- `P2-06` DONE_CODE: centralized app-resume invalidation.
- Next dependency: PR 05 (`P0-04` IAP & backend Gemini security).

## Files changed / migrations

Core implementation:

- `lib/core/auth/model/auth_state.dart` (new)
- `lib/core/auth/data/auth_repository.dart` (new)
- `lib/core/auth/service/guest_progress_migration_service.dart` (new)
- `lib/core/auth/controller/auth_controller.dart` (new)
- `lib/screen/auth/welcome_screen.dart` (new)
- `lib/screen/auth/login_screen.dart` (new)
- `lib/screen/auth/register_screen.dart` (new)
- `lib/screen/auth/forgot_password_screen.dart` (new)
- `lib/screen/auth/widget/guest_save_prompt_sheet.dart` (new)
- `lib/screen/splash/controller/splash_controller.dart`
- `lib/screen/system/widget/profile_achievements.dart`
- `lib/core/widgets/mission_complete_overlay.dart`
- `lib/di.dart`

Tests:

- `test/core/auth/auth_guest_cloud_migration_test.dart` (new)
- `test/core/widgets/learning_adventure_components_test.dart`

Documents:

- `docs/IMPLEMENTATION_STATUS.md`
- `docs/implementation_reports/PR_04.md` (new)
- `docs/AI_HANDOFF.md`

## Commands actually run + PASS/FAIL

- `flutter test test/core/auth/auth_guest_cloud_migration_test.dart`: PASS (12 tests).
- `flutter test test/core/auth/ test/core/widgets/`: PASS (22 tests).
- `flutter test --concurrency=1 test/core/learning/`: PASS (74 tests).
- `flutter test test/core/backend/supabase_config_test.dart`: PASS (1 test).
- `flutter analyze`: PASS (0 errors, 0 warnings across all PR 04 files).
- `dart format`: PASS (all 16 files formatted).
- Backend SQL integration: NOT_RUN (Supabase CLI / live instance not connected locally; migration file written for deploy).
- iOS smoke: NOT_RUN (Windows environment).

## Live Supabase verified?

NO.

- Supabase CLI: not installed.
- Supabase MCP/live database connection: unavailable in current IDE context.
- Migration file `20261011150000_unify_skill_taxonomy_and_unit_mastery.sql` handles server-side normalization, safe legacy `game_mission` backfill and unit mastery aggregation. Needs application via Supabase Dashboard / CLI in CI/CD or production.

## Pending blockers

- Live verification of migration `20261011150000_unify_skill_taxonomy_and_unit_mastery.sql` on remote Supabase instance.
- PR 03: Boss battle hard-coded XP (`xpEarned: 50`) and un-typed `Get.off` navigation flows.

## Next exact 3 coding steps

1. Begin PR 05: Security — IAP Verification & Gemini API Protection.
2. Replace client-only IAP handling with backend verification / receipts policy.
3. Secure Gemini API calls via backend proxy / edge function, avoiding client-side raw key exposure.

## Git status / PR URL

- Integration branch: `hieu`.
- Merge commit: `110740e5e3946546417f2c09afe2cc6fceac9423` (PR 04 merged).
- Feature branch merged: `feature/pr04-auth-guest-cloud-migration`.
- Next task: PR 05.
