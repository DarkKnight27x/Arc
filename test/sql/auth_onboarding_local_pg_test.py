"""Profile trigger/RLS contracts on synthetic local PostgreSQL fixtures only.

Requires the disposable cluster at 127.0.0.1:55439, never a Supabase database.
Uses audited profile DDL and trigger/policy definitions, not real user rows.
"""
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PSQL = Path(r'C:\Program Files\PostgreSQL\18\bin\psql.exe')
DB = 'arc_auth_audit_' + uuid.uuid4().hex[:12]
A = '00000000-0000-0000-0000-000000000001'
B = '00000000-0000-0000-0000-000000000002'


def sql(query, database=DB, role=None, user=None, error=None):
    if role:
        assert role in ('authenticated', 'anon') and user in (A, B, None)
        query = f"begin; set local role {role}; set local request.jwt.claim.sub = '{user or ''}'; {query}; commit;"
    result = subprocess.run([
        str(PSQL), '-X', '-q', '-h', '127.0.0.1', '-p', '55439', '-U', 'arc_test',
        '-d', database, '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose', '-At', '-f', '-'
    ], input=query, capture_output=True, text=True, encoding='utf-8')
    if error:
        assert result.returncode and error in result.stderr, result.stderr
    else:
        assert result.returncode == 0, result.stderr
    return result.stdout.strip()


audit = json.loads((ROOT / 'docs/auth_profile_database_audit.json').read_text())
assert audit['rls'] is True
assert len(audit['policies']) == 1
policy = audit['policies'][0]
assert policy['cmd'] == 'ALL' and policy['roles'] == ['authenticated']
columns = []
for c in audit['columns']:
    dtype = c['udt_name']
    if dtype == '_text':
        dtype = 'text[]'
    definition = f"{c['column_name']} {dtype}"
    if c['column_default'] is not None:
        definition += ' default ' + c['column_default']
    if c['is_nullable'] == 'NO':
        definition += ' not null'
    columns.append(definition)
columns.extend(audit['constraints'])

sql(f'create database {DB}', database='postgres')
try:
    sql("""
do $$begin
 if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
 if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
end$$;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table auth.users(id uuid primary key, email text, raw_user_meta_data jsonb);
create type public.account_type as enum('client');
grant usage on schema auth, public to authenticated, anon;
""" + 'create table public.profiles (' + ','.join(columns) + ');' +
        audit['signup_function'] + ';' + audit['triggers'][0] + ';' +
        'alter table public.profiles enable row level security;' +
        f'create policy "fixture audited ownership" on public.profiles for all to authenticated using ({policy["qual"]}) with check ({policy["with_check"]});' +
        'grant all on public.profiles to authenticated, anon;')
    sql(f"insert into auth.users values ('{A}','a@example.invalid','{{\"display_name\":\"Fixture A\"}}'),('{B}','b@example.invalid','{{}}');")
    assert sql('select bool_and(not onboarding_complete) from public.profiles') == 't'
    assert sql(f"select display_name from public.profiles where user_id='{A}'") == 'Fixture A'
    assert sql(f"select display_name from public.profiles where user_id='{B}'") == 'b@example.invalid'
    assert sql('select count(*) from public.profiles', role='authenticated', user=A) == '1'
    assert sql(f"with changed as (update public.profiles set onboarding_complete=true where user_id='{B}' returning *) select count(*) from changed", role='authenticated', user=A) == '0'
    sql(f"update public.profiles set user_id='{B}' where user_id='{A}'", role='authenticated', user=A, error='42501')
    sql(f"update public.profiles set diet_type='Unsupported', onboarding_complete=true where user_id='{A}'", role='authenticated', user=A, error='23514')
    assert sql(f"select onboarding_complete from public.profiles where user_id='{A}'") == 'f'
    sql(f"update public.profiles set fitness_goal='Build muscle',gender='Male',age=25,height_cm=175.5,weight_kg=70,experience_level='Beginner',train_days=3,diet_type='Veg',allergies=array['None'],onboarding_complete=true where user_id='{A}'", role='authenticated', user=A)
    assert sql(f"select onboarding_complete from public.profiles where user_id='{A}'") == 't'
    assert sql(f"select onboarding_complete from public.profiles where user_id='{B}'") == 'f'
    assert sql(f"select count(*) from public.profiles where user_id='{A}'", role='authenticated', user=B) == '0'
    assert sql('select count(*) from public.profiles', role='anon') == '0'
    assert sql('with changed as (update public.profiles set onboarding_complete=true returning *) select count(*) from changed', role='anon') == '0'
    sql((ROOT / 'docs/sql/auth_profile_privilege_hardening_proposal.sql').read_text())
    assert sql("select has_table_privilege('authenticated','public.profiles','TRUNCATE')") == 'f'
    assert sql("select has_table_privilege('authenticated','public.profiles','UPDATE')") == 't'
    print('PASS: exact audited trigger/default/columns and owner RLS with two synthetic users and anon; cross-owner reads/updates/reassignment denied; invalid completion atomic.')
finally:
    sql(f'drop database {DB}', database='postgres')
