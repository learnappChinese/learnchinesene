-- Avoid evaluating every Stage path when rendering the World/Section list.
-- Section completion is the count of Unit Boss clears; Section availability is
-- the authoritative gate state of its first ordered Unit.

create or replace function public.learning_sections_v2()
returns table(
  section_id text,
  section_number integer,
  section_title text,
  unit_count integer,
  completed_unit_count integer,
  is_unlocked boolean,
  is_completed boolean,
  lock_reason text,
  required_section_number integer
)
language sql
stable
security definer
set search_path = ''
as $$
  with ordered_sections as (
    select
      section.id,
      section.section_number,
      section.title,
      lag(section.section_number) over (
        order by section.section_number, section.id
      ) as previous_section_number
    from public.duo_sections section
  ), ranked_units as (
    select
      unit.id,
      unit.section_id,
      row_number() over (
        partition by unit.section_id
        order by unit.unit_number, unit.unit_index, unit.id
      ) as unit_rank
    from public.duo_units unit
  ), unit_rollup as (
    select
      unit.section_id,
      count(*)::integer as unit_count,
      count(*) filter (
        where exists (
          select 1
          from public.boss_stages stage
          join public.boss_stage_progress progress
            on progress.stage_id = stage.id
           and progress.user_id = auth.uid()
           and progress.completed = true
          where stage.unit_id = unit.id
            and stage.active = true
        )
      )::integer as completed_unit_count,
      max(unit.id) filter (where unit.unit_rank = 1) as first_unit_id
    from ranked_units unit
    group by unit.section_id
  )
  select
    section.id as section_id,
    section.section_number,
    section.title as section_title,
    coalesce(rollup.unit_count, 0) as unit_count,
    coalesce(rollup.completed_unit_count, 0) as completed_unit_count,
    coalesce(
      private.unit_gate_available(auth.uid(), rollup.first_unit_id),
      false
    ) as is_unlocked,
    (
      coalesce(rollup.unit_count, 0) > 0
      and rollup.completed_unit_count >= rollup.unit_count
    ) as is_completed,
    case
      when private.unit_gate_available(auth.uid(), rollup.first_unit_id)
        then null
      else 'complete_previous_world'
    end::text as lock_reason,
    case
      when private.unit_gate_available(auth.uid(), rollup.first_unit_id)
        then null
      else section.previous_section_number
    end::integer as required_section_number
  from ordered_sections section
  left join unit_rollup rollup on rollup.section_id = section.id
  order by section.section_number, section.id;
$$;

revoke all on function public.learning_sections_v2() from public;
grant execute on function public.learning_sections_v2() to anon, authenticated;
