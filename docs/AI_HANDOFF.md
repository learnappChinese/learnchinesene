# AI Handoff

## Timestamp + repo + branch + HEAD

- Timestamp: 2026-10-11 (Asia/Saigon)
- Repo: `D:\Projects\Flutter_Project\learnchinesene`
- Integration branch: `hieu`
- Feature branch: `feature/pr01-learning-progress-sync`
- Base: `a6186408c1fdc526409a09dae360a0e89ff3b1ef`
- PR01 implementation commit: `d990e5e155b3549eb2718090f91e7809ed0b9ac6`

## Phase / PR hiện tại

- PR00 baseline/status inventory: complete.
- PR01 `LearningProgressSyncService`: code, local automated acceptance, push and PR creation complete.
- PR02 mapping characterization is prepared but semantic mapping/database behavior has not been changed.

## Issue IDs đã xong

- `P0-01` DONE_CODE: typed domain invalidation, one reward success boundary, no gameplay dependency on `HomeController`.
- `P0-03` DONE_CODE: mounted Home/Progress/Game, Unit, Sections/Units, Review, Stats, XP History and Profile owners refresh by domain.
- `P1-05` DONE_CODE: Home slice-wise refresh with partial success and stale-response protection.
- `P1-08` DONE_CODE: review, flashcard and mark-learned invalidation.
- `P2-06` DONE_CODE: centralized app-resume invalidation.
- `P0-05`, `P1-01`, `P1-06`: PARTIAL; see `docs/IMPLEMENTATION_STATUS.md`.
- `P0-02` remains OPEN and is the next dependency.

## Files changed / migrations

Core implementation:

- `lib/core/learning/service/learning_progress_sync_service.dart` (new)
- `lib/core/learning/service/learning_reward_service.dart`
- `lib/di.dart`
- Home, Unit overview, Sections/Units, Review, Stats, XP History, Profile controllers/widgets.
- Completion callers in Duo, Boss, Speaking, Hanzi, Vocabulary Adventure and four Dragon/Panda mini-games no longer call Home directly.
- Flashcards, Word List and Word Detail emit lexicon invalidation after a successful write.

Tests:

- `test/core/learning/learning_progress_sync_service_test.dart` (new)
- `test/core/learning/duo_activity_mapping_characterization_test.dart` (new)
- `test/screen/home/home_controller_sync_test.dart` (new)

Documents:

- `docs/CURRENT_APP_FLOW_ARCHITECTURE.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/implementation_reports/PR_00_01.md`
- `docs/AI_HANDOFF.md`

SQL migrations: NONE. No database table/RPC/data mutation was made.

## Commands actually run + PASS/FAIL

- `git fetch origin`: PASS.
- PR00 baseline `flutter test test/core/learning`: PASS, 46 tests.
- PR00 baseline `flutter analyze`: FAIL on 145 pre-existing warnings/info issues; no compiler error.
- `dart format <changed Dart files>`: PASS.
- Focused `flutter test test/core/learning test/screen/home/home_controller_sync_test.dart test/screen/review/review_hub_test.dart test/screen/unit_overview/unit_overview_test.dart`: PASS, 65 tests.
- First parallel `flutter test`: FAIL because a worker closed while loading `duo_word_connect_state_test.dart`; a UI test then did not complete. No assertion failure was reported.
- Rerun of both affected files: PASS, 9 tests.
- `flutter test --concurrency=1`: PASS, 201 tests.
- Current `flutter analyze`: FAIL on 144 warnings/info issues (one fewer than baseline); no compile error and no new analyzer issue attributed to PR01.
- `flutter build apk --debug`: PASS; output `build/app/outputs/flutter-apk/app-debug.apk`. Gradle/AGP/Kotlin future-support warnings remain.
- Backend SQL integration: NOT_RUN (no live access).
- iOS smoke: NOT_RUN (Windows environment).

## Live Supabase verified?

NO.

- Supabase CLI: not installed.
- Supabase MCP/live database connection: unavailable.
- Latest committed migration inspected: `20261010101000_harden_learning_history_rls.sql`.
- Code and committed migrations were compared; production function bodies, response fields, grants/RLS drift and real user data were not verified.

## Pending blockers

- PR02 semantic mastery correction requires read-only live verification of `complete_learning_activity_v2`, `private.unit_mastery_for_user`, `unit_mastery_v2` and representative attempts before any migration/backfill.
- Authenticated multi-device, guest→login migration and account-switch acceptance require test accounts/live environment.
- Store entitlement PR requires store credentials/sandbox and approval for backend entitlement design.
- Existing repository analyzer debt: 144 warnings/info issues.

## Next exact 3 coding steps

1. On the existing feature/next branch, convert the PR02 characterization table into an explicit `gameCode → skill evidence` contract matching `LearningStageGroupingService`, without changing XP or old rows.
2. Verify that contract against live mastery RPC/function output; if live access is still unavailable, stop database work and report the exact required SQL/RPC evidence instead of guessing a migration.
3. Implement PR03 typed completion/navigation outcome, remove Boss `xpEarned: 50`, and align guest dependency traversal after PR02 evidence is accepted.

## Git status / PR URL

- Implementation commit: `d990e5e155b3549eb2718090f91e7809ed0b9ac6`.
- PR: https://github.com/learnappChinese/learnchinesene/pull/23 (base `hieu`).
- Worktree after handoff metadata update contains only unrelated untracked screenshot/image assets listed below.
- Preserve unrelated untracked user assets/spec files unless deliberately included; do not stage `docs/emulator_current.png`, `docs/screenshots/`, or `docs/unit_overview_stages_preview.jpg` for this PR.
