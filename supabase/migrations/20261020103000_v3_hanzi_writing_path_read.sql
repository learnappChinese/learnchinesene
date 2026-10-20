-- V3 Hanzi writing learning-path read model.
-- ADDITIVE, read-only, NOT YET DEPLOYED to production.
-- Keeps original lexicon IDs/strokes and learner progress untouched.
create or replace function public.writing_learning_path_v3(
  p_hsk_level_id integer
)
returns table (
  hsk_level_id integer,
  hsk_name text,
  hsk_sort_order integer,
  section_id integer,
  section_title text,
  section_order integer,
  node_order integer,
  character_id integer,
  character text,
  character_pinyin text,
  character_meaning_vi text,
  context_word_id integer,
  context_word text,
  context_pinyin text,
  context_meaning_vi text,
  source_row integer,
  stroke_count integer,
  stroke_width double precision,
  stroke_height double precision,
  stroke_paths text,
  metadata_quality text
)
language sql
stable
security invoker
set search_path = ''
as $function$
with unit_words as (
  select
    h.id as hsk_level_id,
    h.name as hsk_name,
    coalesce(h.sort_order,h.id) as hsk_sort_order,
    u.id as section_id,
    u.title as section_title,
    coalesce(u.sort_order,u.unit_number,u.id) as section_order,
    w.id as word_id,
    w.word,
    w.pinyin as context_pinyin,
    w.meaning_vi as context_meaning_vi,
    coalesce(min(ws.source_row),w.id)::integer as source_row
  from public.lexicon_hsk_levels h
  join public.lexicon_units u on u.hsk_level_id=h.id
  join public.lexicon_word_units wu on wu.unit_id=u.id
  join public.lexicon_words w on w.id=wu.word_id
  left join public.lexicon_word_sources ws
    on ws.unit_id=u.id and ws.word_id=w.id
  where h.id=p_hsk_level_id
  group by h.id,h.name,h.sort_order,
           u.id,u.title,u.sort_order,u.unit_number,
           w.id,w.word,w.pinyin,w.meaning_vi
), expanded as (
  select uw.*,piece.ch,piece.ord::integer as char_position
  from unit_words uw
  cross join lateral regexp_split_to_table(uw.word,'')
    with ordinality piece(ch,ord)
), mapped as (
  select
    e.*,
    c.id as character_id,
    c.character,
    c.stroke_count,
    c.stroke_width,
    c.stroke_height,
    c.stroke_paths,
    exact_word.pinyin as character_pinyin,
    exact_word.meaning_vi as character_meaning_vi,
    row_number() over (
      partition by e.section_id,c.id
      order by e.source_row,e.word_id,e.char_position
    ) as duplicate_rank
  from expanded e
  join public.lexicon_characters c on c.character=e.ch
  left join lateral (
    select w2.pinyin,w2.meaning_vi
    from public.lexicon_words w2
    where w2.word=c.character
    order by
      case when w2.hsk_level_id=e.hsk_level_id then 0 else 1 end,
      w2.id
    limit 1
  ) exact_word on true
), deduped as (
  select *
  from mapped
  where duplicate_rank=1
), numbered as (
  select
    d.*,
    row_number() over (
      partition by d.section_id
      order by d.source_row,d.word_id,d.char_position,d.character_id
    )::integer as node_order
  from deduped d
)
select
  n.hsk_level_id,n.hsk_name,n.hsk_sort_order,
  n.section_id,n.section_title,n.section_order,n.node_order,
  n.character_id,n.character,
  n.character_pinyin,n.character_meaning_vi,
  n.word_id as context_word_id,n.word as context_word,
  n.context_pinyin,n.context_meaning_vi,n.source_row,
  n.stroke_count,n.stroke_width,n.stroke_height,n.stroke_paths,
  case
    when n.stroke_paths is null or btrim(n.stroke_paths)='' or coalesce(n.stroke_count,0)<=0
      then 'missing_strokes'
    when n.character_pinyin is null or btrim(n.character_pinyin)=''
      then 'context_only_pinyin'
    when n.character_meaning_vi is null or btrim(n.character_meaning_vi)=''
      then 'context_only_meaning'
    else 'complete'
  end as metadata_quality
from numbered n
order by n.hsk_sort_order,n.section_order,n.node_order;
$function$;

revoke all on function public.writing_learning_path_v3(integer) from public;
grant execute on function public.writing_learning_path_v3(integer)
  to anon,authenticated;
comment on function public.writing_learning_path_v3(integer) is
'Static HSK->section->Hanzi writing path from current lexicon mappings. User progress remains separate.';

-- Compact real HSK catalogue. Do not hardcode HSK 1..6 in Flutter.
create or replace function public.writing_hsk_catalog_v3()
returns table (
  hsk_level_id integer,
  name text,
  sort_order integer,
  section_count bigint,
  mapped_character_count bigint
)
language sql
stable
security invoker
set search_path = ''
as $function$
with nodes as (
  select p.hsk_level_id,p.character_id
  from public.lexicon_hsk_levels h
  cross join lateral public.writing_learning_path_v3(h.id) p
)
select
  h.id,
  h.name,
  coalesce(h.sort_order,h.id),
  count(distinct u.id),
  count(distinct n.character_id)
from public.lexicon_hsk_levels h
left join public.lexicon_units u on u.hsk_level_id=h.id
left join nodes n on n.hsk_level_id=h.id
group by h.id,h.name,h.sort_order
order by coalesce(h.sort_order,h.id),h.id;
$function$;

revoke all on function public.writing_hsk_catalog_v3() from public;
grant execute on function public.writing_hsk_catalog_v3() to anon,authenticated;
