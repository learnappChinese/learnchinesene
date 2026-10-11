# AI Handoff

## Timestamp + repo + branch + HEAD

- Timestamp: 2026-10-11 (Asia/Saigon)
- Repo: `D:\Projects\Flutter_Project\learnchinesene`
- Integration branch: `hieu`
- Feature branch: `feature/pr05-security-iap-gemini`
- Base: `110740e5e3946546417f2c09afe2cc6fceac9423` on `hieu` (contains PR 01, PR 02, PR 03, PR 04)

## Phase / PR hiện tại

- PR00 baseline/status inventory: complete.
- PR01 `LearningProgressSyncService`: merged into `hieu` via PR #23.
- PR02 `Skill Taxonomy & Unit Mastery`: merged into `hieu` via PR #24 (`19a6118`).
- PR03 `Complete Learning Flow, Unlock & Boss Navigation`: merged into `hieu` via `9b3965e`.
- PR04 `Authentication, Guest Progress & Cloud Migration`: merged into `hieu` (`110740e`).
- PR05 `Production Security: Premium, IAP, Gemini AI & Supabase`: code, backend migration, edge function, tests and documentation complete.
- Next dependency: PR 06 (`Curriculum, Adaptive Session Composer & Content Quality`).

## Issue IDs đã xong

- `P0-01` DONE_CODE: typed domain invalidation, one reward success boundary, no gameplay dependency on `HomeController`.
- `P0-02` DONE_CODE: standardized 11 Duo game codes to canonical activity types (`vocabulary`, `listening`, `speaking`, `dialogue`) and 4 skill buckets (`vocabulary`, `listening`, `speaking`, `hanzi`) via `LearningSkillTaxonomy`.
- `P0-03` DONE_CODE: mounted Home/Progress/Game, Unit, Sections/Units, Review, Stats, XP History and Profile owners refresh by domain.
- `P0-04` DONE_CODE: server-verified entitlement (`app_user_entitlements`), RPC `verify_app_store_purchase` with anti-replay fraud check, `PremiumAccessService` policy, and `SubscriptionController` refactor.
- `P0-05` DONE_CODE: comprehensive Auth & Identity Lifecycle implemented (Guest mode, Sign In, Sign Up, Sign Out, session restore, password recovery, guest-to-cloud migration, and account switching with scoped cache invalidation).
- `P1-01` DONE_CODE: standardized `LearningResult` contract parsing with `boss_ready`, `unit_completed`, `next_unit_id`, and migration `20261011160000_complete_learning_activity_result_contract.sql`.
- `P1-02` DONE_CODE: removed hardcoded XP (`50` in Unit Complete, `+100 XP` in Boss Victory), dynamically rendering server reward.
- `P1-03` DONE_CODE: standardized navigation outcome with typed `LearningNavigationOutcome` (`completed`, `failed`, `paused`, `abandoned`, `cancelled`, `retry`, `nextMission`, `fightBoss`, `nextUnit`).
- `P1-04` DONE_CODE: guest mode level unlock now follows `reward.nextNodeId` / path dependencies rather than linear index guessing.
- `P1-05` DONE_CODE: Home slice-wise refresh with partial success and stale-response protection.
- `P1-08` DONE_CODE: review, flashcard and mark-learned invalidation.
- `P1-11` DONE_CODE: removed client `geminiApiKey` and direct API calls; all queries routed through secure Supabase Edge Function `gemini-ai-gateway` with token auth and quota enforcement.
- `P2-06` DONE_CODE: centralized app-resume invalidation.
- Next dependency: PR 06 (`Curriculum, Adaptive Session Composer & Content Quality`).

## Files changed / migrations

Core implementation:

- `lib/core/config/app_config.dart` (removed hardcoded Gemini API key)
- `lib/core/ai/model/ai_gateway_exception.dart` (new)
- `lib/core/services/gemini_service.dart` (routed via Edge Function gateway)
- `supabase/functions/gemini-ai-gateway/index.ts` (new Supabase Edge Function)
- `supabase/migrations/20261011180000_secure_entitlements_and_ai_quotas.sql` (new)
- `lib/core/entitlement/model/user_entitlement.dart` (new)
- `lib/core/entitlement/data/entitlement_repository.dart` (new)
- `lib/core/entitlement/service/premium_access_service.dart` (new)
- `lib/core/services/iap_service.dart` (lazy InAppPurchase instance)
- `lib/screen/subscription/controller/subscription_controller.dart` (server-verified flow)
- `lib/screen/subscription/page/subscription_page.dart` (verified status, restore, terms)
- `lib/screen/dictionary/controller/dictionary_controller.dart`
- `lib/screen/conversations/controller/conversations_controller.dart`
- `lib/screen/hsk_exam/controller/hsk_exam_controller.dart`
- `lib/di.dart`

Tests:

- `test/core/security/security_iap_gemini_test.dart` (new, 11 tests)

Documents:

- `docs/IMPLEMENTATION_STATUS.md`
- `docs/implementation_reports/PR_05.md` (new)
- `docs/AI_HANDOFF.md`

## Commands actually run + PASS/FAIL

- `flutter test test/core/security/security_iap_gemini_test.dart`: PASS (11 tests).
- `flutter test test/core/security/ test/core/auth/ test/core/widgets/ test/core/backend/`: PASS (34 tests).
- `flutter test --concurrency=1 test/core/learning/`: PASS (74 tests).
- Total automated tests: PASS (108 tests).
- `flutter analyze`: PASS (0 errors, 0 warnings across all PR 05 files).
- `dart format`: PASS (all PR 05 files formatted).
- Live Google Play / Apple Store sandbox: NOT_RUN (Requires Google Play Console and App Store Connect credentials; architecture and server verification RPC ready).
- iOS smoke: NOT_RUN (Windows environment).

## Live Supabase verified?

NO.

- Supabase CLI: not installed.
- Supabase MCP/live database connection: unavailable in current IDE context.
- Migration file `20261011180000_secure_entitlements_and_ai_quotas.sql` and Edge Function `gemini-ai-gateway` are ready for deployment via Supabase Dashboard / CLI in CI/CD or production.

## Next exact 3 coding steps

1. Merge PR 05 into integration branch `hieu`.
2. Begin PR 06: Curriculum, Adaptive Session Composer & Content Quality.
3. Review and refine curriculum data loaders and adaptive session composition for Duo and Lexicon journeys.

## Git status / PR URL

- Implementation branch: `feature/pr05-security-iap-gemini`.
- Base branch: `hieu`.
- Target PR: PR 05.
