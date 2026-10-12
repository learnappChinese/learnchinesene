# AI Handoff

## Timestamp + repo + branch + HEAD

- Timestamp: 2026-10-12 (Asia/Saigon)
- Repo: `D:\Projects\Flutter_Project\learnchinesene`
- Integration branch: `hieu`
- Feature branch: `feature/guest-learning-progression-fix`
- Current implementation: P0 Bug Fix (`Guest Learning Progression Unlock Flow for Stages, Boss & Units`) — COMPLETED & VERIFIED.

## Phase / PR hiện tại

- PR00–11: COMPLETED & MERGED into `hieu`.
- P0 Bug Fix: `Guest Learning Progression: Stage, Boss & Unit Unlocking`:
  - Production fix: `GuestLearningProgressStore`, `GuestJourneyResolver`, `LearningProgressRepository`, `LearningJourneyRepository`, `LearningRewardService`, `DuoGameRunnerController`, `BossBattleController`, `BossBattleScreen`, `DuoDbHelper`, `VocabularyAdventureRepository`, and `LearningRecommendationService`.
  - Verification: 12/12 dedicated test scenarios in `guest_learning_progression_test.dart` passed; live Android emulator verification with before/after screenshots confirmed.

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
- `P1-06` PARTIAL: Profile observes canonical invalidation and no longer overwrites fresh DB stats.
- `P1-07` DONE_CODE: Canonical `LearningSourceContext` threaded across Unit Overview, Hanzi writing, and Speaking.
- `P1-08` DONE_CODE: review, flashcard and mark-learned invalidation.
- `P1-09` DONE_CODE: `LearningSessionComposer` eliminated global random fallbacks; strict question budget and unit bounding enforced.
- `P1-10` DONE_CODE: HSK Quiz grounded in official curriculum database (`lexicon_words`) with seed fallback; HSK Exam raw score persisted immediately prior to AI analysis with non-duplicating retry support.
- `P1-11` DONE_CODE: removed client `geminiApiKey` and direct API calls; all queries routed through secure Supabase Edge Function `gemini-ai-gateway` with token auth and quota enforcement.
- `P1-12` DONE_CODE: Centralized `TtsService` registered in DI; eliminated scattered direct `FlutterTts()` instantiations across HSK Quiz, Exam, Dictionary, Conversations, and Lessons.
- `P1-13` DONE_CODE: `UnitBridgeResolver` resolves bidirectional mappings between text `duo_unit_id` and integer `lexicon_unit_id`; `LearningSourceContext` carries canonical provenance across activities.
- `P1-14` DONE_CODE: Truthfully separated and labeled in UI: "Lịch sử học tập" (authoritative learning ledger) vs "Lịch sử công cụ AI" (local utility interactions).
- `P2-01` DONE_CODE: Unified single source of truth for next-action recommendations in `LearningRecommendationService` and `RecommendedNextAction`.
- `P2-02` DONE_CODE: SRS spaced repetition due boundaries fixed in `SupabaseReviewRepository`.
- `P2-03` DONE_CODE: Standardized constructor injection (`this.controller`) and route-scoped disposal (`_ownsController`) across 15 screens; fixed SubscriptionPage Obx reactivity on activeProductId; eliminated state leaks.
- `P2-04` DONE_CODE: Home strictly renders Today XP from `controller.todayXp.value` (including 0); eliminated deceptive fallback that swapped Lifetime XP into Today's metric.
- `P2-05` DONE_CODE: Eliminated broad silent catches across services, repositories, and controllers; replaced with structured debugPrint and typed exception logging.
- `P2-06` DONE_CODE: centralized app-resume invalidation.

## Files changed in PR 10

Design tokens, Theme & System UI:
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
- `lib/screen/dragon_panda/theme/app_colors.dart`

Accessibility & Reduced Motion UX:
- `lib/core/widgets/panda_companion.dart`
- `lib/screen/flashcards/flashcards_screen.dart`

Actionable Locked Stage/Mission Sheets:
- `lib/core/widgets/locked_mission_sheet.dart`
- `lib/screen/unit_overview/page/unit_overview_screen.dart`
- `lib/screen/duolingo/page/duo_game_path_screen.dart`

Controller Lifecycle & Route Scoping (P2-03):
- `lib/screen/word_list/word_list_screen.dart`
- `lib/screen/word_detail/word_detail_screen.dart`
- `lib/screen/quiz/quiz_screen.dart`
- `lib/screen/lessons/lessons_screen.dart`
- `lib/screen/conversations/conversations_screen.dart`
- `lib/screen/hsk_exam/hsk_exam_screen.dart`
- `lib/screen/stats/stats_screen.dart`
- `lib/screen/hsk/hsk_screen.dart`
- `lib/screen/unit/unit_screen.dart`
- `lib/screen/review/review_screen.dart`
- `lib/screen/history/history_screen.dart`
- `lib/screen/duolingo/duo_game_center_screen.dart`
- `lib/screen/learning_overview/learning_overview_screen.dart`
- `lib/screen/subscription/page/subscription_page.dart`
- `lib/screen/flashcards/flashcards_screen.dart`

Elimination of Broad Silent Catches (P2-05):
- `lib/screen/unit_overview/controller/unit_overview_controller.dart`
- `lib/screen/subscription/controller/subscription_controller.dart`
- `lib/screen/hsk_quiz/controller/hsk_quiz_controller.dart`
- `lib/screen/dictionary/dictionary_screen.dart`
- `lib/core/widgets/word_card.dart`
- `lib/core/services/audio_service.dart`
- `lib/core/services/progress_service.dart`
- `lib/core/services/history_service.dart`
- `lib/core/models/duo_challenge.dart`
- `lib/core/learning/service/learning_recommendation_service.dart`
- `lib/core/learning/service/learning_mastery_service.dart`
- `lib/core/learning/data/learning_journey_repository.dart`
- `lib/core/learning/data/learning_progress_repository.dart`
- `lib/core/auth/service/guest_progress_migration_service.dart`

Tests:
- `test/screen/ui_followup/design_system_responsive_test.dart` (new comprehensive suite)
- `test/screen/ui_followup/remaining_screens_test.dart` (authoritative victory XP fixture)

Documentation:
- `docs/implementation_reports/PR_10.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/AI_HANDOFF.md`

## Verification Evidence
- `flutter test test/screen/ui_followup`: 30/30 tests passed
- `flutter test test/core`: 133/133 tests passed
- `flutter test test/screen/home`: 35/35 tests passed
- `flutter test test/screen/review`: 12/12 tests passed
- `flutter test test/screen/vocabulary_adventure`: 11/11 tests passed
- `flutter test test/screen/boss_battle`: 9/9 tests passed
- `flutter test test/screen/hsk_quiz`: 7/7 tests passed
- `flutter test test/screen/unit_overview`: 6/6 tests passed
- `flutter test test/screen/hsk`: 5/5 tests passed
- `flutter test test/screen/hsk_exam`: 3/3 tests passed
- `flutter test test/screen/catalog`: 3/3 tests passed
- `flutter test test/screen/history`: 3/3 tests passed
- `flutter test test/screen/duolingo`: 2/2 tests passed
- `flutter test test/features`: 1/1 tests passed
- `flutter analyze`: 0 errors across the entire codebase.
