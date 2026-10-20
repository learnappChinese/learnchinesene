-- V3-1: read-only corpus quality inventory.
-- This file is intentionally SELECT-only and safe to run on production.
-- Null/blank prompt is valid for some challenge types; never treat as globally broken.
-- Report counts by challenge type and potential structural defects.
select
  type, count(*) as challenge_count,
  count(*) filter(where prompt is null or btrim(prompt)='') as blank_prompt_in_storage,
  count(*) filter(where tts is null or btrim(tts)='') as no_direct_tts,
  count(*) filter(where choices_text is not null and jsonb_typeof(choices_text)<>'array') as malformed_choices_text,
  count(*) filter(where choices_correct is not null and jsonb_typeof(choices_correct)<>'array') as malformed_choices_correct,
  count(*) filter(where tokens_text is not null and jsonb_typeof(tokens_text)<>'array') as malformed_tokens_text,
  count(*) filter(where solutions is not null and jsonb_typeof(solutions)<>'array') as malformed_solutions
from public.duo_challenges
group by type order by challenge_count desc;

-- Concrete, limited candidate faults. Review the specific game type before correcting.
select 'lexicon_words' source_table, id::text source_id,
       'missing_pinyin' issue_code, word as preview
from public.lexicon_words
where pinyin is null or btrim(pinyin)=''
union all
select 'lexicon_words', id::text, 'missing_vi_translation', word
from public.lexicon_words
where meaning_vi is null or btrim(meaning_vi)=''
union all
select 'lexicon_examples', id::text, 'missing_zh_sentence', coalesce(sentence_vi,'')
from public.lexicon_examples
where sentence_cn is null or btrim(sentence_cn)=''
union all
select 'lexicon_examples', id::text, 'missing_vi_sentence', coalesce(sentence_cn,'')
from public.lexicon_examples
where sentence_vi is null or btrim(sentence_vi)=''
order by source_table, source_id limit 300;

-- Precise guardrails for translate questions; never infer semantically wrong answers.
select
  count(*) as total_translate,
  count(*) filter(where solutions is null or jsonb_typeof(solutions)<>'array') as invalid_solutions_shape,
  count(*) filter(where solutions='[]'::jsonb) as no_solutions,
  count(*) filter(where choices_text is null or jsonb_typeof(choices_text)<>'array') as invalid_choices_shape,
  count(*) filter(where choices_text='[]'::jsonb) as no_choices
from public.duo_challenges where type='translate';

-- Sample per-Unit census: coverage, not language correctness.
select
  l.unit_id, count(distinct s.id) as sessions,
  count(c.id) as challenges,
  count(distinct c.type) as challenge_types
from public.duo_levels l
left join public.duo_sessions s on s.level_id=l.id
left join public.duo_challenges c on c.session_id=s.id
group by l.unit_id order by l.unit_id;

-- Referential integrity for content read models (should be zero).
select
  (select count(*) from public.duo_challenges c left join public.duo_sessions s on s.id=c.session_id where s.id is null) as orphan_challenges,
  (select count(*) from public.duo_sessions s left join public.duo_levels l on l.id=s.level_id where l.id is null) as orphan_sessions,
  (select count(*) from public.duo_levels l left join public.duo_units u on u.id=l.unit_id where u.id is null) as orphan_levels;
