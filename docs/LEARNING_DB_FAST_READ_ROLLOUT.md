# Unit Content Fast Read — DB/Flutter rollout

Status: **Additive Supabase RPC deployed; Flutter source change is in PR and requires CI/device verification.**

## Scope and invariant
- Keep all existing curriculum/XP/mastery/unlock/Guest/Cloud tables, IDs, mission order, game-to-skill mapping and UIs.
- One `learning_unit_bundle_v1(p_unit_id)` network RPC loads Unit Path, Unit challenge content and Boss metadata (rather than several client-side REST reads).
- Server progression remains under `unit_learning_path_v2`. Guest progression overlay remains in Dart; do **not** reuse signed-in unlock state for Guest.
- If the RPC is unavailable, existing multi-query Flutter code remains as fallback.

## Migration
`supabase/migrations/20261019170023_learning_unit_content_bundle_v1_optimized_read.sql` matches the additive migration already deployed to Supabase project `hrlahralknhijnkypjix`.

RPC uses SECURITY INVOKER and grants EXECUTE to anon and authenticated, consistent with the pre-existing public learning-content read access. It does not expose user XP/progress or update tables.

## Basic correctness evidence — read-only SQL against current Supabase
| Unit | Old path nodes | Bundle path nodes | Old challenges | Bundle challenges |
|---|---:|---:|---:|---:|
| sec_1_unit_1 | 7 | 7 | 123 | 123 |
| sec_1_unit_2 | 9 | 9 | 114 | 114 |
| sec_1_unit_3 | 8 | 8 | 116 | 116 |
| sec_1_unit_4 | 9 | 9 | 125 | 125 |
| sec_1_unit_5 | 9 | 9 | 177 | 177 |

## Runtime acceptance (NOT YET VERIFIED)
1. Dart format/analyze, Flutter tests, Android build, and integration runtime need to run on the feature-branch commit.
2. Compare network calls, total bytes, p50/p95 time-to-interactive for Unit Overview at same network/device/unit against pre-change build. Goal: fewer round trips without regression or >1 MB responses.
3. Test Guest, signed-in and offline/retry. Finish a mission and verify the next stage / Boss / next Unit still unlock correctly after repository invalidation; no stale cached path.
4. Validate challenges map to the same game, session and level as before.
5. Roll back Flutter code to legacy path if response contract or gameplay differs. Only retire legacy RPC after production verification.

## Next optimization batches — separate PRs
- Profile vocabulary/dictionary reads; replace per-word N+1 lookups with paginated field-select single-RPC read models only where measured.
- Add an indexed, paginated vocabulary search / compact topic+HSK bundle rather than loading all lexicon joins per screen.
- Precompute static curriculum metadata only after robust invalidation/versioning design and before/after EXPLAIN measurement. Avoid snapshotting per-user progression.
- Cache immutable content by version/Unit, but do not cache XP, mastery, completion or unlock across identity changes.
- Review indexes before creating them: duo_challenges(session_id,type), duo_sessions(level_id), duo_levels(unit_id), lexicon_words(word) already have indexes. Avoid duplicates.
- Preserve physical normalization and user-state RLS; lowering physical table count is **not** the KPI. Track number of client requests, transferred bytes, p95 latency and identical learning behavior.

## Operational safety
No old tables removed, renamed, truncated or rewritten. No automatic migration of user data. No claims of mobile speedup without measurement. Migration history has the same version as the committed SQL file.
