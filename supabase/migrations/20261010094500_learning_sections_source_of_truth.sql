-- Section/Region projection. World/Section cards consume this function instead
-- of rebuilding unlock state from client-side ordering.

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
  ), rollup as (
    select
      section.id as section_id,
      count(unit.unit_id)::integer as unit_count,
      count(*) filter (where unit.unit_state = 'completed')::integer
        as completed_unit_count,
      coalesce(bool_or(unit.is_unlocked), false) as is_unlocked
    from ordered_sections section
    left join lateral public.learning_units_v2(section.id) unit on true
    group by section.id
  )
  select
    section.id as section_id,
    section.section_number,
    section.title as section_title,
    coalesce(rollup.unit_count, 0) as unit_count,
    coalesce(rollup.completed_unit_count, 0) as completed_unit_count,
    coalesce(rollup.is_unlocked, false) as is_unlocked,
    (
      coalesce(rollup.unit_count, 0) > 0
      and rollup.completed_unit_count >= rollup.unit_count
    ) as is_completed,
    case
      when coalesce(rollup.is_unlocked, false) then null
      else 'complete_previous_world'
    end::text as lock_reason,
    case
      when coalesce(rollup.is_unlocked, false) then null
      else section.previous_section_number
    end::integer as required_section_number
  from ordered_sections section
  left join rollup on rollup.section_id = section.id
  order by section.section_number, section.id;
$$;

revoke all on function public.learning_sections_v2() from public;
grant execute on function public.learning_sections_v2() to anon, authenticated;

comment on function public.learning_sections_v2() is
  'Server-authoritative ordered Sections with Unit completion and World unlock state.';
