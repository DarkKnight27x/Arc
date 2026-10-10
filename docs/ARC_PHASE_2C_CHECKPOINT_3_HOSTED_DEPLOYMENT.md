# ARC Phase 2C Checkpoint 3 hosted deployment

**PASS — deployed and verified 10 October 2026, 15:57 UTC** to `nbojicqbpqgotdmdayku` (PostgreSQL 17.6). Execution stopped after SELECT-only verification. Hosted Android/RPC end-to-end testing remains outstanding.

## Recovery

`C:\Users\ivang\Documents\ARC-Backups\arc_before_training.backup` is readable: complete `pg_restore --list` and full archive-payload extraction to `NUL` both returned exit 0 using PostgreSQL 17.11 tools. Archive: CUSTOM/gzip, 493,770 bytes, 561 TOC entries, source PostgreSQL 17.6. Its header records creation at `2026-10-10 00:49:51` (timezone unspecified). SHA-256:

```text
4f6ddbb035b4b4cda1792133fe114f8f7c307f863dae7c83de6d4651a862a946
```

Platform `backups list` reported `walg_enabled=true`, `pitr_enabled=false`, and an empty backup list. No additional platform restore point was confirmed. The local logical archive is the confirmed recovery path; an actual restore was not performed. It predates this deployment and may predate intervening training/catalog changes, so a whole-database restore would require separate review of subsequent data and migrations. Prefer the separately approved forward recovery described in the CP3 review for an activation-only issue, preserving current rows.

## Migration and CLI execution

Only `supabase/review_only/20261010134016_arc_phase_2c_plan_activation.sql` was copied into `supabase/migrations/`. Its retained review copy and deployed copy both match the approved SHA-256:

```text
94f945ba0f0aeaa84972bf4171e3da43042add5ce156f4467ad859505490e0dc
```

Before deployment, qualified CLI migration history showed the old version applied and only `20261010134016` pending. The exact approved dry-run command returned exit 0:

```text
Would push these migrations:
 • 20261010134016_arc_phase_2c_plan_activation.sql
migrations: [20261010134016_arc_phase_2c_plan_activation.sql]
seeds: []
roles: []
```

The exact approved command without `--dry-run` returned exit 0 and reported applying only that file. `--skip-vault` was used on both commands. No historical migration, catalog seed, mapping seed, classification proposal or superseded session SQL was replayed. No reset, broad history repair or manual hosted user/profile edit occurred.

Remote history after deployment:

| Version | Name |
|---|---|
| `20261009174458` | `arc_phase_2a_2b_training_variants` |
| `20261010134016` | `arc_phase_2c_plan_activation` |

## SELECT-only verification

- Nullable JSONB `workout_plans.generation_metadata` exists; no metadata was backfilled.
- Unique `workout_plans_activation_key` exists; `one_active_plan_per_type` remains unchanged.
- Both `activate_generated_training_plan(jsonb)` functions exist. Public wrapper: SECURITY INVOKER. Private implementation: SECURITY DEFINER. Both have an empty `search_path`.
- Authenticated can EXECUTE both; anon and PUBLIC cannot. Authenticated retains private-schema USAGE without CREATE. Trusted administrative grants remain.
- On all three plan tables, anon/authenticated have no INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER or column-write privileges. SELECT grants and enabled RLS remain; all existing owner policies are byte-for-byte identical to the immediate pre-deployment snapshot. Hosted role impersonation/RPC writes were not performed.
- Public/private `save_workout_session(jsonb)` body fingerprints, security settings and ACLs are unchanged.
- Before/after counts and deterministic aggregate row fingerprints match for exercise library, mappings, auth users, profiles, plans, days, prescriptions, sessions and sets. Exercise catalog remains 78 rows. Plans/session history had zero rows before and after this deployment; no plan was created from SQL. Existing account/profile data is unchanged.
- No seeds were inserted, approved or enabled. Home mapping table remains empty; the six repository proposals remain disabled and separate.

Evidence:


## Next Android manual test

1. Install/run the current Checkpoint 3 Android build and sign into your existing, onboarding-complete test account. Open Home → Start My ARC.
2. For the first available Gym test, use balanced/no priorities, Build Muscle, Beginner where configurable, Gym, full gym equipment, Monday and Thursday, 60-minute sessions and a 30-day journey. This broad-equipment configuration activated in the disposable real-catalog test; restricted equipment/priorities may legitimately produce unavailable coverage.
3. Tap Generate Plan. Check visible loading followed by a readable preview; edit/back before confirmation must not persist a plan. Missing exercise GIFs should show COMING SOON without blocking activation.
4. Tap Confirm My ARC. Check visible progress and duplicate-tap/back protection, then the success notice and automatic Train navigation. Verify Monday/Thursday workouts and rest-day placeholders; do not confirm a second plan unless intentionally testing explicit replacement.
5. Open each persisted Gym day in SessionPlayer. Check exercise names/order, sets/reps/rest, optional media, set completion and timers. Save/finish a test workout through the app's normal controls.
6. Close/reopen ARC, return to Train and confirm the active plan and saved history persist. Log out/back in; if you have another approved account, switch accounts and verify plan/history isolation.
7. Select Home adaptation. With no approved Home mappings, verify honest unavailable feedback; do not approve/enable seed mappings to bypass it.
8. In a controlled retry test, interrupt the connection around confirmation, keep the same preview, reconnect and retry. Expect a recoverable message or the same activation result, never duplicate plans. Intentional active-plan replacement must be explicit and preserve prior history; use an approved test account for this case.

No hosted activation call or device test was performed during deployment. Stop here and carry out the Android checks through the app.
