"""Run the reviewed local SQL suites unchanged, using a PG17 client/server.

Only runtime client-path and result-artifact substitutions are permitted.
Never connects to hosted Supabase. The caller owns the disposable container.
"""
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PSQL = Path(r'C:\Program Files\PostgreSQL\17\bin\psql.exe')
MIGRATION = 'supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql'
EXPECTED = '94f945ba0f0aeaa84972bf4171e3da43042add5ce156f4467ad859505490e0dc'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

assert digest(ROOT / MIGRATION) == EXPECTED, 'Reviewed migration hash changed'
probe = subprocess.run([str(PSQL), '-XAt', '-h', '127.0.0.1', '-p', '55439',
    '-U', 'arc_test', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-c',
    "select current_setting('server_version_num'), version()"],
    capture_output=True, text=True, check=True).stdout.strip()
assert int(probe.split('|')[0]) // 10000 == 17, probe
print(probe, flush=True)
scripts = ['test/sql/phase2c_activation_local_pg_test.py', 'test/sql/phase2b_local_pg_test.py']
before = {name: digest(ROOT / name) for name in scripts}
for name in scripts:
    source = (ROOT / name).read_text(encoding='utf-8')
    old = r"PSQL = Path(r'C:\Program Files\PostgreSQL\18\bin\psql.exe')"
    assert source.count(old) == 1
    source = source.replace(old, r"PSQL = Path(r'C:\Program Files\PostgreSQL\17\bin\psql.exe')")
    if 'phase2c_' in name:
        old_output = "ROOT/'docs/phase2c_checkpoint3_local_e2e.json'"
        assert source.count(old_output) == 1
        source = source.replace(old_output, "ROOT/'docs/phase2c_checkpoint3_pg17_local_e2e.json'")
    sys.argv = [str(ROOT / name)]
    print('Running ' + name, flush=True)
    exec(compile(source, str(ROOT / name), 'exec'),
         {'__file__': str(ROOT / name), '__name__': '__main__'})
assert digest(ROOT / MIGRATION) == EXPECTED
assert all(digest(ROOT / name) == value for name, value in before.items())
result = dict(checked_at_utc=datetime.now(timezone.utc).isoformat(),
    postgres=probe, hosted_writes=False, migration=MIGRATION,
    reviewed_sha256=EXPECTED, executed_sha256=digest(ROOT / MIGRATION),
    unchanged_test_sha256=before, suites_passed=scripts)
(ROOT / 'docs/phase2c_checkpoint3_pg17_verification.json').write_text(
    json.dumps(result, indent=2) + '\n', encoding='utf-8')
print('PASS: PostgreSQL 17 gate; reviewed migration and original suites unchanged', flush=True)
