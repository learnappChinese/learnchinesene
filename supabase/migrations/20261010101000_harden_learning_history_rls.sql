-- History is readable by its owner. Authoritative writes happen only through
-- the narrow SECURITY DEFINER learning pipeline RPCs.

drop policy if exists "Users can view their own XP events"
  on public.learning_xp_events;
drop policy if exists "Users can insert their own XP events"
  on public.learning_xp_events;

create policy "Users can view their own XP events"
on public.learning_xp_events
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can view their own attempts"
  on public.learning_attempts;
drop policy if exists "Users can insert their own attempts"
  on public.learning_attempts;
drop policy if exists "Users can update their own attempts"
  on public.learning_attempts;

create policy "Users can view their own attempts"
on public.learning_attempts
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.learning_xp_events from anon, authenticated;
revoke all on table public.learning_attempts from anon, authenticated;

grant select on table public.learning_xp_events to authenticated;
grant select on table public.learning_attempts to authenticated;
