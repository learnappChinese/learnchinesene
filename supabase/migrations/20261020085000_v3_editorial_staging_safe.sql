-- V3-2/V3-5: editorial staging schema. NEVER apply to production without review.
-- Additive; all existing source IDs, user data and progress functions stay unchanged.
create table if not exists public.content_v3_releases (
  id bigint generated always as identity primary key,
  code text not null unique,
  status text not null default 'draft'
    check(status in ('draft','review','approved','active','retired')),
  notes text,
  created_at timestamptz not null default now(),
  activated_at timestamptz
);
create table if not exists public.content_v3_revisions (
  id bigint generated always as identity primary key,
  release_id bigint not null references public.content_v3_releases(id) on delete restrict,
  source_table text not null check(source_table in ('lexicon_words','lexicon_examples','duo_challenges')),
  source_id text not null,
  candidate jsonb not null check(jsonb_typeof(candidate)='object'),
  source_hash text,
  status text not null default 'draft'
    check(status in ('draft','needs_review','approved','rejected')),
  reviewer_note text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(release_id,source_table,source_id)
);
create table if not exists public.content_v3_quality_issues (
  id bigint generated always as identity primary key,
  source_table text not null check(source_table in ('lexicon_words','lexicon_examples','duo_challenges')),
  source_id text not null,
  issue_code text not null,
  severity text not null check(severity in ('critical','high','medium','low')),
  evidence jsonb not null default '{}'::jsonb,
  state text not null default 'open' check(state in ('open','in_review','resolved','dismissed')),
  created_at timestamptz not null default now(),
  unique(source_table,source_id,issue_code)
);
create index if not exists content_v3_revisions_source_idx on public.content_v3_revisions(source_table,source_id,status);
create index if not exists content_v3_revisions_release_idx on public.content_v3_revisions(release_id,status);
create index if not exists content_v3_quality_issues_open_idx on public.content_v3_quality_issues(state,severity,source_table);
alter table public.content_v3_releases enable row level security;
alter table public.content_v3_revisions enable row level security;
alter table public.content_v3_quality_issues enable row level security;
revoke all on public.content_v3_releases from anon,authenticated;
revoke all on public.content_v3_revisions from anon,authenticated;
revoke all on public.content_v3_quality_issues from anon,authenticated;
-- Do not grant anon/authenticated table permissions, and never embed service_role in Flutter.
-- No publishing trigger: review/activation must be implemented and verified separately.
