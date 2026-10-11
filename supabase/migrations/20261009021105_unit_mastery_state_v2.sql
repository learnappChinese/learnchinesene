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
