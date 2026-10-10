"""Checkpoint 1 approval/ACL/freeze tests; synthetic LOCAL PostgreSQL only.
Requires an independent cluster at 127.0.0.1:55439. Never reads connection env/URLs.
"""
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PSQL = Path(r"C:\Program Files\PostgreSQL\18\bin\psql.exe")
DATABASE = "arc_phase2c_" + uuid.uuid4().hex[:12]
MIGRATION = ROOT / "supabase/review_only/20261010064421_arc_phase2c_exercise_generation_approval.sql"
EXERCISE = "00000000-0000-4000-8000-000000000001"

def quote(value):
    return "'" + str(value).replace("'", "''") + "'"

def sql(statement, role=None, expected=None, database=DATABASE):
    if role:
        assert role in ("anon", "authenticated")
        statement = "begin; set local role " + role + "; " + statement + "; commit;"
    result = subprocess.run(
        [str(PSQL), "-X", "-h", "127.0.0.1", "-p", "55439", "-U", "arc_test",
         "-d", database, "-v", "ON_ERROR_STOP=1", "-v", "VERBOSITY=verbose", "-At", "-f", "-"],
        input=statement, capture_output=True, text=True, encoding="utf-8",
    )
    if expected:
        assert result.returncode != 0 and expected in result.stderr, result.stderr
        return ""
    assert result.returncode == 0, result.stderr
    return result.stdout.strip()

assert MIGRATION.resolve().is_relative_to(ROOT)
assert sql("select host(inet_server_addr()) || ':' || inet_server_port()", database="postgres") == "127.0.0.1:55439"
sql("create database " + DATABASE, database="postgres")
try:
    sql("""do $$ begin
      if not exists(select from pg_roles where rolname='anon') then create role anon; end if;
      if not exists(select from pg_roles where rolname='authenticated') then create role authenticated; end if;
    end $$;
    create schema arc_private;
    create table public.exercise_library (
      id uuid primary key, name text not null, body_part text not null, target_muscle text,
      secondary_muscles text[] not null default '{}', equipment text not null,
      difficulty text, instructions text[] not null default '{}', gif_path text,
      tags text[] not null default '{}', is_published boolean not null default true
    );
    alter table public.exercise_library enable row level security;
    grant select on public.exercise_library to anon,authenticated;
    create policy library_read on public.exercise_library for select to anon,authenticated using(is_published);
    -- Simulate broad inherited/default client grants, as on the deployed baseline.
    alter default privileges in schema public grant all on tables to anon,authenticated;
    alter default privileges in schema arc_private grant execute on functions to anon,authenticated;
    """)
    row = {
      "name": "Synthetic chest fixture", "body_part": "chest", "target_muscle": "pectorals",
      "secondary_muscles": ["triceps"], "equipment": "dumbbell", "difficulty": None,
      "instructions": ["Synthetic fixture only"], "gif_path": None, "tags": [],
    }
    sql("insert into public.exercise_library(id,name,body_part,target_muscle,secondary_muscles,equipment,instructions) values("
      + ",".join([quote(EXERCISE),quote(row["name"]),quote("chest"),quote("pectorals"),
                  "array['triceps']",quote("dumbbell"),"array['Synthetic fixture only']"]) + ")")
    sql(MIGRATION.read_text(encoding="utf-8"))
    assert sql("select count(*) from public.exercise_generation_profiles") == "0"
    sql("""insert into public.exercise_generation_profiles(
      exercise_id,version,primary_muscle,movement_patterns,required_equipment,
      minimum_experience,work_seconds_per_set
    ) values(""" + quote(EXERCISE) + ",1,'chest',array['horizontal_push'],array['dumbbells','bench'],0,30)")
    assert sql("select review_status || ':' || enabled from public.exercise_generation_profiles") == "proposed:false"
    assert sql("select count(*) from public.exercise_generation_profiles", role="authenticated").endswith("0\nCOMMIT")
    sql("select * from public.exercise_generation_profiles", role="anon", expected="42501")
    for privilege in ("INSERT","UPDATE","DELETE","TRUNCATE","REFERENCES","TRIGGER"):
        assert sql("select has_table_privilege('authenticated','public.exercise_generation_profiles'," + quote(privilege) + ")") == "f"
        assert sql("select has_table_privilege('anon','public.exercise_generation_profiles'," + quote(privilege) + ")") == "f"
    sql("update public.exercise_generation_profiles set review_status='approved'", role="authenticated", expected="42501")
    sql("delete from public.exercise_generation_profiles", role="authenticated", expected="42501")
    sql("truncate public.exercise_generation_profiles", role="authenticated", expected="42501")
    sql("update public.exercise_generation_profiles set enabled=true", expected="23514")
    sql("update public.exercise_generation_profiles set review_status='approved'", expected="22023")
    metadata = {"reviewer":"Synthetic SQL fixture only","reference":"Disposable fixture; no real approval",
                "reviewed_at":"2026-10-10T00:00:00Z"}
    sql("update public.exercise_generation_profiles set source_snapshot=" + quote(json.dumps(row))
      + "::jsonb,review_metadata=" + quote(json.dumps(metadata)) + "::jsonb,review_status='approved'")
    assert sql("select count(*) from public.exercise_generation_profiles", role="authenticated").endswith("0\nCOMMIT")
    sql("update public.exercise_generation_profiles set enabled=true")
    assert sql("select count(*) from public.exercise_generation_profiles", role="authenticated").endswith("1\nCOMMIT")
    assert sql("select has_function_privilege('anon','arc_private.validate_generation_profile()','execute')") == "f"
    assert sql("select has_function_privilege('authenticated','arc_private.validate_generation_profile()','execute')") == "f"
    assert sql("select prosecdef || ':' || array_to_string(proconfig,',') from pg_proc where oid='arc_private.validate_generation_profile()'::regprocedure") == 'false:search_path=""'
    sql("update public.exercise_generation_profiles set primary_muscle='biceps'", expected="22023")
    sql("update public.exercise_generation_profiles set version=2", expected="22023")
    sql("delete from public.exercise_generation_profiles", expected="22023")
    # A new reviewed version cannot create two enabled definitions.
    insert2 = """insert into public.exercise_generation_profiles select
      exercise_id,2,primary_muscle,movement_patterns,required_equipment,allowed_locations,
      minimum_experience,work_seconds_per_set,source_snapshot,review_status,true,review_metadata
      from public.exercise_generation_profiles where version=1"""
    sql(insert2, expected="23505")
    sql("update public.exercise_library set instructions=array['Changed after review']")
    assert sql("select count(*) from public.exercise_generation_profiles", role="authenticated").endswith("0\nCOMMIT")
    sql("update public.exercise_generation_profiles set enabled=false")
    sql("update public.exercise_generation_profiles set enabled=true", expected="22023")
    sql("update public.exercise_generation_profiles set review_status='retired'")
    sql("update public.exercise_generation_profiles set review_status='approved'", expected="22023")
    sql("delete from public.exercise_library", expected="23001")
    # Updated source content can be reviewed as a new immutable version.
    row["instructions"] = ["Changed after review"]
    sql("""insert into public.exercise_generation_profiles(
      exercise_id,version,primary_muscle,movement_patterns,required_equipment,
      minimum_experience,work_seconds_per_set,source_snapshot,review_status,enabled,review_metadata
    ) values(""" + quote(EXERCISE) + ",2,'chest',array['horizontal_push'],array['dumbbells','bench'],0,30,"
      + quote(json.dumps(row)) + "::jsonb,'approved',true," + quote(json.dumps(metadata)) + "::jsonb)")
    assert sql("select count(*) from public.exercise_generation_profiles", role="authenticated").endswith("1\nCOMMIT")
    sql("update public.exercise_library set is_published=false")
    assert sql("select count(*) from public.exercise_generation_profiles", role="authenticated").endswith("0\nCOMMIT")
    # No plan/session table or activation function is created by this migration.
    assert sql("select to_regclass('public.workout_plans') is null") == "t"
    print("PASS: local approval defaults, source freshness, RLS/ACLs, metadata validation, immutable versions, retirement and unique enablement.")
finally:
    sql("drop database " + DATABASE, database="postgres")
