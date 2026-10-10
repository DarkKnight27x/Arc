"""LOCAL ONLY. Real exported catalog UUIDs, hosted-shaped schema, no hosted users.
Requires owned disposable Postgres on 127.0.0.1:55439. Writes a non-private local
E2E result to docs/phase2c_checkpoint3_local_e2e.json for Flutter contract tests.
"""
import copy
import json
import os
import subprocess
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PSQL = Path(r'C:\Program Files\PostgreSQL\18\bin\psql.exe')
DATABASE = 'arc_cp3_' + uuid.uuid4().hex[:12]
MIGRATION = ROOT/'supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql'
q = lambda v: "'"+str(v).replace("'", "''")+"'"
checks = []


def sql(statement, owner=None, role='authenticated', error=None, database=None):
    if owner is not None or role == 'anon':
        statement = 'begin; set local role '+role+'; set local request.jwt.claim.sub='+q(owner or '')+'; '+statement+'; commit;'
    result = subprocess.run([str(PSQL), '-X', '-qAt', '-h', '127.0.0.1', '-p', '55439', '-U', 'arc_test',
        '-d', database or DATABASE, '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose', '-f', '-'],
        input=statement, capture_output=True, text=True, encoding='utf-8',
        env={**os.environ, 'PGCLIENTENCODING': 'UTF8'})
    if error:
        assert result.returncode != 0 and error in result.stderr, (error, result.stderr)
    else:
        assert result.returncode == 0, result.stderr
    return result.stdout.strip()


def user():
    owner = str(uuid.uuid4())
    sql('insert into auth.users values('+q(owner)+'); insert into public.profiles values('+q(owner)+')')
    return owner


def activation(owner, case=0):
    c = cases[case]
    p = c['preview']
    return dict(user_id=owner, idempotency_key=str(uuid.uuid4()), contract_version=1, plan_type='training',
        rule_version=p['rule_version'], generator_version='arc-2c-generator-v1', block_weeks=p['block_weeks'], replace_active=False,
        config=dict(goal='buildMuscle', experience='beginner', location='gym', weekdays=c['weekdays'],
            equipment=c['equipment'], priorities=c['priorities'], session_minutes=c['session_minutes'], journey_days=p['journey_days']),
        days=[dict(weekday=d['weekday'], title=d['title'], estimated_minutes=d['estimated_minutes'],
            exercises=[dict(exercise_id=e['exercise_id'], sort_order=i, sets=e['sets'], reps=e['reps'],
                rest_seconds=e['rest_seconds']) for i, e in enumerate(d['exercises'])]) for d in p['days']])


def activate(payload, owner=None, error=None, role='authenticated', private=False):
    result = sql('select '+('arc_private' if private else 'public')+'.activate_generated_training_plan('+q(json.dumps(payload))+'::jsonb)',
        owner=owner or payload['user_id'], error=error, role=role)
    return json.loads(result) if not error else None


def assert_empty(owner):
    assert sql('select count(*) from public.workout_plans where user_id='+q(owner)) == '0'


def replacement(owner, old):
    p = activation(owner)
    p.update(replace_active=True, expected_active_plan_id=old['plan_id'], expected_active_version=old['version'])
    return p


sql('create database '+DATABASE, database='postgres')
try:
    sql("""
    do $$begin
      if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
      if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
      if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
    end$$;
    create schema auth; grant usage on schema auth to authenticated,anon;
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    create table auth.users(id uuid primary key);
    create table public.profiles(user_id uuid primary key references auth.users(id));
    create type public.plan_type as enum ('training','rehab');
    create type public.plan_status as enum ('draft','active','archived');
    create table public.exercise_library(id uuid primary key default gen_random_uuid(),source_external_id text unique,
      name text not null,body_part text not null,target_muscle text,secondary_muscles text[] not null default '{}',
      equipment text not null,difficulty text,instructions text[] not null default '{}',gif_path text,tags text[] not null default '{}',
      is_published boolean not null default true,created_at timestamptz not null default now());
    create table public.workout_plans(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(user_id) on delete cascade,
      plan_type public.plan_type not null default 'training',name text not null,status public.plan_status not null default 'draft',
      version integer not null default 1 check(version>0),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
    create unique index one_active_plan_per_type on public.workout_plans(user_id,plan_type) where status='active';
    create function public.set_updated_at() returns trigger language plpgsql as $$begin new.updated_at=now(); return new; end$$;
    create trigger workout_plans_updated_at before update on public.workout_plans for each row execute function public.set_updated_at();
    create table public.workout_days(id uuid primary key default gen_random_uuid(),workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
      weekday smallint not null check(weekday between 1 and 7),title text not null,estimated_minutes smallint check(estimated_minutes>0),notes text,
      unique(workout_plan_id,weekday));
    create table public.workout_day_exercises(id uuid primary key default gen_random_uuid(),workout_day_id uuid not null references public.workout_days(id) on delete cascade,
      exercise_id uuid not null references public.exercise_library(id),sort_order smallint not null check(sort_order>=0),sets smallint check(sets>0),
      reps text,rest_seconds int check(rest_seconds>=0),notes text,unique(workout_day_id,sort_order));
    create index on public.workout_day_exercises(exercise_id);
    alter table public.workout_plans enable row level security;
    alter table public.workout_days enable row level security;
    alter table public.workout_day_exercises enable row level security;
    alter table public.exercise_library enable row level security;
    create policy plans_owner on public.workout_plans for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
    create policy days_owner on public.workout_days for all to authenticated
      using(exists(select 1 from public.workout_plans p where p.id=workout_plan_id and p.user_id=auth.uid()))
      with check(exists(select 1 from public.workout_plans p where p.id=workout_plan_id and p.user_id=auth.uid()));
    create policy exercises_owner on public.workout_day_exercises for all to authenticated
      using(exists(select 1 from public.workout_days d join public.workout_plans p on p.id=d.workout_plan_id where d.id=workout_day_id and p.user_id=auth.uid()))
      with check(exists(select 1 from public.workout_days d join public.workout_plans p on p.id=d.workout_plan_id where d.id=workout_day_id and p.user_id=auth.uid()));
    create policy published on public.exercise_library for select to anon,authenticated using(is_published);
    grant all on public.workout_plans,public.workout_days,public.workout_day_exercises,public.exercise_library to anon,authenticated,service_role;
    grant insert(name),update(status) on public.workout_plans to authenticated;
    alter default privileges in schema public grant all on tables to anon,authenticated,service_role;
    alter default privileges in schema public grant execute on functions to anon,authenticated;
    """)
    catalog = json.loads((ROOT/'docs/curated_catalog_v1_public_api_catalog.json').read_text(encoding='utf-8'))
    byid = {r['id']: r for r in catalog}
    def val(v):
        if v is None: return 'null'
        if isinstance(v, bool): return 'true' if v else 'false'
        if isinstance(v, list): return 'array['+','.join(q(x) for x in v)+']::text[]'
        return q(v)
    for r in catalog:
        cols = ['id','source_external_id','name','body_part','target_muscle','secondary_muscles','equipment','difficulty','instructions','gif_path','tags','is_published']
        sql('insert into public.exercise_library('+','.join(cols)+') values('+','.join(val(r.get(c)) for c in cols)+')')
    sql((ROOT/'docs/sql/workout_training_variants.sql').read_text(encoding='utf-8-sig'))
    sql(MIGRATION.read_text(encoding='utf-8-sig'))
    cases = json.loads((ROOT/'docs/curated_catalog_v1_real_previews.json').read_text(encoding='utf-8'))['cases']
    for table in ['workout_plans','workout_days','workout_day_exercises']:
        for role in ['anon','authenticated']:
            for privilege in ['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']:
                assert sql('select has_table_privilege('+q(role)+','+q('public.'+table)+','+q(privilege)+')') == 'f'
            assert sql('select has_any_column_privilege('+q(role)+','+q('public.'+table)+',\'INSERT,UPDATE,REFERENCES\')') == 'f'
        assert sql('select has_table_privilege(\'service_role\','+q('public.'+table)+',\'INSERT,UPDATE,DELETE\')') == 't'
    for schema in ['public','arc_private']:
        f = schema+'.activate_generated_training_plan(jsonb)'
        assert sql('select has_function_privilege(\'anon\','+q(f)+',\'EXECUTE\')') == 'f'
        assert sql('select has_function_privilege(\'authenticated\','+q(f)+',\'EXECUTE\')') == 't'
        assert sql('select proconfig @> array[\'search_path=""\'] from pg_proc where oid='+q(f)+'::regprocedure') == 't'
        assert sql('select prosecdef from pg_proc where oid='+q(f)+'::regprocedure') == ('t' if schema == 'arc_private' else 'f')
    checks.append('table/column ACL hardening, RLS retained, administrative writes retained, RPC exposure/search_path')

    owner, other = user(), user()
    p = activation(owner)
    first = activate(p)
    assert first['version'] == 1 and first['status'] == 'active' and not first['replayed']
    again = activate(p, private=True)
    assert again['plan_id'] == first['plan_id'] and again['replayed']
    bad = copy.deepcopy(p); bad['config']['journey_days'] = 60
    activate(bad, error='PT409')
    activate(activation(owner), error='PT409')
    activate(p, owner=other, error='42501')
    activate(p, role='anon', error='42501')
    sql('select public.activate_generated_training_plan('+q(json.dumps(p))+'::jsonb)',owner='',error='42501')
    sql('select public.activate_generated_training_plan('+q(json.dumps(p))+'::jsonb)', role='anon', error='42501')
    for table in ['workout_plans','workout_days','workout_day_exercises']:
        assert sql('select count(*) from public.'+table, owner=other) == '0'
        for statement in ['delete from public.'+table, 'truncate public.'+table]:
            sql(statement, owner=owner, error='42501')
    sql('update public.workout_plans set status=\'archived\' where id='+q(first['plan_id']), owner=owner, error='42501')
    sql('insert into public.workout_plans(user_id,name) values('+q(owner)+',\'bypass\')', owner=owner, error='42501')
    foreign = activate(activation(other))
    forged = replacement(owner,first); forged['expected_active_plan_id'] = foreign['plan_id']
    activate(forged,error='PT409')
    invalid_uppercase = activation(user()); invalid_uppercase['days'][0]['exercises'][0]['exercise_id'] = eid_upper = invalid_uppercase['days'][0]['exercises'][0]['exercise_id'].upper()
    activate(invalid_uppercase)  # UUID spelling is canonicalized; same current catalog row
    checks.append('successful activation, same-key replay, changed-payload conflict, active-plan conflict, caller mismatch, anonymous denial, cross-owner reads and direct writes denied')

    def invalid(change, error='22023'):
        u = user(); bad = activation(u); change(bad); activate(bad, error=error); assert_empty(u)
    invalid(lambda p: p.update(days=[]))
    invalid(lambda p: p['days'][1].update(weekday=8))
    invalid(lambda p: p['days'][1].update(weekday=1))
    invalid(lambda p: p['days'][0].update(exercises=[]))
    invalid(lambda p: p['config'].update(weekdays=[1,1]))
    invalid(lambda p: p['config'].pop('journey_days'))
    invalid(lambda p: p['config'].update(journey_days=None))
    invalid(lambda p: p['config'].update(location='home'))
    invalid(lambda p: p['days'][0]['exercises'][0].update(exercise_id='not-a-uuid'))
    invalid(lambda p: p['days'][0]['exercises'][0].update(exercise_id=str(uuid.uuid4())))
    invalid(lambda p: p['days'][0]['exercises'][1].update(exercise_id=p['days'][0]['exercises'][0]['exercise_id']))
    invalid(lambda p: p['days'][0]['exercises'][1].update(sort_order=0))
    invalid(lambda p: p['days'][0]['exercises'][0].update(sets=0))
    invalid(lambda p: p['days'][0]['exercises'][0].update(reps=' '))
    invalid(lambda p: p['days'][0]['exercises'][0].update(rest_seconds=-1))
    invalid(lambda p: p['days'][0]['exercises'][0].update(user_id=other))
    invalid(lambda p: p['days'][0].update(estimated_minutes=1))
    invalid(lambda p: p['config'].update(equipment=['bodyweight']))
    eid = p['days'][0]['exercises'][0]['exercise_id']
    sql('update public.exercise_library set is_published=false where id='+q(eid))
    invalid(lambda p: None)
    assert activate(p)['plan_id'] == first['plan_id']  # committed retry remains resolvable
    sql('update public.exercise_library set is_published=true where id='+q(eid))
    sql('update public.exercise_library set difficulty=\'advanced\' where id='+q(eid))
    invalid(lambda p: None)
    sql('update public.exercise_library set difficulty=null where id='+q(eid))
    checks.append('20 invalid/stale prescriptions and schedules reject atomically; committed retry survives publication change')

    race_owner = user(); a = activation(race_owner)
    with ThreadPoolExecutor(2) as pool:
        results = list(pool.map(lambda _: activate(a), range(2)))
    assert {r['plan_id'] for r in results} == {results[0]['plan_id']} and sum(r['replayed'] for r in results) == 1
    race_owner = user(); a, b = activation(race_owner), activation(race_owner)
    def racing(p):
        try: return activate(p)
        except AssertionError as e:
            assert 'PT409' in str(e); return None
    with ThreadPoolExecutor(2) as pool:
        results = list(pool.map(racing, [a,b]))
    assert sum(r is not None for r in results) == 1
    assert sql('select count(*) from public.workout_plans where user_id='+q(race_owner)) == '1'
    existing = next(r for r in results if r is not None)
    with ThreadPoolExecutor(2) as pool:
        replacements = list(pool.map(racing, [replacement(race_owner,existing),replacement(race_owner,existing)]))
    assert sum(r is not None for r in replacements) == 1
    assert sql('select count(*) from public.workout_plans where user_id='+q(race_owner)+" and status='active'") == '1'
    assert sql('select count(*) from public.workout_plans where user_id='+q(race_owner)) == '2'
    checks.append('concurrent same-key requests converge; different keys and competing replacements serialize with one conflict')

    # Trigger-induced failures occur after actual inserts, not merely validation.
    for table, predicate in [('workout_days','new.weekday=4'), ('workout_day_exercises','new.sort_order=1')]:
        sql('create function public.cp3_test_failure() returns trigger language plpgsql as $$begin if '+predicate+
            " then raise exception using errcode='P0001',message='fixture injected failure'; end if; return new; end$$;"+
            'create trigger cp3_failure before insert on public.'+table+' for each row execute function public.cp3_test_failure()')
        u = user(); activate(activation(u), error='P0001'); assert_empty(u)
        activate(replacement(owner, first), error='P0001')
        assert sql('select count(*) from public.workout_plans where user_id='+q(owner)) == '1'
        assert sql('select status from public.workout_plans where id='+q(first['plan_id'])) == 'active'
        sql('drop trigger cp3_failure on public.'+table+'; drop function public.cp3_test_failure()')
    checks.append('day-2 and exercise-row failures roll back both first activation and replacement')

    # Query the same nested relation shape that WorkoutService reads in Train.
    relation_query = """select coalesce(jsonb_agg(to_jsonb(d)||jsonb_build_object('workout_day_exercises',(
      select jsonb_agg(to_jsonb(x)||jsonb_build_object('exercise_library',to_jsonb(l)) order by x.sort_order)
      from public.workout_day_exercises x join public.exercise_library l on l.id=x.exercise_id where x.workout_day_id=d.id
    )) order by d.weekday),'[]'::jsonb) from public.workout_days d where d.workout_plan_id="""+q(first['plan_id'])
    relations = json.loads(sql(relation_query, owner=owner))
    assert len(relations) == len(p['days'])
    for saved, planned in zip(relations,p['days']):
        assert saved['weekday'] == planned['weekday'] and saved['estimated_minutes'] == planned['estimated_minutes']
        for x,e in zip(saved['workout_day_exercises'],planned['exercises']):
            assert all(x[k] == e[k] for k in ['exercise_id','sets','reps','rest_seconds','sort_order'])
    day = relations[0]
    moves = []
    for i,x in enumerate(day['workout_day_exercises']):
        l = x['exercise_library']
        moves.append(dict(source_workout_day_exercise_id=x['id'],actual_exercise_library_id=l['id'],exercise_position=i,
            name=l['name'],equipment=l['equipment'],sets=x['sets'],reps=x['reps'],rest_seconds=x['rest_seconds'],sort_order=x['sort_order'],
            notes=x['notes'],gif_url=None,gif_path=l['gif_path'],instructions=l['instructions'],primary_target=l['target_muscle'],
            secondary_muscles=l['secondary_muscles'],body_part=l['body_part'],mapping_id=None,mapping_version=None,movement_pattern=None))
    session = dict(id=str(uuid.uuid4()),user_id=owner,workout_plan_id=first['plan_id'],workout_day_id=day['id'],day_title=day['title'],
        started_at='2026-10-10T00:00:00Z',completed_at=None,status='in_progress',outcome=None,current_index=0,injury_warning=False,
        contract_version=2,training_location='gym',session_variant='gym_original',equipment_selection=[],requested_duration_minutes=None,
        estimated_duration_seconds=None,original_targets=sorted({m['primary_target'] for m in moves}),source_prescription=moves,prescription=moves,
        revision=0,base_revision=-1,completion=[[False]*m['sets'] for m in moves])
    def save(s, error=None):
        return sql('select public.save_workout_session('+q(json.dumps(s))+'::jsonb)', owner=owner, error=error)
    save(session)
    ended = copy.deepcopy(session)
    ended.update(status='completed',outcome='completed',completed_at='2026-10-10T00:45:00Z',revision=1,base_revision=0)
    ended['completion'] = [[True]*m['sets'] for m in moves]
    save(ended)
    # Source is still active here; rejection must be the missing reviewed mapping,
    # rather than merely the archived-source check after replacement.
    home = copy.deepcopy(session); home['id']=str(uuid.uuid4()); home.update(training_location='home',session_variant='home_curated',equipment_selection=['bodyweight'])
    save(home,error='42501')
    other_day_session = copy.deepcopy(session)
    other_day_session.update(id=str(uuid.uuid4()),workout_day_id=relations[1]['id'],day_title=relations[1]['title'])
    other_moves = copy.deepcopy(moves)
    for move, row in zip(other_moves,relations[1]['workout_day_exercises']):
        move['source_workout_day_exercise_id'] = row['id']
    other_day_session.update(source_prescription=other_moves,prescription=other_moves)
    save(other_day_session)
    counts_before = sql('select count(*) from public.workout_session_sets where session_id='+q(session['id']))
    old_rows = sql('select count(*) from public.workout_day_exercises x join public.workout_days d on d.id=x.workout_day_id where d.workout_plan_id='+q(first['plan_id']))
    stale = replacement(owner,first); stale['expected_active_version'] += 1; activate(stale,error='PT409')
    new_payload = replacement(owner,first); second = activate(new_payload)
    assert second['version'] == 2
    assert sql('select status from public.workout_plans where id='+q(first['plan_id'])) == 'archived'
    assert sql('select count(*) from public.workout_day_exercises x join public.workout_days d on d.id=x.workout_day_id where d.workout_plan_id='+q(first['plan_id'])) == old_rows
    assert sql('select count(*) from public.workout_session_sets where session_id='+q(session['id'])) == counts_before
    assert sql('select workout_plan_id from public.workout_sessions where id='+q(session['id'])) == first['plan_id']
    assert activate(p)['status'] == 'archived'  # never reactivates old successful attempt
    save(ended)  # terminal duplicate/retry still accepted for archived history
    other_day_session.update(status='completed',outcome='completed',completed_at='2026-10-10T00:45:00Z',revision=1,base_revision=0,
        completion=[[True]*m['sets'] for m in other_moves])
    save(other_day_session)  # already-registered in-progress history can finish after archive
    checks.append('real UUID prescription roundtrip, gym_original session save/completion, explicit replacement/version conflict, archived FK history and terminal retry preserved; unapproved Home denied')

    # Every successful exported real-catalog preview fits the server contract.
    for i,c in enumerate(cases):
        if c['available']: activate(activation(user(),i))
    checks.append('all nine available real-catalog preview cases activate locally')
    artifact = dict(local_only=True,postgres_version=sql('show server_version'),migration=str(MIGRATION.relative_to(ROOT)),
        checks=checks,activation_payload=p,result=first,relations=relations,gym_session_payload=session)
    (ROOT/'docs/phase2c_checkpoint3_local_e2e.json').write_text(json.dumps(artifact,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('PASS: '+str(len(checks))+' integration groups; owned disposable database; real catalog UUIDs; no hosted writes')
    for check in checks: print('PASS: '+check)
finally:
    assert DATABASE.startswith('arc_cp3_') and len(DATABASE) == len('arc_cp3_')+12
    sql('drop database '+DATABASE+' with (force)',database='postgres')
