create or replace function public.abandon_learning_attempt_v2(
  p_attempt_id text,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt_pk text;
  v_updated integer := 0;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if nullif(btrim(coalesce(p_attempt_id, '')), '') is null then
    raise exception 'Attempt id is required';
  end if;

  v_attempt_pk := v_user_id::text || ':' || p_attempt_id;
  update public.learning_attempts
  set status = 'abandoned',
      completed_at = now(),
      metadata = coalesce(metadata, '{}'::jsonb)
        || coalesce(p_metadata, '{}'::jsonb)
  where id = v_attempt_pk
    and user_id = v_user_id
    and status = 'started';
  get diagnostics v_updated = row_count;

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'status', case when v_updated > 0 then 'abandoned' else null end,
    'updated', v_updated > 0
  );
end;
$$;

revoke execute on function public.abandon_learning_attempt_v2(text, jsonb)
  from public, anon;
grant execute on function public.abandon_learning_attempt_v2(text, jsonb)
  to authenticated;
