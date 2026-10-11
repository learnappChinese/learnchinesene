# AI HANDOFF

## Repository

- Repo: `learnappChinese/learnchinesene`
- Base branch: `hieu`
- Current branch: `feature/learning-pro-ui-flow`

## Current Goal

Deliver the unified Chinese Learning Adventure architecture according to `AI_UNIFIED_LEARNING_ADVENTURE_MASTER_SPEC.md`:
1. Shared learning logic
2. XP/history/mastery/streak synchronized across the entire app
3. Stage → Result → Unlock → Boss → Next Unit
4. Cross-tab consistency (Home, Learning, Game, Progress, Profile)
5. Area-specific visual upgrades according to designated spec roles

## Completed Work

### 1. Shared Learning Logic & Mastery (`LearningMasteryService`)
- Implemented `lib/core/learning/service/learning_mastery_service.dart`:
  - `SkillMasteryProfile`: Computes clamped percentages (0-100%) for overall, vocabulary, listening, speaking, hanzi, and sentence skills.
  - `DefaultLearningMasteryService`: Loads live skill mastery from `SupabaseLearningRewardRepository` with graceful fallbacks.
- Unit tests: `test/core/learning/learning_mastery_service_test.dart` (Passing).

### 2. XP Ledger & History Synchronization (`LearningHistoryRepository`)
- Implemented `lib/core/learning/data/learning_history_repository.dart`:
  - `fetchTodayXp`: Aggregates XP earned today with timezone normalization.
  - `fetch7DayXpActivity`: Pulls rolling 7-day daily XP with dual-key mappings (`dayLabel`/`day_label`, `isToday`/`is_today`, `xpEarned`/`xp_amount`).
  - `fetchRecentTimeline`: Fetches recent unified attempts with automatic XP ledger fallback.
  - `fetchFullXpLedger`: Queries full paginated XP ledger with activity filtering.
  - `fetchAttemptHistory`: Queries attempt history records with score and accuracy details.
- Unit tests: `test/core/learning/learning_history_repository_test.dart` (Passing).

### 3. Mini-Games Plugged into Authoritative Reward Pipeline
- Integrated all 4 mini-games in `lib/screen/dragon_panda/screens/` with `LearningRewardService.completeActivity()`:
  - `quick_answer_screen.dart`: `activityType: 'quiz'`, `sourceType: 'quick_answer'`. Records accuracy, combo, awards XP, triggers `HomeController.refreshStats()`, displays `+XP` badge.
  - `tone_ninja_screen.dart`: `activityType: 'listening'`, `sourceType: 'tone_ninja'`. Records metrics on both game over and victory, awards XP, updates `HomeController`, displays `+XP` badge.
  - `chinese_restaurant_screen.dart`: `activityType: 'sentence'`, `sourceType: 'chinese_restaurant'`. Records completed order metrics, awards XP, updates `HomeController`, displays `+XP` badge.
  - `radical_builder_screen.dart`: `activityType: 'hanzi'`, `sourceType: 'radical_builder'`. Records decomposed radical metrics, awards XP, updates `HomeController`, displays `+XP` badge.

### 4. Stage → Result → Unlock → Boss → Next Unit Flow
- Extended `LearningResult` model (`lib/core/learning/model/learning_result.dart`) with Section 26 fields: `bossReady`, `unitCompleted`, `nextUnitId`, and `nextStageId`.
- Aligned Result CTAs (`lib/core/widgets/mission_complete_overlay.dart` & `lib/screen/vocabulary_adventure/page/vocabulary_adventure_screen.dart`) with Section 27 contract:
  - Fail → `THỬ LẠI` (Icons.refresh_rounded)
  - Next Stage → `ẢI TIẾP THEO` (Icons.arrow_forward_rounded)
  - Boss Ready → `ĐẾN CỔNG BOSS` (Icons.local_fire_department_rounded)
  - Unit Complete → `BÀI TIẾP THEO` (Icons.military_tech_rounded)
  - No Next → `VỀ BẢN ĐỒ` (Icons.map_rounded)
- Updated `UnitOverviewScreen._handleStageReturn()`: When returning from a completed stage that makes the Boss ready (`!wasBossReady && controller.isBossReady`), automatically presents the Boss Gate Modal. When a unit is completed, automatically transitions to `UnitCompleteScreen`.

### 5. Cross-Tab Synchronization & Role-Specific Visual Upgrades
- `HomeController` (`lib/screen/home/controller/home_controller.dart`): Added reactive observables `todayXp`, `lifetimeXp`, `streak`, `masteryProfile`, `sevenDayXp`, `recentTimeline`. Concurrently syncs DB stats, journey, review summary, today XP, 7-day activity, recent timeline, and skill mastery.
- `HomeScreen` (`lib/screen/home/home_screen.dart`): Bound synced XP (`todayXp` with `lifetimeXp` fallback) and `streak`.
- `HomeProgressTab` (`lib/screen/home/widgets/home_progress_tab.dart`): Overhauled into a rich learning analytics & history dashboard: 2x2 summary metric cards, 7-day XP activity chart with today highlighted, skill mastery cards, recent attempt/XP history timeline, and quick-action routes.
- `XpHistoryScreen` (`lib/screen/stats/page/xp_history_screen.dart`): Created full XP ledger view with activity filter chips (All, Vocabulary, Listening, Speaking, Hanzi, Boss, Quick Answer).
- `HomeLearningTab` (`lib/screen/home/widgets/home_learning_tab.dart`): Elevated into a true Curriculum + Practice Hub centered around the Stage Map with current unit hero, review due alert, and quick skills grid.
- `ProfilePage` (`lib/screen/system/profile_page.dart` & `profile_achievements.dart`): Resolved runtime crashes; elevated into an authentic Chinese Fantasy Adventure identity and lifetime achievements screen with rank titles, lifetime metrics, achievement badges, and language competency chips.

## Files Changed

- `lib/core/learning/service/learning_mastery_service.dart`: SkillMasteryProfile & DefaultLearningMasteryService.
- `lib/core/learning/data/learning_history_repository.dart`: authoritative history queries, 7-day XP activity, timeline fallback.
- `lib/core/learning/model/learning_result.dart`: Section 26 fields (bossReady, unitCompleted, nextUnitId, nextStageId).
- `lib/core/widgets/mission_complete_overlay.dart`: Section 27 CTA buttons and icons.
- `lib/screen/dragon_panda/screens/quick_answer/quick_answer_screen.dart`: authoritative reward integration.
- `lib/screen/dragon_panda/screens/tone_ninja/tone_ninja_screen.dart`: authoritative reward integration.
- `lib/screen/dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart`: authoritative reward integration.
- `lib/screen/dragon_panda/screens/radical_builder/radical_builder_screen.dart`: authoritative reward integration.
- `lib/screen/home/controller/home_controller.dart`: cross-tab reactive synchronization.
- `lib/screen/home/home_screen.dart`: bound cross-tab stats and HomeLearningTab wiring.
- `lib/screen/home/widgets/home_learning_tab.dart`: Stage Map hero and curriculum practice hub.
- `lib/screen/home/widgets/home_progress_tab.dart`: learning analytics & history dashboard.
- `lib/screen/stats/page/xp_history_screen.dart`: full XP ledger history screen.
- `lib/screen/system/profile_page.dart`: canonical stat binding and lifecycle listener.
- `lib/screen/system/widget/profile_achievements.dart`: identity and lifetime achievements.
- `lib/screen/unit_overview/page/unit_overview_screen.dart`: stage return handler and UnitCompleteScreen navigation.
- `lib/screen/vocabulary_adventure/page/vocabulary_adventure_screen.dart`: mission completion CTA handling.
- `test/core/learning/learning_mastery_service_test.dart`: unit tests for mastery profile.
- `test/core/learning/learning_history_repository_test.dart`: unit tests for history repository.

## Tests

- All core learning tests: PASS (46/46 passed in `test/core/learning/`).
- Flutter analyze: PASS (0 errors, 0 warnings across all modified modules).

## Git State

- Branch: `feature/learning-pro-ui-flow`.

## DO NOT REDO

- Do not repeat the schema/product audit.
- Do not reintroduce client-side unlock inference or arbitrary index+1 progression.
- Do not reintroduce default `sec_1_unit_1` runtime data.
- Do not chunk stages into a fixed number of challenges.
- Do not create duplicate XP/attempt tables or bypass `complete_learning_activity_v2`.
- Do not bypass `LearningRewardService` in mini-games.
