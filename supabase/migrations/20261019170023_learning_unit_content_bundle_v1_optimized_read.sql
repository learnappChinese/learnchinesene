-- Backward-compatible, read-only learning content bundle.
-- Guest state/XP is NOT included; Flutter still overlays local progress.
create or replace function public.learning_unit_bundle_v1(p_unit_id text)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $function$
select jsonb_build_object(
  'path_rows', coalesce((
    select jsonb_agg(to_jsonb(path_row) order by path_row.node_order)
    from public.unit_learning_path_v2(p_unit_id) path_row
  ), '[]'::jsonb),
  'raw_challenges', coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'session_id', c.session_id,
        'type', c.type,
        'prompt', c.prompt,
        'tts', c.tts,
        'slow_tts', c.slow_tts,
        'choices_text', c.choices_text,
        'solutions', c.solutions,
        'tokens_text', c.tokens_text,
        '_level_id', s.level_id
      ) order by c.id
    )
    from public.duo_levels l
    join public.duo_sessions s on s.level_id = l.id
    join public.duo_challenges c on c.session_id = s.id
    where l.unit_id = p_unit_id
  ), '[]'::jsonb),
  'boss_stage', (
    select to_jsonb(b)
    from (
      select id, unit_id, stage_order, title, question_count,
             difficulty, boss_name, boss_hp, player_hp, theme_code
      from public.boss_stages
      where unit_id = p_unit_id
      order by id
      limit 1
    ) b
  )
);
$function$;
revoke all on function public.learning_unit_bundle_v1(text) from public;
grant execute on function public.learning_unit_bundle_v1(text) to anon, authenticated;
comment on function public.learning_unit_bundle_v1(text) is 'Read-only one-request bundle for Unit Overview. User progression remains in existing server RPC or Guest local store.';
