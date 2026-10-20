-- V3 read-only scorer parity audit (all translate challenges).
-- Mirrors DuoSentenceBuilderWidget.handleCheck: rank 1..N by choices_correct.
-- This verifies structural parity with solutions, NOT linguistic correctness.
with ranked as (
 select c.id,
   string_agg(tile.value, '' order by rank.value::integer)
     filter(where rank.value::integer > 0) as assembled,
   count(*) filter(where rank.value::integer > 0) as used_count,
   count(distinct rank.value::integer)
     filter(where rank.value::integer > 0) as distinct_rank_count,
   max(rank.value::integer) as max_rank
 from public.duo_challenges c
 cross join lateral jsonb_array_elements_text(c.choices_text) with ordinality tile(value, ordinal)
 join lateral jsonb_array_elements_text(c.choices_correct) with ordinality rank(value, ordinal)
   on rank.ordinal = tile.ordinal
 where c.type = 'translate'
 group by c.id
), compared as (
 select c.id, c.prompt, c.solutions, r.assembled, r.used_count,
   r.distinct_rank_count, r.max_rank,
   exists (
      select 1 from jsonb_array_elements_text(c.solutions) sol(value)
      where lower(regexp_replace(sol.value, '[[:space:][:punct:]，。、！？；：“”‘’（）]', '', 'g'))
          = lower(regexp_replace(coalesce(r.assembled,''), '[[:space:][:punct:]，。、！？；：“”‘’（）]', '', 'g'))
   ) matches
 from public.duo_challenges c join ranked r on r.id=c.id
)
select count(*) as checked_translate,
 count(*) filter(where not matches) as scorer_solution_mismatch_candidates,
 count(*) filter(where max_rank <> used_count or distinct_rank_count <> used_count) as invalid_rank_sequences
from compared;

-- Interpret carefully:
-- 0 mismatch does not prove correct translation, natural Vietnamese, good
-- distractors, TTS quality, appropriate HSK difficulty or accepted alternatives.
-- Order/punctuation normalization is used only to triage candidates; the app
-- currently scores exact choices_correct order, not semantic equivalence.
