-- ARC Phase 2A + 2B consolidated proposal. REVIEW ONLY, NOT APPLIED.
-- Supersedes workout_session_progress.sql. Apply this file instead of that file.
begin;
create schema if not exists arc_private;
revoke all on schema arc_private from public, anon;
grant usage on schema arc_private to authenticated;

create table public.workout_alternative_mappings (
  id uuid primary key default gen_random_uuid(),
  source_exercise_id uuid not null references public.exercise_library(id) on delete restrict,
  alternative_exercise_id uuid not null references public.exercise_library(id) on delete restrict,
  version integer not null check (version > 0),
  primary_target text not null,
  secondary_targets text[] not null default '{}',
  movement_pattern text not null check (movement_pattern in ('elbow_flexion','shoulder_flexion','upright_row')),
  required_equipment text[] not null check (cardinality(required_equipment) > 0 and required_equipment <@ array['bodyweight','dumbbells','bands']::text[]),
  sets integer not null check (sets between 1 and 20),
  min_sets integer not null check (min_sets between 1 and sets),
  reps text not null check (length(reps) between 1 and 120),
  rest_seconds integer not null check (rest_seconds between 0 and 600),
  work_seconds_per_set integer not null check (work_seconds_per_set between 1 and 600),
  priority integer not null default 0 check (priority >= 0),
  limitations text not null,
  review_status text not null default 'proposed' check (review_status in ('proposed','approved','retired')),
  enabled boolean not null default false,
  review_metadata jsonb not null default '{}',
  unique (source_exercise_id, alternative_exercise_id, version)
);
create index alternative_target_idx on public.workout_alternative_mappings(alternative_exercise_id);
-- Existing catalog FK lacked a covering index in the read-only advisor audit.
create index if not exists workout_day_exercises_exercise_idx on public.workout_day_exercises(exercise_id);
alter table public.workout_alternative_mappings enable row level security;
create policy mappings_read on public.workout_alternative_mappings for select to authenticated
  using (review_status = 'approved' and enabled);
revoke all on public.workout_alternative_mappings from public, anon, authenticated;
grant select on public.workout_alternative_mappings to authenticated;

-- Approved mapping definitions are append-only. Retire/disable rather than rewrite.
create function arc_private.freeze_mapping() returns trigger language plpgsql set search_path = '' as $$
begin
  if old.review_status in ('approved','retired') and
    ((to_jsonb(old) - array['enabled','review_status']) is distinct from (to_jsonb(new) - array['enabled','review_status'])
      or new.review_status = 'proposed') then
    raise exception 'Create a new mapping version instead of changing reviewed definitions';
  end if;
  return new;
end;
$$;
revoke all on function arc_private.freeze_mapping() from public, anon, authenticated;
create trigger mapping_definition_frozen before update on public.workout_alternative_mappings
  for each row execute function arc_private.freeze_mapping();

create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workout_plan_id uuid references public.workout_plans(id) on delete set null,
  workout_day_id uuid references public.workout_days(id) on delete set null,
  day_title text not null,
  started_at timestamptz not null,
  completed_at timestamptz,
  status text not null check (status in ('in_progress','completed','abandoned')),
  outcome text check (outcome in ('completed','partial','discarded')),
  training_location text not null check (training_location in ('gym','home')),
  session_variant text not null check (session_variant in ('gym_original','home_curated')),
  equipment_selection text[] not null,
  requested_duration_minutes integer check (requested_duration_minutes between 1 and 240),
  estimated_duration_seconds integer check (estimated_duration_seconds > 0),
  original_targets text[] not null,
  source_prescription jsonb not null check (jsonb_typeof(source_prescription) = 'array'),
  prescription jsonb not null check (jsonb_typeof(prescription) = 'array' and jsonb_array_length(prescription) between 1 and 100),
  -- Source UUIDs survive FK deletion in this immutable envelope.
  snapshot jsonb not null,
  current_index integer not null check (current_index >= 0 and current_index < jsonb_array_length(prescription)),
  revision integer not null check (revision >= 0),
  injury_warning boolean not null default false,
  check ((training_location = 'gym' and session_variant = 'gym_original') or (training_location = 'home' and session_variant = 'home_curated')),
  check (completed_at is null or completed_at >= started_at),
  check (coalesce((status = 'in_progress' and completed_at is null and outcome is null)
    or (status = 'completed' and completed_at is not null and outcome = 'completed')
    or (status = 'abandoned' and completed_at is not null and outcome in ('partial','discarded')), false))
);
create table public.workout_session_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_position integer not null check (exercise_position >= 0),
  source_workout_day_exercise_id uuid references public.workout_day_exercises(id) on delete set null,
  actual_exercise_library_id uuid references public.exercise_library(id) on delete set null,
  mapping_id uuid references public.workout_alternative_mappings(id) on delete set null,
  mapping_version integer,
  set_number integer not null check (set_number > 0),
  completed boolean not null default false,
  recorded_reps integer check (recorded_reps >= 0),
  weight_kg numeric(8,3) check (weight_kg >= 0 and weight_kg <> 'NaN'::numeric),
  unique(session_id, exercise_position, set_number)
);
create index session_user_history_idx on public.workout_sessions(user_id, started_at desc);
create unique index one_in_progress_session_per_day on public.workout_sessions(user_id, workout_day_id) where status = 'in_progress' and workout_day_id is not null;
create index session_plan_idx on public.workout_sessions(workout_plan_id);
create index session_day_idx on public.workout_sessions(workout_day_id);
create index session_set_source_idx on public.workout_session_sets(source_workout_day_exercise_id);
create index session_set_actual_idx on public.workout_session_sets(actual_exercise_library_id);
create index session_set_mapping_idx on public.workout_session_sets(mapping_id);
alter table public.workout_sessions enable row level security;
alter table public.workout_session_sets enable row level security;
create policy session_read on public.workout_sessions for select to authenticated using (user_id = (select auth.uid()));
create policy set_read on public.workout_session_sets for select to authenticated using (
  exists(select 1 from public.workout_sessions s where s.id = session_id and s.user_id = (select auth.uid())));
-- RLS alone does not validate substitutions. Direct client writes are forbidden.
revoke all on public.workout_sessions, public.workout_session_sets from public, anon, authenticated;
grant select on public.workout_sessions, public.workout_session_sets to authenticated;

create function arc_private.save_workout_session(payload jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  sid uuid := (payload->>'id')::uuid;
  pid uuid := (payload->>'workout_plan_id')::uuid;
  did uuid := (payload->>'workout_day_id')::uuid;
  incoming_revision integer := (payload->>'revision')::integer;
  base_revision integer := (payload->>'base_revision')::integer;
  old_session public.workout_sessions%rowtype;
  mapping public.workout_alternative_mappings%rowtype;
  source record;
  actual public.exercise_library%rowtype;
  source_json jsonb;
  ex jsonb;
  flags jsonb;
  envelope jsonb;
  original_targets text[];
  equipment text[];
  i integer;
  j integer;
  expected integer;
  estimated integer := 180;
  all_done boolean := true;
  is_new boolean;
  location text := payload->>'training_location';
  new_status text := payload->>'status';
  n integer;
  started timestamptz := (payload->>'started_at')::timestamptz;
  ended timestamptz := (payload->>'completed_at')::timestamptz;
begin
  if caller is null or (payload->>'user_id')::uuid is distinct from caller then
    raise exception 'Authenticated owner mismatch' using errcode = '42501';
  end if;
  if sid is null or payload->>'contract_version' is distinct from '2' then
    raise exception 'Invalid snapshot contract' using errcode = '22023';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(caller::text || ':' || did::text, 0));
  select * into old_session from public.workout_sessions where id = sid for update;
  is_new := not found;
  if not is_new and old_session.user_id <> caller then
    raise exception 'Authenticated owner mismatch' using errcode = '42501';
  end if;
  if jsonb_typeof(payload->'prescription') is distinct from 'array' or jsonb_typeof(payload->'completion') is distinct from 'array'
    or jsonb_typeof(payload->'source_prescription') is distinct from 'array'
    or jsonb_typeof(payload->'equipment_selection') is distinct from 'array'
    or jsonb_typeof(payload->'original_targets') is distinct from 'array' then
    raise exception 'Malformed snapshot arrays' using errcode = '22023';
  end if;
  n := jsonb_array_length(payload->'prescription');
  if n not between 1 and 100 or jsonb_array_length(payload->'completion') <> n
    or incoming_revision is null or incoming_revision < 0 or base_revision is null
    or started is null or started > clock_timestamp() + interval '5 minutes'
    or (ended is not null and (ended < started or ended > clock_timestamp() + interval '5 minutes')) then
    raise exception 'Invalid snapshot shape, revision or time' using errcode = '22023';
  end if;
  select coalesce(array_agg(value order by value collate "C"), '{}') into equipment from jsonb_array_elements_text(payload->'equipment_selection');
  if cardinality(equipment) <> (select count(distinct x) from unnest(equipment) x)
    or (location = 'home' and (not equipment @> array['bodyweight'] or not equipment <@ array['bodyweight','dumbbells','bands']))
    or (location = 'gym' and (cardinality(equipment) <> 0 or payload->>'requested_duration_minutes' is not null))
    or location not in ('gym','home')
    or (location = 'gym' and payload->>'session_variant' is distinct from 'gym_original')
    or (location = 'home' and payload->>'session_variant' is distinct from 'home_curated') then
    raise exception 'Invalid variant equipment metadata' using errcode = '22023';
  end if;
  -- Validate every flag, even on an otherwise idempotent retry.
  for i in 0 .. n - 1 loop
    ex := payload->'prescription'->i; flags := payload->'completion'->i;
    expected := coalesce((ex->>'sets')::integer, 1);
    if (ex->>'exercise_position')::integer is distinct from i or expected not between 1 and 100
      or jsonb_typeof(flags) is distinct from 'array' or jsonb_array_length(flags) <> expected then
      raise exception 'Invalid completion dimensions' using errcode = '22023';
    end if;
    for j in 0 .. expected - 1 loop
      if jsonb_typeof(flags->j) is distinct from 'boolean' then raise exception 'Completion flags must be boolean' using errcode = '22023'; end if;
    end loop;
  end loop;
  envelope := payload - array['completion','status','outcome','completed_at','current_index','revision','base_revision','injury_warning'];
  if not is_new then
    if old_session.snapshot <> envelope then
      raise exception 'Immutable prescription or source changed' using errcode = '22023';
    end if;
    if incoming_revision = old_session.revision then
      if new_status is distinct from old_session.status or payload->>'outcome' is distinct from old_session.outcome
        or ended is distinct from old_session.completed_at or (payload->>'current_index')::integer is distinct from old_session.current_index
        or exists(select 1 from public.workout_session_sets st where st.session_id = sid
          and st.completed is distinct from (payload->'completion'->st.exercise_position->>(st.set_number-1))::boolean) then
        raise exception 'Conflicting retry snapshot' using errcode = '40001';
      end if;
      return sid;
    end if;
    if old_session.status <> 'in_progress' or incoming_revision <= old_session.revision or base_revision <> old_session.revision then
      raise exception 'Session changed or ended. Reload and resolve the conflict.' using errcode = '40001';
    end if;
  else
    if exists(select 1 from public.workout_sessions s where s.user_id = caller and s.workout_day_id = did and s.status = 'in_progress') then
      raise exception 'Continue or explicitly end the existing session first' using errcode = '40001';
    end if;
    if not exists(select 1 from public.workout_days d join public.workout_plans p on p.id = d.workout_plan_id
      where d.id = did and p.id = pid and p.user_id = caller and p.status = 'active' and p.plan_type = 'training' and d.title = payload->>'day_title') then
      raise exception 'Source plan/day is not the active owned training prescription' using errcode = '42501';
    end if;
    if jsonb_array_length(payload->'source_prescription') <> (select count(*) from public.workout_day_exercises where workout_day_id = did) then
      raise exception 'Incomplete source snapshot' using errcode = '22023';
    end if;
    i := 0;
    for source in select e.*, l.name, l.equipment, l.target_muscle, l.instructions, l.secondary_muscles, l.body_part, l.gif_path, l.is_published
      from public.workout_day_exercises e join public.exercise_library l on l.id = e.exercise_id where e.workout_day_id = did order by e.sort_order loop
      source_json := payload->'source_prescription'->i;
      if not source.is_published or (source_json->>'source_workout_day_exercise_id')::uuid is distinct from source.id
        or (source_json->>'actual_exercise_library_id')::uuid is distinct from source.exercise_id
        or (source_json->>'sort_order')::integer is distinct from source.sort_order
        or (source_json->>'sets')::integer is distinct from source.sets
        or source_json->>'reps' is distinct from source.reps or (source_json->>'rest_seconds')::integer is distinct from source.rest_seconds
        or source_json->>'notes' is distinct from source.notes or source_json->>'name' is distinct from source.name
        or source_json->>'equipment' is distinct from source.equipment
        or source_json->'instructions' is distinct from to_jsonb(source.instructions)
        or (source_json->>'primary_target' is not null and source_json->>'primary_target' is distinct from source.target_muscle)
        or (location = 'home' and (source_json->>'primary_target' is distinct from source.target_muscle
          or source_json->'secondary_muscles' is distinct from to_jsonb(source.secondary_muscles)
          or source_json->>'body_part' is distinct from source.body_part or source_json->>'gif_path' is distinct from source.gif_path)) then
        raise exception 'Source snapshot does not match saved prescription' using errcode = '22023';
      end if;
      i := i + 1;
    end loop;
    select coalesce(array_agg(distinct l.target_muscle order by l.target_muscle), '{}') into original_targets
      from public.workout_day_exercises e join public.exercise_library l on l.id = e.exercise_id where e.workout_day_id = did and l.target_muscle is not null;
    -- Legacy Phase 2A gym drafts may have no target metadata, never home drafts.
    if (payload->'original_targets' <> to_jsonb(original_targets)) and not (location = 'gym' and payload->'original_targets' = '[]'::jsonb) then
      raise exception 'Original scheduled targets changed' using errcode = '22023';
    end if;
    if location = 'gym' and payload->'prescription' <> payload->'source_prescription' then
      raise exception 'Gym must preserve its original ordered prescription' using errcode = '22023';
    end if;
    if location = 'gym' and exists (select 1 from jsonb_array_elements(payload->'prescription') x
      where x->>'mapping_id' is not null or x->>'mapping_version' is not null or x->>'movement_pattern' is not null) then
      raise exception 'Gym cannot claim home mapping approval' using errcode = '22023';
    end if;
    if location = 'home' and ((select count(distinct value->>'actual_exercise_library_id') from jsonb_array_elements(payload->'prescription')) <> n
      or (select count(distinct value->>'source_workout_day_exercise_id') from jsonb_array_elements(payload->'prescription')) <> n) then
      raise exception 'Duplicate home alternatives' using errcode = '22023';
    end if;
  end if;
  for i in 0 .. n - 1 loop
    ex := payload->'prescription'->i;
    flags := payload->'completion'->i;
    expected := coalesce((ex->>'sets')::integer, 1);
    if (ex->>'exercise_position')::integer is distinct from i or expected not between 1 and 100
      or coalesce((ex->>'rest_seconds')::integer, 0) < 0 or jsonb_typeof(flags) is distinct from 'array'
      or jsonb_array_length(flags) <> expected then
      raise exception 'Invalid exercise position or set array' using errcode = '22023';
    end if;
    if is_new and location = 'home' then
      select * into mapping from public.workout_alternative_mappings where id = (ex->>'mapping_id')::uuid
        and version = (ex->>'mapping_version')::integer and review_status = 'approved' and enabled;
      if not found then raise exception 'Mapping is unavailable or unreviewed' using errcode = '42501'; end if;
      select e.*, l.target_muscle into source from public.workout_day_exercises e join public.exercise_library l on l.id = e.exercise_id
        where e.id = (ex->>'source_workout_day_exercise_id')::uuid and e.workout_day_id = did;
      if not found or source.exercise_id <> mapping.source_exercise_id or source.target_muscle is distinct from mapping.primary_target
        or (ex->>'actual_exercise_library_id')::uuid is distinct from mapping.alternative_exercise_id
        or not mapping.required_equipment <@ equipment or ex->>'movement_pattern' is distinct from mapping.movement_pattern
        or expected not between mapping.min_sets and mapping.sets
        or (payload->>'requested_duration_minutes' is null and expected <> mapping.sets)
        or ex->>'reps' is distinct from mapping.reps or (ex->>'rest_seconds')::integer is distinct from mapping.rest_seconds
        or (ex->>'sort_order')::integer is distinct from source.sort_order or ex->>'notes' is distinct from mapping.limitations then
        raise exception 'Home prescription is not authorized by its reviewed mapping' using errcode = '42501';
      end if;
      select * into actual from public.exercise_library where id = mapping.alternative_exercise_id and is_published;
      if not found or actual.target_muscle is distinct from mapping.primary_target or ex->>'primary_target' is distinct from actual.target_muscle
        or ex->>'name' is distinct from actual.name or ex->>'equipment' is distinct from actual.equipment
        or ex->'instructions' is distinct from to_jsonb(actual.instructions)
        or ex->'secondary_muscles' is distinct from to_jsonb(actual.secondary_muscles)
        or ex->>'body_part' is distinct from actual.body_part or ex->>'gif_path' is distinct from actual.gif_path then
        raise exception 'Actual home exercise is unpublished or its metadata is invalid' using errcode = '42501';
      end if;
      if not (mapping.required_equipment @> (case lower(trim(actual.equipment)) when 'dumbbells' then array['dumbbells'] when 'resistance bands' then array['bands'] when 'dumbbell' then array['dumbbells']
        when 'body weight' then array['bodyweight'] when 'bodyweight' then array['bodyweight']
        when 'band' then array['bands'] when 'resistance band' then array['bands'] else array['unsupported'] end)) then
        raise exception 'Alternative equipment is incompatible' using errcode = '42501';
      end if;
      estimated := estimated + expected * mapping.work_seconds_per_set + (expected-1) * mapping.rest_seconds + 30;
    end if;
    for j in 0 .. expected - 1 loop
      if jsonb_typeof(flags->j) is distinct from 'boolean' then raise exception 'Completion flags must be boolean' using errcode = '22023'; end if;
      all_done := all_done and (flags->>j)::boolean;
    end loop;
  end loop;
  if is_new and location = 'home' and ((payload->>'estimated_duration_seconds')::integer is distinct from estimated
    or (payload->>'requested_duration_minutes' is not null and estimated > (payload->>'requested_duration_minutes')::integer * 60)) then
    raise exception 'Home duration estimate is invalid or exceeds the requested budget' using errcode = '22023';
  end if;
  if (new_status = 'completed' and not all_done) or (payload->>'outcome' = 'partial' and all_done) then
    raise exception 'Completion status contradicts checked sets' using errcode = '22023';
  end if;
  if is_new then
    insert into public.workout_sessions(id,user_id,workout_plan_id,workout_day_id,day_title,started_at,completed_at,status,outcome,
      training_location,session_variant,equipment_selection,requested_duration_minutes,estimated_duration_seconds,original_targets,
      source_prescription,prescription,snapshot,current_index,revision,injury_warning)
    values(sid,caller,pid,did,payload->>'day_title',started,ended,new_status,payload->>'outcome',location,payload->>'session_variant',equipment,
      (payload->>'requested_duration_minutes')::integer,(payload->>'estimated_duration_seconds')::integer,
      array(select jsonb_array_elements_text(payload->'original_targets')),payload->'source_prescription',payload->'prescription',envelope,
      (payload->>'current_index')::integer,incoming_revision,coalesce((payload->>'injury_warning')::boolean,false));
    for i in 0 .. n - 1 loop
      ex := payload->'prescription'->i; flags := payload->'completion'->i;
      for j in 0 .. jsonb_array_length(flags) - 1 loop
        insert into public.workout_session_sets(session_id,exercise_position,source_workout_day_exercise_id,actual_exercise_library_id,mapping_id,mapping_version,set_number,completed)
        values(sid,i,(ex->>'source_workout_day_exercise_id')::uuid,(ex->>'actual_exercise_library_id')::uuid,
          (ex->>'mapping_id')::uuid,(ex->>'mapping_version')::integer,j+1,(flags->>j)::boolean);
      end loop;
    end loop;
  else
    -- Existing registered snapshots remain authorized after plan/mapping/catalog edits.
    -- Update flags only; nullable historical FKs are not reinserted or revalidated.
    update public.workout_sessions set completed_at = ended, status = new_status, outcome = payload->>'outcome',
      current_index = (payload->>'current_index')::integer, revision = incoming_revision,
      injury_warning = injury_warning or coalesce((payload->>'injury_warning')::boolean,false) where id = sid and user_id = caller;
    update public.workout_session_sets st set completed = (payload->'completion'->st.exercise_position->>(st.set_number-1))::boolean where st.session_id = sid;
  end if;
  return sid;
end;
$$;
revoke all on function arc_private.save_workout_session(jsonb) from public, anon, authenticated;
grant execute on function arc_private.save_workout_session(jsonb) to authenticated;
create function public.save_workout_session(payload jsonb) returns uuid
language sql security invoker set search_path = '' as $$ select arc_private.save_workout_session(payload); $$;
revoke all on function public.save_workout_session(jsonb) from public, anon, authenticated;
grant execute on function public.save_workout_session(jsonb) to authenticated;
commit;
