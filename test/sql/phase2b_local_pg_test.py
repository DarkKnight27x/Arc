"""Disposable LOCAL Postgres contract tests. Never targets a Supabase project.
Requires a throwaway cluster already listening on 127.0.0.1:55439.
Creates synthetic fixture roles/tables in a fresh local database for each run.
"""
import copy, json, os, subprocess, uuid
import argparse
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--schema',type=Path,default=ROOT/'docs/sql/workout_training_variants.sql')
parser.add_argument('--seed',type=Path,default=ROOT/'docs/sql/home_mapping_seed_proposal.sql')
args=parser.parse_args()
assert args.schema.resolve().is_relative_to(ROOT) and args.seed.resolve().is_relative_to(ROOT)
PSQL = Path(r'C:\Program Files\PostgreSQL\18\bin\psql.exe')
USER_A='00000000-0000-0000-0000-000000000001'
USER_B='00000000-0000-0000-0000-000000000002'
PLAN='20000000-0000-0000-0000-000000000001'
DAY='30000000-0000-0000-0000-000000000001'
SRC1='10000000-0000-0000-0000-000000000001'
SRC2='10000000-0000-0000-0000-000000000002'
DATABASE = 'arc_phase2b_' + uuid.uuid4().hex[:12]
q=lambda value: "'"+str(value).replace("'","''")+"'"

def sql(statement, user=None, role='authenticated', error=None, database=None):
    if user is not None or role == 'anon':
        statement='begin; set local role '+role+'; set local request.jwt.claim.sub = '+q(user or '')+'; '+statement+'; commit;'
    result=subprocess.run([str(PSQL),'-X','-h','127.0.0.1','-p','55439','-U','arc_test','-d',database or DATABASE,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-At','-f','-'],input=statement,capture_output=True,text=True,encoding='utf-8',env={**os.environ,'PGCLIENTENCODING':'UTF8'})
    if error:
        assert result.returncode != 0 and error in result.stderr, (error,result.stdout,result.stderr)
    else:
        assert result.returncode == 0, result.stderr
    return result.stdout.strip()

def save(payload,user=USER_A,error=None):
    return sql('select public.save_workout_session('+q(json.dumps(payload))+'::jsonb)',user=user,error=error)

def count(): return sql('select count(*) from public.workout_sessions')

schema="""
do $$begin if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if; if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if; end$$;
create schema auth; grant usage on schema auth to authenticated,anon;
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table auth.users(id uuid primary key);
create table public.profiles(user_id uuid primary key references auth.users(id));
create table public.exercise_library(id uuid primary key,name text not null,body_part text not null,target_muscle text,secondary_muscles text[] not null,equipment text not null,difficulty text,instructions text[] not null,gif_path text,tags text[] not null,is_published boolean not null);
create table public.workout_plans(id uuid primary key,user_id uuid references public.profiles(user_id),plan_type text,status text,version integer,updated_at timestamptz);
create table public.workout_days(id uuid primary key,workout_plan_id uuid references public.workout_plans(id) on delete cascade,weekday integer,title text,estimated_minutes integer,notes text);
create table public.workout_day_exercises(id uuid primary key,workout_day_id uuid references public.workout_days(id) on delete cascade,exercise_id uuid references public.exercise_library(id),sort_order integer,sets integer,reps text,rest_seconds integer,notes text);
"""
sql('create database '+DATABASE,database='postgres')
sql(schema)
# Mirror the live project's broad public default grants; the proposal must revoke them.
sql('alter default privileges in schema public grant all on tables to anon,authenticated; alter default privileges in schema public grant execute on functions to anon,authenticated')
for user in [USER_A,USER_B]: sql('insert into auth.users values('+q(user)+'); insert into public.profiles values('+q(user)+')')
catalog=json.loads((ROOT/'docs/exercise_catalog_phase2b.json').read_text(encoding='utf-8'))
byid={x['id']:x for x in catalog}
for ex in catalog:
    columns=['id','name','body_part','target_muscle','secondary_muscles','equipment','difficulty','instructions','gif_path','tags','is_published']
    def val(value):
        if value is None:return 'null'
        if isinstance(value,list):return 'array['+','.join(q(x) for x in value)+']::text[]'
        if isinstance(value,bool):return 'true' if value else 'false'
        return q(value)
    sql('insert into public.exercise_library('+','.join(columns)+') values('+','.join(val(ex[k]) for k in columns)+')')
sql('insert into public.workout_plans values('+','.join([q(PLAN),q(USER_A),q('training'),q('active'),'1','now()'])+'); insert into public.workout_days values('+','.join([q(DAY),q(PLAN),'1',q('Saved workout'),'35',q('Day notes')])+')')
sources=[(SRC1,'12fd053b-c9d7-4de4-b9f5-61c0f6d8afdf'),(SRC2,'39839277-9273-4e7d-bfbc-200f2c1b737a')]
for i,(src,eid) in enumerate(sources): sql('insert into public.workout_day_exercises values('+','.join([q(src),q(DAY),q(eid),str(i),'3',q('10'),'75',q('Saved cue')])+')')
sql(args.schema.read_text(encoding='utf-8-sig'))
sql(args.seed.read_text(encoding='utf-8-sig'))
mappings=json.loads((ROOT/'docs/home_mapping_proposal.json').read_text())
assert sql("select count(*) from public.workout_alternative_mappings where review_status='proposed' and not enabled")=='6'
assert sql("select count(*) from public.workout_alternative_mappings",user=USER_A).endswith('0\nCOMMIT')
for table in ['workout_sessions','workout_session_sets','workout_alternative_mappings']:
    assert sql("select relrowsecurity from pg_class where oid="+q('public.'+table)+"::regclass")=='t'
    for role in ['anon','authenticated']:
        for privilege in ['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']:
            assert sql('select has_table_privilege('+q(role)+','+q('public.'+table)+','+q(privilege)+')')=='f'
        assert sql('select has_table_privilege('+q(role)+','+q('public.'+table)+','+q('SELECT')+')')==('t' if role=='authenticated' else 'f')
for function in ['public.save_workout_session(jsonb)','arc_private.save_workout_session(jsonb)']:
    assert sql('select has_function_privilege('+q('anon')+','+q(function)+','+q('EXECUTE')+')')=='f'
    assert sql('select has_function_privilege('+q('authenticated')+','+q(function)+','+q('EXECUTE')+')')=='t'
    assert sql('select proconfig @> array[\'search_path=""\'] from pg_proc where oid='+q(function)+'::regprocedure')=='t'
assert sql("select prosecdef from pg_proc where oid='public.save_workout_session(jsonb)'::regprocedure")=='f'
assert sql("select prosecdef from pg_proc where oid='arc_private.save_workout_session(jsonb)'::regprocedure")=='t'
assert sql("select has_schema_privilege('authenticated','arc_private','CREATE')")=='f'
assert sql("select has_schema_privilege('anon','arc_private','USAGE')")=='f'
assert sql("select has_function_privilege('authenticated','arc_private.freeze_mapping()','EXECUTE')")=='f'

def move(src,ex,position,sets=3,reps='10',rest=75,notes='Saved cue',mapping=None):
    return dict(source_workout_day_exercise_id=src,actual_exercise_library_id=ex['id'],exercise_position=position,
      name=ex['name'],equipment=ex['equipment'],sets=sets,reps=reps,rest_seconds=rest,sort_order=position,notes=notes,
      gif_url=None,gif_path=ex['gif_path'],instructions=ex['instructions'],primary_target=ex['target_muscle'],
      secondary_muscles=ex['secondary_muscles'],body_part=ex['body_part'],mapping_id=None if not mapping else mapping['id'],
      mapping_version=None if not mapping else mapping['version'],movement_pattern=None if not mapping else mapping['movement_pattern'])
source_moves=[move(src,byid[eid],i) for i,(src,eid) in enumerate(sources)]
prescription=[]
for i,(src,eid) in enumerate(sources):
    mapping=next(m for m in mappings if m['source_exercise_id']==eid)
    prescription.append(move(src,byid[mapping['alternative_exercise_id']],i,mapping['sets'],mapping['reps'],mapping['rest_seconds'],mapping['limitations'],mapping))
payload=dict(id=str(uuid.uuid4()),user_id=USER_A,workout_plan_id=PLAN,workout_day_id=DAY,day_title='Saved workout',
 started_at='2026-10-09T10:00:00Z',completed_at=None,status='in_progress',outcome=None,current_index=0,
 injury_warning=False,contract_version=2,training_location='home',session_variant='home_curated',
 equipment_selection=['bodyweight','dumbbells'],requested_duration_minutes=None,estimated_duration_seconds=630,
 original_targets=['biceps','delts'],source_prescription=source_moves,prescription=prescription,revision=0,base_revision=-1,
 completion=[[False,False],[False,False]])
save(payload,error='42501'); assert count()=='0'
sql('select arc_private.save_workout_session('+q(json.dumps(payload))+'::jsonb)',user=USER_A,error='42501')
sql("update public.workout_alternative_mappings set review_status='approved',enabled=true")
# SQL NULL must never pass an approved primary-target comparison.
sql('update public.exercise_library set target_muscle=null where id='+q(prescription[0]['actual_exercise_library_id']))
bad=copy.deepcopy(payload);bad['prescription'][0]['primary_target']=None
save(bad,error='42501');assert count()=='0'
sql('update public.exercise_library set target_muscle='+q('biceps')+' where id='+q(prescription[0]['actual_exercise_library_id']))
sql('update public.exercise_library set target_muscle=null where id='+q(sources[0][1]))
bad=copy.deepcopy(payload);bad['source_prescription'][0]['primary_target']=None;bad['original_targets']=['delts']
save(bad,error='42501');assert count()=='0'
sql('update public.exercise_library set target_muscle='+q('biceps')+' where id='+q(sources[0][1]))
# Forged source relationship, arbitrary actual ID, equipment, target, budget, sets and flags all fail atomically.
for key,value,error in [('workout_plan_id',str(uuid.uuid4()),'42501'),('equipment_selection',['bodyweight'],'42501'),('requested_duration_minutes',1,'22023')]:
    bad=copy.deepcopy(payload);bad[key]=value;save(bad,error=error);assert count()=='0'
for key,value in [('actual_exercise_library_id','800750ec-bbfd-4975-901c-c0096d10d916'),('primary_target','pectorals'),('sets',7),('mapping_version',99)]:
    bad=copy.deepcopy(payload);bad['prescription'][0][key]=value
    if key=='sets':bad['completion'][0]=[False]*7
    save(bad,error='42501');assert count()=='0'
bad=copy.deepcopy(payload);bad['completion'][0][0]='true';save(bad,error='22023');assert count()=='0'
bad=copy.deepcopy(payload);bad['status']='completed';bad['outcome']='completed';bad['completed_at']='2026-10-09T10:30:00Z';save(bad,error='22023');assert count()=='0'
bad=copy.deepcopy(payload);bad['user_id']=USER_B;save(bad,user=USER_B,error='42501');assert count()=='0'
# New sessions reject changed source/catalog state. Existing snapshots are tested below.
sql("update public.workout_plans set status='archived'")
save(payload,error='42501');assert count()=='0'
sql("update public.workout_plans set status='active'")
sql('update public.workout_day_exercises set sets=4 where id='+q(SRC1))
save(payload,error='22023');assert count()=='0'
sql('update public.workout_day_exercises set sets=3 where id='+q(SRC1))
sql('update public.exercise_library set is_published=false where id='+q(prescription[0]['actual_exercise_library_id']))
save(payload,error='42501');assert count()=='0'
sql('update public.exercise_library set is_published=true where id='+q(prescription[0]['actual_exercise_library_id']))
bad=copy.deepcopy(payload);bad['prescription'][1]=copy.deepcopy(bad['prescription'][0]);bad['prescription'][1]['exercise_position']=1
save(bad,error='22023');assert count()=='0'
# Original Gym, partial and discard use the same schema/RPC without Home mappings.
gym=copy.deepcopy(payload);gym.update(id=str(uuid.uuid4()),training_location='gym',session_variant='gym_original',equipment_selection=[],estimated_duration_seconds=None,prescription=source_moves,completion=[[False]*3,[False]*3])
bad=copy.deepcopy(gym);bad['source_prescription'][0]['mapping_id']=prescription[0]['mapping_id'];bad['prescription']=bad['source_prescription']
save(bad,error='22023');assert count()=='0'
save(gym);save(gym)
gym.update(revision=1,base_revision=0,status='abandoned',outcome='partial',completed_at='2026-10-09T10:30:00Z');save(gym)
assert sql('select count(*) from public.workout_session_sets where completed')=='0'
discard=copy.deepcopy(gym);discard.update(id=str(uuid.uuid4()),revision=0,base_revision=-1,outcome='discarded');save(discard);save(discard)
sql('delete from public.workout_sessions where training_location='+q('gym'))
# Two simultaneous first-insert retries serialize to one parent and one set grid.
with ThreadPoolExecutor(max_workers=2) as pool:
    responses=list(pool.map(lambda _:save(payload),range(2)))
assert all(payload['id'] in response for response in responses);assert count()=='1'
set_ids=sql('select string_agg(id::text,\',\' order by exercise_position,set_number) from public.workout_session_sets')
save(payload);assert count()=='1';assert sql('select string_agg(id::text,\',\' order by exercise_position,set_number) from public.workout_session_sets')==set_ids
bad=copy.deepcopy(payload);bad['completion'][0][0]='true';save(bad,error='22023')
bad=copy.deepcopy(payload);bad['completion'][0][0]=True;save(bad,error='40001')
bad=copy.deepcopy(payload);bad['id']=str(uuid.uuid4());save(bad,error='40001')
assert '0' in sql('select count(*) from public.workout_sessions',user=USER_B)
assert '0' in sql('select count(*) from public.workout_session_sets',user=USER_B)
save(payload,user=USER_B,error='42501')
sql('select public.save_workout_session('+q(json.dumps(payload))+'::jsonb)',role='anon',error='42501')
sql('select * from public.workout_sessions',role='anon',error='42501')
sql('update public.workout_session_sets set completed=true',user=USER_A,error='42501')
sql('insert into public.workout_sessions(id) values(gen_random_uuid())',user=USER_A,error='42501')
sql('update public.workout_alternative_mappings set sets=4',user=USER_A,error='42501')
sql('update public.workout_alternative_mappings set sets=4',error='P0001')
sql("update public.workout_alternative_mappings set review_status='proposed'",error='P0001')
sql("update public.workout_alternative_mappings set review_metadata='{}'::jsonb",error='P0001')
# A new definition is a new version/UUID, never a rewrite of the approved row.
new_mapping=str(uuid.uuid4())
sql('insert into public.workout_alternative_mappings select '+q(new_mapping)+'::uuid,source_exercise_id,alternative_exercise_id,version+1,primary_target,secondary_targets,movement_pattern,required_equipment,sets,min_sets,reps,rest_seconds,work_seconds_per_set,priority,limitations,review_status,enabled,review_metadata from public.workout_alternative_mappings where id='+q(prescription[0]['mapping_id']))
assert sql('select version from public.workout_alternative_mappings where id='+q(new_mapping))=='2'
sql('select arc_private.save_workout_session('+q(json.dumps(payload))+'::jsonb)',user=USER_B,error='42501')
bad=copy.deepcopy(payload);bad['user_id']=USER_B
sql('select arc_private.save_workout_session('+q(json.dumps(bad))+'::jsonb)',user=USER_B,error='42501')
# A registered session survives retired mappings, unpublished alternatives, archived sources and FK deletion.
sql("update public.exercise_library set is_published=false where id="+q(prescription[0]['actual_exercise_library_id']))
sql("update public.workout_alternative_mappings set enabled=false,review_status='retired'")
sql("update public.workout_plans set status='archived'")
payload['revision']=1;payload['base_revision']=0;payload['completion'][0][0]=True;save(payload)
stale=copy.deepcopy(payload);stale['revision']=2;stale['base_revision']=0;save(stale,error='40001')
sql('delete from public.workout_day_exercises where id='+q(SRC1))
payload['revision']=2;payload['base_revision']=1;payload['completion'][0][1]=True;save(payload)
assert sql('select count(*) from public.workout_session_sets where source_workout_day_exercise_id is null')=='2'
payload['revision']=3;payload['base_revision']=2;payload['completion']=[[True,True],[True,True]];payload['status']='completed';payload['outcome']='completed';payload['completed_at']='2026-10-09T10:30:00Z';save(payload);save(payload)
regression=copy.deepcopy(payload);regression['revision']=4;regression['base_revision']=3;regression['status']='in_progress';regression['outcome']=None;regression['completed_at']=None;save(regression,error='40001')
sql('delete from public.workout_days where id='+q(DAY))
assert sql("select snapshot->>'workout_day_id' from public.workout_sessions")==DAY
assert sql('select count(*) from public.workout_session_sets')=='4'
sql('delete from public.workout_alternative_mappings')
sql('delete from public.exercise_library where id='+q(prescription[0]['actual_exercise_library_id']))
assert sql('select count(*) from public.workout_session_sets where mapping_id is null')=='4'
assert sql('select count(*) from public.workout_session_sets where actual_exercise_library_id is null')=='2'
assert sql("select prescription->0->>'actual_exercise_library_id' from public.workout_sessions")==prescription[0]['actual_exercise_library_id']
assert '1' in sql('select count(*) from public.workout_sessions',user=USER_A)
assert '4' in sql('select count(*) from public.workout_session_sets',user=USER_A)
print('LOCAL database: schema + seed + RPC + RLS tests passed. Two authenticated identities and anonymous identity tested.')
print('Assertions include arbitrary substitution rejection, unpublished/retired history, nullable FKs, atomicity, idempotent UUIDs, revisions and terminal transitions.')

sql('drop database '+DATABASE,database='postgres')
