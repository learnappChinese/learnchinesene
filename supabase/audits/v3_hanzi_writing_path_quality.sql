-- V3 Hanzi writing-path quality audit. SELECT only.
-- Quantifies whether current lexicon data is sufficient for a real HSK→Section→Hanzi path.
with unit_words as (
  select u.hsk_level_id,u.id section_id,u.title section_title,
         coalesce(u.sort_order,u.unit_number,u.id) section_order,
         w.id word_id,w.word,w.pinyin context_pinyin,w.meaning_vi context_meaning_vi,
         coalesce(min(ws.source_row),w.id)::integer source_row
  from public.lexicon_units u
  join public.lexicon_word_units wu on wu.unit_id=u.id
  join public.lexicon_words w on w.id=wu.word_id
  left join public.lexicon_word_sources ws on ws.unit_id=u.id and ws.word_id=w.id
  group by u.hsk_level_id,u.id,u.title,u.sort_order,u.unit_number,
           w.id,w.word,w.pinyin,w.meaning_vi
), expanded as (
  select uw.*,p.ch,p.ord::integer char_position
  from unit_words uw
  cross join lateral regexp_split_to_table(uw.word,'') with ordinality p(ch,ord)
), mapped as (
  select e.*,c.id character_id,c.stroke_count,c.stroke_paths,
         cw.pinyin character_pinyin,cw.meaning_vi character_meaning,
         row_number() over(
           partition by e.section_id,c.id
           order by e.source_row,e.word_id,e.char_position
         ) dedupe
  from expanded e
  left join public.lexicon_characters c on c.character=e.ch
  left join lateral (
    select w2.pinyin,w2.meaning_vi
    from public.lexicon_words w2
    where c.id is not null and w2.word=c.character
    order by case when w2.hsk_level_id=e.hsk_level_id then 0 else 1 end,w2.id
    limit 1
  ) cw on true
)
select h.id hsk_level_id,h.name,
       count(distinct m.section_id) sections,
       count(*) filter(where m.dedupe=1 and m.character_id is not null) path_nodes,
       count(*) filter(where m.dedupe=1 and m.character_id is not null
          and (m.character_pinyin is null or btrim(m.character_pinyin)=''))
          missing_standalone_pinyin,
       count(*) filter(where m.dedupe=1 and m.character_id is not null
          and (m.character_meaning is null or btrim(m.character_meaning)=''))
          missing_standalone_meaning,
       count(*) filter(where m.dedupe=1 and m.character_id is not null
          and (m.stroke_paths is null or btrim(m.stroke_paths)=''
               or coalesce(m.stroke_count,0)<=0))
          missing_strokes,
       count(*) filter(where m.character_id is null) unmapped_character_positions
from public.lexicon_hsk_levels h
left join mapped m on m.hsk_level_id=h.id
group by h.id,h.name,h.sort_order
order by h.sort_order,h.id;

-- Top unmapped characters. These are data-completeness candidates, not automatic
-- requests to fabricate stroke paths.
with expanded as (
  select w.word,u.hsk_level_id,p.ch
  from public.lexicon_word_units wu
  join public.lexicon_words w on w.id=wu.word_id
  join public.lexicon_units u on u.id=wu.unit_id
  cross join lateral regexp_split_to_table(w.word,'') p(ch)
)
select e.ch,count(*) occurrences,
       jsonb_agg(distinct e.word order by e.word) sample_words
from expanded e
left join public.lexicon_characters c on c.character=e.ch
where c.id is null
group by e.ch
order by count(*) desc,e.ch
limit 100;
