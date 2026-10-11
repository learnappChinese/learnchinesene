-- Unit catalogue projection for the Learning Adventure UI.
--
-- Progress and unlock state stay authoritative on the server. The client only
-- renders this projection and never infers whether a Unit can be entered.

create or replace function public.learning_units_v2(p_section_id text)
returns table(
  unit_id text,
  section_id text,
  section_number integer,
  unit_number integer,
  unit_index integer,
  unit_title text,
  teaching_objective text,
  stage_count integer,
  completed_stage_count integer,
  overall_mastery double precision,
  unit_state text,
  is_unlocked boolean,
  boss_available boolean,
  boss_won boolean,
  boss_stage_id bigint,
  boss_name text,
  lock_reason text,
  required_unit_id text
)
language sql
stable
security definer
set search_path = ''
as $$
  with ordered_units as (
    select
      unit.id,
      unit.section_id,
      section.section_number,
      unit.unit_number,
      unit.unit_index,
      unit.title,
      lag(unit.id) over (
        order by section.section_number, unit.unit_number, unit.unit_index, unit.id
      ) as previous_unit_id
    from public.duo_units unit
    join public.duo_sections section on section.id = unit.section_id
    where unit.section_id = p_section_id
  ), path_rollup as (
    select
      unit.id as unit_id,
      count(*) filter (where path.node_type = 'learning')::integer as stage_count,
      count(*) filter (
        where path.node_type = 'learning' and path.is_completed
      )::integer as completed_stage_count,
      coalesce(bool_or(path.in_progress) filter (
        where path.node_type = 'learning'
      ), false) as has_active_stage,
      coalesce(bool_or(path.attempts > 0 and not path.is_completed) filter (
        where path.node_type = 'learning'
      ), false) as has_failed_stage,
      coalesce(max(path.overall_mastery), 0)::double precision as overall_mastery,
      coalesce(bool_or(path.is_unlocked) filter (
        where path.node_type = 'boss'
      ), false) as boss_available,
      coalesce(bool_or(path.is_completed) filter (
        where path.node_type = 'boss'
      ), false) as boss_won,
      max(path.boss_stage_id) filter (where path.node_type = 'boss') as boss_stage_id,
      max(path.boss_name) filter (where path.node_type = 'boss') as boss_name
    from ordered_units unit
    left join lateral public.unit_learning_path_v2(unit.id) path on true
    group by unit.id
  )
  select
    unit.id as unit_id,
    unit.section_id,
    unit.section_number,
    unit.unit_number,
    unit.unit_index,
    unit.title as unit_title,
    coalesce((
      select level.teaching_objective
      from public.duo_levels level
      where level.unit_id = unit.id
        and nullif(btrim(level.teaching_objective), '') is not null
      order by level.level_index, level.absolute_node_index, level.id
      limit 1
    ), unit.title, '') as teaching_objective,
    coalesce(path.stage_count, 0) as stage_count,
    coalesce(path.completed_stage_count, 0) as completed_stage_count,
    coalesce(path.overall_mastery, 0) as overall_mastery,
    case
      when not private.unit_gate_available(auth.uid(), unit.id) then 'locked'
      when coalesce(path.boss_won, false) then 'completed'
      when coalesce(path.has_active_stage, false) then 'in_progress'
      when coalesce(path.has_failed_stage, false) then 'failed'
      when coalesce(path.completed_stage_count, 0) > 0 then 'in_progress'
      else 'available'
    end::text as unit_state,
    private.unit_gate_available(auth.uid(), unit.id) as is_unlocked,
    coalesce(path.boss_available, false) as boss_available,
    coalesce(path.boss_won, false) as boss_won,
    path.boss_stage_id,
    path.boss_name,
    case
      when private.unit_gate_available(auth.uid(), unit.id) then null
      when unit.previous_unit_id is not null then 'boss_required'
      else 'chapter_locked'
    end::text as lock_reason,
    case
      when private.unit_gate_available(auth.uid(), unit.id) then null
      else unit.previous_unit_id
    end::text as required_unit_id
  from ordered_units unit
  left join path_rollup path on path.unit_id = unit.id
  order by unit.section_number, unit.unit_number, unit.unit_index, unit.id;
$$;

revoke all on function public.learning_units_v2(text) from public;
grant execute on function public.learning_units_v2(text) to anon, authenticated;

comment on function public.learning_units_v2(text) is
  'Server-authoritative ordered Unit list with dynamic Stage progress, mastery, Boss, and lock state.';
