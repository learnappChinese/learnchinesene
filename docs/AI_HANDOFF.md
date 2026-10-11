# AI Handoff

## Timestamp + repo + branch + HEAD

- Timestamp: 2026-10-11 (Asia/Saigon)
- Repo: `D:\Projects\Flutter_Project\learnchinesene`
- Integration branch: `hieu`
- Feature branch: `feature/pr02-skill-taxonomy-unit-mastery`
- Base: `6658d662811ad8178cef224d9d1986121a5937c6` (PR #23 merged into `hieu`)
- PR02 implementation commit: pending

## Phase / PR hiện tại

- PR00 baseline/status inventory: complete.
- PR01 `LearningProgressSyncService`: merged into `hieu` via PR #23.
- PR02 `Skill Taxonomy & Unit Mastery`: code, unit tests, local guest calculation, and SQL migration prepared.

## Issue IDs đã xong

- `P0-01` DONE_CODE: typed domain invalidation, one reward success boundary, no gameplay dependency on `HomeController`.
- `P0-02` DONE_CODE: standardized 11 Duo game codes to canonical activity types (`vocabulary`, `listening`, `speaking`, `dialogue`) and 4 skill buckets (`vocabulary`, `listening`, `speaking`, `hanzi`) via `LearningSkillTaxonomy`. Supabase migration `20261011150000_unify_skill_taxonomy_and_unit_mastery.sql` updates `private.unit_mastery_for_user` & `unit_mastery_v2` with safe legacy `game_mission` backfill. Guest fallback in `SupabaseLearningProgressRepository._fetchLocalUnitMastery` computes real mastery from local attempts.
- `P0-03` DONE_CODE: mounted Home/Progress/Game, Unit, Sections/Units, Review, Stats, XP History and Profile owners refresh by domain.
- `P1-05` DONE_CODE: Home slice-wise refresh with partial success and stale-response protection.
- `P1-08` DONE_CODE: review, flashcard and mark-learned invalidation.
- `P2-06` DONE_CODE: centralized app-resume invalidation.
- `P0-05`, `P1-01`, `P1-06`: PARTIAL; see `docs/IMPLEMENTATION_STATUS.md`.
- Next dependency: PR 03 (`P1-01`, `P1-02`, `P1-03`, `P1-04`).

## Files changed / migrations

Core implementation:

- `lib/core/learning/model/learning_skill_taxonomy.dart` (new)
- `lib/core/learning/service/learning_reward_service.dart`
- `lib/core/learning/data/learning_progress_repository.dart`

Tests:

- `test/core/learning/duo_activity_mapping_characterization_test.dart`
- `test/core/learning/skill_taxonomy_unit_mastery_test.dart` (new)

SQL migrations:

- `supabase/migrations/20261011150000_unify_skill_taxonomy_and_unit_mastery.sql` (new)

Documents:

- `docs/IMPLEMENTATION_STATUS.md`
- `docs/implementation_reports/PR_02.md` (new)
- `docs/AI_HANDOFF.md`

## Commands actually run + PASS/FAIL

- `flutter test --concurrency=1 test/core/learning/duo_activity_mapping_characterization_test.dart test/core/learning/skill_taxonomy_unit_mastery_test.dart`: PASS (10 tests).
- `flutter test --concurrency=1 test/core/learning/`: PASS (63 tests).
- `flutter analyze lib/core/learning/model/learning_skill_taxonomy.dart lib/core/learning/service/learning_reward_service.dart lib/core/learning/data/learning_progress_repository.dart test/core/learning/duo_activity_mapping_characterization_test.dart test/core/learning/skill_taxonomy_unit_mastery_test.dart`: PASS (0 issues found).
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

1. Create GitHub PR for PR 02 against `hieu`.
2. Transition to PR 03: implement typed completion & navigation outcome (`LearningCompletionOutcome`).
3. Refactor `BossBattleScreen` and Unit Complete to remove hard-coded XP/star parameters and use server-authoritative results.

## Git status / PR URL

- Implementation branch: `feature/pr02-skill-taxonomy-unit-mastery`.
- Base branch: `hieu`.
- Target PR: PR 02.
