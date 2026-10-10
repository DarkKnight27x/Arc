# ARC Phase 2C Checkpoint 3 — implementation and activation review

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

Prepared 10 October 2026. **Local implementation/tests pass. Hosted deployment has not been performed.** No hosted users, profile records, exercise records, mappings, settings, schema or migration history were changed in this checkpoint.

## Review result

| Check | Result |
|---|---|
| Explicit Preview → Confirm My ARC | PASS |
| Atomic activation, caller ownership and current catalog validation | PASS locally |
| Same-key retry and concurrent activation/replacement protection | PASS locally |
| Rollback after day-2 / exercise-row insertion failure | PASS locally |
| Plan history, prescription FKs and registered session history preserved | PASS locally |
| Existing Train refetch and Home → Train navigation | PASS in Flutter tests |
| Real catalog → persistence → Train parser → Gym SessionPlayer / save RPC | PASS in disposable fixtures |
| Home mapping enforcement and unchanged Phase 2A/2B semantics | PASS locally |
| Focused Flutter tests | PASS — 102 |
| Full Flutter suite | PASS — 177 |
| Flutter analyzer | NOT CLEAN — 0 errors, 15 warnings, 70 infos; exactly the prior 85 diagnostics, no additions |
| Hosted activation and real Android end-to-end | PENDING separate migration approval and manual verification |

The 13 new activation tests are included in the focused and full totals. SQL activation tests pass seven integration groups, including all nine available exported real-catalog preview cases. The existing Phase 2A/2B SQL suite also passes. SQL tests ran on disposable **PostgreSQL 18.4**, not on hosted PostgreSQL **17.6.1.166**. The proposal uses PostgreSQL 17-compatible constructs; a hosted deployment/test is not claimed. A PostgreSQL 17 rehearsal should precede production execution if exact target-version testing is required by the deployment gate.

## Read-only hosted findings

Project: `nbojicqbpqgotdmdayku`. Remote migration history contains only `20261009174458_arc_phase_2a_2b_training_variants`. Neither the activation RPC nor its metadata column/index exists remotely. The existing `plan_type` enum includes `training`, `rehab`; `plan_status` includes `draft`, `active`, `archived`. The existing `one_active_plan_per_type` partial unique index already prevents two active plans for an owner/type; no duplicate active plans were observed by an aggregate check.

Plans, days and exercises already have owner-scoped `ALL` authenticated RLS policies. Both `anon` and `authenticated` have broad table privileges, including INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER. Thus an owner can currently bypass the proposed activation rules through direct plan DML; RLS alone does not establish the new write boundary.

The repository's actual plan-table call sites are read-only: `WorkoutService` and `StartArcEntry`. There are no INSERT/UPDATE/DELETE/upsert calls to these three tables in `lib`. The hosted function-body inspection found `arc_private.save_workout_session` referencing these tables for validation/read purposes, without writing them. Its session writes use SECURITY DEFINER and retain their existing grants. This is not an audit of unknown external tools or administrative writers; confirm any such clients before approving ACL hardening.

Evidence:

- `docs/phase2c_checkpoint3_local_e2e.json`: synthetic local owner/plan/day/prescription IDs with real exercise-library UUIDs, persisted relations, activation payload and successfully saved Gym snapshot.

## Exact migration proposal and effects

**Unapplied review file:** `supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql`.

The filename was created with `supabase migration new arc_phase_2c_plan_activation`, then moved out of automatic migration discovery. No new file was left pending in `supabase/migrations/`.

Within one migration transaction it:

1. Adds one nullable `generation_metadata jsonb` column to `public.workout_plans`. Existing rows receive NULL; existing prescriptions and records are not rewritten.
2. Adds `workout_plans_activation_key`, a partial unique expression index on `(user_id, generation_metadata->>'activation_key')` for metadata source `arc_generator`. It covers archived generated plans as well as active ones.
3. Revokes client INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER on only the three plan tables, including explicit INSERT/UPDATE/REFERENCES column grants. It checks effective privileges and RLS, aborting on unexpected inherited write access. SELECT, existing owner policies and explicitly granted administrative/service-role writes remain. Rehabilitation plan readers use the same preserved SELECT path.
4. Creates `arc_private.activate_generated_training_plan(jsonb)`, SECURITY DEFINER with empty `search_path`, and the public SECURITY INVOKER RPC wrapper of the same name. Only authenticated receives EXECUTE; PUBLIC/anon receive none. The deployed Phase 2A/2B private-schema USAGE grant remains the prerequisite; no private-schema CREATE grant is added.
5. Notifies PostgREST to reload its schema cache.

It does not alter enum values, foreign keys, `save_workout_session`, mapping approval/freeze triggers, catalog data, auth, profiles, onboarding, meals or rehabilitation prescriptions. It contains no DROP, deletion, seed, approval or migration-history repair. Migration lock timeout is 5 seconds; statement timeout is 60 seconds, and a failed migration rolls back its DDL/grants together.

The private-definer/public-invoker structure and explicit function ACLs follow the current [Supabase database function guidance](https://supabase.com/docs/guides/database/functions).

## Activation payload and trusted guarantees

Flutter calls `activate_generated_training_plan` with one named argument, `payload`. Its projection is implemented in `trainingActivationPayload` in `lib/data/plan_activation_service.dart`. The complete locally executed example is in `docs/phase2c_checkpoint3_local_e2e.json` under `activation_payload`.

| Field | Contract |
|---|---|
| `contract_version` | integer 1 |
| `user_id` | exactly the authenticated caller UUID |
| `idempotency_key` | UUID generated once when this preview is first confirmed |
| `plan_type` | `training` |
| `rule_version` | `arc-2c-direct-coverage-v2` |
| `generator_version` | `arc-2c-generator-v1` |
| `block_weeks` | integer 4 |
| `replace_active` | explicit boolean, normally false |
| `expected_active_plan_id`, `expected_active_version` | supplied only for explicit replacement; must match the current owned active plan |
| `config` | goal, experience, Gym location, unique training weekdays, equipment, up to three canonical priorities, duration target and 30/60/90-day journey |
| `days` | ordered training-day rows only: weekday, split/title, estimated minutes, optional notes, ordered exercise rows |
| exercise row | real `exercise_id`, contiguous zero-based `sort_order`, sets, nonempty reps, rest seconds, optional notes |

No private age, injury report, profile object, exercise name/GIF snapshot, client issue state or `can_activate` flag is sent or stored as activation authority. The existing pure planning models still carry no activation authority. The server constructs the plan name and validates day titles against the supported split schedule.

The server independently enforces authenticated owner/profile existence, bounded JSON/allowed keys, UUIDs, 2–6 unique weekdays, supported journey/configuration enums, schedule/day count/order, nonempty days, unique exercise IDs/order, positive bounded sets, nonempty bounded reps, bounded nonnegative rest, notes bounds, current publication/name/instructions/target/equipment/difficulty validity and configuration-compatible equipment/experience. It locks referenced library rows `FOR SHARE` in UUID order so publication/metadata edits or deletion cannot occur between validation and insertion. It mirrors required direct muscle coverage per split and verifies the current generic duration estimate (300-second warm-up, 60 seconds per set, between-set rest, 30-second transitions) and requested duration budget.

**Programming limits:** this is a versioned activation contract, not a second selection engine. Deterministic selection, optional-priority placement, exact goal-based prescription defaults, weekly volume/frequency, cyclic recovery, optional movement-pattern coverage and the builder's adult/limitations scope check remain the existing client generator/validator's guarantees. The SQL does not claim full generator equivalence, medical screening, professional exercise approval or clinically cleared programming. Unknown difficulty remains unknown, and missing movement-pattern/support-equipment metadata is not invented. Future catalog schema or rule-version changes require revisiting this contract rather than silently treating new metadata as covered.

Gym is the activation scope. Available Home-configured previews receive an explicit explanation and configuration-edit path instead of an activation CTA. Train's existing Home adaptation still requires approved/enabled mappings, even for bodyweight or dumbbell source exercises. No mapping is created, enabled, approved or relabeled by activation.

## Atomicity, idempotency and replacement

An owner-scoped transaction advisory lock serializes all activations for that caller. The function first checks a previously committed owner/key result; identical JSONB payload fingerprint returns the same plan ID/version and its current status. Key reuse for changed content returns `PT409`. The fingerprint is an MD5 of canonical JSONB solely for retry-content comparison, not a signature or authorization decision. The unique owner/key index and existing active-plan unique index provide independent database backstops.

For a new activation: validate current active-plan state, create draft plan with next owner/training version, insert all days and exercises, archive the old plan only for an exact explicit replacement intent, then activate the new plan last. Errors roll back the entire statement, including draft/child inserts and status transitions. Same-key concurrent requests converge. Different keys competing for initial activation produce one winner/one conflict; competing replacements using the same old ID/version likewise produce one winner/one conflict.

Without replacement intent, an existing active plan produces conflict and remains unchanged. Replacement requires both the expected active ID and version. Old plan/day/exercise rows and all saved session FKs remain; no rows are deleted. A retry of an older successful key returns its original archived result without reactivating it. Train then reads whichever plan is currently active.

Flutter keeps one key for retries while that preview remains open, including ambiguous network/timeouts. Editing/regeneration starts a new attempt/key. The key is not persisted across process termination; after restart the active-plan guard prevents duplicate activation, but it is not a durable offline confirmation queue. There is no replacement UI in this checkpoint: accidental access with an existing plan produces conflict, not a silent replacement. The service/RPC explicitly support reviewed replacement intent for future callers.

Already registered sessions can continue/finish after archival; terminal retries also remain valid. A never-synced old-plan draft still faces the existing first-save active-plan check after replacement. A future replacement UI must require resolving/syncing such drafts first; this checkpoint does not weaken session authorization to accommodate them.

## Flutter and session integration

`StartArcPage` adds Confirm My ARC only for available Gym previews. It prevents same-frame duplicate calls, displays activation progress, disables conflicting edits/back navigation while writing, preserves preview on failure, and presents a visible fixed error banner for conflict, unavailable activation, network/timeout, validation or account changes. SQL error bodies are not displayed or logged. Success remains guarded against duplicate submissions while its route closes.

`PlanActivationService` calls only the RPC, validates the response, checks that the account is unchanged, and publishes an owner-scoped `WorkoutService` invalidation event. `TrainPage` listens, refetches its existing service/model path, ignores other-owner events, discards stale loads and removes its listener on disposal. A newly activated Gym plan initially displays Gym; existing profile-driven location behavior remains for ordinary loads. No workout rendering or generator rewrite was introduced.

`StartArcEntry` consumes the successful typed navigation result, rechecks active-plan availability, displays “ARC activated. Your weekly plan is ready in Train.” and invokes Home's existing Train-tab callback. The already mounted Train page refreshes without restarting ARC.

Only training days are persisted. Existing `workoutWeek` fills rest placeholders. Real persisted prescription UUIDs remain distinct from actual library exercise UUIDs. Local tests compare the generated payload against exact saved sets/reps/rest/order, parse the actual nested relation shape through `WorkoutService`, construct `WorkoutSession.start` for every persisted day, open unchanged `SessionPlayer`, and compare its source snapshot with the snapshot successfully saved through the original Phase 2A/2B RPC. Both null and existing GIF paths remain optional. `gym_original` uses the exact source sequence; unreviewed Home conversion is rejected.

## Exact files changed in this checkpoint

- `lib/data/plan_activation_service.dart` — new contract, typed results/errors and RPC service.
- `lib/start_arc_page.dart` — explicit confirmation, retry state, progress, error visibility and navigation protection.
- `lib/data/workout_service.dart` — owner-scoped plan invalidation notification.
- `lib/train_page.dart` — notification/refetch integration and stale/disposed-load protection.
- `lib/widgets/start_arc_entry.dart` — typed activation result, success notice and existing Train callback; injected builder supports navigation testing.
- `lib/home_page.dart` — connects the entry to the existing Train-tab callback.
- `test/plan_activation_test.dart` — 13 new contract/service/UI/navigation/refetch/real-catalog session tests.
- `test/exercise_media_test.dart` — updates the preview-copy assertion for explicit confirmation; media behavior is unchanged.
- `test/sql/phase2c_activation_local_pg_test.py` — disposable schema/ACL/RLS/concurrency/rollback/replacement/session tests.
- `supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql` — new unapplied migration proposal.
- `supabase/README.md` — records the review-only workflow.
- `docs/ARC_PHASE_2C_CHECKPOINT_3.md` — this report.
- `docs/phase2c_checkpoint3_local_e2e.json` — local fixture output, real exercise IDs.

Pre-existing working-tree changes were preserved. No Checkpoint 3 edits were made to auth/onboarding, SessionPlayer/session persistence, generation architecture/eligibility, Rehab, Coach, AI/LLM, mascot, anatomy defaults or media implementation.

## Deployment order and recovery — approval required

1. Review and separately approve the exact activation SQL **including plan-table privilege revocations**. Confirm unknown external plan writers, a usable backup/recovery point, target PostgreSQL rehearsal requirements, target project ID, current schema/history and private-schema ACLs before live execution.
2. After approval only, promote this one file from `review_only/` to `migrations/`. Keep the already deployed `20261009174458_arc_phase_2a_2b_training_variants.sql`. Leave the older classification proposal in `review_only/` and the six proposed/disabled Home rows in `supabase/seeds/20261009174458_home_mapping_seed_disabled.sql`.
3. Inspect linked migration history and the qualified dry-run/pending list. Only version `20261010134016` may be pending. Stop for any unexpected SQL/history divergence. Never reset the DB, replay obsolete migrations, execute `workout_session_progress.sql`, repair history broadly, rerun the curated catalog seed or use an unqualified push.
4. Apply only the approved single migration through the reviewed linked-project migration procedure, with normal history recording. No seed operation is part of this deployment.
5. Verify function ACL/search_path, effective table/column write denials, retained owner SELECT/RLS and no data changes to existing plans, then test the new Android build. The app must receive the RPC before activation can succeed; missing deployment produces the recoverable unavailable state.

Before migration commit, failure rolls back schema/grants automatically. After commit, prefer forward recovery: retain metadata/indexes/plan/day/exercise/session rows and disable only activation execution if needed. The following is **review-only recovery SQL, not executed**:

```sql
begin;
revoke execute on function public.activate_generated_training_plan(jsonb),
  arc_private.activate_generated_training_plan(jsonb) from authenticated;
notify pgrst, 'reload schema';
commit;
```

Do not restore broad client DML as an automatic rollback. Correct the RPC/ACLs in a separately approved forward migration. If a particular replacement needs reversal, review that owner's current active ID/version and both plans' sessions, then perform an explicitly approved atomic status transition; preserve all records and history. No destructive DROP/CASCADE or history repair is proposed.

## Manual Android checks after approved deployment

1. Use an approved test account with onboarding complete and no active training plan; install the updated ARC build. This checkpoint created no hosted account.
2. Home → Start My ARC → balanced priorities or up to three selections → Gym → actual available equipment → Monday/Thursday → 60 minutes → 30-day journey → Generate Plan.
3. Review the real preview and missing-GIF COMING SOON tiles. Confirm must be the first write; generating/back/editing must not create a plan.
4. Tap Confirm My ARC, including rapid duplicate taps. Check visible progress and blocked back/edit controls. Success should show the ready notice and select Train immediately, with the same two workout weekdays and five rest days.
5. Select each scheduled day, keep Gym, and launch SessionPlayer. Verify actual names/targets, ordered sets/reps/rest, optional GIF fallback, check a set, exercise rest timer and next/previous behavior. Save/finish through existing session controls.
6. Close/reopen ARC and return to Train; verify the same active plan and history. Log out/switch accounts and verify no prior-owner plan/session cache is shown.
7. Check Home adaptation: it must show honest unavailable coverage when approved mappings are missing. Do not approve/enable seed rows for this test.
8. With controlled connection loss around confirmation, wait for the recoverable response, keep the preview, reconnect and retry. Check one active plan and one plan for the original owner/key. Editing/restarting intentionally does not preserve the in-memory retry key.
9. With an approved controlled second-device/test scenario creating an active plan while a preview is open, confirmation must show conflict and preserve that active plan. No silent replacement should occur.

Actual hosted RPC execution, hosted RLS after the proposed grants, real Android networking/back-button behavior and restart persistence remain manual/deployment verification. Mocked/disposable tests do not establish hosted end-to-end success.
