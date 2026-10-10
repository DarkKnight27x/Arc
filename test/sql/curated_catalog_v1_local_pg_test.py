"""Atomic insertion/replay/drift checks in a disposable localhost database only."""
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PSQL = Path(r"C:\Program Files\PostgreSQL\18\bin\psql.exe")
DATABASE = "arc_curated_v1_" + uuid.uuid4().hex[:12]
SEED = ROOT / "supabase/seeds/arc_curated_exercise_catalog_v1.sql"
BASELINE = json.loads((ROOT / "docs/curated_catalog_v1_preflight.json").read_text(encoding="utf-8"))


def sql(statement, database=DATABASE, error=None):
    result = subprocess.run(
        [str(PSQL), "-X", "-q", "-h", "127.0.0.1", "-p", "55439", "-U", "arc_test",
         "-d", database, "-v", "ON_ERROR_STOP=1", "-At", "-f", "-"],
        input="set timezone = 'UTC';\n" + statement, capture_output=True, text=True, encoding="utf-8",
    )
    if error:
        assert result.returncode != 0 and error in result.stderr, result.stderr
    else:
        assert result.returncode == 0, result.stderr
    return result.stdout.strip()


assert sql("select host(inet_server_addr()) || ':' || inet_server_port()", database="postgres") == "127.0.0.1:55439"
assert DATABASE.startswith("arc_curated_v1_") and DATABASE.isidentifier()
sql("create database " + DATABASE, database="postgres")
try:
    sql("""create table public.exercise_library (
      id uuid primary key default gen_random_uuid(), source_external_id text unique,
      name text not null, body_part text not null, target_muscle text,
      secondary_muscles text[] not null default '{}', equipment text not null default 'bodyweight',
      difficulty text, instructions text[] not null default '{}', gif_path text,
      tags text[] not null default '{}', is_published boolean not null default true,
      created_at timestamptz not null default now()
    );""")
    payload = json.dumps(BASELINE["catalog"])
    sql("""insert into public.exercise_library select * from jsonb_to_recordset($baseline$""" + payload + """$baseline$::jsonb)
      as r(id uuid, source_external_id text, name text, body_part text, target_muscle text,
           secondary_muscles text[], equipment text, difficulty text, instructions text[],
           gif_path text, tags text[], is_published boolean, created_at timestamptz);""")
    assert sql("select md5(string_agg(to_jsonb(e)::text,'' order by id)) from public.exercise_library e") == BASELINE["catalog_hash"]
    seed = SEED.read_text(encoding="utf-8")
    # A failure after all inserts must roll back the whole batch.
    sql(seed.replace("commit;", "select 1/0; commit;"), error="division by zero")
    assert sql("select count(*) from public.exercise_library") == "30"
    # Baseline edits must abort, never overwrite or silently continue.
    sql("update public.exercise_library set name=name || ' drift' where id='" + BASELINE["catalog"][0]["id"] + "'")
    sql(seed, error="baseline changed")
    assert sql("select count(*) from public.exercise_library") == "30"
    sql("update public.exercise_library set name=left(name,length(name)-6) where id='" + BASELINE["catalog"][0]["id"] + "'")
    sql(seed)
    assert sql("select count(*) from public.exercise_library") == "78"
    assert sql("select count(*) from public.exercise_library where starts_with(source_external_id,'arc_curated_v1_') and gif_path is null and difficulty is null and is_published and cardinality(tags)=0 and cardinality(instructions)=5") == "48"
    old_ids = ",".join("'" + r["id"] + "'" for r in BASELINE["catalog"])
    assert sql("select count(*) from public.exercise_library where starts_with(source_external_id,'arc_curated_v1_') and id in (" + old_ids + ")") == "0"
    sql(seed, error="baseline changed")
    assert sql("select count(*) from public.exercise_library") == "78"
    print("PASS: exact SQL, DB UUID defaults, 48 rows, rollback on failure, drift abort, replay abort, original rows preserved.")
finally:
    # This is only the unique database created above on the asserted local server.
    sql("drop database " + DATABASE, database="postgres")
