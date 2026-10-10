-- REVIEW ONLY. Requires the deployed Phase 2A/2B schema. No exercise seed.
-- Run as the migration owner in one transaction after separate deployment approval.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';

alter table public.workout_plans add column generation_metadata jsonb;
create unique index workout_plans_activation_key
  on public.workout_plans(user_id, (generation_metadata ->> 'activation_key'))
  where generation_metadata ->> 'source' = 'arc_generator';

-- Keep existing owner-scoped RLS/SELECT and administrative writes. The repository
-- has no client DML on these three tables (including its rehabilitation reader).
revoke insert, update, delete, truncate, references, trigger
  on public.workout_plans, public.workout_days, public.workout_day_exercises
  from public, anon, authenticated;
-- Remove explicit column grants too; table REVOKE alone does not remove them.
do $$
declare t text; cols text;
begin
  foreach t in array array['workout_plans','workout_days','workout_day_exercises'] loop
    select string_agg(quote_ident(attname), ',') into cols from pg_attribute
      where attrelid = ('public.' || t)::regclass and attnum > 0 and not attisdropped;
    execute format('revoke insert (%s), update (%s), references (%s) on public.%I from public, anon, authenticated', cols, cols, cols, t);
    if not (select relrowsecurity from pg_class where oid = ('public.' || t)::regclass)
       or has_table_privilege('authenticated','public.' || t,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       or has_any_column_privilege('authenticated','public.' || t,'INSERT,UPDATE,REFERENCES')
       or has_table_privilege('anon','public.' || t,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       or has_any_column_privilege('anon','public.' || t,'INSERT,UPDATE,REFERENCES') then
      raise exception 'ARC activation privilege preflight failed';
    end if;
  end loop;
end;
$$;

create function arc_private.activate_generated_training_plan(payload jsonb)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  key_id uuid; plan_id uuid; day_id uuid; old_plan public.workout_plans%rowtype;
  prior public.workout_plans%rowtype; cfg jsonb; d jsonb; e jsonb;
  lib public.exercise_library%rowtype;
  schedule int[]; splits text[]; seen_days int[] := '{}'; seen_ids uuid[];
  seen_orders int[]; muscles text[]; required_muscles text[];
  priority text[]; available_equipment text[]; muscle text; equip text;
  frequency int; day_index int := 0; weekday int; position int; set_count int;
  seconds int; estimated int; duration int; next_version int; level int;
  fingerprint text; replace_plan boolean;
  uuid_pattern constant text := '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
begin
  if caller is null then raise exception using errcode='42501', message='ARC_AUTH_REQUIRED'; end if;
  if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text) > 100000
     or (payload->>'user_id') is distinct from caller::text then
    raise exception using errcode='42501', message='ARC_OWNER_MISMATCH';
  end if;
  if not exists(select 1 from public.profiles where user_id=caller) then
    raise exception using errcode='42501', message='ARC_PROFILE_REQUIRED';
  end if;
  if (payload->>'idempotency_key') is null or (payload->>'idempotency_key') !~ uuid_pattern
     or payload->'contract_version' is distinct from '1'::jsonb
     or payload->>'plan_type' is distinct from 'training'
     or payload->>'rule_version' is distinct from 'arc-2c-direct-coverage-v2'
     or payload->>'generator_version' is distinct from 'arc-2c-generator-v1'
     or payload->'block_weeks' is distinct from '4'::jsonb
     or jsonb_typeof(payload->'replace_active') is distinct from 'boolean'
     or (payload - array['user_id','idempotency_key','contract_version','plan_type','rule_version','generator_version','block_weeks','config','days','replace_active','expected_active_plan_id','expected_active_version']) <> '{}'::jsonb then
    raise exception using errcode='22023', message='ARC_INVALID_CONTRACT';
  end if;
  key_id := (payload->>'idempotency_key')::uuid;
  fingerprint := md5((payload - 'idempotency_key')::text);
  replace_plan := (payload->>'replace_active')::boolean;
  perform pg_advisory_xact_lock(hashtextextended('arc_training_activation:' || caller::text, 0));
  select * into prior from public.workout_plans where user_id=caller
    and generation_metadata->>'source'='arc_generator'
    and generation_metadata->>'activation_key'=key_id::text;
  if found then
    if prior.generation_metadata->>'payload_hash' is distinct from fingerprint then
      raise exception using errcode='PT409', message='ARC_IDEMPOTENCY_CONFLICT';
    end if;
    -- A retry never reactivates an archived plan or depends on subsequent catalog edits.
    return jsonb_build_object('plan_id',prior.id,'version',prior.version,'status',prior.status,'replayed',true);
  end if;
  select * into old_plan from public.workout_plans where user_id=caller
    and plan_type='training' and status='active' for update;
  if old_plan.id is not null then
    if not replace_plan or payload->>'expected_active_plan_id' is distinct from old_plan.id::text
       or payload->'expected_active_version' is distinct from to_jsonb(old_plan.version) then
      raise exception using errcode='PT409', message='ARC_ACTIVE_PLAN_CONFLICT';
    end if;
  elsif replace_plan or payload ? 'expected_active_plan_id' or payload ? 'expected_active_version' then
    raise exception using errcode='PT409', message='ARC_ACTIVE_PLAN_CONFLICT';
  end if;
  if not replace_plan and (payload ? 'expected_active_plan_id' or payload ? 'expected_active_version') then
    raise exception using errcode='22023', message='ARC_INVALID_REPLACEMENT';
  end if;

  cfg := payload->'config';
  if jsonb_typeof(cfg) is distinct from 'object'
     or (cfg - array['goal','experience','location','weekdays','equipment','priorities','session_minutes','journey_days']) <> '{}'::jsonb
     or (cfg->>'goal') is null or cfg->>'goal' not in ('buildMuscle','loseFat','consistency')
     or (cfg->>'experience') is null or cfg->>'experience' not in ('beginner','intermediate','advanced')
     or cfg->>'location' is distinct from 'gym'
     or cfg->'journey_days' not in ('30'::jsonb,'60'::jsonb,'90'::jsonb)
     or jsonb_typeof(cfg->'session_minutes') is distinct from 'number'
     or coalesce(cfg->>'session_minutes','') !~ '^[0-9]{2,3}$'
     or jsonb_typeof(cfg->'weekdays') is distinct from 'array'
     or jsonb_typeof(cfg->'equipment') is distinct from 'array'
     or jsonb_typeof(cfg->'priorities') is distinct from 'array'
     or jsonb_typeof(payload->'days') is distinct from 'array' then
    raise exception using errcode='22023', message='ARC_INVALID_CONFIGURATION';
  end if;
  -- Explicit missing-value check: SQL NULL must not bypass a numeric enum check.
  if cfg->'journey_days' is null then raise exception using errcode='22023',message='ARC_INVALID_CONFIGURATION'; end if;
  duration := (cfg->>'session_minutes')::int;
  frequency := jsonb_array_length(cfg->'weekdays');
  if duration not between 10 and 120 or frequency not between 2 and 6
     or jsonb_array_length(payload->'days') <> frequency
     or jsonb_array_length(cfg->'equipment') not between 1 and 40
     or jsonb_array_length(cfg->'priorities') > 3
     or exists(select 1 from jsonb_array_elements(cfg->'weekdays') v where jsonb_typeof(v) <> 'number' or v::text !~ '^[1-7]$')
     or exists(select 1 from jsonb_array_elements(cfg->'equipment') v where jsonb_typeof(v) <> 'string' or v#>>'{}' !~ '^[a-z][a-z0-9_]{0,63}$')
     or exists(select 1 from jsonb_array_elements(cfg->'priorities') v where jsonb_typeof(v) <> 'string' or v#>>'{}' not in ('abs','adductors','biceps','calves','chest','shoulders','forearms','glutes','hamstrings','spinal_extensors','obliques','quadriceps','tibialis','trapezius','triceps','upper_back')) then
    raise exception using errcode='22023', message='ARC_INVALID_CONFIGURATION';
  end if;
  select array_agg(value::int order by value::int) into schedule from jsonb_array_elements_text(cfg->'weekdays');
  select coalesce(array_agg(value),'{}') into priority from jsonb_array_elements_text(cfg->'priorities');
  select array_agg(value) into available_equipment from jsonb_array_elements_text(cfg->'equipment');
  if (select count(distinct v) from unnest(schedule) v) <> frequency
     or (select count(distinct v) from unnest(priority) v) <> cardinality(priority)
     or (select count(distinct v) from unnest(available_equipment) v) <> cardinality(available_equipment) then
    raise exception using errcode='22023', message='ARC_DUPLICATE_CONFIGURATION';
  end if;
  splits := case frequency
    when 2 then array['Full body','Full body'] when 3 then array['Full body','Full body','Full body']
    when 4 then array['Upper','Lower','Upper','Lower'] when 5 then array['Upper','Lower','Push','Pull','Legs']
    when 6 then array['Push','Pull','Legs','Push','Pull','Legs'] end;
  level := case cfg->>'experience' when 'beginner' then 0 when 'intermediate' then 1 else 2 end;
  -- Lock library rows in stable order. FOR SHARE blocks publication/metadata UPDATE
  -- and DELETE until this transaction finishes; no stale catalog check/write gap.
  perform l.id from public.exercise_library l where l.id::text in
    (select lower(x->>'exercise_id') from jsonb_array_elements(payload->'days') y,
      lateral jsonb_array_elements(case when jsonb_typeof(y->'exercises')='array' then y->'exercises' else '[]'::jsonb end) x)
    order by l.id for share;
  select coalesce(max(version),0)+1 into next_version from public.workout_plans where user_id=caller and plan_type='training';
  insert into public.workout_plans(user_id,plan_type,name,status,version,generation_metadata)
    values(caller,'training','My ARC · ' || (cfg->>'journey_days') || ' days','draft',next_version,
      jsonb_build_object('source','arc_generator','activation_key',key_id,'payload_hash',fingerprint,
        'contract_version',1,'rule_version',payload->>'rule_version','generator_version',payload->>'generator_version',
        'block_weeks',4,'config',cfg,'frequency',frequency)) returning id into plan_id;
  for d in select value from jsonb_array_elements(payload->'days') loop
    day_index := day_index+1;
    if jsonb_typeof(d) is distinct from 'object'
       or (d-array['weekday','title','estimated_minutes','notes','exercises']) <> '{}'::jsonb
       or jsonb_typeof(d->'weekday') is distinct from 'number' or coalesce(d->>'weekday','') !~ '^[1-7]$'
       or jsonb_typeof(d->'estimated_minutes') is distinct from 'number' or coalesce(d->>'estimated_minutes','') !~ '^[0-9]{1,3}$'
       or jsonb_typeof(d->'exercises') is distinct from 'array'
       or d->>'title' is distinct from splits[day_index]
       or (d ? 'notes' and d->'notes' <> 'null'::jsonb and (jsonb_typeof(d->'notes') <> 'string' or length(d->>'notes')>1000)) then
      raise exception using errcode='22023', message='ARC_INVALID_DAY';
    end if;
    weekday := (d->>'weekday')::int;
    estimated := (d->>'estimated_minutes')::int;
    if weekday <> schedule[day_index] or weekday=any(seen_days)
       or jsonb_array_length(d->'exercises') not between 1 and 20 or estimated not between 1 and duration then
      raise exception using errcode='22023', message='ARC_INVALID_DAY';
    end if;
    seen_days := array_append(seen_days,weekday); seen_ids := '{}'; seen_orders := '{}'; muscles := '{}'; seconds := 300;
    required_muscles := case splits[day_index]
      when 'Push' then array['chest','shoulders','triceps'] when 'Pull' then array['upper_back','lats','biceps']
      when 'Upper' then array['chest','shoulders','triceps','upper_back','lats','biceps']
      when 'Full body' then array['chest','shoulders','triceps','upper_back','lats','biceps','quadriceps','hamstrings','glutes','calves','abs']
      else array['quadriceps','hamstrings','glutes','calves','abs'] end;
    insert into public.workout_days(workout_plan_id,weekday,title,estimated_minutes,notes)
      values(plan_id,weekday,splits[day_index],estimated,d->>'notes') returning id into day_id;
    for e in select value from jsonb_array_elements(d->'exercises') loop
      if jsonb_typeof(e) is distinct from 'object' or (e-array['exercise_id','sort_order','sets','reps','rest_seconds','notes']) <> '{}'::jsonb
         or coalesce(e->>'exercise_id','') !~ uuid_pattern
         or jsonb_typeof(e->'sort_order') is distinct from 'number' or coalesce(e->>'sort_order','') !~ '^[0-9]{1,2}$'
         or jsonb_typeof(e->'sets') is distinct from 'number' or coalesce(e->>'sets','') !~ '^[1-9][0-9]?$'
         or jsonb_typeof(e->'rest_seconds') is distinct from 'number' or coalesce(e->>'rest_seconds','') !~ '^[0-9]{1,3}$'
         or jsonb_typeof(e->'reps') is distinct from 'string' or length(btrim(e->>'reps')) not between 1 and 40
         or (e ? 'notes' and e->'notes' <> 'null'::jsonb and (jsonb_typeof(e->'notes') <> 'string' or length(e->>'notes')>1000)) then
        raise exception using errcode='22023', message='ARC_INVALID_PRESCRIPTION';
      end if;
      position := (e->>'sort_order')::int; set_count := (e->>'sets')::int;
      if position <> cardinality(seen_ids) or position=any(seen_orders) or (e->>'exercise_id')::uuid=any(seen_ids)
         or set_count>10 or (e->>'rest_seconds')::int>600 then
        raise exception using errcode='22023', message='ARC_INVALID_PRESCRIPTION';
      end if;
      select * into lib from public.exercise_library where id=(e->>'exercise_id')::uuid;
      if not found or not lib.is_published or length(btrim(lib.name))=0
         or cardinality(lib.instructions)=0 or exists(select 1 from unnest(lib.instructions) i where i is null or btrim(i)='')
         or lib.target_muscle is null or lib.equipment is null then
        raise exception using errcode='22023', message='ARC_EXERCISE_UNAVAILABLE';
      end if;
      muscle := case lower(btrim(lib.target_muscle))
        when 'pectorals' then 'chest' when 'delts' then 'shoulders' when 'deltoids' then 'shoulders'
        when 'upper-back' then 'upper_back' when 'upper back' then 'upper_back'
        when 'lower-back' then 'spinal_extensors' when 'lower back' then 'spinal_extensors' when 'spine' then 'spinal_extensors'
        when 'gluteal' then 'glutes' when 'hamstring' then 'hamstrings' when 'quads' then 'quadriceps'
        when 'forearm' then 'forearms' when 'traps' then 'trapezius' else lower(btrim(lib.target_muscle)) end;
      equip := case lower(btrim(lib.equipment)) when 'body weight' then 'bodyweight' when 'dumbbell' then 'dumbbells'
        else replace(lower(btrim(lib.equipment)), ' ', '_') end;
      if muscle !~ '^[a-z][a-z0-9_]{0,63}$' or equip !~ '^[a-z][a-z0-9_]{0,63}$' or not equip=any(available_equipment)
         or (lib.difficulty is not null and (lower(btrim(lib.difficulty)) not in ('beginner','intermediate','advanced')
           or array_position(array['beginner','intermediate','advanced'],lower(btrim(lib.difficulty)))-1>level)) then
        raise exception using errcode='22023', message='ARC_EXERCISE_UNAVAILABLE';
      end if;
      seen_ids := array_append(seen_ids,lib.id); seen_orders := array_append(seen_orders,position); muscles := array_append(muscles,muscle);
      seconds := seconds + set_count*60+(set_count-1)*(e->>'rest_seconds')::int+30;
      insert into public.workout_day_exercises(workout_day_id,exercise_id,sort_order,sets,reps,rest_seconds,notes)
        values(day_id,lib.id,position,set_count,e->>'reps',(e->>'rest_seconds')::int,e->>'notes');
    end loop;
    if not required_muscles <@ muscles or estimated <> (seconds+59)/60 or seconds > duration*60 then
      raise exception using errcode='22023', message='ARC_INVALID_COVERAGE_OR_DURATION';
    end if;
  end loop;
  if old_plan.id is not null then update public.workout_plans set status='archived' where id=old_plan.id; end if;
  update public.workout_plans set status='active' where id=plan_id;
  return jsonb_build_object('plan_id',plan_id,'version',next_version,'status','active','replayed',false);
end;
$$;

create function public.activate_generated_training_plan(payload jsonb)
returns jsonb language sql security invoker set search_path = ''
as $$ select arc_private.activate_generated_training_plan(payload); $$;
revoke all on function arc_private.activate_generated_training_plan(jsonb), public.activate_generated_training_plan(jsonb) from public, anon, authenticated;
grant execute on function arc_private.activate_generated_training_plan(jsonb), public.activate_generated_training_plan(jsonb) to authenticated;
-- arc_private schema USAGE without CREATE is already required by save_workout_session.
notify pgrst, 'reload schema';
commit;
