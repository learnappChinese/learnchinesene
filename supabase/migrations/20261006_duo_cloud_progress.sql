-- Cloud progress/session state for Duolingo-style game levels.
-- Applied to Supabase on 2026-10-06.

create table if not exists public.duo_level_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  game_id bigint not null references public.duo_game_definitions(id) on delete cascade,
  level_id text not null references public.duo_levels(id) on delete cascade,
  attempts integer not null default 0 check (attempts >= 0),
  best_score integer not null default 0 check (best_score >= 0),
  stars smallint not null default 0 check (stars between 0 and 3),
  is_unlocked boolean not null default false,
  is_completed boolean not null default false,
  last_played_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, game_id, level_id)
);

create index if not exists duo_level_progress_user_game_idx
  on public.duo_level_progress(user_id, game_id);

create index if not exists duo_level_progress_user_level_idx
  on public.duo_level_progress(user_id, level_id);

alter table public.duo_level_progress enable row level security;

drop policy if exists duo_level_progress_select_own on public.duo_level_progress;
create policy duo_level_progress_select_own
on public.duo_level_progress for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists duo_level_progress_insert_own on public.duo_level_progress;
create policy duo_level_progress_insert_own
on public.duo_level_progress for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists duo_level_progress_update_own on public.duo_level_progress;
create policy duo_level_progress_update_own
on public.duo_level_progress for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists duo_level_progress_delete_own on public.duo_level_progress;
create policy duo_level_progress_delete_own
on public.duo_level_progress for delete to authenticated
using ((select auth.uid()) = user_id);

create table if not exists public.duo_active_sessions (
  user_id uuid not null references auth.users(id) on delete cascade,
  game_id bigint not null references public.duo_game_definitions(id) on delete cascade,
  level_id text not null references public.duo_levels(id) on delete cascade,
  current_index integer not null default 0 check (current_index >= 0),
  score integer not null default 0 check (score >= 0),
  correct_count integer not null default 0 check (correct_count >= 0),
  wrong_count integer not null default 0 check (wrong_count >= 0),
  status text not null default 'active'
    check (status in ('active', 'completed', 'abandoned')),
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, game_id, level_id)
);

create index if not exists duo_active_sessions_user_idx
  on public.duo_active_sessions(user_id);

alter table public.duo_active_sessions enable row level security;

drop policy if exists duo_active_sessions_select_own on public.duo_active_sessions;
create policy duo_active_sessions_select_own
on public.duo_active_sessions for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists duo_active_sessions_insert_own on public.duo_active_sessions;
create policy duo_active_sessions_insert_own
on public.duo_active_sessions for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists duo_active_sessions_update_own on public.duo_active_sessions;
create policy duo_active_sessions_update_own
on public.duo_active_sessions for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists duo_active_sessions_delete_own on public.duo_active_sessions;
create policy duo_active_sessions_delete_own
on public.duo_active_sessions for delete to authenticated
using ((select auth.uid()) = user_id);

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
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.duo_level_progress (
    user_id, game_id, level_id, attempts, best_score, stars,
    is_unlocked, is_completed, last_played_at, completed_at, updated_at
  )
  values (
    v_user_id, p_game_id, p_level_id, 1,
    greatest(coalesce(p_score, 0), 0),
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

  return v_row;
end;
$$;

create or replace function public.unlock_duo_level(
  p_game_id bigint,
  p_level_id text
)
returns public.duo_level_progress
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.duo_level_progress;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.duo_level_progress (
    user_id, game_id, level_id, is_unlocked, updated_at
  )
  values (
    v_user_id, p_game_id, p_level_id, true, now()
  )
  on conflict (user_id, game_id, level_id) do update
  set is_unlocked = true,
      updated_at = now()
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.record_duo_level_progress(
  bigint, text, integer, smallint, boolean
) to authenticated;

grant execute on function public.unlock_duo_level(bigint, text)
to authenticated;
