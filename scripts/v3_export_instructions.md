# V3 dataset extraction for offline audit

Run the SELECT-only SQL at `supabase/audits/v3_1_full_corpus_quality.sql` for a complete database-wide summary. For per-record multilingual quality review, export `lexicon_words`, `lexicon_examples`, and `duo_challenges` in bounded pages with a `source_table` string field and source IDs unchanged. Avoid exporting auth/attempts and keep raw content exports outside Git. Feed NDJSON to `scripts/v3_quality_check.py`; semantic translation correctness requires Chinese/Vietnamese human review, not just automated checks.
