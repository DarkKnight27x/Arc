# ARC Phase 2B implementation

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

Date: 9 October 2026. Repository: `Arc`. Connected project: `nbojicqbpqgotdmdayku`.

Repository implementation is complete and tested locally. **No live SQL, migration, mapping approval, or production record write was performed. Cloud deployment and approved mapping coverage remain pending.** The current public catalog cannot support a complete Gym-to-Home replacement for every scheduled muscle group. The UI makes this limitation explicit and never supplies invented exercises.

## Scope and files

Phase 2B extends the existing Phase 2A player, local draft keys, session tables and RPC. It adds no separate Home history system and never rewrites a Gym plan. No mascot, Coach/AI/backend, Recover, AuthGate, HomeShell, onboarding or navigation implementation was changed in this phase. Existing profile/Home/main changes in the working tree predate this work and were retained.

| File | Change |
| --- | --- |
| `lib/data/home_workout.dart` | Deterministic curated mapping engine, exact equipment capabilities, target coverage, budget selection and disclosures |
| `lib/data/home_workout_service.dart` | Reads approved/enabled mappings and published actual library exercises; no bundled fallback or writes |
| `lib/data/training_context_service.dart` | Current-account profile preference and active discomfort report status, read-only |
| `lib/data/workout_models.dart` | Source prescription UUID versus actual exercise-library UUID; target, mapping and GIF metadata |
| `lib/data/workout_session.dart` | Version 2 immutable prescription snapshots, variant/options/source metadata and revisions; legacy Gym deserialization |
| `lib/data/workout_session_service.dart` | Exact local/remote reconciliation, conflict backups, confirmed revisions and matching-UUID local cleanup |
| `lib/train_page.dart` | Gym/Home proposal flow, injury warnings, review before Home start, current-session safeguards; text-scaled weekday selector |
| `lib/widgets/training_variant_panel.dart` | Metallic selector, conservative equipment choices, Full/30/15 budgets, async request invalidation and actual exercise previews |
| `lib/session_player.dart` | Same player for both variants; variant/options/warning display, revisioned navigation, scrollable status and wrapping controls; Keep Draft does not wait for cloud |
| `docs/sql/workout_training_variants.sql` | Consolidated Phase 2A + 2B migration proposal |
| `docs/sql/workout_session_progress.sql` | Superseded notice; old Phase 2A proposal retained for reference |
| `docs/sql/home_mapping_seed_proposal.sql`, `docs/home_mapping_proposal.json` | Six real-ID mappings, all proposed and disabled |
| `docs/exercise_catalog_phase2b.json` | Public published catalog snapshot used for the coverage review and tests |
| `test/home_workout_test.dart` | Curated engine, snapshot, service scoping, injury context, unavailable states and reconciliation tests |
| `test/home_workout_widget_test.dart` | Equipment/location changes, async invalidation, unavailable states, Home player and Back during save |
| `test/train_variant_test.dart` | Train integration, no plan/rest/empty, profile preference, active-session protection and large text |
| `test/sql/phase2b_local_pg_test.py` | Disposable loopback PostgreSQL schema/RPC/RLS contract tests with A, B and anonymous identities |

## User flow

1. Train loads the current user's latest active training plan and selected scheduled weekday through the existing workout service. Gym shows the original saved exercise sequence and its actual prescription. Missing weekdays remain rest days.
2. Profile `workout_location` can set the initial location. Users can change it for a day. Home starts with **bodyweight only**; a Home profile preference never implies equipment ownership. Profile duration informs 15/30 only when actually present.
3. Home offers No equipment, Dumbbells, Resistance bands and combined capabilities, plus Full available session, 30 minutes or 15 minutes. It displays original target focus, actual proposed moves/GIF previews, targets, sets/reps/rest, estimated duration and missing coverage.
4. Equipment/time changes clear the previous proposal immediately. A generation counter ignores late responses so a stale prescription cannot be started. Changing location changes preview only.
5. Review & start Home opens a confirmation showing the selected options, estimate and limitations. Starting snapshots the exact selected library exercises and reviewed mapping versions. Gym uses the unchanged saved prescription.
6. If any variant already exists for the day, users see Continue current session, Keep current draft, or End / discard current. The last action opens the original player, where Finish or Close > Discard explicitly records its outcome before another variant is started. Choosing a different location never silently changes the current session.
7. Both variants use the same player: variable set rows, reps, instructions, rest timer, Previous/Next, exact flags, partial completion, discard and retry. A Home flag belongs to its actual selected exercise, not to the Gym source prescription.
8. Keep Draft saves locally without waiting for a pending cloud request. A failed terminal cloud save stays reviewable and retryable; it cannot be represented as a successful cloud finish. Offline users can retain that ended draft. Starting another variant remains blocked until the existing session has been explicitly reconciled/ended, avoiding a hidden overwrite.

## Actual catalog coverage

Read-only Supabase metadata and published-library HTTP GETs found **30 published exercises**, 1 workout-plan row, 7 workout-day rows and 24 saved exercise rows. These counts do not imply that the plan belongs to the current app user. All inspected workout/library tables have RLS enabled. No Phase 2A session tables or mapping table appeared in the live table inventory; the migration list was empty. The absence of session tables establishes that the complete Phase 2A persistence schema is not deployed. Fresh RPC definitions were not retrieved independently.

All 30 difficulty values are null and all tags are empty. There is no existing movement taxonomy or band catalog coverage. Primary target counts below come directly from the snapshot, grouped for display; secondary muscle involvement does not count as a replacement for a missing primary target.

| Scheduled group | Published primary-target records | Justified Home proposal coverage |
| --- | ---: | --- |
| Chest | 3 | None. Dumbbell incline press requires an incline bench. No verified bodyweight/band press. |
| Shoulders | 2 | Standing dumbbell front raise and one-arm upright row retained as self-mappings. No automatic horizontal-press replacement. |
| Back | 3 | None for this equipment flow. Cable/machine/weighted work is not silently converted into a different movement. |
| Biceps | 6 | Standing dumbbell concentration curl; four explicit source-to-alternative mappings including its own self-mapping. |
| Triceps | 4 | None. Catalog lying extensions specify a bench; “impossible dips” require parallel bars despite a body-weight equipment label. |
| Legs | 7 | None. Gym sled/barbell/Smith movements have no verified Home strength replacement in this catalog. |
| Core | 3 | None. No reviewed equipment-free equivalent. |
| Forearms | 2 | Outside the requested seven primary groups; no added substitution. |

Equipment labels: dumbbell 8, barbell 6, cable 4, sled machine 2, Smith machine 2, weighted 2, leverage machine 2, body weight 2, assisted 1, kettlebell 1. **No bands.** The bodyweight lying twist is a glute stretch and cannot stand in for a strength prescription. The other bodyweight entry requires dip bars. These observations come from instructions as well as labels, so bodyweight-only Home is currently unavailable with this proposal.

The reverse spider curl's name/instructions conflict, and preacher/incline/lying movements require support or benches. Those exercises are excluded. No IDs, movements, tags or difficulty classifications were invented. Catalog gaps should be filled through a separate reviewed library expansion before broader coverage is promised.

The six proposed mappings select only **three distinct alternative library records**. They are proposals for review, not operational ARC approvals:

| Source library exercise | Alternative | Pattern |
| --- | --- | --- |
| Cable seated curl | Dumbbell standing concentration curl | Elbow flexion |
| Barbell standing close-grip curl | Dumbbell standing concentration curl | Elbow flexion |
| Cable squatting curl | Dumbbell standing concentration curl | Elbow flexion |
| Dumbbell standing concentration curl | Same exercise | Elbow flexion |
| Dumbbell front raise | Same exercise | Shoulder flexion |
| Dumbbell one-arm upright row | Same exercise | Upright row |

The curl rationale is preservation of primary biceps/elbow-flexion work, with different support and resistance profiles explicitly disclosed. The [ACE biceps review](https://www.acefitness.org/resources/pros/expert-articles/9033/building-better-biceps-evidence-based-exercises-for-strength-and-function/) supports the general movement rationale; it does not approve these ARC prescriptions or provide injury clearance. Two sets, minimum one, 8–12 reps, 60-second rest and both-arm time allowances are explicit proposed programming values requiring reviewer sign-off. Gym loading schemes are not copied.

## Selection algorithm

The engine requires bodyweight as the baseline capability and permits only `bodyweight`, `dumbbells`, `bands`. Exact normalized catalog labels map to capabilities; unknown equipment is incompatible. There is no substring, body-part or exercise-name selection.

For each source move in saved order, candidates must be approved/enabled, reference the exact source library UUID, match its exact primary target, have a published actual alternative with instructions, and satisfy explicit required equipment and curated prescription bounds. Candidates sort by version descending, priority ascending, then mapping UUID. Selection is deterministic for the same source, catalog, mappings and options.

Repeated alternatives are kept once. The skipped source and unreproduced extra Gym volume are disclosed. Partial coverage lists missing original target groups and unmatched source moves; secondary muscles never disguise a missing primary group. Empty/rest/unavailable source days cannot adapt.

Estimated seconds = **180 seconds setup/warm-up allowance + 30 seconds per selected move + work seconds for every prescribed set + rest between sets**. Curated unilateral work includes both arms. This is an estimate, not a timer guarantee.

Full uses the mapping's full prescribed set count. A short budget selects minimum approved volume, prioritizing an uncovered primary target before already-covered targets, with saved order as the tie-breaker. It then distributes additional approved sets within budget and restores source order. It never exceeds full curated volume, claims equal outcomes, or supplies a move that cannot fit even at its minimum volume. No feasible moves produces an explicit unavailable proposal.

## Snapshot and persistence contract

Version 2 records source plan/day UUIDs, original day title and target list, original Gym source prescription, actual selected immutable prescription, location, variant, equipment, requested budget, computed estimate, mapping UUID/version/pattern, actual names/instructions/GIF metadata, start/end/status/outcome, checked flags and revision/base revision.

Each exercise has unambiguous `source_workout_day_exercise_id`, `actual_exercise_library_id`, and `exercise_position`. The source UUID is retained for traceability; the actual UUID identifies the performed exercise. Missing Gym sets/reps/rest remain null and visibly unspecified. Tracking one set/no timer for an unspecified Gym prescription is labelled and does not fabricate a source prescription. Home requires explicit approved values.

Snapshots copied at start and restored from JSON use immutable exercise metadata and collections. Completion is mutable session progress; exported flag arrays are copied. Reopening a Home draft restores its exact variant/options/prescription/flags without rerunning adaptation.

Existing per-user/per-day draft keys remain unchanged. Legacy Phase 2A snapshots deserialize as Gym and are reserialized with explicit IDs. Saved source/actual/mapping relational FKs may become null after deletion; historical immutable JSON preserves original identity and display data. Registered sessions can continue updating flags after source archival/change, mapping retirement or catalog unpublishing. New sessions must validate against current approved data. Deleting an account cascades its sessions.

Train reconciles local and remote snapshots. Exact matches resume; a newer local flag revision based on the confirmed remote revision remains an unsynced draft. Divergent flags or distinct variant/session UUIDs produce an explicit conflict dialog. The unchosen snapshot is retained under an account-scoped conflict backup key. Prescriptions cannot replace another prescription under the same UUID, and flags are never automatically merged. Revision conflicts remain visible; direct retries do not silently overwrite another device's progress. Concurrent saves are serialized in the player; local writes run independently of slow cloud writes. Cloud responses must confirm the exact session UUID before showing success. Terminal cleanup removes only that same UUID's current local pointer.

## SQL path and security review

Use **only** `docs/sql/workout_training_variants.sql` for the observed undeployed Phase 2A schema. Do not apply the old `workout_session_progress.sql` first. The consolidated proposal is transactional and intentionally fails on conflicting existing tables rather than guessing a destructive upgrade. Re-inspect deployment state immediately before release; if Phase 2A has been deployed meanwhile, prepare and review an additive migration with actual backfill requirements instead.

`workout_alternative_mappings` uses real source/alternative library FKs, version, primary/secondary targets, minimal movement pattern, exact equipment, curated sets/minimum/reps/rest/work seconds, priority, limitations, review status/enabled and metadata. All seed rows are proposed/disabled. Runtime SELECT RLS exposes only approved/enabled rows. Once approved or retired, definitions are frozen: changes require a new version; disabling/retiring keeps historical meaning. Review metadata must be recorded before or in the approval update.

Client table INSERT/UPDATE/DELETE grants are revoked, including PUBLIC grants. Owner RLS provides only session/set reads. Session-set access follows parent session ownership, so nullable historical source FKs do not break access. Mapping clients have no write grants. New session/source/history/FK indexes are included, along with the missing existing workout-day-exercise library FK index reported by the advisor.

The exposed `public.save_workout_session` wrapper is SECURITY INVOKER. Its private SECURITY DEFINER implementation has an empty search path, schema-qualified references, explicit `auth.uid()` authorization and authenticated-only execution. The private schema is not an exposed API schema. Anonymous and PUBLIC execution are revoked. This narrowly scoped definer is needed because clients cannot write tables directly; it performs validation rather than trusting owner RLS as prescription approval.

At registration the RPC verifies current owned active training plan/day, full source snapshot/order/current library metadata, exact Gym prescription, or every Home mapping ID/version/approved status/source relationship/actual published ID/target/pattern/equipment/prescribed sets/reps/rest/limitations. It recalculates Home duration and rejects budget excess, duplicate actual/source IDs and forged Home mapping claims in Gym. Original target coverage metadata is verified against the full saved day. Clients cannot register arbitrary exercises as approved alternatives.

Every call validates completion shape and boolean flags, count/position bounds, authenticated ownership, contract version, revision and timestamp consistency. Registration and all set writes are atomic. Advisory transaction locks plus one-in-progress-per-user/day uniqueness prevent variant races. Stable session/set UUIDs survive retry. Equal revisions are accepted only for identical progress/status/end/index; divergent retries or stale base revisions raise `40001`. Terminal sessions cannot regress or change outcome. Completing with unchecked sets is rejected; partial and discarded sets retain their actual flags. Existing registered updates must preserve the immutable envelope and do not recreate deleted FKs or require currently enabled mappings.

The fresh metadata inspection verified RLS flags, PK/FKs, absent session/mapping tables and migration history. Advisor metadata confirmed a missing source library FK index and per-row auth evaluation in existing workout policies. Full current live policy/grant/function definitions were not freshly retrieved, because this phase performed no live SQL. Prior same-day inspection evidence is retained in `ARC_CURRENT_STATE_AUDIT.md`; deployment must recheck the exact DDL.

Existing production advisor findings are outside this feature and were not changed: [source FK indexing](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys), [workout policy auth evaluation](https://supabase.com/docs/guides/database/database-linter?lint=0003_auth_rls_initplan), [meal security-definer view](https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view), [mutable function search path](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable), [public vector extension](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public), [anonymous definer execution](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable), [authenticated definer execution](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [knowledge tables without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), and [disabled leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). See the saved metadata audit for affected objects.

## Injury behavior

The context service reads the current account profile and scoped `rehab_cases` statuses `active`, `improving`, `needs_review`. Existing report status is displayed, not modified. Available profile injury state and existing local InjuryMode trigger a conservative warning for both locations. Because the available report data is not a clinical compatibility assessment, the warning is deliberately broader than a precise region match. A context-read failure is disclosed rather than treated as clearance. Session snapshots retain the warning; switching location cannot erase it. No physiotherapist approval, rehabilitation prescription or medical safety claim is made. Local InjuryMode is pre-existing unscoped app state; only its generic warning is used here, not another user's report details.

## Edge cases and validation evidence

| Cases | Behavior and executed evidence |
| --- | --- |
| 1–3: no active plan, rest day, empty saved day | No start action; existing workout service tests and Train widgets |
| 4–7: missing/unpublished catalog, no equipment, mismatch, no mapping | No fabricated proposal/start; engine/service/widgets and RPC reject invalid new actual entries |
| 8–9: partial muscle coverage, duplicate replacements | Explicit missing-target/volume disclosure; engine tests |
| 10–11: short budget, missing prescription fields | Minimum approved Home volume with coverage priority; Gym fields remain unspecified; engine, legacy workout/player tests and SQL bounds |
| 12–14: equipment/location changes and active-session switching | Async proposal invalidation, reversible preview, exact existing player; panel/Train widgets |
| 15–16: local/remote conflict and restart/resume | Exact serialized variant/flags, explicit conflict backup, unsynced revisions; service tests |
| 17–19: offline/failed saves, duplicate retry, different account | Account-scoped drafts, no fake success, retry UUID stability, RLS/caller isolation; service/player/local PostgreSQL |
| 20–22: archived/changed source, retired mapping, unpublished alternative | Reject changed new registration; preserve authorized historical snapshot and updates; local PostgreSQL |
| 23: different weekdays | Seven-day schedule and source-day isolation; workout and Train tests |
| 24–25: active injury, missing migration | Report warning/status retained; missing mapping migration is distinct unavailable state and session save remains a local draft; context/service/Train widgets |
| 26–27: small screens/large text, Back during save | Train/panel/player at 320×640 with 200% text; wrapping controls, scaled weekday circles and scrolling status; Keep Draft exits during pending cloud save |
| 28–30: partial/discard, source/actual IDs, malformed/unauthorized payloads | Same session outcomes, exact actual exercise traceability, server-side registration and flags validation; unit/widgets/local PostgreSQL |

Executed checks:

- **Flutter suite: 55 tests pass**, including all 35 existing profile/Phase 2A tests and 20 Phase 2B tests.
- **`flutter analyze --no-pub`: zero errors, 15 existing warnings and 72 existing infos (87 total)**. Exit 1 reflects the pre-existing findings. No diagnostics in the Phase 2B training files. Unrelated files were not refactored to clear the baseline.
- **SQL grammar:** pglast parses the consolidated SQL and both PL/pgSQL bodies, and the seed SQL. This is separate from execution verification.
- **Actual database execution:** the proposal and seed ran in fresh disposable PostgreSQL 18 databases on `127.0.0.1:55439`, using an independent temporary cluster and synthetic auth/users/workout fixtures. The test hardcodes loopback and never targets a Supabase project. Two authenticated identities and anonymous were exercised. Assertions cover arbitrary substitutions, forged ownership, equipment/targets/versions/sets/budget/flags, original Gym, partial/discard, changed source/unpublished registration, duplicate active sessions, table-write denial, mapping freeze, retry-stable child UUIDs, stale revisions, terminal regression, retired/unpublished history and nullable source/day FKs. Successful test databases are dropped. The owned temporary cluster is stopped after validation.

The local auth fixture simulates the UID claim and roles; it is **not** verification of hosted JWT issuance, PostgREST schema exposure/cache or real-device networking. No production destructive setup, live authenticated workout query, cloud save or device walkthrough occurred.

## Remaining manual verification and explicit approval boundary

Before live release:

1. Review the consolidated migration and six disabled mapping proposals. A programming reviewer must assess each source/alternative, support/equipment, suitability, limitations, reps/volume and work-time allowance. Do not bulk approve just to make the UI look populated. Add verified catalog records through a separately approved process for missing primary groups and no-equipment/band coverage.
2. Reinspect the target schema, exact policies/grants/functions, existing session data and catalog IDs. Confirm Phase 2A is still undeployed; otherwise prepare an additive migration/backfill and rerun local/staging checks. Take the project's normal backup and record rollback/release steps.
3. With a working Supabase CLI, create a migration via `supabase migration new arc_phase_2a_2b_training_variants`, place the reviewed consolidated SQL in that generated migration, and review the diff. The repository SQL remains a proposal; it has not been automatically pushed.
4. **Obtain explicit approval before applying any migration to the connected live project.** Review and explicitly approve the separate production seed operation; seed initially as proposed/disabled. Approval of schema does not imply approval of exercise programming or every mapping.
5. Apply only the approved migration/seed through the authorized release workflow. Record reviewer identity/date/rationale in mapping metadata in the same controlled operation that approves/enables individually reviewed rows. Refresh/verify PostgREST schema visibility and RPC permissions. Re-run advisors and two-user/anonymous checks in staging first.
6. On actual Android/iOS devices, verify both themes, exercise GIF/storage behavior, selected weekdays, actual owned plan, initial profile preference, slow/offline first save and retry, app restart and account switching, two-device revision conflicts, partial/discard, and available injury report integration. Confirm both Gym and Home share history and that Home completion never changes Gym plan rows.
7. Only after deployed schema, approved mappings and hosted/device checks pass may the cloud feature be described as operational. Until then, Home has an honest unavailable state where approved mappings are absent and session cloud saves clearly remain unconfirmed.

No further live operation has been started or authorized by this implementation report.
