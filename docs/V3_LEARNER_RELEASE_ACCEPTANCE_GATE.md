# V3 learner-led Unit release acceptance gate

Purpose: a lesson is not accepted because tests pass, question rows exist or reviewers clicked a positive rating. The learner must **actually learn the stated objective** and retain Guest progress correctly.

## Release-gate semantics

Use this classification for every Unit:
- `BLOCKED`: invalid question, wrong answer, demonstrably incorrect translation, failed Guest unlock, duplicate XP, crash, inaccessible audio-dependent required stage, or incomplete data/reference. Must fix.
- `NEEDS_CONTENT_REVIEW`: answers syntactically valid but no bilingual contextual review; content sequencing/HSK level unverified; audio quality untested; suspicious duplicate question groups. Cannot approve.
- `NEEDS_RUNTIME_TEST`: quality approved but no emulator/device execution on correct branch/commit. Cannot approve.
- `CANARY_READY`: bilingual reviewer signed, all required end-to-end Guest and signed-in tests passed, no critical defects, verified performance & rollback.
- `ROLLED_OUT`: flag enabled for a specific approved Unit + content release ID, observability and rollback operational.

### Mandatory tester sessions

**Session A, novice** — Learner starts with no prior target-vocabulary mastery. Does the lesson introduce Hanzi, pinyin, pronunciation and Vietnamese **before** asking them to generate/translate? Can learner explain what was taught and complete unfamiliar variant questions without guessing?

**Session B, error recovery** — Intentionally answer incorrectly. Is feedback intelligible? Do distractors allow one correct answer or explicitly recognized legitimate variants? Are retries fair and non-reward farming?

**Session C, listening/TTS** — Mute/unmute, replay normal/slow where available, missing voice engine, wrong audio mapping, permission denied. No fake success when speech/audio unavailable.

**Session D, progression** — Guest completes Stage 1, returns to path; Stage 2 unlocks and launches. Continue to Boss, win, next Unit available. Restart app and verify persisted completion and XP credited once. Repeat with signed-in account and Guest→Cloud migration separately.

**Session E, content quality** — Bilingual reviewer verifies Chinese semantics, polyphonic pronunciations, tone marks, natural Vietnamese, grammaticality, HSK target suitability, and all accepted answers, *including the token bank allowing the intended answer*.

### Acceptance checklist recorded per Unit

| Area | Required evidence | Failing outcome |
|---|---|---|
| Objective | Learner can demonstrate a skill aligned to Unit objective | Missing/irrelevant exercises |
| Content sequence | Input → recognition → recall → listening → production → checkpoint | Production with no scaffolding |
| Coverage | Unique vocabulary, grammar, examples, all required modalities supported/fallback | Unanswerable or missing content |
| Difficulty | HSK level matches target, no unexplained leaps | Critical difficulty mismatch |
| Translation | Bilingual reviewer checks CN↔VI in context; alternatives scored correctly | Wrong meaning or unfair mark |
| Audio | Verified on Android playback and failure fallback | Incorrect pronunciation or blocking |
| Feedback | Real explanation, not just right/wrong | Misleading / no recovery |
| Boss | Questions from Unit, valid mastery gate, victory persisted | Incorrect reward/unlock |
| Performance | Median and p95 lesson load, request count, payload size | Regression over baseline without benefit |
| Data safety | Stable IDs, unchanged XP/mastery/SRS unless separately approved | Lost/doubled learner progress |

### Report handoff from in-app QA

On the **debug build from PR #28** tap the quality icon on Unit Overview (rate 1–5 or report) or on the active Duo question (report exact ID). This writes a separate local queue; it does **not** upload to Supabase or alter learning progress. Copy locally and triage via:
```bash
python scripts/v3_feedback_triage.py --input feedback.json --output review_queue.json
python scripts/v3_unit_experience_audit.py --input unit_snapshot.json --output unit_gate.json
python -m unittest discover -s scripts -p 'test_v3*.py' -v
```
Note: `unit_snapshot.json` must include actual Unit words, examples, path and challenges; do not assume mapping by numbering. Until an approved extraction is available, use read-only SQL scorecard and human testing.

### Safety

No auto-translation approval, deleting “duplicate” candidate challenges, toggling production curriculum, dropping tables, changing Guest XP or merging `hieu` before the above evidence. This is an acceptance contract, not evidence that Unit 1 has passed.
