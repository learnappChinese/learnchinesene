# AI Handoff

## Timestamp + repo + branch + HEAD

- Timestamp: 2026-10-11 (Asia/Saigon)
- Repo: `D:\Projects\Flutter_Project\learnchinesene`
- Integration branch: `hieu`
- Feature branch: `feature/pr09-hsk-exam-quiz-engine`
- Next implementation: PR 10 (`Unified Chinese Fantasy Design System & UX Polish`).

## Phase / PR hiện tại

- PR00 baseline/status inventory: complete.
- PR01 `LearningProgressSyncService`: merged into `hieu` via PR #23.
- PR02 `Skill Taxonomy & Unit Mastery`: merged into `hieu` via PR #24 (`19a6118`).
- PR03 `Complete Learning Flow, Unlock & Boss Navigation`: merged into `hieu` via `9b3965e`.
- PR04 `Authentication, Guest Progress & Cloud Migration`: merged into `hieu` (`110740e`).
- PR05 `Production Security: Premium, IAP, Gemini AI & Supabase`: merged into `hieu` (`6f965e2`).
- PR06 `Curriculum, Adaptive Session Composer & Content Quality`: MERGED into `hieu` (`9cebe28`).
- PR07 `Review, Hanzi, Speaking Context & SRS Quality`: MERGED into `hieu` (`a1cfaf8`).
- PR08 `Personalized Home, Smart Next Action & Learning Recommendation`: MERGED into `hieu` (`c88e86d`).
- PR09 `AI Learning Quality, HSK Quiz/Exam & Unified Learning Outcomes`: COMPLETED & VERIFIED.
- Next implementation: PR 10 (`Unified Chinese Fantasy Design System & UX Polish`).

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
- `P2-04` DONE_CODE: Home strictly renders Today XP from `controller.todayXp.value` (including 0); eliminated deceptive fallback that swapped Lifetime XP into Today's metric.
- `P2-06` DONE_CODE: centralized app-resume invalidation.

## Files changed in PR 09

Core implementation:
- `lib/core/services/tts_service.dart` (new centralized TTS service)
- `lib/di.dart` (registered `TtsService`)
- `lib/screen/hsk_quiz/data/hsk_quiz_repository.dart` (new curriculum repository & standard seed)
- `lib/screen/hsk_quiz/domain/hsk_quiz_question_generator.dart` (curriculum-grounded question generator)
- `lib/screen/hsk_quiz/controller/hsk_quiz_controller.dart` (repository integration & practice history)
- `lib/screen/hsk_quiz/hsk_quiz_screen.dart` (centralized TTS and curriculum repository)
- `lib/screen/hsk_exam/controller/hsk_exam_controller.dart` (raw score persistence before AI, `retryAnalysis`, centralized TTS)
- `lib/screen/hsk_exam/widget/hsk_exam_content.dart` (AI analysis retry UI & error handling)
- `lib/screen/hsk_exam/hsk_exam_screen.dart` (wire retry callback & error state)
- `lib/core/services/history_service.dart` (added `updateHistoryContent`)
- `lib/screen/history/controller/history_controller.dart` (dual system management)
- `lib/screen/history/widget/history_content.dart` (added `LearningAttemptTile` & AI utility labels)
- `lib/screen/history/history_screen.dart` (two-tab UI with honest labels)
- `lib/screen/dictionary/dictionary_screen.dart` (centralized TTS)
- `lib/screen/conversations/controller/conversations_controller.dart` (centralized TTS)
- `lib/screen/lessons/controller/lessons_controller.dart` (centralized TTS)

Tests:
- `test/core/services/tts_service_test.dart` (new)
- `test/screen/hsk_quiz/hsk_quiz_curriculum_grounding_test.dart` (new)
- `test/screen/hsk_exam/hsk_exam_durability_test.dart` (new)
- `test/screen/history/history_two_systems_test.dart` (new)

Documents:
- `docs/implementation_reports/PR_09.md` (new)
- `docs/IMPLEMENTATION_STATUS.md` (updated)
- `docs/AI_HANDOFF.md` (updated)

## What NOT to redo
- Do NOT re-audit recommendations (PR 08 is merged).
- Do NOT re-generate questions via Gemini in HSK Quiz.
- Do NOT call direct `FlutterTts()` in HSK Quiz/Exam/Dictionary/Conversations/Lessons.
- Do NOT delete official learning records when user clears AI tool history.

## Next Step
- Commit PR 09 changes with proper author.
- Push `feature/pr09-hsk-exam-quiz-engine` to origin.
- Merge `--no-ff` into `hieu`.
- Push `hieu` to `origin/hieu`.
- Proceed with PR 10 (`Unified Chinese Fantasy Design System & UX Polish`).
