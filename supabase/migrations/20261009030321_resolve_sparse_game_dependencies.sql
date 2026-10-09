create or replace function private.learning_node_available(
  p_user_id uuid,
  p_game_id bigint,
  p_level_id text
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_unit_id text;
  v_level_index integer;
  v_game_code text;
  v_game_order integer;
  v_prerequisites text[];
  v_previous_level_id text;
  v_has_supported_prerequisite boolean;
begin
  if exists (
    select 1
    from public.duo_level_progress progress
    where progress.user_id = p_user_id
      and progress.game_id = p_game_id
      and progress.level_id = p_level_id
      and (progress.is_unlocked or progress.is_completed)
  ) then
    return true;
  end if;

  select
    level.unit_id,
    level.level_index,
    game.game_code,
    game.game_order,
    game.prerequisite_game_codes
  into
    v_unit_id,
    v_level_index,
    v_game_code,
    v_game_order,
    v_prerequisites
  from public.duo_levels level
  join public.duo_game_definitions game on game.id = p_game_id
  where level.id = p_level_id;

  if v_unit_id is null
     or not private.duo_game_supported(p_level_id, v_game_code)
     or not private.unit_gate_available(p_user_id, v_unit_id) then
    return false;
  end if;

  select previous.id
  into v_previous_level_id
  from public.duo_levels previous
  where previous.unit_id = v_unit_id
    and previous.level_index < v_level_index
  order by previous.level_index desc, previous.absolute_node_index desc
  limit 1;

  if v_previous_level_id is not null and exists (
    select 1
    from public.duo_game_definitions required_game
    where required_game.is_required_for_boss = true
      and private.duo_game_supported(
        v_previous_level_id,
        required_game.game_code
      )
      and not exists (
        select 1
        from public.duo_level_progress progress
        where progress.user_id = p_user_id
          and progress.game_id = required_game.id
          and progress.level_id = v_previous_level_id
          and progress.is_completed = true
      )
  ) then
    return false;
  end if;

  select exists (
    select 1
    from unnest(coalesce(v_prerequisites, '{}'::text[])) prerequisite(code)
    where private.duo_game_supported(p_level_id, prerequisite.code)
  ) into v_has_supported_prerequisite;

  if v_has_supported_prerequisite then
    return not exists (
      select 1
      from unnest(v_prerequisites) prerequisite(code)
      join public.duo_game_definitions prerequisite_game
        on prerequisite_game.game_code = prerequisite.code
      where private.duo_game_supported(p_level_id, prerequisite.code)
        and not exists (
          select 1
          from public.duo_level_progress progress
          where progress.user_id = p_user_id
            and progress.game_id = prerequisite_game.id
            and progress.level_id = p_level_id
            and progress.is_completed = true
        )
    );
  end if;

  -- Imported curriculum can omit a configured prerequisite activity. In that
  -- case depend on the nearest earlier supported activity instead of silently
  -- making this node available.
  if cardinality(coalesce(v_prerequisites, '{}'::text[])) > 0 then
    return not exists (
      select 1
      from public.duo_game_definitions previous_game
      where previous_game.game_order = (
        select max(candidate.game_order)
        from public.duo_game_definitions candidate
        where candidate.game_order < v_game_order
          and private.duo_game_supported(p_level_id, candidate.game_code)
      )
        and not exists (
          select 1
          from public.duo_level_progress progress
          where progress.user_id = p_user_id
            and progress.game_id = previous_game.id
            and progress.level_id = p_level_id
            and progress.is_completed = true
        )
    );
  end if;

  return true;
end;
$$;

revoke all on function private.learning_node_available(uuid, bigint, text)
  from public, anon, authenticated;
