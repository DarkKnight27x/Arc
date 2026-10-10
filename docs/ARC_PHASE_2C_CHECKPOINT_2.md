# ARC Phase 2C — eligibility revision and Checkpoint 2

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

Completed 10 October 2026. **Stop at Checkpoint 2: previews only, no activation or persistence.** This document supersedes the per-exercise approval dependency and development-preview path described in the original Checkpoint 1 handoff.

## Changed files

All paths are relative to `C:/Users/ivang/ARC VSCODE/Arc`.

| File | Change in this checkpoint |
| --- | --- |
| `lib/data/training_metadata.dart` | Central muscle/anatomy/equipment normalization, immutable library metadata, optional richer metadata support |
| `lib/data/training_plan_models.dart` | Library eligibility; removes runtime approval classification and development-only result; journey in days; eligible count |
| `lib/data/training_catalog_source.dart` | Fresh paginated `exercise_library` reads; no approval-table query |
| `lib/data/training_programming_rules.dart` | Isolated conservative product defaults; removes proposed-rule review flag as a runtime preview gate |
| `lib/data/training_plan_generator.dart` | Metadata selection, Gym/Home previews, 30/60/90-day journeys, no development escape hatch |
| `lib/data/training_coverage_validator.dart` | Direct coverage and optional explicit movement validation; retains identity, prescriptions, volume, frequency, duration and recovery checks |
| `lib/data/arc_plan_builder_service.dart` | Read-only profile/context/catalog orchestration; refetches catalog on every Generate; rejects account changes |
| `lib/start_arc_page.dart` | Start, configuration, generation, complete weekly preview and editable unavailable states |
| `lib/widgets/start_arc_entry.dart` | Owner-scoped active training-plan check, retry on failure and Home navigation |
| `lib/home_page.dart` | Only adds the entry widget/import in this checkpoint; earlier profile changes were already present |
| `lib/anatomy_test_page.dart` | Optional priority mode, independent state, canonical selection summary, Continue and retry handling |
| `assets/body_parts/index.html` | Opt-in selection protocol and cap; default Browse protocol remains unchanged |
| `test/training_plan_generator_test.dart` | Revised eligibility tests plus journey, coverage, location and retained deterministic/programming checks |
| `test/start_arc_test.dart` | Flow, prefills, journey choices, themes, narrow screen, errors, isolation and GET-only service tests |
| `test/anatomy_selection_test.cjs` | Executes actual anatomy JavaScript: Browse messages, cap, deselection, front/back and reset |
| `docs/ARC_PHASE_2C_CHECKPOINT_1.md`, `docs/ARC_PHASE_2C_ARCHITECTURE_AUDIT.md`, `supabase/README.md` | Supersession/future-governance notes |
| `docs/ARC_PHASE_2C_CHECKPOINT_2.md` | This handoff |

No auth, onboarding, Train, session RPC, Rehab, Coach, AI or mascot implementation was changed in this checkpoint. Existing dirty files from earlier work were preserved.

## Eligibility and dynamic expansion

Previously an exercise needed a matching approved/enabled generation profile with a frozen source snapshot. That table is now neither queried nor required. The review-only SQL remains outside `supabase/migrations`, unapplied and unused, as a possible future governance layer. No professionally reviewed status is inferred from publication.

An eligible row must have:

- `is_published == true`, a UUID-shaped stable ID and nonempty display name.
- String, nonempty `target_muscle` and `equipment`, normalized to valid canonical identifiers (`^[a-z][a-z0-9_]{0,63}$`).
- A nonempty instructions array, with every element a nonempty string; null, numbers, blank entries and non-array values fail eligibility.
- Valid optional metadata if present: difficulty is beginner/intermediate/advanced; optional `required_equipment`, `movement_patterns`, and `allowed_locations` are nonempty string arrays with valid identifiers. Allowed locations must be Gym/Home. Null or malformed optional arrays are rejected.

Missing/null difficulty is accepted as unknown; it is **not** evidence of beginner suitability. Experience changes set prescriptions and respects difficulty where present. Secondary muscle labels cannot replace missing direct primary coverage.

Every Generate reads the current library, ordered by UUID and paginated until an empty page. It advances by the actual returned row count, handles server row caps, rejects repeated IDs and discards completions after account changes. No exercise-name matching, UUID allowlist, fixed catalog count, cached candidate pool, demo path or AI is used. Eligible new rows automatically become candidates; tests show added metadata records improve coverage and permutations preserve deterministic results. Identical inputs and rule versions produce identical previews.

## Normalization and programming limits

Actual inspected values include `pectorals`, `delts`, `upper back`, `spine`, `body weight`, `dumbbell`, `leverage machine`, `sled machine` and `smith machine`. Central aliases map these to chest, shoulders, upper_back, spinal_extensors, bodyweight, dumbbells and canonical equipment identifiers. Anatomy aliases additionally include deltoids, gluteal, hamstring, forearm and upper-back/lower-back. This is vocabulary normalization, never movement equivalence.

The live schema has no movement-pattern or complete equipment-requirement fields. No patterns are inferred from names, instructions or secondary muscles. The current baseline validates direct chest, shoulders, triceps, upper_back, lats, biceps, quadriceps, hamstrings, glutes, calves and abs coverage. Optional priorities are added in their appropriate split. Explicit future library pattern metadata influences selection/order; required patterns are enforced only when every selected exercise in that session has explicit pattern metadata. Partial/absent metadata does not establish complete movement coverage.

Product defaults use 2 sets for beginners/intermediate, 3 for advanced, at most one extra set for priorities, goal-specific rep/rest ranges, at least two direct weekly exposures, at least two calendar days between direct exposures including Sunday→Monday, and at most 12 direct sets per muscle/week. Splits cover 2–6 training days. Full sessions include a five-minute warm-up, a generic conservative 60-second work estimate per set, between-set rest and 30-second transitions. Journeys are 30/60/90 days; the initial block is four weeks. No automatic load progression is prescribed. Adults with reported limitations or missing adult suitability information receive an unavailable result.

Known limits: missing difficulty cannot establish exercise-specific suitability; one equipment label may omit benches, bars or other support surfaces; generic time estimates are not measured timings; direct primary coverage cannot establish compound movement balance or indirect-muscle recovery. Location filters explicit library restrictions where available, and available equipment is selected explicitly; Gym/Home alone does not imply ownership of equipment. Native Home activation/session semantics are deferred to Checkpoint 3.

## UI and anatomy integration

Home shows **Start My ARC** only after a successful authenticated read confirms no active `plan_type=training` plan owned by the current user. A failed read provides a retry and never guesses that no plan exists.

Flow: **Home → Start My ARC → Select Priority Muscles → Configure ARC → Generate Plan → Preview/unavailable**. The existing body map has a dedicated opt-in mode with at most three highlighted selectable muscles, front/back, reset, canonical selected-state summary and Continue. Non-muscle body regions are excluded. Its JavaScript emits full selection arrays in this mode, keeping highlights and Flutter state synchronized. Default Browse keeps its prior toggle messages, unconstrained selection, `MuscleFocus` behavior and discovery navigation. Builder mode never updates `MuscleFocus`.

The configuration prefills goal, experience, training frequency, location and duration from the current profile. Actual weekdays can be edited; profile frequency selects a recovery-spaced initial schedule. Missing/ambiguous location requires a Gym/Home choice for the initial block. Equipment is explicitly selected from the current eligible catalog metadata. Configuration is local and does not update the profile. Journey choices remain independent of training frequency. Generation rechecks current age and reported limitations through existing read-only profile/context services.

A successful preview displays all seven weekdays, rest days, session titles, real exercise names/IDs, sets/reps/rest, estimated duration, priorities, journey days and first-block duration. `canActivate` is always false. Unavailable screens use product wording, identify affected selected priorities where available, and offer editing; raw issue codes remain in structured internal results. Load and generation failures are sanitized and retryable. Account changes dismiss the builder and nested selection routes, and stale completions are discarded.

## Real catalog evidence and examples

Read-only verification against `nbojicqbpqgotdmdayku` on 10 October: 30 rows, all published; all 30 satisfy the basic eligibility checks; all difficulty values null; no `exercise_generation_profiles` table. Counts are evidence snapshots, not constants in code. No live user rows were inspected for this report.

**A successful balanced preview using the current real catalog is not possible.** It contains no direct quadriceps or hamstrings targets. Glute exercises with secondary leg labels do not fill those gaps. Nothing was invented or reclassified to manufacture success. Successful previews are verified only with clearly synthetic automated fixtures, which are not a runtime product mode.

Real unavailable example: adult age 25, Build muscle, Beginner, Gym, Monday/Thursday, 90-minute limit, 30-day journey, no extra priorities, all equipment labels present in the real catalog selected. Result: 30 eligible candidates, no preview, direct hamstrings/quadriceps missing on both training days and insufficient frequency for both. Adding either as a priority does not silently remove it. The saved example JSON contains the exact configuration and structured result.

## Verification and Checkpoint 3 boundary

Final verification:

- Focused Flutter tests: **48 passed** (36 generator/catalog tests, 12 builder/UI tests).
- Full Flutter suite: **131 passed**, including existing auth/profile, training/session and unrelated feature tests.
- Actual anatomy JavaScript regression harness: **PASS**, executed using `node test/anatomy_selection_test.cjs`.
- Analyzer for the 12 new/revised training, builder, anatomy and test files: **no issues**.
- Full `flutter analyze`: **0 errors, 15 warnings, 72 infos (87 existing diagnostics)**. The command exits nonzero because the repository's existing warnings/infos remain; no new diagnostics were introduced.

Commands: `flutter test test/start_arc_test.dart test/training_plan_generator_test.dart`; `flutter test`; `flutter analyze`; `node test/anatomy_selection_test.cjs`. Automated checks use mocks/disposable fixtures; the live project was accessed only using SELECT statements. No migration, seed, approval, account creation, profile update, catalog update, active plan write or RPC execution occurred.

Before Checkpoint 3: expand actual primary leg coverage; define and implement owner-checked atomic/idempotent plan activation, version/conflict handling and compatible native Home semantics; decide how richer exercise metadata and rule calibration support production prescriptions. The approval proposal remains optional future governance, not a newly imposed runtime prerequisite.

Manual Android verification remains: local WebView asset loading, highlights and summary across front/back/reset, three-selection cap, back/cancel behavior, actual Home entry, profile prefills, network interruption and account switching with nested routes. No hosted/device end-to-end success or production activation is claimed.
