# V3 Hanzi writing data audit — real Supabase corpus

This audit exists because the writing experience must follow real HSK/Section data, real stroke paths and real progress. It must not pretend that every word is one Hanzi, and must not show contextual pinyin as if it were a verified standalone reading.

## Current real corpus
- 4 HSK levels exist in `lexicon_hsk_levels` (HSK 1–4). The old writing screen hardcodes HSK 1–6, so that UI does not reflect the database.
- 130 lexicon Units/Sections are mapped to 2,299 Unit-word links.
- 2,205 words: **1,873 are multi-character**, 332 single-character. Therefore using only `main_character_id` cannot create the requested writing curriculum correctly.
- Splitting Unit words into Unicode characters yields 4,725 character positions. 4,207 positions currently map to `lexicon_characters`; 518 positions do not.
- Those mappings produce 3,763 unique Unit-character path items after de-duplicating the same Hanzi inside one Unit.
- All 935 rows currently in `lexicon_characters` have a non-empty stroke path and positive stroke count.
- Missing stroke coverage still exists at the curriculum level because some characters that occur in words do not exist in `lexicon_characters` at all (examples include 餐, 花, 剧, 装, 器, 部, 化...).

## HSK path quality snapshot
| HSK | Sections | unique path nodes | missing standalone pinyin/meaning | missing stroke among mapped nodes | unmapped positions |
|---|---:|---:|---:|---:|---:|
| HSK 1 | 10 | 159 | 69 | 0 | 7 |
| HSK 2 | 30 | 1012 | 477 | 0 | 75 |
| HSK 3 | 30 | 957 | 491 | 0 | 122 |
| HSK 4 | 60 | 1635 | 929 | 0 | 314 |

The pinyin/meaning gap is not treated as “empty data to fill with guesses.” If a standalone character row has not been linguistically reviewed, the preview shows the **context word** (e.g. 咖 in 咖啡, with the word pinyin/meaning) and explicitly labels standalone metadata as unavailable.

## Smart-path behavior implemented in PR #28
- HSK catalogue is dynamic; no `List.generate(6)`.
- Each HSK is loaded only when needed; sections and nodes are rendered with `CustomScrollView`/Sliver lists.
- Multi-character words are decomposed into their actual Unicode characters; duplicate Hanzi inside the same Unit are collapsed with stable order from `lexicon_word_sources.source_row`.
- Static curriculum data and user progress stay separate. Signed-in progress comes from `lexicon_hanzi_progress`; Guest progress is reconstructed from the existing `guest_learning_attempts_v2` Hanzi attempts.
- A node is completed using the **existing Hanzi pass threshold (70)**; no new reward threshold is invented. The next unfinished node becomes current; later nodes/sections stay locked until prerequisites pass.
- Smart Continue prefers due Cloud review items when `next_review_at` is available; otherwise it routes to the current writing node.
- Missing-stroke nodes are unavailable rather than fake-pass.
- The new UI is preview-gated by `V3_HANZI_PATH_PREVIEW`; old learning flows remain fallback until QA.

## Still required before activation
1. Linguistically curate standalone pinyin/meaning for the missing metadata cases; do not derive a character reading blindly from a multi-character word.
2. Decide which unmapped characters should enter the official writing curriculum, then source/verify stroke data under an appropriate license/provenance.
3. Device-test stroke validation, accessibility, scrolling, returning to exact position, Guest persistence and next-node unlock.
4. Apply the read-only RPC migration on approved staging first and compare query count/p95 against the normalized-table fallback.
5. Add content version/release ID to writing-path publication before enabling per-Unit rollout.

Reproducible query: `supabase/audits/v3_hanzi_writing_path_quality.sql`.
