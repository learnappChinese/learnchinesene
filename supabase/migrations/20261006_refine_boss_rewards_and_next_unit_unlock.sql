
create or replace function public.record_boss_progress(
  p_stage_id bigint,
  p_score integer,
  p_stars smallint,
  p_best_combo integer,
  p_won boolean
)
returns public.boss_stage_progress
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.boss_stage_progress;
  v_exp integer := case
    when coalesce(p_won, false)
      then least(greatest(coalesce(p_score, 0), 0), 300) + 100
    else 0
  end;
  v_unit_id text;
  v_next_unit_id text;
  v_next_game_id bigint;
  v_next_level_id text;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select bs.unit_id
  into v_unit_id
  from public.boss_stages bs
  where bs.id = p_stage_id
    and bs.active = true;

  if v_unit_id is null then
    raise exception 'Boss stage not found';
  end if;

  insert into public.boss_stage_progress (
    user_id, stage_id, completed, stars, best_score, best_combo,
    attempts, last_played_at, updated_at
  )
  values (
    v_user_id,
    p_stage_id,
    coalesce(p_won, false),
    case
      when coalesce(p_won, false)
        then least(greatest(coalesce(p_stars, 0), 0), 3)
      else 0
    end,
    greatest(coalesce(p_score, 0), 0),
    greatest(coalesce(p_best_combo, 0), 0),
    1,
    now(),
    now()
  )
  on conflict (user_id, stage_id) do update
  set completed = public.boss_stage_progress.completed or excluded.completed,
      stars = greatest(public.boss_stage_progress.stars, excluded.stars),
      best_score = greatest(public.boss_stage_progress.best_score, excluded.best_score),
      best_combo = greatest(public.boss_stage_progress.best_combo, excluded.best_combo),
      attempts = public.boss_stage_progress.attempts + 1,
      last_played_at = now(),
      updated_at = now()
  returning * into v_row;

  if v_exp > 0 then
    insert into public.app_user_stats (
      user_id, total_exp, current_streak, last_study_date,
      total_words_mastered, total_favorites, updated_at
    )
    values (
      v_user_id, v_exp, 1, now(), 0, 0, now()
    )
    on conflict (user_id) do update
    set total_exp = public.app_user_stats.total_exp + v_exp,
        current_streak = case
          when public.app_user_stats.last_study_date::date = current_date
            then greatest(public.app_user_stats.current_streak, 1)
          when public.app_user_stats.last_study_date::date = current_date - 1
            then public.app_user_stats.current_streak + 1
          else 1
        end,
        last_study_date = now(),
        updated_at = now();
  end if;

  if coalesce(p_won, false) then
    select u2.id
    into v_next_unit_id
    from public.duo_units current_u
    join public.duo_sections current_s on current_s.id = current_u.section_id
    join public.duo_units u2 on true
    join public.duo_sections s2 on s2.id = u2.section_id
    where current_u.id = v_unit_id
      and (
        s2.section_number > current_s.section_number
        or (
          s2.section_number = current_s.section_number
          and u2.unit_number > current_u.unit_number
        )
      )
    order by s2.section_number, u2.unit_number, u2.unit_index
    limit 1;

    if v_next_unit_id is not null then
      select g.id, l.id
      into v_next_game_id, v_next_level_id
      from public.duo_levels l
      cross join public.duo_game_definitions g
      where l.unit_id = v_next_unit_id
        and exists (
          select 1
          from public.duo_sessions s
          join public.duo_challenges c on c.session_id = s.id
          where s.level_id = l.id
            and (
              (g.game_code = 'learn_words'
                and c.type in ('select','assist','match'))
              or (g.game_code = 'select_answer'
                and c.type in ('select','assist'))
              or (g.game_code in ('word_connect','match_pairs')
                and c.type = 'match')
              or (g.game_code = 'listen_select' and c.type = 'listenTap')
              or (g.game_code = 'translate' and c.type = 'translate')
              or (g.game_code = 'gap_fill' and c.type = 'gapFill')
              or (g.game_code = 'tap_complete' and c.type = 'tapComplete')
              or (g.game_code = 'dialogue' and c.type = 'dialogue')
              or (g.game_code = 'sentence_order' and c.type = 'orderTapComplete')
              or (
                g.game_code = 'speaking'
                and c.prompt is not null
                and btrim(c.prompt) <> ''
              )
            )
        )
      order by l.level_index, g.game_order, g.id
      limit 1;

      if v_next_game_id is not null and v_next_level_id is not null then
        insert into public.duo_level_progress (
          user_id, game_id, level_id, is_unlocked, updated_at
        )
        values (
          v_user_id, v_next_game_id, v_next_level_id, true, now()
        )
        on conflict (user_id, game_id, level_id) do update
        set is_unlocked = true,
            updated_at = now();
      end if;
    end if;
  end if;

  return v_row;
end;
$$;

grant execute on function public.record_boss_progress(
  bigint, integer, smallint, integer, boolean
) to authenticated;
