# Implementation Status

- Snapshot date: 2026-10-11
- Base: `hieu` at `110740e5e3946546417f2c09afe2cc6fceac9423` (PR 04 merged)
- Next implementation: PR 05 (Security: IAP Verification & Gemini API Protection)

This is the living issue matrix for `AI_MASTERPLAN_HOAN_THIEN_APP_TIENg_TRUNG.md`. Status is based on current Flutter code and committed SQL migrations. It does not claim live-production verification.

## Verification boundary

- Flutter 3.47.5; Dart 3.13.4.
- Latest committed migration: `20261011160000_complete_learning_activity_result_contract.sql`.
- Supabase CLI is not installed and no Supabase MCP/live connection is available in this environment. Live function bodies, grants, RLS drift, production data and authenticated multi-device behavior are `NOT_VERIFIED_LIVE`.
- Migration `20261011160000_complete_learning_activity_result_contract.sql` standardizes the `complete_learning_activity_v2` result contract with `boss_ready`, `unit_completed`, and `next_unit_id`.
- Baseline at `hieu`: `test/core/learning` passed 74 tests; `flutter analyze` on changed PR03 files reported 0 issues/warnings.

Status vocabulary:

- `DONE_CODE`: implemented and covered by local automated tests; live/device acceptance may still remain.
- `PARTIAL`: useful portion is implemented, but the masterplan acceptance is not complete.
- `OPEN`: verified current-code mismatch remains.
- `NOT_VERIFIED_LIVE`: code/migrations were inspected but the production Supabase claim cannot be made.

## Issue matrix

| ID | Status | Current evidence | Next owner/PR |
| --- | --- | --- | --- |
| P0-01 | DONE_CODE | `LearningProgressSyncService` is registered in DI; reward success emits typed scoped invalidation; direct gameplay calls to `HomeController.refreshStats()` are removed; rapid events coalesce and serialize; failed owners retry once | PR01 live/device acceptance |
| P0-02 | DONE_CODE | Standardized 11 Duo game codes via `LearningSkillTaxonomy` to canonical activity types (`vocabulary`, `listening`, `speaking`, `dialogue`) and 4 skill buckets. Migration `20261011150000_unify_skill_taxonomy_and_unit_mastery.sql` resolves legacy attempts into proper skills and updates `private.unit_mastery_for_user` & `unit_mastery_v2`. Guest mode computes real local mastery in `SupabaseLearningProgressRepository._fetchLocalUnitMastery` | PR02 live/device acceptance |
| P0-03 | DONE_CODE | Home/Progress/Game, Unit, Sections/Units, Review, Stats, XP History and Profile register lifecycle-owned refreshers; app resume revalidates all mounted owners | PR01 authenticated/guest runtime matrix |
| P0-04 | DONE_CODE | Server-verified entitlement (`app_user_entitlements`), RPC `verify_app_store_purchase` with anti-replay fraud check, `PremiumAccessService` policy, and `SubscriptionController` refactor | PR05 live store verification |
| P0-05 | DONE_CODE | Comprehensive Auth & Identity Lifecycle implemented: Guest mode, Sign In, Sign Up, Sign Out, session restore, password recovery, guest-to-cloud migration (`GuestProgressMigrationService`), and account switching with scoped cache invalidation | PR04 live/device acceptance |
| P1-01 | DONE_CODE | `LearningResult` parses `boss_ready`, `unit_completed`, and `next_unit_id` from JSON & attempt metadata; migration `20261011160000_complete_learning_activity_result_contract.sql` returns these fields explicitly in RPC payload | PR03 live/device acceptance |
| P1-02 | DONE_CODE | Removed hardcoded XP (`50` in `UnitCompleteScreen` and `+100 XP` in `BossVictoryContent`); displays authoritative XP and stars from `LearningResult` | PR03 |
| P1-03 | DONE_CODE | Implemented typed `LearningNavigationOutcome` with actions (`completed`, `failed`, `paused`, `abandoned`, `cancelled`, `retry`, `nextMission`, `fightBoss`, `nextUnit`) replacing loose `Get.off` chains | PR03 |
| P1-04 | DONE_CODE | Guest level progression (`_unlockNextGuestLevel`) in `DuoGameRunnerController` unlocks `reward.nextNodeId` directly based on path dependencies instead of guessing linearly | PR03 |
| P1-05 | DONE_CODE | Home loads seven slices independently, preserves successful values, exposes partial error state and rejects stale requests | PR01 |
| P1-06 | PARTIAL | Profile now observes canonical invalidation and no longer overwrites fresh DB stats from a racing Home snapshot; `lastStudyDate` is still `DateTime.now()` | PR06 |
| P1-07 | OPEN | Hanzi/Speaking context remains optional/inconsistent for several entry paths | PR03/PR07 |
| P1-08 | DONE_CODE | review completion, flashcard rating and mark-learned actions invalidate Review/Stats/Mastery/Profile/Path scopes | PR01 |
| P1-09 | OPEN | loaders still contain broad Unit pools and random/hard-coded fallbacks | PR07 |
| P1-10 | OPEN | HSK Quiz and Exam remain outside the canonical durable learning result policy | PR09 |
| P1-11 | DONE_CODE | Removed client `geminiApiKey` and direct API calls; all queries routed through secure Supabase Edge Function `gemini-ai-gateway` with token auth and quota enforcement | PR05 |
| P1-12 | OPEN | multiple independent `FlutterTts` instances remain | PR08 |
| P1-13 | OPEN | integer lexicon IDs and text Duo IDs still rely on implicit bridges | PR07 |
| P1-14 | OPEN | Supabase learning history and local `history_logs.json` remain separate/overloaded in product terminology | PR06/PR09 |
| P2-01 | OPEN | legacy HSK/Unit, journey v2, chapter adventure and Game Center remain overlapping navigation/progression surfaces | PR06 |
| P2-02 | OPEN | session selection is not yet mastery/history-adaptive | PR07 |
| P2-03 | OPEN | route bindings/fallback `Get.put` ownership overlap and duplicate subscription DI remain | PR10 |
| P2-04 | OPEN | Home still substitutes lifetime XP when today XP is zero | PR06 |
| P2-05 | OPEN | broad silent catches and empty fallbacks remain across the repository | PR10 |
| P2-06 | DONE_CODE | lifecycle refresh moved from Profile-only behavior to app-wide typed invalidation owned by Home lifecycle | PR01 |

## PR01 implementation boundary

```mermaid
sequenceDiagram
    participant UI as Activity UI/controller
    participant Reward as LearningRewardService
    participant Repo as LearningProgressRepository
    participant DB as Supabase / guest persistence
    participant Sync as LearningProgressSyncService
    participant Owners as Mounted domain owners

    UI->>Reward: completeActivity(submission)
    Reward->>Repo: completeActivity(submission)
    Repo->>DB: complete_learning_activity_v2 / local idempotent rules
    DB-->>Repo: LearningResult
    Repo-->>Reward: authoritative result
    Reward->>Sync: syncAfterCompletion(result, submission)
    Sync->>Owners: coalesced typed invalidation
    Owners->>DB: re-read owned slices
    DB-->>Owners: fresh state / scoped failure
    Sync-->>Reward: report
    Reward-->>UI: LearningResult
```

The coordinator does not duplicate business state or infer unlocks. Each owner re-reads its existing repository/RPC/table source. This keeps PR01 within the no-mass-refactor and no-duplicate-database constraints.

## PR01 acceptance evidence

- Reward repository success triggers one shared invalidation boundary.
- Scope filtering updates relevant owners and ignores unrelated owners.
- Two immediate invalidations coalesce into one non-overlapping refresh generation.
- A failing owner retries twice total and does not prevent successful owners from updating.
- Disposed registrations no longer receive refreshes.
- `LearningResult` fixture covers XP, idempotency context, next stage and next Unit fields.
- Existing guest idempotency, zero-XP Boss loss, progression, stage grouping, lock and Boss tests remain green.

Still requiring external evidence:

- Signed-in pass → XP/history/path/unlock across actual production RPC and RLS.
- Guest → login migration and user switch on a device.
- Multi-device/app-resume reconciliation against production.
- Live response fields and semantic mastery aggregation for every Duo game code.
