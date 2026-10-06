-- Keep Home XP/streak synchronized when a cloud game level finishes.

create or replace function public.record_duo_level_progress(
  p_game_id bigint,
  p_level_id text,
  p_score integer,
  p_stars smallint,
  p_passed boolean
)
returns public.duo_level_progress
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.duo_level_progress;
  v_exp integer := greatest(coalesce(p_score, 0), 0);
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.duo_level_progress (
    user_id, game_id, level_id, attempts, best_score, stars,
    is_unlocked, is_completed, last_played_at, completed_at, updated_at
  )
  values (
    v_user_id, p_game_id, p_level_id, 1, v_exp,
    least(greatest(coalesce(p_stars, 0), 0), 3),
    true, coalesce(p_passed, false), now(),
    case when coalesce(p_passed, false) then now() else null end,
    now()
  )
  on conflict (user_id, game_id, level_id) do update
  set attempts = public.duo_level_progress.attempts + 1,
      best_score = greatest(public.duo_level_progress.best_score, excluded.best_score),
      stars = greatest(public.duo_level_progress.stars, excluded.stars),
      is_unlocked = true,
      is_completed = public.duo_level_progress.is_completed or excluded.is_completed,
      last_played_at = now(),
      completed_at = case
        when public.duo_level_progress.completed_at is not null
          then public.duo_level_progress.completed_at
        when excluded.is_completed
          then now()
        else null
      end,
      updated_at = now()
  returning * into v_row;

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

  return v_row;
end;
$$;

grant execute on function public.record_duo_level_progress(
  bigint, text, integer, smallint, boolean
) to authenticated;
