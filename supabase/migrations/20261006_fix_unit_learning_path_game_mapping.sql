-- Follow-up for the Unit-centric learning journey.
-- Keeps the existing unit_learning_path(text) result contract intact.
-- Applied to Supabase on 2026-10-06.

create or replace function public.duo_game_path(p_game_code text)
returns table(
  level_id text,
  section_number integer,
  section_title text,
  unit_number integer,
  unit_title text,
  level_index integer,
  challenge_count bigint
)
language sql
stable
set search_path = public
as $$
  select
    l.id as level_id,
    sec.section_number,
    sec.title as section_title,
    u.unit_number,
    u.title as unit_title,
    l.level_index,
    count(c.id) as challenge_count
  from public.duo_levels l
  join public.duo_units u on u.id = l.unit_id
  join public.duo_sections sec on sec.id = u.section_id
  left join public.duo_sessions s on s.level_id = l.id
  left join public.duo_challenges c
    on c.session_id = s.id
   and (
     (p_game_code = 'learn_words' and c.type in ('select','assist','match'))
     or (p_game_code = 'select_answer' and c.type in ('select','assist'))
     or (p_game_code in ('word_connect','match_pairs') and c.type = 'match')
     or (p_game_code = 'listen_select' and c.type = 'listenTap')
     or (p_game_code = 'translate' and c.type = 'translate')
     or (p_game_code = 'gap_fill' and c.type = 'gapFill')
     or (p_game_code = 'tap_complete' and c.type = 'tapComplete')
     or (p_game_code = 'dialogue' and c.type = 'dialogue')
     or (p_game_code = 'sentence_order' and c.type = 'orderTapComplete')
     or (
       p_game_code = 'speaking'
       and c.prompt is not null
       and btrim(c.prompt) <> ''
     )
   )
  group by
    l.id,
    sec.section_number,
    sec.title,
    u.unit_number,
    u.title,
    l.level_index
  order by
    sec.section_number,
    u.unit_number,
    l.level_index;
$$;

create or replace function public.duo_level_challenges(
  p_level_id text,
  p_game_code text,
  p_limit integer default 10
)
returns setof public.duo_challenges
language sql
stable
set search_path = public
as $$
  select c.*
  from public.duo_challenges c
  join public.duo_sessions s on s.id = c.session_id
  where s.level_id = p_level_id
    and (
      (p_game_code = 'learn_words' and c.type in ('select','assist','match'))
      or (p_game_code = 'select_answer' and c.type in ('select','assist'))
      or (p_game_code in ('word_connect','match_pairs') and c.type = 'match')
      or (p_game_code = 'listen_select' and c.type = 'listenTap')
      or (p_game_code = 'translate' and c.type = 'translate')
      or (p_game_code = 'gap_fill' and c.type = 'gapFill')
      or (p_game_code = 'tap_complete' and c.type = 'tapComplete')
      or (p_game_code = 'dialogue' and c.type = 'dialogue')
      or (p_game_code = 'sentence_order' and c.type = 'orderTapComplete')
      or (
        p_game_code = 'speaking'
        and c.prompt is not null
        and btrim(c.prompt) <> ''
      )
    )
  order by random()
  limit greatest(1, least(p_limit, 100));
$$;

create or replace function public.unit_learning_path(p_unit_id text)
returns table(
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
  boss_stage_id bigint,
  boss_name text,
  boss_hp integer,
  player_hp integer,
  difficulty integer
)
language sql
stable
security invoker
set search_path = public
as $$
  with learning as (
    select
      u.id as unit_id,
      u.title as unit_title,
      sec.section_number,
      u.unit_number,
      l.id as level_id,
      l.level_index,
      g.id as game_id,
      g.game_code,
      g.name_vi as game_name,
      coalesce(g.description_vi, '') as game_description,
      coalesce(g.icon, '🎯') as game_icon,
      count(c.id)::bigint as challenge_count,
      row_number() over (
        order by l.level_index, g.game_order, g.id
      )::integer as node_order
    from public.duo_units u
    join public.duo_sections sec on sec.id = u.section_id
    join public.duo_levels l on l.unit_id = u.id
    cross join public.duo_game_definitions g
    left join public.duo_sessions s on s.level_id = l.id
    left join public.duo_challenges c
      on c.session_id = s.id
     and (
       (g.game_code = 'learn_words' and c.type in ('select','assist','match'))
       or (g.game_code = 'select_answer' and c.type in ('select','assist'))
       or (g.game_code in ('word_connect','match_pairs') and c.type = 'match')
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
    where u.id = p_unit_id
    group by
      u.id, u.title, sec.section_number, u.unit_number,
      l.id, l.level_index,
      g.id, g.game_code, g.name_vi, g.description_vi, g.icon, g.game_order
    having count(c.id) > 0
  ),
  current_stage as (
    select bs.*
    from public.boss_stages bs
    where bs.unit_id = p_unit_id
      and bs.active = true
    limit 1
  ),
  unit_gate as (
    select
      case
        when cs.id is null then true
        when cs.stage_order = 1 then true
        else coalesce(prev_progress.completed, false)
      end as unlocked
    from current_stage cs
    left join public.boss_stages prev
      on prev.stage_order = cs.stage_order - 1
     and prev.active = true
    left join public.boss_stage_progress prev_progress
      on prev_progress.stage_id = prev.id
     and prev_progress.user_id = auth.uid()

    union all

    select true
    where not exists (select 1 from current_stage)
    limit 1
  ),
  learning_with_state as (
    select
      'learning'::text as node_type,
      l.node_order,
      l.unit_id,
      l.unit_title,
      l.section_number,
      l.unit_number,
      l.level_id,
      l.level_index,
      l.game_id,
      l.game_code,
      l.game_name,
      l.game_description,
      l.game_icon,
      l.challenge_count,
      coalesce(p.attempts, 0)::integer as attempts,
      coalesce(p.best_score, 0)::integer as best_score,
      coalesce(p.stars, 0)::integer as stars,
      (
        coalesce(p.is_unlocked, false)
        or (
          l.node_order = 1
          and coalesce((select unlocked from unit_gate limit 1), false)
        )
      ) as is_unlocked,
      coalesce(p.is_completed, false) as is_completed,
      coalesce(a.status = 'active', false) as in_progress,
      coalesce(a.current_index, 0)::integer as current_index,
      null::bigint as boss_stage_id,
      null::text as boss_name,
      null::integer as boss_hp,
      null::integer as player_hp,
      null::integer as difficulty
    from learning l
    left join public.duo_level_progress p
      on p.user_id = auth.uid()
     and p.game_id = l.game_id
     and p.level_id = l.level_id
    left join public.duo_active_sessions a
      on a.user_id = auth.uid()
     and a.game_id = l.game_id
     and a.level_id = l.level_id
     and a.status = 'active'
  ),
  boss as (
    select
      'boss'::text as node_type,
      (coalesce((select max(node_order) from learning), 0) + 1)::integer
        as node_order,
      bs.unit_id,
      u.title as unit_title,
      bs.section_number,
      bs.unit_number,
      null::text as level_id,
      null::integer as level_index,
      null::bigint as game_id,
      'boss_battle'::text as game_code,
      bs.title as game_name,
      ('Đánh bại ' || bs.boss_name || ' để hoàn thành chương')::text
        as game_description,
      '🐉'::text as game_icon,
      bs.question_count::bigint as challenge_count,
      coalesce(bp.attempts, 0)::integer as attempts,
      coalesce(bp.best_score, 0)::integer as best_score,
      coalesce(bp.stars, 0)::integer as stars,
      (
        coalesce((select unlocked from unit_gate limit 1), false)
        and not exists (
          select 1
          from learning_with_state s
          where not s.is_completed
        )
      ) as is_unlocked,
      coalesce(bp.completed, false) as is_completed,
      false as in_progress,
      0::integer as current_index,
      bs.id as boss_stage_id,
      bs.boss_name,
      bs.boss_hp,
      bs.player_hp,
      bs.difficulty
    from public.boss_stages bs
    join public.duo_units u on u.id = bs.unit_id
    left join public.boss_stage_progress bp
      on bp.user_id = auth.uid()
     and bp.stage_id = bs.id
    where bs.unit_id = p_unit_id
      and bs.active = true
  )
  select * from learning_with_state
  union all
  select * from boss
  order by node_order;
$$;

grant execute on function public.duo_game_path(text) to anon, authenticated;
grant execute on function public.duo_level_challenges(text, text, integer)
  to anon, authenticated;
grant execute on function public.unit_learning_path(text) to anon, authenticated;
