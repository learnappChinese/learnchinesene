create or replace function public.current_learning_unit_v2()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_unit_id text;
  v_result jsonb;
begin
  if v_user_id is not null then
    select level.unit_id
    into v_unit_id
    from public.duo_active_sessions active
    join public.duo_levels level on level.id = active.level_id
    where active.user_id = v_user_id
      and active.status = 'active'
    order by active.updated_at desc
    limit 1;

    if v_unit_id is null then
      select level.unit_id
      into v_unit_id
      from public.duo_level_progress progress
      join public.duo_levels level on level.id = progress.level_id
      where progress.user_id = v_user_id
        and progress.is_unlocked = true
        and progress.is_completed = false
      order by progress.updated_at desc, level.level_index
      limit 1;
    end if;

    if v_unit_id is null then
      select level.unit_id
      into v_unit_id
      from public.duo_level_progress progress
      join public.duo_levels level on level.id = progress.level_id
      where progress.user_id = v_user_id
      order by progress.updated_at desc, level.level_index
      limit 1;
    end if;
  end if;

  if v_unit_id is null then
    select unit.id
    into v_unit_id
    from public.duo_units unit
    join public.duo_sections section on section.id = unit.section_id
    where private.unit_gate_available(v_user_id, unit.id)
    order by section.section_number, unit.unit_number, unit.unit_index
    limit 1;
  end if;

  select jsonb_build_object(
    'unit_id', unit.id,
    'unit_title', unit.title,
    'unit_number', unit.unit_number,
    'section_number', section.section_number,
    'section_title', section.title,
    'boss_available', private.boss_available(v_user_id, unit.id),
    'mastery', private.unit_mastery_for_user(v_user_id, unit.id)
  )
  into v_result
  from public.duo_units unit
  join public.duo_sections section on section.id = unit.section_id
  where unit.id = v_unit_id;

  return coalesce(v_result, '{}'::jsonb);
end;
$$;

revoke execute on function public.current_learning_unit_v2()
  from public;
grant execute on function public.current_learning_unit_v2()
  to anon, authenticated;
