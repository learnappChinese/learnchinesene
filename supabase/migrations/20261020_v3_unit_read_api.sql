-- V3-3: indexed, paginated single-request read model. DRAFT MIGRATION.
-- Original question IDs/JSON payloads and authoritative path RPC are preserved.
-- No per-user XP or guest state is cached here.
create or replace function public.learning_v3_unit_read_v1(
    p_unit_id text, p_offset integer default 0, p_page_size integer default 100
) returns jsonb
language sql stable security invoker set search_path = ''
as $f$
with args as (
  select greatest(0,p_offset) as page_offset,
         greatest(1,least(250,p_page_size)) as page_size
), path as (
  select coalesce(jsonb_agg(to_jsonb(x) order by x.node_order),'[]'::jsonb) val
  from public.unit_learning_path_v2(p_unit_id) x
), src as (
  select c.id,c.session_id,s.level_id,c.type,c.prompt,c.tts,c.slow_tts,
         c.choices_text,c.choices_correct,c.solutions,c.tokens_text,
         c.tokens_tts,c.tokens_hints,c.choices_tts,c.choices_image
  from public.duo_levels l
  join public.duo_sessions s on s.level_id=l.id
  join public.duo_challenges c on c.session_id=s.id
  where l.unit_id=p_unit_id
), rows as (
  select coalesce(jsonb_agg(to_jsonb(q) order by q.level_id,q.session_id,q.id),'[]'::jsonb) val
  from (
    select * from src
    order by level_id,session_id,id
    limit (select page_size from args)
    offset (select page_offset from args)
  ) q
)
select jsonb_build_object(
  'schema_version',3,'content_source','legacy','unit_id',p_unit_id,
  'path_rows',(select val from path),
  'challenges',(select val from rows),
  'total_challenges',(select count(*) from src),
  'offset',(select page_offset from args),
  'page_size',(select page_size from args)
);
$f$;
revoke all on function public.learning_v3_unit_read_v1(text,integer,integer) from public;
grant execute on function public.learning_v3_unit_read_v1(text,integer,integer) to anon,authenticated;
comment on function public.learning_v3_unit_read_v1(text,integer,integer) is
'Versioned read-only Unit content with bounded challenge page. Existing progress RPC remains authoritative.';
