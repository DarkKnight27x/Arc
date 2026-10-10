# ARC migration cleanup and training deployment report

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

Reviewed **2026-10-09 17:59 UTC**. Target project: **`nbojicqbpqgotdmdayku`**. Execution boundary: repository cleanup and read-only production inspection only. **No production migration, seed, history repair, mapping approval, or application-data write was executed.**

**Deployment readiness: FAIL / BLOCKED.** Cleanup and local training verification pass. A usable backup, authenticated CLI pending/dry-run verification, target-version runtime verification and hosted RPC verification remain unresolved. This report supersedes the earlier release review's obsolete-migration reconciliation proposal. The existing database is the baseline; do not mark the removed versions applied.

## Repository cleanup

The complete contents and filenames of these three obsolete files were inspected, then the files were deleted:

| Deleted file | Former purpose |
| --- | --- |
| `supabase/migrations/20260902000100_create_prototype_schema.sql` | Prototype profile/auth integration, workout, meal, rehabilitation and provider schema/policies/storage |
| `supabase/migrations/20260904000100_add_rag_knowledge.sql` | Knowledge/RAG tables and retrieval function |
| `supabase/migrations/20260922000100_fix_profile_display_name_trigger.sql` | Signup profile display-name trigger function update |

These SQL files were not executed, replayed or marked applied. Removing repository files does not remove their existing live objects. Their original metadata is retained in the [repository cleanup record](ARC_REPOSITORY_CLEANUP.md). No unrelated application source was changed during this cleanup.

Exactly one file remains in `supabase/migrations/`:

- **Schema:** `supabase/migrations/20261009174458_arc_phase_2a_2b_training_variants.sql`
- **Separate seed:** `supabase/seeds/20261009174458_home_mapping_seed_disabled.sql`

The schema and seed remain byte-identical to `docs/sql/workout_training_variants.sql` and `docs/sql/home_mapping_seed_proposal.sql`, respectively. No new SQL defect was found and no approved SQL was changed in this step. `docs/sql/workout_session_progress.sql` remains a superseded reference and must not be applied.

| Preserved release file | SHA256 |
| --- | --- |
| Schema migration | `108c27156afd5a3fcad6b6bb64122593e042c810e04de9cd93ad66427a525e69` |
| Disabled seed | `35986777670dd01505e0b703f91a1c8363c1ab67daf4bfd4c21c5f82e051327c` |

## Current live baseline and compatibility

The connected project was verified as `nbojicqbpqgotdmdayku`, `ACTIVE_HEALTHY`, PostgreSQL **17.6.1.166**. The connector's fresh remote migration-history response is **`[]`**. Empty migration history does not mean an empty database. Existing application schema is retained as the baseline.

Fresh read-only catalogs captured auth/storage inventory and public tables, columns, constraints, policies, indexes, triggers and relevant function definitions. No private application user rows were retrieved.

Existing objects include profiles and onboarding fields; `auth.users` and its `on_auth_user_created` signup trigger; `workout_plans`, `workout_days`, `workout_day_exercises`, `exercise_library`; `foods`, `meals`, `meal_ingredients`, `meal_plans`, `meal_plan_items`, `meal_nutrition`; `rehab_cases`, `medical_documents`; and provider/booking and knowledge tables. Their definitions and existing RLS policies are not replaced by the proposed migration. Existing unrelated privilege/security findings from the earlier review remain outside this training change.

All required source columns and referenced primary keys exist. `auth.uid()`, `gen_random_uuid()`, `pg_advisory_xact_lock(bigint)` and `hashtextextended(text,bigint)` exist. The three new training tables, `arc_private`, all three proposed functions, three policies, mapping-freeze trigger and all nine named indexes are absent. No catalog name conflict was found.

**Compatible by catalog and SQL review; target-version execution remains unverified.** No PostgreSQL-18-only syntax was identified. The disposable runtime test used PostgreSQL 18, not the target's 17.6. This distinction is a release gate, not a production test result.

## Pending migration verification

Repository inventory contains only version `20261009174458`; remote connector history contains no versions. Their comparison yields **exactly one pending migration**. The disabled seed is outside the migration directory and there is no automatic seed configuration.

The qualified read-only CLI command below was attempted and failed with **Access token not provided**. No unexpected migration was executed:

```powershell
supabase migration list --project-ref nbojicqbpqgotdmdayku --output json --agent yes
```

Therefore the CLI's own remote pending list/dry-run is **not verified**. Before any later approved execution, authenticate the release workflow, qualify the target explicitly, rerun migration listing and a qualified dry-run, and require that only `20261009174458` would execute. Stop on unexpected SQL, obsolete versions or divergent remote history. Do not use broad repair, `--include-all`, automatic seed inclusion, an unqualified push, or `db reset`.

## Exact proposed operations and order

These are proposals only. No executable deployment command was run.

1. After all gates pass and the user explicitly approves this report, apply **only** `supabase/migrations/20261009174458_arc_phase_2a_2b_training_variants.sql`, preserving its reviewed bytes and recording only that migration version through the approved migration workflow. The 36 top-level statements run in one `BEGIN`/`COMMIT` transaction:
   - Create `arc_private`; revoke PUBLIC/anon access; grant authenticated USAGE.
   - Create `public.workout_alternative_mappings`, `public.workout_sessions`, `public.workout_session_sets`, their constraints and implicit primary/unique indexes.
   - Create `alternative_target_idx`, `workout_day_exercises_exercise_idx`, `session_user_history_idx`, `one_in_progress_session_per_day`, `session_plan_idx`, `session_day_idx`, `session_set_source_idx`, `session_set_actual_idx`, `session_set_mapping_idx`.
   - Enable RLS on the three new tables and create `mappings_read`, `session_read`, `set_read`.
   - Revoke all PUBLIC/anon/authenticated privileges on the new tables, then grant authenticated SELECT only.
   - Create `arc_private.freeze_mapping()` and `mapping_definition_frozen`; revoke client execution of the trigger function.
   - Create guarded `arc_private.save_workout_session(jsonb)` and delegating `public.save_workout_session(jsonb)`; revoke PUBLIC/anon/authenticated execution, then grant authenticated EXECUTE on both save routines.
2. Verify deployed catalogs, effective grants and hosted RPC/schema-cache behavior before enabling cloud training usage. Compare the pre-deployment baseline metadata to confirm existing objects/policies survived. Use staging identities for ownership/write-path checks before production execution; production writes require the later authorization scope.
3. Only with **separate seed authorization**, apply `supabase/seeds/20261009174458_home_mapping_seed_disabled.sql`. Its eight statements are a separate transaction containing six `INSERT ... ON CONFLICT (id) DO NOTHING` operations. No schema deployment includes the seed. No approval or enabling UPDATE is proposed.

Schema application inserts no application rows and removes or overwrites no existing data. The only explicit index on an existing table is `workout_day_exercises_exercise_idx`. Foreign keys introduce normal dependency triggers on referenced tables. Index/FK creation can temporarily block concurrent writes; use a planned release window and abort/retry rather than forcing through contention. Migration failure rolls back its transaction. Seed failure does not undo an already committed schema migration.

## Security and state guarantees checked locally

Authenticated clients receive SELECT only on new tables; anon receives no access. Session RLS uses `auth.uid()` ownership and child reads follow the parent's owner. Direct client DML/TRUNCATE and mapping approval are denied, including under simulated broad Supabase default grants. Trusted owners/service administrators remain privileged.

The public wrapper is SECURITY INVOKER; the private saver is SECURITY DEFINER. Both have `search_path = ''`, use qualified application objects and have no dynamic SQL. Authenticated USAGE and private EXECUTE deliberately allow delegation and direct private invocation; both entry paths enforce the same owner and prescription checks. The trigger also has an empty search path. Its raw condition is correctly quoted: `or new.review_status = 'proposed') then`.

New registration validates the caller, payload owner, existing session owner, active owned training plan/day, exact source prescription, Gym preservation or approved/enabled Home mapping IDs/versions, published actual exercises, target/equipment/prescription/duration metadata. Nullable target mismatches are rejected. Updates preserve the immutable registered snapshot; retirement, unpublishing or source deletion do not invalidate an already registered historical session. They cannot authorize a new unapproved Home prescription.

Per-owner/day advisory locking and the unique active-session index prevent duplicate first registration. Same-UUID exact retries are idempotent; conflicting retries and stale base revisions return `40001`. Completed/abandoned sessions cannot resume or mutate through a higher revision. Completed status requires every set; abandoned outcomes retain partial/discarded semantics.

Source plan/day/set-source/actual/mapping foreign keys use SET NULL where historical references must survive; immutable JSON preserves original identifiers and metadata. Parent session deletion cascades to its set grid; auth-user deletion cascades to that user's sessions. Mapping source/alternative library references use RESTRICT: a later seed insertion can prevent deletion of those exercise-library rows even while mappings are disabled. This expected seed dependency is separate from schema deployment and requires review before seeding. Reviewed/retired mapping definitions and review metadata freeze; administrators may disable/retire and create a new version instead of rewriting definitions.

Hosted Data API exposed-schema configuration, real JWT behavior, schema-cache refresh and device/network flows have not been verified by local SQL tests. Their success must not be inferred from the wrapper's local grants.

## Disabled seed status

Exactly six proposed rows remain `review_status = 'proposed'`, `enabled = false`. Their referenced public library IDs exist in the fresh read-only catalog check. Programming, suitability and loading still require reviewer sign-off; these rows are **not professionally approved exercise programming or medical clearance**. No additional mapping was fabricated.

Schema-only deployment creates zero mappings. Separately inserting this seed still creates zero enabled/approved Home choices; Gym session persistence can work while Home adaptation remains unavailable for unsupported days. Coverage is limited to these catalog-backed dumbbell proposals. `ON CONFLICT DO NOTHING` never overwrites an existing row; if any unexpected mapping UUID already exists at seed time, stop and review rather than assuming it is proposed/disabled.

## Test results after cleanup

| Check | Result |
| --- | --- |
| Raw grammar / preserved hashes | PASS: 36 schema statements, 8 seed statements; canonical copies match |
| Disposable schema + six-row seed execution | PASS on PostgreSQL 18 |
| RLS / owner / anon / direct private RPC / direct DML denial | PASS |
| Session RPC / approved mapping / forged metadata rejection | PASS |
| Duplicate-session / concurrent first insert / retry / revision / terminal tests | PASS |
| Gym/Home snapshots, equipment, duration and nullable-target validation | PASS |
| Approval freeze / retirement / foreign-key history preservation | PASS |
| Flutter tests | PASS: 55/55 |
| Flutter analyzer | FAIL: exit 1, zero errors, 15 existing warnings, 72 existing infos; unchanged baseline |

Executed with the exact release copies:

```text
python test/sql/phase2b_local_pg_test.py --schema supabase/migrations/20261009174458_arc_phase_2a_2b_training_variants.sql --seed supabase/seeds/20261009174458_home_mapping_seed_disabled.sql
flutter test
flutter analyze
```

The SQL test only contacts `127.0.0.1:55439`, uses synthetic fixtures/identities and removes its successful disposable database. The owned PostgreSQL cluster was stopped afterward. Local tests exercise the feature contracts; they do not prove every existing hosted application flow. No mascot, AI/LLM, Coach or unrelated feature source was modified during this cleanup.

## Backup and recovery gate

**FAIL: a usable backup/recovery point has not been verified.** The qualified `supabase backups list --project-ref nbojicqbpqgotdmdayku --output json --agent yes` read-only attempt failed for missing CLI access token. No enabled browser surface was available for dashboard verification. A healthy project or schema catalog JSON is not a restorable database backup.

Before deployment, record a completed backup ID/timestamp and retention/restore availability, or a validated restorable database export/recovery point covering the existing baseline. Confirm the recovery point still exists immediately before execution. Document auth/database coverage and any separately needed Storage file protection; database backups do not restore deleted Storage object bytes. Verification must include a usable restore procedure and preferably a restore drill in a separate environment. See [Supabase backup and recovery documentation](https://supabase.com/docs/guides/platform/backups). Do not initiate production restore as a verification step.

Before commit, let PostgreSQL roll back a failed transaction. After commit, preserve session history and use a corrective forward migration. The following is a **proposed emergency containment procedure, not executed or independently authorized**:

```sql
begin;
revoke execute on function public.save_workout_session(jsonb) from public, anon, authenticated;
revoke execute on function arc_private.save_workout_session(jsonb) from public, anon, authenticated;
update public.workout_alternative_mappings set enabled = false where enabled;
commit;
```

This stops client session saves and new mapping-based adaptations, retains owned read history and does not destroy existing application data. Existing app drafts must remain local/unconfirmed while saves are paused. Keep trusted administration controlled. Restore EXECUTE only through a reviewed fix after validation. Do not drop tables/functions/schema, use destructive DROP/CASCADE, delete session history, reset the database, replay the obsolete prototype, or perform broad history repair. A whole-project recovery can lose changes after the recovery point and requires a separate outage/restore plan and explicit approval.

## Final release gates

| Gate | PASS / FAIL |
| --- | --- |
| Exactly three obsolete repository migrations removed; live objects untouched | PASS |
| Exactly one planned schema migration; seed separate and unchanged | PASS |
| Correct live project, schema/history read-only audit and no training-name collisions | PASS |
| Existing data preserved by proposed additive operations | PASS by review; temporary DDL locks disclosed |
| Training security/state/SQL contracts and Flutter tests | PASS locally |
| Analyzer clean exit | FAIL: existing 87 diagnostics |
| Authenticated CLI pending-list / qualified dry-run | FAIL: credentials unavailable; connector/inventory comparison only |
| Live PostgreSQL 17.6 runtime and hosted RPC verification | FAIL: not run |
| Usable current backup/recovery point | FAIL: unverified |
| Explicit approval of this final report before any production write | PENDING: execution boundary retained |

**Stop here.** Resolve the failed safety gates and obtain explicit approval before any production migration, seed or migration-history change. No obsolete-history repair is needed under this baseline decision.
