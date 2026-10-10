# ARC Phase 2C Checkpoint 3 — final pre-deployment gate

**Requested gate: PASS. Production deployment: NOT EXECUTED; explicit approval pending.**

Tests completed 2026-10-10 15:47:57 UTC. Fresh hosted SELECT-only preflight completed 2026-10-10 15:48:06 UTC against `nbojicqbpqgotdmdayku` (PostgreSQL 17.6).

## Exact migration

`supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql`

Reviewed, executed locally, and post-test SHA-256 are identical:

```text
94f945ba0f0aeaa84972bf4171e3da43042add5ce156f4467ad859505490e0dc
```

No migration, original SQL suite, seed, Flutter implementation, hosted records, or hosted migration history was changed during this gate. The proposal remains in `review_only/`.

## PostgreSQL 17 results

The server reported `170011`, PostgreSQL **17.11**, x86_64 Windows. A newly initialized owned temporary cluster listened only on `127.0.0.1:55439`. Matching initialization tools were obtained from the official 17.11 binary archive into that temporary directory; existing installed services/data were untouched. Docker image downloads stalled and were abandoned before running any tests. The native disposable server was stopped after verification.

The original suites were executed with only an in-memory PostgreSQL client-path substitution (18 to 17) and a separate CP3 output artifact. The raw migration was read unchanged by the original suite. Both original suite hashes remained unchanged.

| Verification | Result |
|---|---|
| Atomic activation and persisted prescription roundtrip | PASS |
| Same-key idempotent retry; changed payload rejected | PASS |
| Concurrent same-key activation converges | PASS |
| Concurrent different-key activation and competing replacements serialize | PASS |
| First activation and replacement rollback after day/exercise insertion failure | PASS |
| Explicit replacement and expected-version conflicts | PASS |
| Old plans, prescriptions, sessions, sets and terminal retries preserved | PASS |
| Existing registered session can finish after its plan is archived | PASS |
| Table/column ACLs, owner RLS, administrative access, RPC exposure and empty search paths | PASS |
| Cross-owner and anonymous access, direct writes and caller mismatch denied | PASS |
| Twenty invalid/stale prescription/schedule cases rejected atomically | PASS |
| All nine available real-catalog previews activate | PASS |
| Unchanged Phase 2A/2B `save_workout_session`, approved Home enforcement, revisions, terminal transitions, nullable FKs and retries | PASS |

All seven CP3 integration groups match the prior PostgreSQL 18 rehearsal outcomes. The independent Phase 2A/2B SQL suite also passed. No PostgreSQL 17 behavioral difference or SQL failure was found. Flutter was not rerun in this SQL-only gate; previous Flutter results remain recorded separately and are not claimed as fresh runs.

Evidence:

- `docs/phase2c_checkpoint3_pg17_local_e2e.json`
- Reproduction harness: `tools/verify_phase2c_pg17.py` (requires an owned fresh local PostgreSQL 17 server on the stated port).

## Fresh hosted SELECT-only preflight

| Check | Result |
|---|---|
| History exactly `20261009174458 / arc_phase_2a_2b_training_variants` | PASS |
| `workout_plans.generation_metadata` absent | PASS |
| `activate_generated_training_plan` absent | PASS |
| `one_active_plan_per_type` present, definition unchanged | PASS |
| 84 table-grant records and 176 client column-grant records match audit | PASS |
| 22 columns, 7 indexes, 3 policies, 1 trigger, 15 constraints, 5 FK dependencies and public enums match audit | PASS |
| RLS enabled on all three plan tables; duplicate active-plan groups zero | PASS |
| Existing function boundary/security metadata matches audit | PASS |
| Unexpected drift within the audited plan/activation dependency scope | NONE |

Only metadata and a duplicate-group count were retrieved; no private user/profile/session rows were returned. This is scoped schema comparison, not a full unrelated-schema dump or hosted activation test.

Evidence/query:

- `docs/sql/phase2c_checkpoint3_final_preflight_select.sql`

## Pending migrations and proposed execution procedure

Currently `supabase/migrations/` contains only the already applied `20261009174458_arc_phase_2a_2b_training_variants.sql`, so **nothing is currently pending**. Promoting only the exact reviewed CP3 file would make **only `20261010134016` pending**. This is proven by local filename/version comparison with the freshly selected remote history. A hosted CLI dry-run was deliberately not performed during the SELECT-only gate.

**After explicit approval only**, confirm a usable current backup/recovery point and recheck project/history/schema/hash. Backup usability was not independently established by this SELECT-only gate; it remains required before live execution. Then, from `C:\Users\ivang\ARC VSCODE\Arc`:

```powershell
$gateCli = Join-Path $env:TEMP 'arc_release_cli_2_120_0\supabase.exe'
$gateSource = 'supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql'
$gateDestination = 'supabase/migrations/20261010134016_arc_phase_2c_plan_activation.sql'
$gateHash = '94f945ba0f0aeaa84972bf4171e3da43042add5ce156f4467ad859505490e0dc'
if ((Get-FileHash -LiteralPath $gateSource -Algorithm SHA256).Hash.ToLowerInvariant() -ne $gateHash) { throw 'Reviewed SQL changed' }
if (Test-Path -LiteralPath $gateDestination) { throw 'Destination already exists; re-inspect pending list' }
Copy-Item -LiteralPath $gateSource -Destination $gateDestination
if ((Get-FileHash -LiteralPath $gateDestination -Algorithm SHA256).Hash.ToLowerInvariant() -ne $gateHash) { throw 'Promoted SQL differs' }
& $gateCli migration list --project-ref nbojicqbpqgotdmdayku
if ($LASTEXITCODE -ne 0) { throw 'Migration list failed' }
& $gateCli db push --project-ref nbojicqbpqgotdmdayku --skip-vault --dry-run
if ($LASTEXITCODE -ne 0) { throw 'Dry-run failed' }
```

Inspect the output before continuing: **exactly `20261010134016_arc_phase_2c_plan_activation.sql` may execute**. Stop for any extra pending SQL, obsolete history, unexpected config/connection behavior, or drift. Do not force, repair history, reset, initialize an unrelated baseline, or include seeds/roles. Only after that inspection:

```powershell
& $gateCli db push --project-ref nbojicqbpqgotdmdayku --skip-vault
if ($LASTEXITCODE -ne 0) { throw 'Deployment failed; inspect state before any retry' }
```

CLI 2.120.0 help confirms these flags. `--skip-vault` prevents its default Vault-config update step. No `--include-all`, `--include-roles`, `--include-seed`, broad repair or unqualified push is proposed. These commands have **not** been executed against hosted Supabase.

Expected effects: add nullable generation metadata and the owner/key unique index; revoke client direct DML/table and column write privileges on the three plan tables; create private SECURITY DEFINER activation and the authenticated public wrapper; reload the API schema. Existing rows are retained. Activation later persists a plan atomically and can archive an explicitly identified previous plan. Neither this schema migration nor the procedure inserts exercise mappings or runs any seed.

After deployment, verify history includes exactly the old and new versions, intended ACLs/RLS/search paths and functions, then perform separately authorized hosted/device verification. Disposable SQL success does not establish hosted/Android end-to-end success.

Recovery: before commit, migration failure rolls back its transaction. After commit, prefer a separately approved forward migration; retain all plans/session history and metadata. If required, separately approve revoking authenticated EXECUTE on both activation functions and reloading the API schema to pause activation. Do not automatically restore broad DML, drop schema/data, or repair migration history. See the original CP3 report for the reviewed recovery SQL.

**Execution boundary: stopped, awaiting explicit deployment approval.**
