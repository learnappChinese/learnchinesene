# V3 Learner Experience Gate — Unit sec_1_unit_1
Status: **candidate for human review, NOT approved for production v3**. Original learning journey unchanged.

## Real DB facts (read-only SQL)
- Name and teaching objective: **Gọi tên món ăn và đồ uống**.
- 123 challenges, 6 different question types: 63 translate, 23 listenTap, 19 tapComplete, 10 match, 5 select, 3 assist.
- Receptive/recognition-related challenges: 18; production-like: 82 (overlap with translate and tapComplete classification).
- 0 translate questions missing answer/choice arrays, 0 listenTap questions missing correct-choice array.
- 23 translate rows have no direct `tts`. Could be perfectly fine if another audio source or synthesis is provided; MUST check on device rather than labeling every row broken.
- 8 duplicate-looking groups / 16 rows above one per group **within this Unit** (grouped by type, session, prompt, choices_text). Review full solutions/audio and rationale. Never automatically delete.
- Vocabulary/explanation linkage to this `duo_units` must be verified separately; `lexicon_units` is a distinct curriculum mapping and cannot be naively equated by unit number.

## Human acceptance checklist (record evidence and question IDs)
| Category | Acceptance question | Proof |
|---|---|---|
| Pedagogical goal | Can a beginner name everyday foods and drinks after this Unit? | Unprompted retrieval at finish |
| New-word scaffolding | Is pinyin + correct Vietnamese shown *before* production demand? | Screen-by-screen trace |
| Chinese accuracy | Are Hanzi, tones, vocabulary collocations and sentence syntax correct? | Bilingual review, citation/reference |
| Vietnamese accuracy | Is every candidate meaning natural, in correct context, multiple valid answers supported? | Reviewer notes per challenge ID |
| Question design | Are wrong choices plausible but unambiguously wrong, non-leading, not trivially distinguishable? | Review question IDs and option sets |
| Listening | Can novice replay the audio and distinguish target from options? | Real Android TTS/playback check |
| Repetition | Are repeated questions intentional spaced reinforcement instead of needless repetition? | Compare 8 candidate groups |
| Difficulty | Does question difficulty progress from preview to retrieval and production? | Attempt trace, mistake types |
| Feedback | Does incorrect answer explain why, offer recovery, not merely say fail? | Screenshot |
| Boss | Does it evaluate this Unit's learning objective and valid evidence? | Boss challenge provenance |
| Progress | On Guest, can Stage 1 completion unlock Stage 2 immediately and persist after restart? | Local progress readback and gameplay |
| Reward safety | Do retry/replay/crash recovery preserve XP idempotency? | Ledger/Guest local checks |

## Tester instructions in Flutter debug mode
1. Build **this PR branch**, not unchanged `hieu`; use `flutter run -t lib/main.dart`. V3 curriculum preview flag remains OFF, while the QA icon is available under `kDebugMode`.
2. Use a **separate Guest test profile** to avoid touching personal progress. Never clear the user's primary SharedPreferences to make the test pass.
3. Open World → Section 1 → Unit 1. Tap the debug checklist/feedback icon on **Unit Overview**.
4. Enter the first mission and tap the feedback icon on **each questionable question**. Record category, screenshot (if available), natural Chinese/Vietnamese correction, and question ID. Save feedback.
5. Finish Stage 1, return to Unit Overview, verify Stage 2 unlocked, close/reopen the app, verify persistence. Then run through Boss and Next Unit.
6. Tap the feedback icon and **Sao chép toàn bộ báo cáo kiểm thử**. Review JSON on a private ticket or local file; report includes Unit/level/question IDs and notes but not user ID/audio.
7. Enter review results into the editorial approval workflow only after content reviewers confirm. Do NOT overwrite live `duo_challenges` or change XP during quality review.

## Approval rule
No Unit is marked `approved` until: no critical structural defects; every high-severity translation/answer candidate reviewed; sample learner sessions demonstrate correct ordering/difficulty; replayable audio on device; Guest unlock and XP are correct; content/read RPC parity and device performance have passed. **Automated scripts cannot certify language quality.**

## Limitations
Metrics were measured on Supabase for current source content. Flutter widget tests/CI may pass without device playback or bilingual review; manual gates remain.
