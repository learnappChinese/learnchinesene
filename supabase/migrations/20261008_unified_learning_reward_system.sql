-- Unified Learning Reward & Progress System
-- Tables: learning_xp_events, learning_attempts
-- Extended columns for app_user_stats
-- Central RPC: record_learning_reward

-- 1. Create learning_xp_events table for immutable XP transaction history
create table if not exists public.learning_xp_events (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  source_type text not null, -- 'level', 'word', 'speaking', 'hanzi', 'dialogue', 'boss', 'review', 'daily_quest'
  source_id text not null,
  activity_type text not null, -- 'vocabulary', 'listening', 'speaking', 'hanzi', 'dialogue', 'boss', 'review'
  xp_amount integer not null check (xp_amount >= 0),
  base_xp integer not null default 0 check (base_xp >= 0),
  bonus_xp integer not null default 0 check (bonus_xp >= 0),
  reason text not null default '',
  score double precision default 0,
  accuracy double precision default 0,
  stars smallint default 0 check (stars between 0 and 3),
  idempotency_key text unique not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default now() not null
);

-- Indexes for fast analytics and history lookup
create index if not exists idx_learning_xp_events_user_created 
  on public.learning_xp_events (user_id, created_at desc);
create index if not exists idx_learning_xp_events_source 
  on public.learning_xp_events (source_type, source_id);
create index if not exists idx_learning_xp_events_idempotency 
  on public.learning_xp_events (idempotency_key);

-- RLS for learning_xp_events
alter table public.learning_xp_events enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies 
    where schemaname = 'public' and tablename = 'learning_xp_events' and policyname = 'Users can view their own XP events'
  ) then
    create policy "Users can view their own XP events"
      on public.learning_xp_events for select
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies 
    where schemaname = 'public' and tablename = 'learning_xp_events' and policyname = 'Users can insert their own XP events'
  ) then
    create policy "Users can insert their own XP events"
      on public.learning_xp_events for insert
      with check (auth.uid() = user_id);
  end if;
end $$;


-- 2. Create learning_attempts table for comprehensive attempt & retry tracking
create table if not exists public.learning_attempts (
  id text primary key, -- client generated UUID or nanoid
  user_id uuid references auth.users(id) on delete cascade not null,
  activity_type text not null,
  level_id text,
  unit_id text,
  source_id text,
  started_at timestamp with time zone default now() not null,
  completed_at timestamp with time zone,
  status text not null default 'started' check (status in ('started', 'completed', 'passed', 'failed', 'abandoned')),
  score double precision default 0,
  accuracy double precision default 0,
  correct_count integer default 0,
  wrong_count integer default 0,
  stars smallint default 0 check (stars between 0 and 3),
  xp_earned integer default 0 check (xp_earned >= 0),
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default now() not null
);

create index if not exists idx_learning_attempts_user_created 
  on public.learning_attempts (user_id, created_at desc);
create index if not exists idx_learning_attempts_activity 
  on public.learning_attempts (activity_type, level_id);

alter table public.learning_attempts enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies 
    where schemaname = 'public' and tablename = 'learning_attempts' and policyname = 'Users can view their own attempts'
  ) then
    create policy "Users can view their own attempts"
      on public.learning_attempts for select
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies 
    where schemaname = 'public' and tablename = 'learning_attempts' and policyname = 'Users can insert their own attempts'
  ) then
    create policy "Users can insert their own attempts"
      on public.learning_attempts for insert
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies 
    where schemaname = 'public' and tablename = 'learning_attempts' and policyname = 'Users can update their own attempts'
  ) then
    create policy "Users can update their own attempts"
      on public.learning_attempts for update
      using (auth.uid() = user_id);
  end if;
end $$;


-- 3. Extend app_user_stats with learning analytics columns if missing
alter table public.app_user_stats
  add column if not exists total_lessons_completed integer default 0,
  add column if not exists total_bosses_defeated integer default 0,
  add column if not exists total_speaking_attempts integer default 0,
  add column if not exists total_hanzi_practices integer default 0,
  add column if not exists total_minutes_studied integer default 0,
  add column if not exists highest_combo integer default 0;


-- 4. Central Server-side RPC: record_learning_reward
-- Atomically handles idempotency, attempts, XP history, streak updates, and aggregate stats
create or replace function public.record_learning_reward(
  p_activity_type text,
  p_source_type text,
  p_source_id text,
  p_attempt_id text,
  p_score double precision default 0,
  p_accuracy double precision default 0,
  p_correct_count integer default 0,
  p_wrong_count integer default 0,
  p_stars smallint default 0,
  p_passed boolean default false,
  p_base_xp integer default 0,
  p_bonus_xp integer default 0,
  p_idempotency_key text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_idem_key text;
  v_existing_xp integer;
  v_total_xp integer;
  v_stats public.app_user_stats;
  v_is_first_clear boolean := false;
  v_updated_streak integer := 1;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  -- Construct default idempotency key if not provided
  v_idem_key := coalesce(
    p_idempotency_key, 
    v_user_id::text || ':' || p_source_type || ':' || p_source_id || ':' || coalesce(p_attempt_id, 'def')
  );

  -- 1. Check if already processed (Idempotency)
  select xp_amount into v_existing_xp
  from public.learning_xp_events
  where idempotency_key = v_idem_key;

  if v_existing_xp is not null then
    -- Return existing stats without re-awarding XP
    select * into v_stats from public.app_user_stats where user_id = v_user_id;
    return jsonb_build_object(
      'success', true,
      'idempotent', true,
      'xp_awarded', 0,
      'total_exp', coalesce(v_stats.total_exp, 0),
      'current_streak', coalesce(v_stats.current_streak, 0),
      'passed', p_passed,
      'stars', p_stars,
      'is_first_clear', false
    );
  end if;

  v_total_xp := greatest(coalesce(p_base_xp, 0) + coalesce(p_bonus_xp, 0), 0);

  -- 2. Check first clear status
  if p_passed then
    if not exists (
      select 1 from public.learning_xp_events
      where user_id = v_user_id 
        and source_type = p_source_type 
        and source_id = p_source_id
    ) then
      v_is_first_clear := true;
    end if;
  end if;

  -- 3. Record or update attempt
  if p_attempt_id is not null and btrim(p_attempt_id) <> '' then
    insert into public.learning_attempts (
      id, user_id, activity_type, source_id, status,
      score, accuracy, correct_count, wrong_count, stars, xp_earned,
      metadata, completed_at
    )
    values (
      p_attempt_id, v_user_id, p_activity_type, p_source_id,
      case when p_passed then 'passed' else 'failed' end,
      p_score, p_accuracy, p_correct_count, p_wrong_count,
      p_stars, v_total_xp, p_metadata, now()
    )
    on conflict (id) do update set
      status = case when p_passed then 'passed' else 'failed' end,
      score = excluded.score,
      accuracy = excluded.accuracy,
      correct_count = excluded.correct_count,
      wrong_count = excluded.wrong_count,
      stars = greatest(public.learning_attempts.stars, excluded.stars),
      xp_earned = excluded.xp_earned,
      metadata = excluded.metadata,
      completed_at = now();
  end if;

  -- 4. Record XP transaction if any XP awarded
  if v_total_xp > 0 then
    insert into public.learning_xp_events (
      user_id, source_type, source_id, activity_type,
      xp_amount, base_xp, bonus_xp, reason,
      score, accuracy, stars, idempotency_key, metadata
    )
    values (
      v_user_id, p_source_type, p_source_id, p_activity_type,
      v_total_xp, p_base_xp, p_bonus_xp,
      case 
        when v_is_first_clear then 'first_clear'
        when p_passed then 'pass_completion'
        else 'practice_effort'
      end,
      p_score, p_accuracy, p_stars, v_idem_key, p_metadata
    );
  end if;

  -- 5. Update app_user_stats (Aggregate & Central Streak Rule)
  insert into public.app_user_stats (
    user_id, total_exp, current_streak, last_study_date,
    total_words_mastered, total_favorites, total_lessons_completed,
    total_bosses_defeated, total_speaking_attempts, total_hanzi_practices,
    updated_at
  )
  values (
    v_user_id, v_total_xp, 1, now(),
    0, 0,
    case when p_passed and p_activity_type in ('vocabulary', 'listening', 'dialogue') then 1 else 0 end,
    case when p_passed and p_activity_type = 'boss' then 1 else 0 end,
    case when p_activity_type = 'speaking' then 1 else 0 end,
    case when p_activity_type = 'hanzi' then 1 else 0 end,
    now()
  )
  on conflict (user_id) do update set
    total_exp = public.app_user_stats.total_exp + v_total_xp,
    current_streak = case
      when p_passed then
        case
          when public.app_user_stats.last_study_date::date = current_date
            then greatest(public.app_user_stats.current_streak, 1)
          when public.app_user_stats.last_study_date::date = current_date - 1
            then public.app_user_stats.current_streak + 1
          else 1
        end
      else public.app_user_stats.current_streak
    end,
    last_study_date = case when p_passed then now() else public.app_user_stats.last_study_date end,
    total_lessons_completed = public.app_user_stats.total_lessons_completed 
      + case when p_passed and p_activity_type in ('vocabulary', 'listening', 'dialogue') then 1 else 0 end,
    total_bosses_defeated = public.app_user_stats.total_bosses_defeated 
      + case when p_passed and p_activity_type = 'boss' then 1 else 0 end,
    total_speaking_attempts = public.app_user_stats.total_speaking_attempts 
      + case when p_activity_type = 'speaking' then 1 else 0 end,
    total_hanzi_practices = public.app_user_stats.total_hanzi_practices 
      + case when p_activity_type = 'hanzi' then 1 else 0 end,
    updated_at = now()
  returning * into v_stats;

  return jsonb_build_object(
    'success', true,
    'idempotent', false,
    'xp_awarded', v_total_xp,
    'total_exp', coalesce(v_stats.total_exp, 0),
    'current_streak', coalesce(v_stats.current_streak, 0),
    'passed', p_passed,
    'stars', p_stars,
    'is_first_clear', v_is_first_clear
  );
end;
$$;

grant execute on function public.record_learning_reward(
  text, text, text, text, double precision, double precision,
  integer, integer, smallint, boolean, integer, integer, text, jsonb
) to authenticated;
