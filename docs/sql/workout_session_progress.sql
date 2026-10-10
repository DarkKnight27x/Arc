-- SUPERSEDED: review/apply workout_training_variants.sql instead; do not apply both.
-- ARC Phase 2A proposal. REVIEW ONLY: never applied by this task.
-- Audit: nbojicqbpqgotdmdayku, 2026-10-09; no session/history tables exist.
-- Apply only after approval, preferably in staging first. Atomic RPC uses RLS.
begin;

create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workout_plan_id uuid not null references public.workout_plans(id) on delete restrict,
  workout_day_id uuid not null references public.workout_days(id) on delete restrict,
  day_title text not null,
  started_at timestamptz not null,
  completed_at timestamptz,
  status text not null default 'in_progress' check (status in ('in_progress','completed','abandoned')),
  outcome text check (outcome in ('completed','partial','discarded')),
  current_index integer not null default 0 check (current_index >= 0),
  prescription jsonb not null check (jsonb_typeof(prescription) = 'array' and jsonb_array_length(prescription) > 0),
  check (current_index < jsonb_array_length(prescription)),
  check (completed_at is null or completed_at >= started_at),
  check ((status = 'in_progress' and completed_at is null and outcome is null)
    or (status = 'completed' and completed_at is not null and outcome = 'completed')
    or (status = 'abandoned' and completed_at is not null and outcome in ('partial','discarded')))
);
-- The immutable prescription snapshot retains order, sets/reps/rest, equipment,
-- notes and exercise UUIDs. Exercise completion is derived from its checked sets.
create table public.workout_session_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_position integer not null check (exercise_position >= 0),
  workout_day_exercise_id uuid references public.workout_day_exercises(id) on delete set null,
  set_number integer not null check (set_number > 0),
  completed boolean not null default false,
  recorded_reps integer check (recorded_reps >= 0),
  weight_kg numeric(8,3) check (weight_kg >= 0 and weight_kg <> 'NaN'::numeric),
  unique (session_id, exercise_position, set_number)
);
create index workout_sessions_user_started_idx on public.workout_sessions(user_id, started_at desc);
create index workout_sessions_resume_idx on public.workout_sessions(user_id, workout_day_id, started_at desc) where status = 'in_progress';
create index workout_sessions_plan_idx on public.workout_sessions(workout_plan_id);
create index workout_sessions_day_idx on public.workout_sessions(workout_day_id);
create index workout_session_sets_prescription_idx on public.workout_session_sets(workout_day_exercise_id);
-- Unique set key already indexes session_id for parent ownership checks.
alter table public.workout_sessions enable row level security;
alter table public.workout_session_sets enable row level security;

create policy session_select on public.workout_sessions for select to authenticated
  using (user_id = (select auth.uid()));
create policy session_insert on public.workout_sessions for insert to authenticated
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.workout_days d join public.workout_plans p on p.id = d.workout_plan_id
    where d.id = workout_sessions.workout_day_id and p.id = workout_sessions.workout_plan_id and p.user_id = (select auth.uid()) and p.plan_type = 'training'));
create policy session_update on public.workout_sessions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.workout_days d join public.workout_plans p on p.id = d.workout_plan_id
    where d.id = workout_sessions.workout_day_id and p.id = workout_sessions.workout_plan_id and p.user_id = (select auth.uid()) and p.plan_type = 'training'));
create policy set_select on public.workout_session_sets for select to authenticated
  using (exists (select 1 from public.workout_sessions s where s.id = session_id and s.user_id = (select auth.uid())));
create policy set_insert on public.workout_session_sets for insert to authenticated
  with check (exists (select 1 from public.workout_sessions s where s.id = session_id and s.user_id = (select auth.uid())
    and exercise_position < jsonb_array_length(s.prescription)
    and set_number <= coalesce((s.prescription->exercise_position->>'sets')::integer, 1)
    and exists (select 1 from public.workout_day_exercises e where e.id = workout_day_exercise_id and e.workout_day_id = s.workout_day_id)));
create policy set_update on public.workout_session_sets for update to authenticated
  using (exists (select 1 from public.workout_sessions s where s.id = session_id and s.user_id = (select auth.uid())))
  with check (exists (select 1 from public.workout_sessions s where s.id = session_id and s.user_id = (select auth.uid())
    and exercise_position < jsonb_array_length(s.prescription)
    and set_number <= coalesce((s.prescription->exercise_position->>'sets')::integer, 1)
    and (workout_day_exercise_id is null or exists (select 1 from public.workout_day_exercises e where e.id = workout_day_exercise_id and e.workout_day_id = s.workout_day_id))));
-- No delete grants: discarded sessions retain their honest completion record.
revoke all on public.workout_sessions, public.workout_session_sets from anon, authenticated;
grant select, insert, update on public.workout_sessions, public.workout_session_sets to authenticated;

create function public.save_workout_session(payload jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  session_uuid uuid := (payload->>'id')::uuid;
  owner_uuid uuid := (payload->>'user_id')::uuid;
  old_session public.workout_sessions%rowtype;
  ex jsonb;
  checks jsonb;
  i integer;
  j integer;
  expected integer;
  all_done boolean := true;
  new_status text := payload->>'status';
begin
  if auth.uid() is null or owner_uuid is distinct from auth.uid() then
    raise exception 'Session owner does not match authenticated user' using errcode = '42501';
  end if;
  -- Serialize even the first insert, including overlapping timeout retries.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(session_uuid::text, 0));
  if jsonb_typeof(payload->'prescription') is distinct from 'array'
    or jsonb_typeof(payload->'completion') is distinct from 'array'
    or jsonb_array_length(payload->'prescription') = 0
    or jsonb_array_length(payload->'completion') <> jsonb_array_length(payload->'prescription') then
    raise exception 'Malformed session snapshot' using errcode = '22023';
  end if;
  for i in 0 .. jsonb_array_length(payload->'prescription') - 1 loop
    ex := payload->'prescription'->i;
    checks := payload->'completion'->i;
    expected := coalesce((ex->>'sets')::integer, 1);
    if expected <= 0 or coalesce((ex->>'rest_seconds')::integer, 0) < 0
      or jsonb_typeof(checks) is distinct from 'array' or jsonb_array_length(checks) <> expected then
      raise exception 'Invalid set prescription' using errcode = '22023';
    end if;
    for j in 0 .. expected - 1 loop
      if jsonb_typeof(checks->j) is distinct from 'boolean' then
        raise exception 'Invalid completion flag' using errcode = '22023';
      end if;
      all_done := all_done and (checks->>j)::boolean;
    end loop;
  end loop;
  if payload->>'outcome' = 'partial' and all_done then
    raise exception 'A fully checked session is not partial' using errcode = '22023';
  end if;
  if new_status = 'completed' and not all_done then
    raise exception 'Unchecked sets cannot be completed' using errcode = '22023';
  end if;
  select * into old_session from public.workout_sessions where id = session_uuid for update;
  if found then
    if old_session.user_id <> owner_uuid or old_session.workout_plan_id <> (payload->>'workout_plan_id')::uuid
      or old_session.workout_day_id <> (payload->>'workout_day_id')::uuid
      or old_session.prescription <> payload->'prescription'
      or old_session.started_at <> (payload->>'started_at')::timestamptz then
      raise exception 'Session identity or prescription changed' using errcode = '22023';
    end if;
    if old_session.status <> 'in_progress' and exists (
      select 1 from public.workout_session_sets st where st.session_id = session_uuid
        and st.completed is distinct from (payload->'completion'->st.exercise_position->>(st.set_number - 1))::boolean) then
      raise exception 'An ended session cannot change completion flags' using errcode = '22023';
    end if;
    if old_session.status <> 'in_progress' and (old_session.status <> new_status or old_session.outcome is distinct from payload->>'outcome') then
      raise exception 'An ended session cannot be reopened' using errcode = '22023';
    end if;
  end if;
  insert into public.workout_sessions(id, user_id, workout_plan_id, workout_day_id, day_title,
    started_at, completed_at, status, outcome, current_index, prescription)
  values(session_uuid, owner_uuid, (payload->>'workout_plan_id')::uuid, (payload->>'workout_day_id')::uuid,
    payload->>'day_title', (payload->>'started_at')::timestamptz, (payload->>'completed_at')::timestamptz,
    new_status, payload->>'outcome', (payload->>'current_index')::integer, payload->'prescription')
  on conflict(id) do update set completed_at = excluded.completed_at, status = excluded.status,
    outcome = excluded.outcome, current_index = excluded.current_index;
  for i in 0 .. jsonb_array_length(payload->'prescription') - 1 loop
    ex := payload->'prescription'->i;
    checks := payload->'completion'->i;
    for j in 0 .. jsonb_array_length(checks) - 1 loop
      insert into public.workout_session_sets(session_id, exercise_position, workout_day_exercise_id, set_number, completed)
      values(session_uuid, i, (ex->>'id')::uuid, j + 1, (checks->>j)::boolean)
      on conflict(session_id, exercise_position, set_number) do update set completed = excluded.completed;
    end loop;
  end loop;
  return session_uuid;
end;
$$;
revoke execute on function public.save_workout_session(jsonb) from public, anon;
grant execute on function public.save_workout_session(jsonb) to authenticated;
commit;
