-- Unified, server-authoritative learning completion pipeline.
-- Reuses the existing history/progress tables and keeps every completion
-- transaction atomic: result, XP, mastery, aggregate stats and unlock state.

create schema if not exists private;

alter table public.learning_xp_events
  add column if not exists event_key text,
  add column if not exists attempt_id text;

update public.learning_xp_events
set event_key = idempotency_key
where event_key is null;

alter table public.learning_xp_events
  alter column event_key set not null;

alter table public.learning_xp_events
  drop constraint if exists learning_xp_events_idempotency_key_key;

drop index if exists public.idx_learning_xp_events_idempotency;

create unique index if not exists learning_xp_events_user_event_key_key
  on public.learning_xp_events (user_id, event_key);

create index if not exists idx_learning_xp_events_user_source
  on public.learning_xp_events (user_id, source_type, source_id);

alter table public.learning_attempts
  add column if not exists source_type text not null default '',
  add column if not exists duration_seconds integer not null default 0,
  add column if not exists best_combo integer not null default 0,
  add column if not exists mastery_before double precision not null default 0,
  add column if not exists mastery_after double precision not null default 0,
  add column if not exists reason text not null default '',
  add column if not exists first_clear boolean not null default false,
  add column if not exists perfect boolean not null default false;

alter table public.learning_attempts
  drop constraint if exists learning_attempts_status_check;

alter table public.learning_attempts
  add constraint learning_attempts_status_check
  check (status in ('started', 'passed', 'failed', 'abandoned'));

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.learning_attempts'::regclass
      and conname = 'learning_attempts_duration_seconds_check'
  ) then
    alter table public.learning_attempts
      add constraint learning_attempts_duration_seconds_check
      check (duration_seconds >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.learning_attempts'::regclass
      and conname = 'learning_attempts_best_combo_check'
  ) then
    alter table public.learning_attempts
      add constraint learning_attempts_best_combo_check
      check (best_combo >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.learning_attempts'::regclass
      and conname = 'learning_attempts_mastery_before_check'
  ) then
    alter table public.learning_attempts
      add constraint learning_attempts_mastery_before_check
      check (mastery_before between 0 and 1);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.learning_attempts'::regclass
      and conname = 'learning_attempts_mastery_after_check'
  ) then
    alter table public.learning_attempts
      add constraint learning_attempts_mastery_after_check
      check (mastery_after between 0 and 1);
  end if;
end
$$;

create index if not exists idx_learning_attempts_user_source_status
  on public.learning_attempts (user_id, source_type, source_id, status);

create index if not exists idx_learning_attempts_user_unit_activity
  on public.learning_attempts (user_id, unit_id, activity_type, completed_at desc);

alter table public.lexicon_hanzi_progress
  add column if not exists next_review_at timestamp with time zone,
  add column if not exists last_score double precision;

alter table public.duo_active_sessions
  add column if not exists attempt_id text;

alter table public.duo_game_definitions
  add column if not exists prerequisite_game_codes text[] not null default '{}',
  add column if not exists is_required_for_boss boolean not null default true;

update public.duo_game_definitions
set prerequisite_game_codes = case game_code
  when 'learn_words' then '{}'::text[]
  when 'select_answer' then array['learn_words']::text[]
  when 'match_pairs' then array['learn_words']::text[]
  when 'word_connect' then array['learn_words']::text[]
  when 'listen_select' then array['select_answer']::text[]
  when 'translate' then array['select_answer']::text[]
  when 'gap_fill' then array['translate']::text[]
  when 'tap_complete' then array['gap_fill']::text[]
  when 'dialogue' then array['listen_select', 'gap_fill']::text[]
  when 'sentence_order' then array['dialogue']::text[]
  when 'speaking' then array['dialogue']::text[]
  else prerequisite_game_codes
end;

create or replace function private.duo_game_supported(
  p_level_id text,
  p_game_code text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.duo_sessions s
    join public.duo_challenges c on c.session_id = s.id
    where s.level_id = p_level_id
      and (
        (p_game_code = 'learn_words' and c.type in ('select', 'assist', 'match'))
        or (p_game_code = 'select_answer' and c.type in ('select', 'assist'))
        or (p_game_code in ('word_connect', 'match_pairs') and c.type = 'match')
        or (p_game_code = 'listen_select' and c.type = 'listenTap')
        or (p_game_code = 'translate' and c.type = 'translate')
        or (p_game_code = 'gap_fill' and c.type = 'gapFill')
        or (p_game_code = 'tap_complete' and c.type = 'tapComplete')
        or (p_game_code = 'dialogue' and c.type = 'dialogue')
        or (p_game_code = 'sentence_order' and c.type = 'orderTapComplete')
        or (p_game_code = 'speaking' and c.type = 'speaking')
      )
  );
$$;

create or replace function private.unit_gate_available(
  p_user_id uuid,
  p_unit_id text
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stage_order integer;
begin
  select bs.stage_order
  into v_stage_order
  from public.boss_stages bs
  where bs.unit_id = p_unit_id and bs.active = true
  order by bs.stage_order
  limit 1;

  if v_stage_order is null or v_stage_order <= 1 then
    return true;
  end if;

  return exists (
    select 1
    from public.boss_stages previous_stage
    join public.boss_stage_progress progress
      on progress.stage_id = previous_stage.id
     and progress.user_id = p_user_id
     and progress.completed = true
    where previous_stage.stage_order = v_stage_order - 1
      and previous_stage.active = true
  );
end;
$$;

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
  v_prerequisites text[];
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

  select level.unit_id, game.prerequisite_game_codes
  into v_unit_id, v_prerequisites
  from public.duo_levels level
  join public.duo_game_definitions game on game.id = p_game_id
  where level.id = p_level_id;

  if v_unit_id is null
     or not private.duo_game_supported(p_level_id, (
       select game_code from public.duo_game_definitions where id = p_game_id
     ))
     or not private.unit_gate_available(p_user_id, v_unit_id) then
    return false;
  end if;

  return not exists (
    select 1
    from unnest(coalesce(v_prerequisites, '{}'::text[])) prerequisite(code)
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
end;
$$;

create or replace function private.unit_mastery_for_user(
  p_user_id uuid,
  p_unit_id text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with best_by_source as (
    select
      attempts.activity_type,
      attempts.source_type,
      attempts.source_id,
      max(
        case
          when attempts.activity_type in ('speaking', 'hanzi')
            then least(greatest(attempts.score / 100.0, 0), 1)
          else least(greatest(attempts.accuracy, 0), 1)
        end
      ) as mastery
    from public.learning_attempts attempts
    where attempts.user_id = p_user_id
      and attempts.unit_id = p_unit_id
      and attempts.status in ('passed', 'failed')
    group by attempts.activity_type, attempts.source_type, attempts.source_id
  ), skill_scores as (
    select
      avg(mastery) filter (where activity_type = 'vocabulary') as vocabulary,
      avg(mastery) filter (where activity_type = 'listening') as listening,
      avg(mastery) filter (where activity_type = 'speaking') as speaking,
      avg(mastery) filter (where activity_type = 'hanzi') as hanzi
    from best_by_source
  ), weighted as (
    select
      vocabulary,
      listening,
      speaking,
      hanzi,
      (case when vocabulary is null then 0 else vocabulary * 0.35 end
       + case when listening is null then 0 else listening * 0.25 end
       + case when speaking is null then 0 else speaking * 0.20 end
       + case when hanzi is null then 0 else hanzi * 0.20 end) as weighted_sum,
      (case when vocabulary is null then 0 else 0.35 end
       + case when listening is null then 0 else 0.25 end
       + case when speaking is null then 0 else 0.20 end
       + case when hanzi is null then 0 else 0.20 end) as total_weight
    from skill_scores
  )
  select jsonb_build_object(
    'vocabulary_mastery', vocabulary,
    'listening_mastery', listening,
    'speaking_mastery', speaking,
    'hanzi_mastery', hanzi,
    'overall_mastery', case
      when total_weight > 0 then least(greatest(weighted_sum / total_weight, 0), 1)
      else 0
    end
  )
  from weighted;
$$;

create or replace function private.boss_available(
  p_user_id uuid,
  p_unit_id text
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_mastery double precision;
begin
  if not private.unit_gate_available(p_user_id, p_unit_id) then
    return false;
  end if;

  if exists (
    select 1
    from public.duo_levels level
    cross join public.duo_game_definitions game
    where level.unit_id = p_unit_id
      and game.is_required_for_boss = true
      and private.duo_game_supported(level.id, game.game_code)
      and not exists (
        select 1
        from public.duo_level_progress progress
        where progress.user_id = p_user_id
          and progress.game_id = game.id
          and progress.level_id = level.id
          and progress.is_completed = true
      )
  ) then
    return false;
  end if;

  v_mastery := coalesce(
    (private.unit_mastery_for_user(p_user_id, p_unit_id)
      ->> 'overall_mastery')::double precision,
    0
  );
  return v_mastery >= 0.70;
end;
$$;

create or replace function private.start_learning_attempt_v2_internal(
  p_attempt_id text,
  p_activity_type text,
  p_source_type text,
  p_source_id text,
  p_unit_id text,
  p_level_id text,
  p_metadata jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt_pk text;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if nullif(btrim(p_attempt_id), '') is null
     or nullif(btrim(p_activity_type), '') is null
     or nullif(btrim(p_source_type), '') is null
     or nullif(btrim(p_source_id), '') is null then
    raise exception 'Invalid learning attempt identity';
  end if;

  v_attempt_pk := v_user_id::text || ':' || p_attempt_id;
  insert into public.learning_attempts (
    id, user_id, activity_type, source_type, source_id,
    unit_id, level_id, status, metadata, started_at
  )
  values (
    v_attempt_pk, v_user_id, p_activity_type, p_source_type, p_source_id,
    p_unit_id, p_level_id, 'started', coalesce(p_metadata, '{}'::jsonb), now()
  )
  on conflict (id) do nothing;

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'status', (
      select status from public.learning_attempts where id = v_attempt_pk
    )
  );
end;
$$;

create or replace function public.start_learning_attempt_v2(
  p_attempt_id text,
  p_activity_type text,
  p_source_type text,
  p_source_id text,
  p_unit_id text,
  p_level_id text,
  p_metadata jsonb
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.start_learning_attempt_v2_internal(
    p_attempt_id,
    p_activity_type,
    p_source_type,
    p_source_id,
    p_unit_id,
    p_level_id,
    coalesce(p_metadata, '{}'::jsonb)
  );
$$;

create or replace function private.complete_learning_activity_v2_internal(
  p_activity_type text,
  p_source_type text,
  p_source_id text,
  p_unit_id text,
  p_level_id text,
  p_score double precision,
  p_correct_count integer,
  p_wrong_count integer,
  p_duration_seconds integer,
  p_best_combo integer,
  p_accuracy double precision,
  p_pronunciation double precision,
  p_tone double precision,
  p_fluency double precision,
  p_hanzi_score double precision,
  p_objective_completion double precision,
  p_boss_hp integer,
  p_player_hp integer,
  p_metadata jsonb,
  p_attempt_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt_pk text;
  v_event_key text;
  v_existing_result jsonb;
  v_activity_type text := lower(btrim(coalesce(p_activity_type, '')));
  v_source_type text := lower(btrim(coalesce(p_source_type, '')));
  v_source_id text := btrim(coalesce(p_source_id, ''));
  v_unit_id text := nullif(btrim(coalesce(p_unit_id, '')), '');
  v_level_id text := nullif(btrim(coalesce(p_level_id, '')), '');
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_game_id bigint;
  v_game_code text;
  v_stage_id bigint;
  v_character_id integer;
  v_word_id integer;
  v_example_id integer;
  v_total integer := greatest(coalesce(p_correct_count, 0), 0)
    + greatest(coalesce(p_wrong_count, 0), 0);
  v_correct integer := greatest(coalesce(p_correct_count, 0), 0);
  v_wrong integer := greatest(coalesce(p_wrong_count, 0), 0);
  v_duration integer := least(greatest(coalesce(p_duration_seconds, 0), 0), 86400);
  v_best_combo integer := least(greatest(coalesce(p_best_combo, 0), 0), 10000);
  v_accuracy double precision;
  v_score double precision;
  v_ratio double precision;
  v_overall double precision;
  v_passed boolean := false;
  v_perfect boolean := false;
  v_stars smallint := 0;
  v_first_clear boolean := false;
  v_attempt_number integer := 1;
  v_base_xp integer := 0;
  v_bonus_xp integer := 0;
  v_xp_earned integer := 0;
  v_reason text := 'accuracy_below_threshold';
  v_xp_reason text := 'practice_effort';
  v_difficulty integer := 1;
  v_mastery_before double precision := 0;
  v_mastery_after double precision := 0;
  v_mastery_payload jsonb := '{}'::jsonb;
  v_previous_hanzi_count integer := 0;
  v_previous_hanzi_best double precision := 0;
  v_hanzi_count integer := 0;
  v_hanzi_best double precision := 0;
  v_hanzi_mastered boolean := false;
  v_unlocked_next boolean := false;
  v_next_node_id text;
  v_current_streak integer := 0;
  v_total_exp integer := 0;
  v_eligible_streak boolean := false;
  v_today date := (timezone('Asia/Ho_Chi_Minh', now()))::date;
  v_result jsonb;
  v_candidate record;
  v_previous_unlocked boolean;
  v_next_unit_id text;
  v_boss_stage_id bigint;
  v_boss_player_hp integer := 100;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if v_activity_type not in (
    'vocabulary', 'listening', 'speaking', 'hanzi', 'dialogue',
    'boss', 'review', 'game_mission'
  ) then
    raise exception 'Unsupported activity type: %', v_activity_type;
  end if;
  if v_source_type = '' or v_source_id = ''
     or nullif(btrim(coalesce(p_attempt_id, '')), '') is null then
    raise exception 'Invalid learning completion identity';
  end if;

  v_attempt_pk := v_user_id::text || ':' || p_attempt_id;
  v_event_key := v_source_type || ':' || v_source_id || ':'
    || p_attempt_id || ':completion';

  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':' || v_event_key, 0));

  select event.metadata -> 'learning_result'
  into v_existing_result
  from public.learning_xp_events event
  where event.user_id = v_user_id
    and event.event_key = v_event_key;

  if v_existing_result is not null then
    return v_existing_result || jsonb_build_object('idempotent', true);
  end if;

  if v_source_type = 'duo_level' then
    begin
      v_game_id := nullif(v_metadata ->> 'game_id', '')::bigint;
    exception when invalid_text_representation then
      raise exception 'Invalid game id';
    end;
    if v_game_id is null or v_level_id is null then
      raise exception 'Duo completion requires game_id and level_id';
    end if;
    select level.unit_id, game.game_code
    into v_unit_id, v_game_code
    from public.duo_levels level
    join public.duo_game_definitions game on game.id = v_game_id
    where level.id = v_level_id;
    if v_unit_id is null
       or not private.duo_game_supported(v_level_id, v_game_code) then
      raise exception 'Learning node not found or has no supported content';
    end if;
    v_source_id := v_game_id::text || ':' || v_level_id;
    v_event_key := v_source_type || ':' || v_source_id || ':'
      || p_attempt_id || ':completion';
    if not private.learning_node_available(v_user_id, v_game_id, v_level_id) then
      raise exception 'Learning node is locked';
    end if;
  elsif v_source_type = 'boss_stage' then
    begin
      v_stage_id := v_source_id::bigint;
    exception when invalid_text_representation then
      raise exception 'Invalid boss stage id';
    end;
    select stage.unit_id, stage.difficulty, stage.player_hp
    into v_unit_id, v_difficulty, v_boss_player_hp
    from public.boss_stages stage
    where stage.id = v_stage_id and stage.active = true;
    if v_unit_id is null then
      raise exception 'Boss stage not found';
    end if;
    if not private.boss_available(v_user_id, v_unit_id)
       and not exists (
         select 1 from public.boss_stage_progress progress
         where progress.user_id = v_user_id
           and progress.stage_id = v_stage_id
           and progress.completed = true
       ) then
      raise exception 'Boss stage is locked';
    end if;
  elsif v_source_type = 'character' then
    begin
      v_character_id := v_source_id::integer;
    exception when invalid_text_representation then
      raise exception 'Invalid Hanzi character id';
    end;
    if not exists (
      select 1 from public.lexicon_characters character
      where character.id = v_character_id
    ) then
      raise exception 'Hanzi character not found';
    end if;
  end if;

  v_accuracy := least(greatest(
    coalesce(
      p_accuracy,
      case when v_total > 0 then v_correct::double precision / v_total else 0 end
    ),
    0
  ), 1);
  v_score := least(greatest(coalesce(p_score, v_accuracy * 100), 0), 1000000);
  v_ratio := v_accuracy;

  if v_activity_type = 'vocabulary' then
    v_passed := v_accuracy >= 0.70
      and v_total >= coalesce(nullif(v_metadata ->> 'required_questions', '')::integer, v_total);
    v_score := v_accuracy * 100;
    v_reason := case
      when v_total < coalesce(nullif(v_metadata ->> 'required_questions', '')::integer, v_total)
        then 'required_questions_incomplete'
      when v_passed then 'passed'
      else 'accuracy_below_threshold'
    end;
  elsif v_activity_type = 'listening' then
    v_passed := v_accuracy >= 0.70;
    v_score := v_accuracy * 100;
    v_reason := case when v_passed then 'passed' else 'accuracy_below_threshold' end;
  elsif v_activity_type = 'speaking' then
    v_overall := least(greatest(
      (v_accuracy * 100 * 0.35)
      + (coalesce(p_pronunciation, 0) * 0.30)
      + (coalesce(p_tone, 0) * 0.20)
      + (coalesce(p_fluency, 0) * 0.15),
      0
    ), 100);
    v_score := v_overall;
    v_ratio := v_overall / 100.0;
    v_passed := v_overall >= 65
      and coalesce(p_pronunciation, 0) >= 60
      and coalesce(p_tone, 0) >= 50;
    v_reason := case
      when coalesce(p_pronunciation, 0) < 60 then 'pronunciation_below_threshold'
      when coalesce(p_tone, 0) < 50 then 'tone_below_threshold'
      when v_overall < 65 then 'speaking_overall_below_threshold'
      else 'passed'
    end;
  elsif v_activity_type = 'hanzi' then
    v_score := least(greatest(coalesce(p_hanzi_score, p_score, 0), 0), 100);
    v_ratio := v_score / 100.0;
    v_passed := v_score >= 70;
    v_reason := case when v_passed then 'passed' else 'hanzi_score_below_threshold' end;
  elsif v_activity_type = 'dialogue' then
    v_ratio := least(greatest(coalesce(p_objective_completion, v_accuracy), 0), 1);
    v_score := v_ratio * 100;
    v_passed := v_ratio >= 0.70;
    v_reason := case when v_passed then 'passed' else 'objective_incomplete' end;
  elsif v_activity_type = 'boss' then
    v_passed := coalesce(p_boss_hp, 1) <= 0 and coalesce(p_player_hp, 0) > 0;
    v_ratio := case
      when v_total > 0 then v_accuracy
      else least(greatest(coalesce(p_player_hp, 0)::double precision
        / greatest(v_boss_player_hp, 1), 0), 1)
    end;
    v_reason := case when v_passed then 'boss_defeated' else 'boss_not_defeated' end;
  elsif v_activity_type = 'review' then
    v_passed := v_total > 0;
    v_score := v_accuracy * 100;
    v_reason := case when v_passed then 'review_completed' else 'review_incomplete' end;
  else
    v_passed := v_accuracy >= 0.70;
    v_score := v_accuracy * 100;
    v_reason := case when v_passed then 'passed' else 'accuracy_below_threshold' end;
  end if;

  if v_passed then
    if v_activity_type = 'boss' then
      v_stars := case
        when coalesce(p_player_hp, 0) >= v_boss_player_hp * 0.80 then 3
        when coalesce(p_player_hp, 0) >= v_boss_player_hp * 0.50 then 2
        else 1
      end;
    else
      v_stars := case
        when v_ratio >= 0.95 then 3
        when v_ratio >= 0.80 then 2
        else 1
      end;
    end if;
  end if;

  v_perfect := v_passed and case
    when v_activity_type = 'boss'
      then coalesce(p_boss_hp, 1) <= 0 and coalesce(p_player_hp, 0) >= v_boss_player_hp
    else v_ratio >= 1.0
  end;

  select
    not bool_or(attempt.status = 'passed'),
    count(*)::integer + case when bool_or(attempt.id = v_attempt_pk) then 0 else 1 end
  into v_first_clear, v_attempt_number
  from public.learning_attempts attempt
  where attempt.user_id = v_user_id
    and attempt.source_type = v_source_type
    and attempt.source_id = v_source_id;
  v_first_clear := coalesce(v_first_clear, true) and v_passed;
  v_attempt_number := greatest(coalesce(v_attempt_number, 1), 1);

  if v_unit_id is not null then
    v_mastery_payload := private.unit_mastery_for_user(v_user_id, v_unit_id);
    v_mastery_before := coalesce((v_mastery_payload ->> 'overall_mastery')::double precision, 0);
  elsif v_activity_type = 'hanzi' then
    select coalesce(progress.best_score, 0) / 100.0,
           coalesce(progress.practice_count, 0),
           coalesce(progress.best_score, 0)
    into v_mastery_before, v_previous_hanzi_count, v_previous_hanzi_best
    from public.lexicon_hanzi_progress progress
    where progress.user_id = v_user_id
      and progress.character_id = v_character_id;
    v_mastery_before := coalesce(v_mastery_before, 0);
  end if;

  if v_passed then
    v_base_xp := case v_activity_type
      when 'vocabulary' then 20
      when 'listening' then 25
      when 'speaking' then 30
      when 'hanzi' then 25
      when 'dialogue' then 30
      when 'boss' then 100
      when 'review' then 20
      else 30
    end;
    if v_perfect then v_bonus_xp := v_bonus_xp + 15; end if;
    if v_ratio >= 0.85 then v_bonus_xp := v_bonus_xp + 10; end if;
    v_bonus_xp := v_bonus_xp + least((v_best_combo / 5) * 5, 10);
    begin
      v_difficulty := greatest(coalesce(nullif(v_metadata ->> 'difficulty', '')::integer, v_difficulty), 1);
    exception when invalid_text_representation then
      v_difficulty := 1;
    end;
    v_bonus_xp := v_bonus_xp + least(greatest(v_difficulty - 1, 0) * 2, 10);
    if v_first_clear then
      v_bonus_xp := v_bonus_xp + case when v_activity_type = 'boss' then 50 else 20 end;
    else
      v_base_xp := least(v_base_xp, 15);
      v_bonus_xp := 0;
    end if;
    v_xp_earned := least(
      v_base_xp + v_bonus_xp,
      case when v_activity_type = 'boss' then 250 else 100 end
    );
    v_bonus_xp := v_xp_earned - v_base_xp;
    v_xp_reason := case
      when v_first_clear then 'first_clear'
      when v_perfect then 'perfect'
      else 'pass_completion'
    end;
  else
    v_base_xp := case
      when v_activity_type = 'boss'
        then least(greatest(100 - coalesce(p_boss_hp, 100), 0) / 10, 15)
      else 5
    end;
    v_bonus_xp := 0;
    v_xp_earned := v_base_xp;
    v_xp_reason := 'practice_effort';
  end if;

  insert into public.learning_attempts (
    id, user_id, activity_type, source_type, source_id, unit_id, level_id,
    status, score, accuracy, correct_count, wrong_count, stars, xp_earned,
    duration_seconds, best_combo, mastery_before, mastery_after, reason,
    first_clear, perfect, metadata, started_at, completed_at
  )
  values (
    v_attempt_pk, v_user_id, v_activity_type, v_source_type, v_source_id,
    v_unit_id, v_level_id, case when v_passed then 'passed' else 'failed' end,
    v_score, v_ratio, v_correct, v_wrong, v_stars, v_xp_earned,
    v_duration, v_best_combo, v_mastery_before, v_mastery_before, v_reason,
    v_first_clear, v_perfect, v_metadata,
    now() - make_interval(secs => v_duration), now()
  )
  on conflict (id) do update set
    activity_type = excluded.activity_type,
    source_type = excluded.source_type,
    source_id = excluded.source_id,
    unit_id = excluded.unit_id,
    level_id = excluded.level_id,
    status = excluded.status,
    score = excluded.score,
    accuracy = excluded.accuracy,
    correct_count = excluded.correct_count,
    wrong_count = excluded.wrong_count,
    stars = excluded.stars,
    xp_earned = excluded.xp_earned,
    duration_seconds = excluded.duration_seconds,
    best_combo = excluded.best_combo,
    mastery_before = excluded.mastery_before,
    reason = excluded.reason,
    first_clear = excluded.first_clear,
    perfect = excluded.perfect,
    metadata = excluded.metadata,
    completed_at = now();

  if v_source_type = 'duo_level' then
    insert into public.duo_level_progress (
      user_id, game_id, level_id, attempts, best_score, stars,
      is_unlocked, is_completed, last_played_at, completed_at, updated_at
    )
    values (
      v_user_id, v_game_id, v_level_id, 1, round(v_ratio * 100)::integer,
      v_stars, true, v_passed, now(),
      case when v_passed then now() else null end, now()
    )
    on conflict (user_id, game_id, level_id) do update set
      attempts = public.duo_level_progress.attempts + 1,
      best_score = greatest(public.duo_level_progress.best_score, excluded.best_score),
      stars = greatest(public.duo_level_progress.stars, excluded.stars),
      is_unlocked = true,
      is_completed = public.duo_level_progress.is_completed or excluded.is_completed,
      last_played_at = now(),
      completed_at = coalesce(
        public.duo_level_progress.completed_at,
        excluded.completed_at
      ),
      updated_at = now();

    delete from public.duo_active_sessions session
    where session.user_id = v_user_id
      and session.game_id = v_game_id
      and session.level_id = v_level_id;
  end if;

  if v_activity_type = 'listening'
     and nullif(v_metadata ->> 'word_id', '') is not null then
    begin
      v_word_id := (v_metadata ->> 'word_id')::integer;
      insert into public.lexicon_user_progress (
        user_id, word_id, listening_score, updated_at
      )
      values (v_user_id, v_word_id, v_ratio * 100, now())
      on conflict (user_id, word_id) do update set
        listening_score = case
          when public.lexicon_user_progress.listening_score is null
            then excluded.listening_score
          else public.lexicon_user_progress.listening_score * 0.70
            + excluded.listening_score * 0.30
        end,
        updated_at = now();
    exception when invalid_text_representation or foreign_key_violation then
      v_word_id := null;
    end;
  end if;

  if v_activity_type = 'speaking' then
    begin
      v_word_id := nullif(v_metadata ->> 'word_id', '')::integer;
      v_example_id := nullif(v_metadata ->> 'example_id', '')::integer;
    exception when invalid_text_representation then
      v_word_id := null;
      v_example_id := null;
    end;
    insert into public.lexicon_speaking_practice (
      user_id, word_id, example_id, target_text, recognized_text,
      accuracy_score, pronunciation_score, tone_score, fluency_score
    )
    values (
      v_user_id, v_word_id, v_example_id,
      coalesce(nullif(v_metadata ->> 'target_text', ''), v_source_id),
      nullif(v_metadata ->> 'recognized_text', ''),
      v_accuracy * 100, p_pronunciation, p_tone, p_fluency
    );

    if v_word_id is not null then
      insert into public.lexicon_user_progress (
        user_id, word_id, pronunciation_score, updated_at
      )
      values (v_user_id, v_word_id, coalesce(p_pronunciation, 0), now())
      on conflict (user_id, word_id) do update set
        pronunciation_score = case
          when public.lexicon_user_progress.pronunciation_score is null
            then excluded.pronunciation_score
          else public.lexicon_user_progress.pronunciation_score * 0.70
            + excluded.pronunciation_score * 0.30
        end,
        updated_at = now();
    end if;
  end if;

  if v_activity_type = 'hanzi' then
    v_hanzi_count := v_previous_hanzi_count
      + least(greatest(coalesce(nullif(v_metadata ->> 'practice_attempts', '')::integer, 1), 1), 100);
    v_hanzi_best := greatest(v_previous_hanzi_best, v_score);
    v_hanzi_mastered := v_hanzi_best >= 85 and v_hanzi_count >= 3;
    insert into public.lexicon_hanzi_progress (
      user_id, character_id, practice_count, best_score, last_score,
      last_practice_at, next_review_at, updated_at
    )
    values (
      v_user_id, v_character_id,
      least(greatest(coalesce(nullif(v_metadata ->> 'practice_attempts', '')::integer, 1), 1), 100),
      v_score, v_score, now(),
      now() + case
        when v_hanzi_mastered then interval '7 days'
        when v_passed then interval '2 days'
        else interval '1 day'
      end,
      now()
    )
    on conflict (user_id, character_id) do update set
      practice_count = v_hanzi_count,
      best_score = v_hanzi_best,
      last_score = excluded.last_score,
      last_practice_at = now(),
      next_review_at = excluded.next_review_at,
      updated_at = now();
    if v_unit_id is null then
      v_mastery_after := least(greatest(v_hanzi_best / 100.0, 0), 1);
    end if;
  end if;

  if v_activity_type = 'boss' and v_stage_id is not null then
    insert into public.boss_stage_progress (
      user_id, stage_id, completed, stars, best_score, best_combo,
      attempts, last_played_at, updated_at
    )
    values (
      v_user_id, v_stage_id, v_passed, v_stars,
      round(v_score)::integer, v_best_combo, 1, now(), now()
    )
    on conflict (user_id, stage_id) do update set
      completed = public.boss_stage_progress.completed or excluded.completed,
      stars = greatest(public.boss_stage_progress.stars, excluded.stars),
      best_score = greatest(public.boss_stage_progress.best_score, excluded.best_score),
      best_combo = greatest(public.boss_stage_progress.best_combo, excluded.best_combo),
      attempts = public.boss_stage_progress.attempts + 1,
      last_played_at = now(),
      updated_at = now();
  end if;

  if v_unit_id is not null then
    v_mastery_payload := private.unit_mastery_for_user(v_user_id, v_unit_id);
    v_mastery_after := coalesce((v_mastery_payload ->> 'overall_mastery')::double precision, 0);
  elsif v_activity_type <> 'hanzi' then
    v_mastery_after := v_mastery_before;
  end if;

  update public.learning_attempts
  set mastery_after = least(greatest(v_mastery_after, 0), 1)
  where id = v_attempt_pk and user_id = v_user_id;

  if v_passed and v_source_type = 'duo_level' then
    for v_candidate in
      select game.id as game_id, game.game_code, game.game_order
      from public.duo_game_definitions game
      where private.duo_game_supported(v_level_id, game.game_code)
        and private.learning_node_available(v_user_id, game.id, v_level_id)
      order by game.game_order, game.id
    loop
      select progress.is_unlocked
      into v_previous_unlocked
      from public.duo_level_progress progress
      where progress.user_id = v_user_id
        and progress.game_id = v_candidate.game_id
        and progress.level_id = v_level_id;

      insert into public.duo_level_progress (
        user_id, game_id, level_id, is_unlocked, updated_at
      )
      values (v_user_id, v_candidate.game_id, v_level_id, true, now())
      on conflict (user_id, game_id, level_id) do update set
        is_unlocked = true,
        updated_at = now();

      if coalesce(v_previous_unlocked, false) = false
         and v_candidate.game_id <> v_game_id
         and v_next_node_id is null then
        v_unlocked_next := true;
        v_next_node_id := v_candidate.game_id::text || ':' || v_level_id;
      end if;
    end loop;

    if private.boss_available(v_user_id, v_unit_id) then
      select stage.id into v_boss_stage_id
      from public.boss_stages stage
      where stage.unit_id = v_unit_id and stage.active = true
      order by stage.stage_order
      limit 1;
      if v_boss_stage_id is not null then
        v_unlocked_next := true;
        v_next_node_id := 'boss:' || v_boss_stage_id::text;
      end if;
    end if;
  end if;

  if v_passed and v_activity_type = 'boss' and v_source_type = 'boss_stage' then
    select next_unit.id
    into v_next_unit_id
    from public.duo_units current_unit
    join public.duo_sections current_section on current_section.id = current_unit.section_id
    join public.duo_units next_unit on true
    join public.duo_sections next_section on next_section.id = next_unit.section_id
    where current_unit.id = v_unit_id
      and (
        next_section.section_number > current_section.section_number
        or (
          next_section.section_number = current_section.section_number
          and next_unit.unit_number > current_unit.unit_number
        )
      )
    order by next_section.section_number, next_unit.unit_number, next_unit.unit_index
    limit 1;

    if v_next_unit_id is not null then
      select game.id, level.id
      into v_game_id, v_level_id
      from public.duo_levels level
      cross join public.duo_game_definitions game
      where level.unit_id = v_next_unit_id
        and cardinality(game.prerequisite_game_codes) = 0
        and private.duo_game_supported(level.id, game.game_code)
      order by level.level_index, game.game_order, game.id
      limit 1;

      if v_game_id is not null and v_level_id is not null then
        insert into public.duo_level_progress (
          user_id, game_id, level_id, is_unlocked, updated_at
        )
        values (v_user_id, v_game_id, v_level_id, true, now())
        on conflict (user_id, game_id, level_id) do update set
          is_unlocked = true,
          updated_at = now();
        v_unlocked_next := true;
        v_next_node_id := v_game_id::text || ':' || v_level_id;
      end if;
    end if;
  end if;

  v_eligible_streak := v_passed and v_activity_type in (
    'vocabulary', 'listening', 'speaking', 'hanzi', 'dialogue',
    'boss', 'review', 'game_mission'
  );

  insert into public.app_user_stats (
    user_id, total_exp, current_streak, last_study_date,
    total_words_mastered, total_favorites, total_lessons_completed,
    total_bosses_defeated, total_speaking_attempts, total_hanzi_practices,
    total_minutes_studied, highest_combo, updated_at
  )
  values (
    v_user_id, v_xp_earned, case when v_eligible_streak then 1 else 0 end, now(),
    0, 0,
    case when v_first_clear and v_activity_type not in ('boss', 'review') then 1 else 0 end,
    case when v_first_clear and v_activity_type = 'boss'
      and v_source_type = 'boss_stage' then 1 else 0 end,
    case when v_activity_type = 'speaking' then 1 else 0 end,
    case when v_activity_type = 'hanzi' then 1 else 0 end,
    floor(v_duration / 60.0)::integer,
    v_best_combo,
    now()
  )
  on conflict (user_id) do update set
    total_exp = public.app_user_stats.total_exp + v_xp_earned,
    current_streak = case
      when not v_eligible_streak then public.app_user_stats.current_streak
      when (timezone('Asia/Ho_Chi_Minh', public.app_user_stats.last_study_date))::date = v_today
        then greatest(public.app_user_stats.current_streak, 1)
      when (timezone('Asia/Ho_Chi_Minh', public.app_user_stats.last_study_date))::date = v_today - 1
        then public.app_user_stats.current_streak + 1
      else 1
    end,
    last_study_date = case
      when v_eligible_streak then now()
      else public.app_user_stats.last_study_date
    end,
    total_lessons_completed = coalesce(public.app_user_stats.total_lessons_completed, 0)
      + case when v_first_clear and v_activity_type not in ('boss', 'review') then 1 else 0 end,
    total_bosses_defeated = coalesce(public.app_user_stats.total_bosses_defeated, 0)
      + case when v_first_clear and v_activity_type = 'boss'
        and v_source_type = 'boss_stage' then 1 else 0 end,
    total_speaking_attempts = coalesce(public.app_user_stats.total_speaking_attempts, 0)
      + case when v_activity_type = 'speaking' then 1 else 0 end,
    total_hanzi_practices = coalesce(public.app_user_stats.total_hanzi_practices, 0)
      + case when v_activity_type = 'hanzi' then 1 else 0 end,
    total_minutes_studied = coalesce(public.app_user_stats.total_minutes_studied, 0)
      + floor(v_duration / 60.0)::integer,
    highest_combo = greatest(coalesce(public.app_user_stats.highest_combo, 0), v_best_combo),
    updated_at = now()
  returning total_exp, current_streak into v_total_exp, v_current_streak;

  v_result := jsonb_build_object(
    'activity_type', v_activity_type,
    'source_id', v_source_id,
    'attempt_id', p_attempt_id,
    'passed', v_passed,
    'failed', not v_passed,
    'score', v_score,
    'accuracy', v_ratio,
    'stars', v_stars,
    'xp_earned', v_xp_earned,
    'base_xp', v_base_xp,
    'bonus_xp', v_bonus_xp,
    'mastery_before', least(greatest(v_mastery_before, 0), 1),
    'mastery_after', least(greatest(v_mastery_after, 0), 1),
    'best_combo', v_best_combo,
    'first_clear', v_first_clear,
    'perfect', v_perfect,
    'attempt_number', v_attempt_number,
    'unlocked_next', v_unlocked_next,
    'next_node_id', v_next_node_id,
    'reason', v_reason,
    'new_total_xp', v_total_exp,
    'current_streak', v_current_streak,
    'correct_count', v_correct,
    'wrong_count', v_wrong,
    'idempotent', false,
    'metadata', v_metadata || jsonb_build_object(
      'xp_reason', v_xp_reason,
      'hanzi_mastered', v_hanzi_mastered,
      'unit_mastery', v_mastery_payload
    )
  );

  insert into public.learning_xp_events (
    user_id, event_key, idempotency_key, attempt_id,
    source_type, source_id, activity_type,
    xp_amount, base_xp, bonus_xp, reason,
    score, accuracy, stars, metadata, created_at
  )
  values (
    v_user_id, v_event_key, v_event_key, p_attempt_id,
    v_source_type, v_source_id, v_activity_type,
    v_xp_earned, v_base_xp, v_bonus_xp, v_xp_reason,
    v_score, v_ratio, v_stars,
    v_metadata || jsonb_build_object('learning_result', v_result),
    now()
  );

  return v_result;
end;
$$;

create or replace function public.complete_learning_activity_v2(
  p_activity_type text,
  p_source_type text,
  p_source_id text,
  p_unit_id text,
  p_level_id text,
  p_score double precision,
  p_correct_count integer,
  p_wrong_count integer,
  p_duration_seconds integer,
  p_best_combo integer,
  p_accuracy double precision,
  p_pronunciation double precision,
  p_tone double precision,
  p_fluency double precision,
  p_hanzi_score double precision,
  p_objective_completion double precision,
  p_boss_hp integer,
  p_player_hp integer,
  p_metadata jsonb,
  p_attempt_id text
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.complete_learning_activity_v2_internal(
    p_activity_type, p_source_type, p_source_id, p_unit_id, p_level_id,
    p_score, p_correct_count, p_wrong_count, p_duration_seconds, p_best_combo,
    p_accuracy, p_pronunciation, p_tone, p_fluency, p_hanzi_score,
    p_objective_completion, p_boss_hp, p_player_hp, p_metadata, p_attempt_id
  );
$$;

create or replace function public.unit_mastery_v2(p_unit_id text)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select private.unit_mastery_for_user(auth.uid(), p_unit_id);
$$;

create or replace function public.unit_learning_path_v2(p_unit_id text)
returns table (
  node_type text,
  node_order integer,
  unit_id text,
  unit_title text,
  section_number integer,
  unit_number integer,
  level_id text,
  level_index integer,
  game_id bigint,
  game_code text,
  game_name text,
  game_description text,
  game_icon text,
  challenge_count bigint,
  attempts integer,
  best_score integer,
  stars integer,
  is_unlocked boolean,
  is_completed boolean,
  in_progress boolean,
  current_index integer,
  current_total integer,
  boss_stage_id bigint,
  boss_name text,
  boss_hp integer,
  player_hp integer,
  difficulty integer,
  lock_reason text,
  required_node_id text,
  required_mastery double precision,
  overall_mastery double precision
)
language sql
stable
security definer
set search_path = ''
as $$
  with learning as (
    select
      unit.id as unit_id,
      unit.title as unit_title,
      section.section_number,
      unit.unit_number,
      level.id as level_id,
      level.level_index,
      game.id as game_id,
      game.game_code,
      game.name_vi as game_name,
      coalesce(game.description_vi, '') as game_description,
      coalesce(game.icon, '🎯') as game_icon,
      game.game_order,
      game.prerequisite_game_codes,
      count(challenge.id)::bigint as challenge_count
    from public.duo_units unit
    join public.duo_sections section on section.id = unit.section_id
    join public.duo_levels level on level.unit_id = unit.id
    cross join public.duo_game_definitions game
    left join public.duo_sessions session on session.level_id = level.id
    left join public.duo_challenges challenge
      on challenge.session_id = session.id
     and (
       (game.game_code = 'learn_words' and challenge.type in ('select', 'assist', 'match'))
       or (game.game_code = 'select_answer' and challenge.type in ('select', 'assist'))
       or (game.game_code in ('word_connect', 'match_pairs') and challenge.type = 'match')
       or (game.game_code = 'listen_select' and challenge.type = 'listenTap')
       or (game.game_code = 'translate' and challenge.type = 'translate')
       or (game.game_code = 'gap_fill' and challenge.type = 'gapFill')
       or (game.game_code = 'tap_complete' and challenge.type = 'tapComplete')
       or (game.game_code = 'dialogue' and challenge.type = 'dialogue')
       or (game.game_code = 'sentence_order' and challenge.type = 'orderTapComplete')
       or (game.game_code = 'speaking' and challenge.type = 'speaking')
     )
    where unit.id = p_unit_id
    group by
      unit.id, unit.title, section.section_number, unit.unit_number,
      level.id, level.level_index, game.id, game.game_code, game.name_vi,
      game.description_vi, game.icon, game.game_order,
      game.prerequisite_game_codes
    having count(challenge.id) > 0
  ), ordered as (
    select learning.*,
      row_number() over (
        order by learning.level_index, learning.game_order, learning.game_id
      )::integer as node_order
    from learning
  ), mastery as (
    select private.unit_mastery_for_user(auth.uid(), p_unit_id) as value
  ), learning_state as (
    select
      'learning'::text as node_type,
      ordered.node_order,
      ordered.unit_id,
      ordered.unit_title,
      ordered.section_number,
      ordered.unit_number,
      ordered.level_id,
      ordered.level_index,
      ordered.game_id,
      ordered.game_code,
      ordered.game_name,
      ordered.game_description,
      ordered.game_icon,
      ordered.challenge_count,
      coalesce(progress.attempts, 0)::integer as attempts,
      coalesce(progress.best_score, 0)::integer as best_score,
      coalesce(progress.stars, 0)::integer as stars,
      private.learning_node_available(
        auth.uid(), ordered.game_id, ordered.level_id
      ) as is_unlocked,
      coalesce(progress.is_completed, false) as is_completed,
      coalesce(active.status = 'active', false) as in_progress,
      coalesce(active.current_index, 0)::integer as current_index,
      ordered.challenge_count::integer as current_total,
      null::bigint as boss_stage_id,
      null::text as boss_name,
      null::integer as boss_hp,
      null::integer as player_hp,
      null::integer as difficulty,
      case
        when private.learning_node_available(auth.uid(), ordered.game_id, ordered.level_id)
          then null
        when not private.unit_gate_available(auth.uid(), ordered.unit_id)
          then 'chapter_locked'
        else 'complete_previous'
      end::text as lock_reason,
      (
        select prerequisite_game.id::text || ':' || ordered.level_id
        from unnest(ordered.prerequisite_game_codes) prerequisite(code)
        join public.duo_game_definitions prerequisite_game
          on prerequisite_game.game_code = prerequisite.code
        where private.duo_game_supported(ordered.level_id, prerequisite.code)
          and not exists (
            select 1 from public.duo_level_progress required_progress
            where required_progress.user_id = auth.uid()
              and required_progress.game_id = prerequisite_game.id
              and required_progress.level_id = ordered.level_id
              and required_progress.is_completed = true
          )
        order by prerequisite_game.game_order
        limit 1
      )::text as required_node_id,
      null::double precision as required_mastery,
      coalesce((mastery.value ->> 'overall_mastery')::double precision, 0)
        as overall_mastery
    from ordered
    cross join mastery
    left join public.duo_level_progress progress
      on progress.user_id = auth.uid()
     and progress.game_id = ordered.game_id
     and progress.level_id = ordered.level_id
    left join public.duo_active_sessions active
      on active.user_id = auth.uid()
     and active.game_id = ordered.game_id
     and active.level_id = ordered.level_id
     and active.status = 'active'
  ), boss as (
    select
      'boss'::text as node_type,
      (coalesce((select max(node_order) from ordered), 0) + 1)::integer as node_order,
      stage.unit_id,
      unit.title as unit_title,
      stage.section_number,
      stage.unit_number,
      null::text as level_id,
      null::integer as level_index,
      null::bigint as game_id,
      'boss_battle'::text as game_code,
      stage.title as game_name,
      ('Đánh bại ' || stage.boss_name || ' để hoàn thành chương')::text
        as game_description,
      '🐉'::text as game_icon,
      stage.question_count::bigint as challenge_count,
      coalesce(progress.attempts, 0)::integer as attempts,
      coalesce(progress.best_score, 0)::integer as best_score,
      coalesce(progress.stars, 0)::integer as stars,
      private.boss_available(auth.uid(), stage.unit_id) as is_unlocked,
      coalesce(progress.completed, false) as is_completed,
      false as in_progress,
      0::integer as current_index,
      stage.question_count::integer as current_total,
      stage.id as boss_stage_id,
      stage.boss_name,
      stage.boss_hp,
      stage.player_hp,
      stage.difficulty::integer,
      case
        when private.boss_available(auth.uid(), stage.unit_id) then null
        when not private.unit_gate_available(auth.uid(), stage.unit_id)
          then 'chapter_locked'
        when exists (select 1 from learning_state state where not state.is_completed)
          then 'complete_previous'
        else 'mastery_too_low'
      end::text as lock_reason,
      (
        select state.game_id::text || ':' || state.level_id
        from learning_state state
        where not state.is_completed
        order by state.node_order
        limit 1
      )::text as required_node_id,
      0.70::double precision as required_mastery,
      coalesce((mastery.value ->> 'overall_mastery')::double precision, 0)
        as overall_mastery
    from public.boss_stages stage
    join public.duo_units unit on unit.id = stage.unit_id
    cross join mastery
    left join public.boss_stage_progress progress
      on progress.user_id = auth.uid()
     and progress.stage_id = stage.id
    where stage.unit_id = p_unit_id and stage.active = true
  )
  select * from learning_state
  union all
  select * from boss
  order by node_order;
$$;

create or replace function public.merge_guest_duo_progress_v2(
  p_progress jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_row jsonb;
  v_game_id bigint;
  v_level_id text;
  v_merged integer := 0;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if p_progress is null or jsonb_typeof(p_progress) <> 'array' then
    raise exception 'Guest progress must be a JSON array';
  end if;
  if jsonb_array_length(p_progress) > 500 then
    raise exception 'Guest progress payload is too large';
  end if;

  for v_row in select value from jsonb_array_elements(p_progress)
  loop
    begin
      v_game_id := nullif(v_row ->> 'game_id', '')::bigint;
      v_level_id := nullif(v_row ->> 'level_id', '');
    exception when invalid_text_representation then
      continue;
    end;
    if v_game_id is null or v_level_id is null or not exists (
      select 1
      from public.duo_game_definitions game
      join public.duo_levels level on level.id = v_level_id
      where game.id = v_game_id
        and private.duo_game_supported(level.id, game.game_code)
    ) then
      continue;
    end if;

    insert into public.duo_level_progress (
      user_id, game_id, level_id, attempts, best_score, stars,
      is_unlocked, is_completed, last_played_at, completed_at, updated_at
    )
    values (
      v_user_id,
      v_game_id,
      v_level_id,
      least(greatest(coalesce((v_row ->> 'attempts')::integer, 0), 0), 10000),
      least(greatest(coalesce((v_row ->> 'best_score')::integer, 0), 0), 100),
      least(greatest(coalesce((v_row ->> 'stars')::smallint, 0), 0), 3),
      coalesce((v_row ->> 'is_unlocked')::boolean, false),
      coalesce((v_row ->> 'is_completed')::boolean, false),
      now(),
      case when coalesce((v_row ->> 'is_completed')::boolean, false)
        then now() else null end,
      now()
    )
    on conflict (user_id, game_id, level_id) do update set
      attempts = greatest(
        public.duo_level_progress.attempts,
        excluded.attempts
      ),
      best_score = greatest(
        public.duo_level_progress.best_score,
        excluded.best_score
      ),
      stars = greatest(public.duo_level_progress.stars, excluded.stars),
      is_unlocked = public.duo_level_progress.is_unlocked
        or excluded.is_unlocked,
      is_completed = public.duo_level_progress.is_completed
        or excluded.is_completed,
      last_played_at = greatest(
        public.duo_level_progress.last_played_at,
        excluded.last_played_at
      ),
      completed_at = coalesce(
        public.duo_level_progress.completed_at,
        excluded.completed_at
      ),
      updated_at = now();
    v_merged := v_merged + 1;
  end loop;

  return jsonb_build_object('merged', v_merged);
end;
$$;

-- Protected learning state is readable by its owner, but authoritative writes
-- are only performed by the narrow completion RPC above.
revoke insert, update, delete, truncate on table public.learning_xp_events
  from anon, authenticated;
revoke insert, update, delete, truncate on table public.learning_attempts
  from anon, authenticated;
revoke insert, update, delete, truncate on table public.app_user_stats
  from anon, authenticated;
revoke insert, update, delete, truncate on table public.duo_level_progress
  from anon, authenticated;
revoke insert, update, delete, truncate on table public.boss_stage_progress
  from anon, authenticated;
revoke insert, update, delete, truncate on table public.lexicon_speaking_practice
  from anon, authenticated;
revoke insert, update, delete, truncate on table public.lexicon_hanzi_progress
  from anon, authenticated;

grant select on table public.learning_xp_events to authenticated;
grant select on table public.learning_attempts to authenticated;
grant select on table public.app_user_stats to authenticated;
grant select on table public.duo_level_progress to authenticated;
grant select on table public.boss_stage_progress to authenticated;
grant select on table public.lexicon_speaking_practice to authenticated;
grant select on table public.lexicon_hanzi_progress to authenticated;

revoke execute on function public.record_learning_reward(
  text, text, text, text, double precision, double precision,
  integer, integer, smallint, boolean, integer, integer, text, jsonb
) from public, anon, authenticated;
revoke execute on function public.record_duo_level_progress(
  bigint, text, integer, smallint, boolean
) from public, anon, authenticated;
revoke execute on function public.unlock_duo_level(bigint, text)
  from public, anon, authenticated;
revoke execute on function public.record_boss_progress(
  bigint, integer, smallint, integer, boolean
) from public, anon, authenticated;
revoke execute on function public.record_hanzi_progress(
  integer, double precision, integer
) from public, anon, authenticated;
revoke execute on function public.record_word_progress(integer, boolean, integer)
  from public, anon;
grant execute on function public.record_word_progress(integer, boolean, integer)
  to authenticated;

revoke all on function private.start_learning_attempt_v2_internal(
  text, text, text, text, text, text, jsonb
) from public, anon;
revoke all on function private.complete_learning_activity_v2_internal(
  text, text, text, text, text, double precision, integer, integer, integer,
  integer, double precision, double precision, double precision,
  double precision, double precision, double precision, integer, integer,
  jsonb, text
) from public, anon;

grant usage on schema private to authenticated;
grant execute on function private.start_learning_attempt_v2_internal(
  text, text, text, text, text, text, jsonb
) to authenticated;
grant execute on function private.complete_learning_activity_v2_internal(
  text, text, text, text, text, double precision, integer, integer, integer,
  integer, double precision, double precision, double precision,
  double precision, double precision, double precision, integer, integer,
  jsonb, text
) to authenticated;

revoke execute on function public.start_learning_attempt_v2(
  text, text, text, text, text, text, jsonb
) from public, anon;
grant execute on function public.start_learning_attempt_v2(
  text, text, text, text, text, text, jsonb
) to authenticated;

revoke execute on function public.complete_learning_activity_v2(
  text, text, text, text, text, double precision, integer, integer, integer,
  integer, double precision, double precision, double precision,
  double precision, double precision, double precision, integer, integer,
  jsonb, text
) from public, anon;
grant execute on function public.complete_learning_activity_v2(
  text, text, text, text, text, double precision, integer, integer, integer,
  integer, double precision, double precision, double precision,
  double precision, double precision, double precision, integer, integer,
  jsonb, text
) to authenticated;

revoke execute on function public.unit_mastery_v2(text) from public, anon;
grant execute on function public.unit_mastery_v2(text) to authenticated;
revoke execute on function public.unit_learning_path_v2(text) from public, anon;
grant execute on function public.unit_learning_path_v2(text)
  to anon, authenticated;
revoke execute on function public.merge_guest_duo_progress_v2(jsonb)
  from public, anon;
grant execute on function public.merge_guest_duo_progress_v2(jsonb)
  to authenticated;
