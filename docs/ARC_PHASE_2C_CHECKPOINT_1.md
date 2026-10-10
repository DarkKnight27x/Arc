# ARC Phase 2C — Checkpoint 1 handoff

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

> Historical handoff: the per-exercise generation approval dependency and development-preview path below are superseded by [Checkpoint 2](ARC_PHASE_2C_CHECKPOINT_2.md). The review-only SQL remains unapplied and unused; runtime candidates come from the current exercise_library.

Completed 10 October 2026 (Asia/Calcutta). **Checkpoint 1 only. Stop here for review.** No Home/anatomy/configuration screen or activation implementation was started.

## What is implemented

| File | Responsibility |
| --- | --- |
| `lib/data/training_plan_models.dart` | Immutable configuration, public catalog and versioned classification models; canonical priority aliases; stable UUID validation; frozen review snapshots; structured issue/result DTOs; a seven-day preview with rest days and journey/block distinction |
| `lib/data/training_programming_rules.dart` | Independent configurable programming manifest: split targets/patterns, goal/experience prescriptions, priority/volume bounds, calendar-day recovery, time estimates, block length and exercise order |
| `lib/data/training_plan_generator.dart` | Pure deterministic exercise selection using eligible actual records; no invented exercises/IDs, database operations or source-plan IDs |
| `lib/data/training_coverage_validator.dart` | Independent validation of direct muscle and movement coverage, frequency, recovery including Sunday→Monday, weekly sets, equipment/experience and full session time |
| `lib/data/training_catalog_source.dart` | Read-only Supabase adapter and injectable source interface; stable paginated reads, lower server row-cap handling, stale/repeated-page rejection, sanitized failures and account-change isolation |
| `test/training_plan_generator_test.dart` | 33 generator/catalog/compatibility tests with explicitly synthetic approvals |
| `test/sql/phase2c_approval_local_pg_test.py` | Disposable approval-schema, source-freshness, freeze/version and ACL/RLS tests; hardcoded local host/port, synthetic catalog, fixture cleanup |
| `supabase/review_only/20261010064421_arc_phase2c_exercise_generation_approval.sql` | Local, unapplied exercise generation classification/approval schema proposal |
| `supabase/README.md` | Corrects historical pending/deployed status and documents the isolated review-only migration |

Repository root: `C:/Users/ivang/ARC VSCODE/Arc`. The table lists exact paths relative to that root. Earlier architecture findings remain in `docs/ARC_PHASE_2C_ARCHITECTURE_AUDIT.md`.

## Generation behavior and data independence

The generator consumes a TrainingPlanConfig, TrainingCatalog and TrainingProgrammingRules. It has no literal exercise-ID allowlist, fixed catalog size or name-substring substitutions. The Supabase adapter reads the actual visible library and approval table rather than the approximate catalog count in the request.

Candidates need all of: stable real library UUID, publication, non-empty instructions, enabled approved classification, complete reviewer/reference/date metadata and an exact match with the reviewed source snapshot. Exercise edits invalidate eligibility. Location, minimum experience and every required equipment/support capability are then checked.

Classifications contain a canonical **direct primary** muscle, movement-pattern IDs, complete required equipment, allowed locations, minimum experience and reviewed work-time estimate. Raw secondary muscle metadata is preserved in the source snapshot but never counted as direct coverage. Adding eligible exercises to existing canonical targets/patterns only requires catalog/classification data; the generator source does not change.

Selection first fills every required direct target for a split. It prefers missing required patterns, then lower reviewed work-time cost, then stable UUID. Remaining pattern gaps can only use another real, compatible exercise with a direct target belonging to that split. It never substitutes an unrelated target. A configurable pattern order places proposed compound work before remaining accessory work. Inputs are copied/frozen; catalog ordering does not change results.

Selected priorities retain the balanced baseline and receive a bounded extra-set allowance. Optional priorities such as forearms require their own genuine direct coverage. Requested priorities that cannot be supported are reported, not silently removed. Duration, experience, equipment, volume and recovery failures produce structured issues and an unavailable result. No load/weight increases are generated.

Results serialize a status, actual catalog/eligible counts, issue codes/details and optional preview. Normally an invalid/incomplete plan has no preview. Explicit `allowDevelopmentPreview: true` may return a labeled incomplete proposal containing only eligible exercises; `available` stays false. Both preview/result `canActivate` are **always false in Checkpoint 1**, including complete synthetic proposals. There is no persistence/activation method, so an incomplete development proposal cannot be submitted through a new activation path.

`available_for_review` is a proposal status, not server authorization. The client-side `reviewed` flag and classification objects cannot be trusted by a future activation API. Checkpoint 3 must validate current server-owned manifests, coverage and ownership independently/authoritatively inside the activation boundary and close direct-plan write bypasses. No production approval authority is implied by these DTOs.

## Proposed programming defaults — not professional approval

Default rule version `proposed-arc-2c-v1` has `reviewed = false`. These are configurable development proposals requiring programming/product review:

- 2/3 days: full body; 4: upper/lower; 5: upper/lower/push/pull/legs; 6: push/pull/legs twice. Exact user weekdays are respected, with conflict detection. One/seven days are unavailable under this manifest.
- Direct baseline groups cover chest, shoulders, triceps, upper back, lats, biceps, quadriceps, hamstrings, glutes, calves and abs. Required patterns cover horizontal/vertical push/pull, knee-dominant, hip-hinge and core work.
- Beginner/intermediate base: two sets; advanced: three. Build-muscle proposal: 8–12 reps / 75s rest; lose-fat proposal: 10–15 / 60s; consistency: 8–12 / 60s. These software defaults are not validated medical prescriptions or weight-loss promises.
- Maximum three priorities, one extra set on prioritized direct targets, two direct weekly exposures, two **calendar-day** recovery spacing, maximum 12 direct sets per muscle/week.
- Estimated session cost includes five-minute warm-up allowance, reviewed work time per set, between-set rest and 30-second exercise transitions.
- Four-week initial block, capped by journey length. Journey weeks are separate (validated 1–104); later blocks require review, not automatic repetitions of future prescriptions.
- First implementation scope is Gym, ages 18–120, without reported limitations. Unsupported age/safety/location configurations are unavailable rather than treated as medically cleared.

Numeric defaults and scope are proposals, and no rule manifest was professionally approved here. Tests explicitly use synthetic reviewed rules to demonstrate the successful generation path. Runtime defaults remain unavailable even if the catalog later gains classifications until an accepted rule manifest is supplied through a trusted future integration.

The first generator is conservative and greedy, not a global schedule/selection optimizer. It may reject preferences for which a more complex optimization could find a solution. It never “fixes” a rejection by omitting essential coverage or altering requested weekdays. Calendar spacing is not exact-hour recovery; secondary overlap, whole-session fatigue, medical suitability, detailed loading and media accuracy require rule/content review.

## Actual current catalog outcome

Fresh read-only project check: **nbojicqbpqgotdmdayku** still has **30** exercise rows, all published, no difficulty values and **no exercise_generation_profiles table**. Current remote migration history remains exactly `20261009174458 / arc_phase_2a_2b_training_variants`.

The earlier catalog coverage gaps remain. The new adapter recognizes a missing approval schema and returns `approvalSchemaMissing`; publication is never a fallback approval. The generator reports `noApprovedExercises`, missing direct muscles/patterns/frequency and proposed-rule review requirements. Current catalog tests select **zero unapproved exercises**. No exercises or mappings were invented, approved, seeded or enabled.

The schema proposal deliberately inserts **zero classification rows**. Missing classification means unapproved; future proposed rows default to `review_status = 'proposed'` and `enabled = false`.

## Database change requiring separate approval

Exact file: `supabase/review_only/20261010064421_arc_phase2c_exercise_generation_approval.sql`.

The filename was created with Supabase CLI `migration new`, then moved outside `supabase/migrations/` to prevent accidental automatic migration discovery. It was executed **only on a disposable local PostgreSQL fixture**. It is not applied to Supabase and must not be promoted or executed without separate approval.

Proposed effects:

1. Create public.exercise_generation_profiles with composite library-UUID/version primary key, direct target/pattern/equipment/experience/time classification, source snapshot, review state and provenance.
2. Add a unique partial index allowing only one enabled classification per exercise.
3. Enable RLS. Explicitly revoke inherited PUBLIC/anon/authenticated privileges on this new table, then grant authenticated SELECT only. No client write policy. Clients see only enabled approved definitions whose source remains published and unchanged.
4. Add an invoker trigger in the existing arc_private schema with empty search_path and client EXECUTE revoked. Approval requires provenance and current published instructions/snapshot; approved/retired definitions are immutable, cannot be deleted, and need a new version for classification changes. Disabling/retirement is supported; retirement cannot be reversed.
5. Preserve library records via an ON DELETE RESTRICT reference. Privileged reviewer operations remain separately authorized; metadata presence does not independently prove professional qualifications.

The proposal does **not** alter auth/profiles/onboarding, existing library publication, old plans, Phase 2A/2B sessions, mapping approvals, existing policies or the session RPC. It does not contain a seed, generation/activation RPC, SECURITY DEFINER function, DROP/CASCADE or migration-history repair.

Before eventual deployment, separately review reviewer governance, supported IDs/equipment, compatibility of the new library RESTRICT FK with administrative deletion workflows, target-version execution and promotion order. Within the proposal transaction, failure rolls back creation. After use, prefer forward recovery and disable/retire unsuitable classifications while retaining reviewed provenance; do not delete catalog/history to roll back a content problem.

## Verification

| Check | Result |
| --- | --- |
| New generator/catalog tests | **33 passed** (also included in final full run) |
| Full Flutter suite | **116/116 passed** after final pagination/order changes |
| Flutter analyzer | **0 errors, 15 existing warnings, 72 existing infos**; command exit 1 for the unchanged 87 baseline issues |
| Initial targeted analysis of five new production files | No issues; final full analysis added no diagnostics |
| Disposable approval-schema execution | **PASS on PostgreSQL 18**, independent 127.0.0.1:55439 |
| SQL checks | Default proposed/disabled, zero auto-seed, ACL/RLS, no client writes/TRUNCATE/EXECUTE, valid provenance, snapshot freshness, immutable reviewed versions, retirement, one enabled version and FK deletion restriction |
| Generator checks | All goals/levels, 2–6-day splits, single/multiple priorities, equipment/support, time/recovery/volume conflicts, direct vs secondary coverage, unapproved/unpublished/stale records, catalog expansion/order independence, seven-day/block preview, immutability and tampered-prescription rejection |
| Existing Train/session data shape | Compatible via synthetic persisted source UUIDs, WorkoutService parsing, seven-day rest placeholders and gym_original session snapshot; old session contract unchanged |
| Hosted activation / real-device UI | **Not implemented or tested** in Checkpoint 1 |
| PostgreSQL 17 target-version execution | **Not run**; live metadata is 17.6, disposable execution was 18 |

The SQL fixture database was removed by the test harness and the owned temporary cluster stopped. No real users or profiles were accessed/changed for tests. Fresh remote checks were SELECT-only. Supabase changelog/function guidance was checked; no SDK/dependency version was changed. [Function guidance](https://supabase.com/docs/guides/database/functions).

## Boundaries and next checkpoints

Authentication, onboarding behavior, Rehab, Coach, AI/LLM, mascot, Home, Train, SessionPlayer and Browse Anatomy source were not modified. The previously identified anatomy state mismatch remains for focused reusable-selector work in Checkpoint 2. This checkpoint adds data/logic only.

**Not yet implemented:** Start My ARC, reusable anatomy selection mode, missing-input forms, preview UI, trusted rule-manifest delivery, journey dates/timezone, activation, idempotent/concurrent activation, owner-write hardening and Train invalidation. Duplicate/concurrent activation and plan ownership tests belong to Checkpoint 3, where an activation path actually exists; they are not claimed as passing here.

Native Home programs remain incompatible with the existing gym_original/home_curated snapshot contract and are explicitly unavailable. Checkpoint 3 must retain the Phase 2A/2B contract and introduce no silent Home relabeling or approved-mapping bypass.

**Checkpoint 1 is complete and stopped for review.** The architecture can now be exercised/expanded with reviewed classifications without generator source edits; current real-catalog generation remains honestly unavailable. Proceed to Checkpoint 2 only after this handoff is reviewed, and keep all live schema/approval/activation actions behind their separate authorization boundary.
