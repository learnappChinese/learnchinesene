-- Unify skill taxonomy & unit mastery across all Duo game activities.
-- PR 02: Skill Taxonomy & Unit Mastery.
--
-- 1. Standardize Game Code -> Activity Type -> Skill Bucket mapping.
-- 2. Ensure all Duo games (select_answer, translate, gap_fill, tap_complete,
--    sentence_order, word_connect, match_pairs, listen_select, dialogue, etc.)
--    contribute accurately to unit skill mastery buckets.
-- 3. Maintain backward compatibility for historical 'game_mission' attempts.
-- 4. Align unit mastery with Boss availability and unit progression.
-- 5. Zero mutation to XP ledger, idempotency, or user rewards.

create or replace function private.unit_mastery_for_user(
  p_user_id uuid,
  p_unit_id text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with resolved_attempts as (
    select
      case
        when attempts.activity_type in ('vocabulary', 'listening', 'speaking', 'hanzi')
          then attempts.activity_type
        when attempts.activity_type = 'dialogue'
          then 'listening'
        when attempts.activity_type = 'game_mission' then
          case coalesce(attempts.metadata ->> 'game_code', '')
            when 'listen_select' then 'listening'
            when 'speaking' then 'speaking'
            when 'dialogue' then 'listening'
            else 'vocabulary'
          end
        else 'vocabulary'
      end as skill_bucket,
      attempts.source_type,
      attempts.source_id,
      case
        when attempts.activity_type in ('speaking', 'hanzi')
          then least(greatest(attempts.score / 100.0, 0), 1)
        else least(greatest(attempts.accuracy, 0), 1)
      end as attempt_mastery
    from public.learning_attempts attempts
    where attempts.user_id = p_user_id
      and attempts.unit_id = p_unit_id
      and attempts.status in ('passed', 'failed')
  ), best_by_source as (
    select
      skill_bucket,
      source_type,
      source_id,
      max(attempt_mastery) as mastery
    from resolved_attempts
    group by skill_bucket, source_type, source_id
  ), skill_scores as (
    select
      avg(mastery) filter (where skill_bucket = 'vocabulary') as vocabulary,
      avg(mastery) filter (where skill_bucket = 'listening') as listening,
      avg(mastery) filter (where skill_bucket = 'speaking') as speaking,
      avg(mastery) filter (where skill_bucket = 'hanzi') as hanzi
    from best_by_source
  ), weighted as (
    select
      vocabulary,
      listening,
      speaking,
      hanzi,
      (case when vocabulary is null then 0 else vocabulary * 0.35 end
       + case when listening is null then 0 else listening * 0.25 end
       + case when speaking is null then 0 else speaking * 0.20 end
       + case when hanzi is null then 0 else hanzi * 0.20 end) as weighted_sum,
      (case when vocabulary is null then 0 else 0.35 end
       + case when listening is null then 0 else 0.25 end
       + case when speaking is null then 0 else 0.20 end
       + case when hanzi is null then 0 else 0.20 end) as total_weight
    from skill_scores
  )
  select jsonb_build_object(
    'vocabulary_mastery', vocabulary,
    'listening_mastery', listening,
    'speaking_mastery', speaking,
    'hanzi_mastery', hanzi,
    'overall_mastery', case
      when total_weight > 0 then least(greatest(weighted_sum / total_weight, 0), 1)
      else 0
    end
  )
  from weighted;
$$;

create or replace function public.unit_mastery_v2(p_unit_id text)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with metrics as (
    select private.unit_mastery_for_user(auth.uid(), p_unit_id) as value
  ), state as (
    select
      not exists (
        select 1
        from public.duo_levels level
        cross join public.duo_game_definitions game
        where level.unit_id = p_unit_id
          and game.is_required_for_boss = true
          and private.duo_game_supported(level.id, game.game_code)
          and not exists (
            select 1
            from public.duo_level_progress progress
            where progress.user_id = auth.uid()
              and progress.game_id = game.id
              and progress.level_id = level.id
              and progress.is_completed = true
          )
      ) as all_required_missions_passed,
      exists (
        select 1 from public.boss_stages stage
        where stage.unit_id = p_unit_id and stage.active = true
      ) as boss_required,
      exists (
        select 1
        from public.boss_stages stage
        join public.boss_stage_progress progress
          on progress.stage_id = stage.id
         and progress.user_id = auth.uid()
         and progress.completed = true
        where stage.unit_id = p_unit_id and stage.active = true
      ) as boss_won
  )
  select metrics.value || jsonb_build_object(
    'all_required_missions_passed', state.all_required_missions_passed,
    'mastery_threshold', 0.70,
    'boss_required', state.boss_required,
    'boss_available', private.boss_available(auth.uid(), p_unit_id),
    'boss_won', state.boss_won,
    'unit_state', case
      when not state.all_required_missions_passed
        or coalesce((metrics.value ->> 'overall_mastery')::double precision, 0) < 0.70
        then 'in_progress'
      when state.boss_required and not state.boss_won then 'boss_pending'
      else 'completed'
    end
  )
  from metrics cross join state;
$$;

revoke execute on function public.unit_mastery_v2(text) from public, anon;
grant execute on function public.unit_mastery_v2(text) to authenticated;

-- Safe historical backfill: harmonize activity_type for legacy game_mission rows.
-- Preserves existing attempts, IDs, scores, and does NOT touch XP ledger or events.
update public.learning_attempts
set activity_type = case
  when coalesce(metadata ->> 'game_code', '') = 'listen_select' then 'listening'
  when coalesce(metadata ->> 'game_code', '') = 'speaking' then 'speaking'
  when coalesce(metadata ->> 'game_code', '') = 'dialogue' then 'dialogue'
  else 'vocabulary'
end
where activity_type = 'game_mission';
