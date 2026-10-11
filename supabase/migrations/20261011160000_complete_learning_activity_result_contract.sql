-- ============================================================================
-- Migration: 20261011160000_complete_learning_activity_result_contract.sql
-- Description: Explicitly include boss_ready, unit_completed, and next_unit_id
-- in the return payload of private.complete_learning_activity_v2_internal
-- to establish a rock-solid, server-authoritative contract with Flutter.
-- ============================================================================

create or replace function private.complete_learning_activity_v2_internal(
  p_user_id uuid,
  p_activity_type text,
  p_source_type text,
  p_source_id text,
  p_unit_id text,
  p_level_id text,
  p_score double precision,
  p_accuracy double precision,
  p_correct_count integer,
  p_wrong_count integer,
  p_duration_seconds integer,
  p_best_combo integer,
  p_attempt_id text,
  p_pronunciation double precision,
  p_tone double precision,
  p_fluency double precision,
  p_hanzi_score double precision,
  p_objective_completion double precision,
  p_boss_hp integer,
  p_player_hp integer,
  p_metadata jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := p_user_id;
  v_activity_type text := lower(btrim(coalesce(p_activity_type, '')));
  v_source_type text := lower(btrim(coalesce(p_source_type, '')));
  v_source_id text := btrim(coalesce(p_source_id, ''));
  v_unit_id text := nullif(btrim(coalesce(p_unit_id, '')), '');
  v_level_id text := nullif(btrim(coalesce(p_level_id, '')), '');
  v_score double precision := coalesce(p_score, 0);
  v_ratio double precision := coalesce(p_accuracy, 0);
  v_correct integer := greatest(coalesce(p_correct_count, 0), 0);
  v_wrong integer := greatest(coalesce(p_wrong_count, 0), 0);
  v_duration integer := greatest(coalesce(p_duration_seconds, 0), 0);
  v_best_combo integer := greatest(coalesce(p_best_combo, 0), 0);
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_attempt_pk text;
  v_event_key text;
  v_existing_result jsonb;
  v_game_id bigint;
  v_game_code text;
  v_unit_row record;
  v_level_row record;
  v_passed boolean := false;
  v_stars integer := 0;
  v_base_xp integer := 0;
  v_bonus_xp integer := 0;
  v_xp_earned integer := 0;
  v_xp_reason text := 'activity_passed';
  v_first_clear boolean := false;
  v_perfect boolean := false;
  v_attempt_number integer := 1;
  v_mastery_before double precision := 0;
  v_mastery_after double precision := 0;
  v_mastery_payload jsonb := '{}'::jsonb;
  v_reason text := '';
  v_character_id bigint;
  v_hanzi_attempts integer := 1;
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
  v_boss_ready boolean := false;
  v_unit_completed boolean := false;
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
    if v_game_id is null and strpos(v_source_id, ':') > 0 then
      begin
        v_game_id := split_part(v_source_id, ':', 1)::bigint;
      exception when invalid_text_representation then
        v_game_id := null;
      end;
    end if;
    if v_level_id is null and strpos(v_source_id, ':') > 0 then
      v_level_id := split_part(v_source_id, ':', 2);
    end if;

    select * into v_level_row
    from public.duo_levels
    where id = v_level_id;
    if v_level_row.id is not null then
      v_unit_id := coalesce(v_unit_id, v_level_row.unit_id);
    end if;

    select * into v_candidate
    from public.duo_game_definitions
    where id = v_game_id;
    if v_candidate.id is not null then
      v_game_code := v_candidate.game_code;
    end if;
  end if;

  if v_unit_id is not null then
    select * into v_unit_row
    from public.duo_units
    where id = v_unit_id;
  end if;

  if v_ratio <= 0 and (v_correct + v_wrong) > 0 then
    v_ratio := (v_correct::double precision) / ((v_correct + v_wrong)::double precision);
  end if;
  if v_score <= 0 and v_ratio > 0 then
    v_score := round(v_ratio * 100);
  end if;

  if v_unit_id is not null then
    v_mastery_before := coalesce(
      (private.unit_mastery_for_user(v_user_id, v_unit_id) ->> 'overall_mastery')::double precision,
      0
    );
  end if;

  select count(*) + 1 into v_attempt_number
  from public.learning_attempts
  where user_id = v_user_id
    and source_type = v_source_type
    and source_id = v_source_id
    and status in ('passed', 'completed');

  v_first_clear := not exists (
    select 1
    from public.learning_attempts
    where user_id = v_user_id
      and source_type = v_source_type
      and source_id = v_source_id
      and status in ('passed', 'completed')
  );

  case v_activity_type
    when 'vocabulary' then
      v_passed := v_ratio >= 0.70;
      if not v_passed then
        v_reason := 'accuracy_below_threshold';
      end if;
    when 'listening' then
      v_passed := v_ratio >= 0.70;
      if not v_passed then
        v_reason := 'accuracy_below_threshold';
      end if;
    when 'speaking' then
      v_passed := v_score >= 70
        and coalesce(p_pronunciation, 0) >= 60
        and coalesce(p_tone, 0) >= 50;
      if not v_passed then
        if coalesce(p_pronunciation, 0) < 60 then
          v_reason := 'speaking_pronunciation_below_minimum';
        elsif coalesce(p_tone, 0) < 50 then
          v_reason := 'speaking_tone_below_minimum';
        else
          v_reason := 'score_below_threshold';
        end if;
      end if;
    when 'hanzi' then
      begin
        v_character_id := nullif(v_metadata ->> 'character_id', '')::bigint;
      exception when invalid_text_representation then
        v_character_id := null;
      end;
      v_passed := coalesce(p_hanzi_score, v_score) >= 70;
      v_hanzi_mastered := coalesce(p_hanzi_score, v_score) >= 85;
      if not v_passed then
        v_reason := 'hanzi_score_below_threshold';
      end if;
    when 'dialogue' then
      v_passed := coalesce(p_objective_completion, v_ratio) >= 0.70;
      if not v_passed then
        v_reason := 'objectives_incomplete';
      end if;
    when 'review' then
      v_passed := v_ratio >= 0.70;
      if not v_passed then
        v_reason := 'accuracy_below_threshold';
      end if;
    when 'boss' then
      v_passed := coalesce(p_boss_hp, 0) <= 0 and coalesce(p_player_hp, 1) > 0;
      if not v_passed then
        v_reason := 'boss_not_defeated';
      end if;
    else
      v_passed := v_score >= 70 or v_ratio >= 0.70;
      if not v_passed then
        v_reason := 'failed';
      end if;
  end case;

  if v_passed then
    if v_ratio >= 0.95 or v_score >= 95 then
      v_stars := 3;
      v_perfect := true;
    elsif v_ratio >= 0.80 or v_score >= 80 then
      v_stars := 2;
    else
      v_stars := 1;
    end if;

    case v_activity_type
      when 'vocabulary' then v_base_xp := 20;
      when 'listening' then v_base_xp := 20;
      when 'speaking' then v_base_xp := 25;
      when 'hanzi' then v_base_xp := 15;
      when 'dialogue' then v_base_xp := 30;
      when 'boss' then v_base_xp := 100;
      when 'review' then v_base_xp := 15;
      else v_base_xp := 20;
    end case;

    if v_first_clear then
      v_bonus_xp := v_bonus_xp + 10;
      v_xp_reason := 'first_clear_bonus';
    end if;
    if v_perfect then
      v_bonus_xp := v_bonus_xp + 5;
      v_xp_reason := case when v_first_clear then 'first_clear_and_perfect' else 'perfect_score_bonus' end;
    end if;
    if v_best_combo >= 5 then
      v_bonus_xp := v_bonus_xp + least(v_best_combo, 10);
    end if;

    v_xp_earned := v_base_xp + v_bonus_xp;
  else
    v_stars := 0;
    v_base_xp := 0;
    v_bonus_xp := 0;
    v_xp_earned := 0;
    v_xp_reason := coalesce(nullif(v_reason, ''), 'activity_failed');
  end if;

  insert into public.learning_attempts (
    id, user_id, activity_type, source_type, source_id,
    unit_id, level_id, status, score, accuracy,
    correct_count, wrong_count, stars, xp_earned,
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
      completed_at = coalesce(public.duo_level_progress.completed_at, excluded.completed_at),
      updated_at = now();
  end if;

  if v_activity_type = 'boss' and v_source_type = 'boss_stage' then
    begin
      v_boss_stage_id := v_source_id::bigint;
    exception when invalid_text_representation then
      v_boss_stage_id := null;
    end;
  end if;

  if v_boss_stage_id is not null then
    insert into public.boss_stage_progress (
      user_id, stage_id, completed, stars, best_score, best_combo,
      attempts, last_played_at, updated_at
    )
    values (
      v_user_id, v_boss_stage_id, v_passed, v_stars,
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
    v_user_id, v_xp_earned, case when v_eligible_streak then 1 else 0 end,
    case when v_eligible_streak then v_today else null end,
    0, 0, case when v_passed and v_source_type = 'duo_level' then 1 else 0 end,
    case when v_passed and v_activity_type = 'boss' then 1 else 0 end,
    case when v_activity_type = 'speaking' then 1 else 0 end,
    case when v_activity_type = 'hanzi' then 1 else 0 end,
    round(v_duration / 60.0)::integer, v_best_combo, now()
  )
  on conflict (user_id) do update set
    total_exp = public.app_user_stats.total_exp + excluded.total_exp,
    current_streak = case
      when not v_eligible_streak then public.app_user_stats.current_streak
      when public.app_user_stats.last_study_date is null then 1
      when public.app_user_stats.last_study_date = v_today then public.app_user_stats.current_streak
      when public.app_user_stats.last_study_date = v_today - 1 then public.app_user_stats.current_streak + 1
      else 1
    end,
    last_study_date = case
      when v_eligible_streak then v_today
      else public.app_user_stats.last_study_date
    end,
    total_lessons_completed = public.app_user_stats.total_lessons_completed + excluded.total_lessons_completed,
    total_bosses_defeated = public.app_user_stats.total_bosses_defeated + excluded.total_bosses_defeated,
    total_speaking_attempts = public.app_user_stats.total_speaking_attempts + excluded.total_speaking_attempts,
    total_hanzi_practices = public.app_user_stats.total_hanzi_practices + excluded.total_hanzi_practices,
    total_minutes_studied = public.app_user_stats.total_minutes_studied + excluded.total_minutes_studied,
    highest_combo = greatest(public.app_user_stats.highest_combo, excluded.highest_combo),
    updated_at = now()
  returning total_exp, current_streak into v_total_exp, v_current_streak;

  v_boss_ready := coalesce(private.boss_available(v_user_id, v_unit_id), false);
  v_unit_completed := (v_activity_type = 'boss' and v_passed);

  v_result := jsonb_build_object(
    'activity_type', v_activity_type,
    'source_type', v_source_type,
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
    'next_unit_id', v_next_unit_id,
    'boss_ready', v_boss_ready,
    'unit_completed', v_unit_completed,
    'reason', v_reason,
    'new_total_xp', v_total_exp,
    'current_streak', v_current_streak,
    'correct_count', v_correct,
    'wrong_count', v_wrong,
    'idempotent', false,
    'metadata', v_metadata || jsonb_build_object(
      'xp_reason', v_xp_reason,
      'hanzi_mastered', v_hanzi_mastered,
      'unit_mastery', v_mastery_payload,
      'next_unit_id', v_next_unit_id,
      'boss_ready', v_boss_ready,
      'unit_completed', v_unit_completed
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
