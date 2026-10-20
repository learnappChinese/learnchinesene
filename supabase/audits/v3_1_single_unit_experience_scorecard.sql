-- V3 learner-experience candidate scorecard: READ ONLY, safe for live DB.
-- Change the single unit_id in the target CTE for the next Unit.
with target(unit_id) as (values ('sec_1_unit_1'::text)),
content as (
  select u.id unit_id,u.title,l.teaching_objective,c.id challenge_id,
         c.type,c.prompt,c.choices_text,c.choices_correct,c.solutions,c.tts,c.session_id
  from target t
  join public.duo_units u on u.id=t.unit_id
  join public.duo_levels l on l.unit_id=u.id
  join public.duo_sessions s on s.level_id=l.id
  join public.duo_challenges c on c.session_id=s.id
), duplicates as (
  select count(*) group_count,coalesce(sum(n-1),0) extra_rows
  from (
    select type,session_id,coalesce(prompt,''),coalesce(choices_text::text,''),count(*) n
    from content group by 1,2,3,4 having count(*)>1
  ) g
)
select
  (select unit_id from target) unit_id,
  max(title) unit_title,
  max(teaching_objective) teaching_objective,
  count(*) challenge_count,
  count(distinct type) challenge_types,
  count(*) filter(where type='translate') translate_count,
  count(*) filter(where type='listenTap') listening_count,
  count(*) filter(where type in ('select','assist','match')) recognition_count,
  count(*) filter(where type in ('translate','gapFill','tapComplete','orderTapComplete','patternTapComplete','dialogue')) production_count,
  count(*) filter(where type='translate' and
    (solutions is null or solutions='[]'::jsonb or
     choices_text is null or choices_text='[]'::jsonb)) unanswerable_translate_candidate,
  count(*) filter(where type='listenTap' and
    (choices_correct is null or choices_correct='[]'::jsonb)) unanswerable_listening_candidate,
  count(*) filter(where type='translate' and (tts is null or btrim(tts)='')) translate_no_direct_tts,
  (select group_count from duplicates) duplicate_candidate_groups,
  (select extra_rows from duplicates) duplicate_candidate_extra_rows
from content;
-- Zero structural failures does NOT equal correct Mandarin/Vietnamese translation.
-- Require human review of lesson objective, answer alternatives, example
-- sequencing, audio playback, difficulty, and Guest XP/next-stage behavior.
