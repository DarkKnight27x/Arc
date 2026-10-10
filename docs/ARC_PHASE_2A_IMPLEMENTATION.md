# ARC Phase 2A implementation report

Implemented on 2026-10-09. The live database was inspected read-only. No migration, database writes, plan generation, or backend deployment was performed.

## Files changed by this task

- `lib/data/workout_models.dart`: typed prescriptions, nullable saved fields, validation and seven-day mapping.
- `lib/data/workout_service.dart`: authenticated active training plan selection, ordered parsing and propagated errors.
- `lib/train_page.dart`: real saved prescriptions, Rest Day/No Plan/error/unavailable states, start/resume and account invalidation.
- `lib/session_player.dart`: interactive variable sets, exercise-specific rest, progress retention, explicit ending/exit actions, responsive footer and save status.
- `lib/data/workout_session.dart`: UUID session, honest completion state, immutable prescription snapshots and JSON roundtrip validation.
- `lib/data/workout_session_service.dart`: user-scoped local drafts, remote resume, atomic RPC saves and missing-schema/retry handling.
- `test/workout_test.dart`: 15 data/service tests.
- `test/workout_session_widget_test.dart`: seven player tests.
- `pubspec.yaml`: pinned direct `uuid: 4.6.0` and `shared_preferences: 2.5.5`, already present transitively.
- `pubspec.lock`: preserved resolved dependency versions; `.gitignore` now permits the application lockfile.
- `docs/sql/workout_session_progress.sql`: complete review-only proposed migration.
- `docs/ARC_PHASE_2A_IMPLEMENTATION.md`: this report.

The pre-existing edits in profile, Home, main/HomeShell and You files, existing profile tests, and the prior audit were left intact. Mascot assets/widgets, Coach/AI/backend, AuthGate, onboarding and theme definitions were not changed.

## Live schema inspection

Project: `nbojicqbpqgotdmdayku`, matched to the app's configured URL. Inspected current public tables, columns/nullability/defaults, enums, foreign keys/check constraints, indexes and RLS policies.

- `plan_type`: `training`, `rehab`; `plan_status`: `draft`, `active`, `archived`.
- Plans belong to `profiles(user_id)`; days reference plans; day exercises reference days and the exercise library.
- Weekdays are constrained to 1–7. `(workout_plan_id, weekday)` is unique.
- `(workout_day_id, sort_order)` is unique. Sets must be positive when supplied; rest must be nonnegative when supplied.
- Sets/reps/rest/notes/estimated_minutes are nullable, so absent values cannot be treated as prescriptions.
- RLS is enabled on all four workout tables. Plan access uses user ownership; days and prescriptions inherit it through their parent plan. Only published library exercises are readable.
- Existing indexes include table primary keys, unique library source ID, unique day weekday/order keys, and `one_active_plan_per_type` on `(user_id, plan_type)` for active plans. No redundant plan index is proposed.
- No session or set-log/history tables existed. A final read-only check again returned null for `workout_sessions`, `workout_session_sets`, and `save_workout_session(jsonb)`.

## Plan selection and Train

Queries `workout_plans` with the current authenticated user ID, `plan_type='training'`, and `status='active'`, ordered by version descending, updated_at descending, and UUID ascending for a deterministic tie. Fetches days only for that selected plan. Account changes invalidate loaded data; responses from old requests cannot repopulate the page.

No active plan produces No Plan; fetch failures produce retryable errors; malformed relations produce a data error. Missing weekdays become Rest Day. A saved day with an empty exercise list remains an empty saved day, not an inferred rest day. Missing or unpublished exercise relations are shown as unavailable and block starting the incomplete prescription.

Monday is 1 and Sunday is 7; today's actual weekday remains selected even if it is a rest day. Prescriptions are sorted by `sort_order` and shown in one sequence, without muscle regrouping. Equipment, notes, sets/reps/rest and saved estimated duration are retained. Anatomy, previews, day selector and Coach access remain available. The misleading 10-minute button was removed because it launched the full unchanged session.

No library-based fallback workout is created. Optional UI defaults are labelled: missing sets uses one trackable set labelled unspecified; missing reps is unspecified; missing rest has no automatic timer; zero rest has no timer; missing duration is unspecified; absent notes are omitted. Snapshots preserve null prescription values.

## Session Player

The player receives the actual session prescription, including repeated library exercises as separate prescription UUIDs. Set checkboxes preserve state through Previous/Next. A checked set starts that exercise's rest timer. Unchecking a set does not complete anything else.

Finish confirms the actual checked-set count. All checked sets produce `completed/completed`; a partial finish produces `abandoned/partial`; discard produces `abandoned/discarded`. `completed_at` records the ending time for terminal outcomes. A partial or discarded session is never labelled completed. Unchecked sets stay false. Keep draft leaves the session `in_progress`. Failed terminal saves retain the ended snapshot and offer Retry save or Save & close.

System Back and Close use the same exit confirmation. Save requests are serialized; every state change is separately queued to local storage immediately so networking cannot hold up retaining the latest local progress. A changed account hides the previous user's player and blocks saving.

## Proposed database schema and RLS

Migration proposal: `docs/sql/workout_session_progress.sql`. This is outside the automatic migrations directory intentionally. The local Supabase CLI download stalled and its executable was incomplete; the timestamped migration generator could not run. Once approved, use a working `supabase migration new workout_session_progress` and copy the reviewed proposal into its generated file.

Two tables keep the schema minimal:

1. `workout_sessions`: stable UUID, authenticated owner, plan/day foreign keys, title, immutable ordered prescription snapshot, selected exercise index, started_at, completed_at, status and outcome.
2. `workout_session_sets`: stable UUID per set, session foreign key, exercise position and prescription foreign key, set number, boolean completion, optional recorded_reps and weight_kg. Exercise completion is derived from its set records. No aggregate is invented or auto-completed.

Indexes support user history/resume and foreign keys. Unique `(session_id, exercise_position, set_number)` retains set IDs on retries. Plan/day deletion is restricted while referenced by history; deleting a prescription nulls its historical set reference while the snapshot retains the original metadata. User deletion cascades sessions and their sets.

Session SELECT/INSERT/UPDATE policies restrict access to auth.uid(); write checks also require the referenced day and plan to match and belong to the caller. Child SELECT/INSERT/UPDATE policies inherit ownership via their session and validate set position/count and prescription association. No anonymous access or client delete grants are supplied. Both tables explicitly enable RLS and grant only SELECT/INSERT/UPDATE to authenticated.

`save_workout_session(jsonb)` is SECURITY INVOKER with an empty search_path, explicit caller verification, and no public/anonymous EXECUTE privilege. It validates all completion arrays, rejects completed sessions with unchecked sets, rejects changed session identity/prescription and terminal regressions, and saves parent and sets in one transaction. A transaction advisory lock serializes overlapping first-insert/timeout retries of the same session UUID. Upserts retain identity and preserve future reps/weight fields when updating checked flags. Function grammar is validated, but its database behavior is not yet validated.

## Persistence and limitations

Local drafts are keyed by user UUID and workout-day UUID. Resume prefers the local snapshot, including unsynced terminal outcomes. Without a local draft, it fetches the latest remote in-progress session and all its set records; missing/duplicate/invalid set rows are errors, never an excuse to create a replacement session. Remote retries reuse the same UUID, and the UI reports cloud success only after the RPC returns that UUID.

Missing parent tables/function are handled as unavailable cloud persistence during development. Permission/network/other errors remain errors. Terminal local drafts are removed only after confirmed cloud success. Child-table failure for an existing remote session blocks resume instead of creating a duplicate.

**Cloud persistence is implemented but not operationally verified:** the migration has not been reviewed, applied or tested against a database. Until then, only device-local drafts can be verified. Local preferences are device storage, not an encrypted or cross-device history backup. Rest countdown timing is not restored after app restart. Multi-device conflicting edits are not merged; the proposal rejects terminal regressions. A session whose source plan/day disappears cannot be reattached to a different plan automatically.

API choices were checked against the current [Supabase Dart upsert documentation](https://supabase.com/docs/reference/dart/upsert) and [RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security). The changelog was inspected; the relevant PostgreSQL minor-release changes do not affect these built-in UUID/jsonb/btree operations.

## Validation

- `flutter test test/workout_test.dart test/workout_session_widget_test.dart`: 22 passed.
- `flutter test --reporter expanded`: 35 passed, including existing profile tests.
- `flutter analyze --no-pub`: zero errors; 15 existing warnings and 72 existing informational findings (87 total). Baseline was 15 warnings and 86 informational findings (101 total). No findings remain in the changed training/session Dart files or new tests.
- SQL parsed locally with pglast: 22 SQL statements and one PL/pgSQL function. This is grammar validation only, not schema execution or RLS verification.
- `git diff --check`: passed.

Existing analyzer warnings are separately located in `ai_backend/data/recover_api.dart` and `lib/recover_page.dart` (unawaited returns in try blocks), meal/eat files (unused imports), and `lib/home_page.dart` (unused import/field/elements). Other existing informational findings include deprecated opacity usage and underscore/style diagnostics in untouched files. They were not expanded into unrelated changes.

## Manual verification

Before migration approval:

1. Sign in with an existing saved active training plan. Compare each weekday, duration, notes, sets/reps/rest and exercise order to the saved rows. Confirm published exercise previews and anatomy/Coach links.
2. Select a missing weekday: Rest Day should appear without a Start button. Use an account without an active plan: No Plan should appear without a generated workout.
3. Simulate network failure while loading; check the distinct retry state. Verify malformed relations and unavailable exercises do not launch a fabricated session.
4. Start a session. Check a set, inspect the prescribed rest timer, skip rest, move Next/Previous and verify only your checked sets remain checked.
5. Keep draft, close/reopen the app and resume the same session UUID/index/flags. Finish partially and check that unchecked sets remain incomplete. With migration absent, verify the cloud error and retry state; no success message should appear.
6. Test Close/Back Continue, Keep draft and Discard; dark/light themes; a 320-pixel-wide phone; long exercise names/rep targets. Switch accounts and verify old session details disappear.

After explicit migration approval and application in a test environment:

1. Run a real authenticated session through in-progress, partial, complete and discard outcomes. Verify both tables and actual checked flags/timestamps.
2. Re-send an identical snapshot and simulate a timeout after a committed write; confirm one session UUID and unchanged set-row UUIDs/counts. Try overlapping requests, unchecked completion and terminal regression; invalid writes must fail atomically.
3. Use two ordinary authenticated users and an anonymous client. Verify neither anonymous nor user B can SELECT/INSERT/UPDATE user A's sessions or sets, including by changing owner/session/plan/day UUIDs. Test a mismatched plan/day association and child prescription association.
4. Verify permission and network failure keep local drafts and show retry, then successful retry clears terminal drafts. Test cloud-only resume after clearing the test device's local draft.
5. Run Supabase security/performance advisors and confirm Data API grants, RLS policies and schema cache exposure before claiming production persistence works.

## Approval boundary

The next step is reviewing `docs/sql/workout_session_progress.sql` together. Explicit approval is required before applying any migration to Supabase. No approval is needed for the completed Flutter edits or local tests. Nothing was applied to the live database.
