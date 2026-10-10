# ARC Home status synchronization — 2026-10-10

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

## Root cause

Home's TODAY title and muscle/time description were hardcoded. Its separate StartArcEntry query only checked for an active-plan ID and ran on initialization, authentication events and builder return. It did not subscribe to the Checkpoint 3 activation invalidation event. HomeShell keeps Home mounted in an IndexedStack, so returning from Train does not initialize Home again. No session-history source fed Home's training card.

## Correction and authoritative source

Home's existing training card now contains a single StartArcEntry status view. Both Home and Train use `WorkoutService.fetchWorkoutPlan()`, including its owner filter, active/training selector, version ordering and seven-day rest-day projection. There is no second plan query or persistent training cache in Home. The component holds only the current owner's rendered fetch result.

- A confirmed empty result offers Start My ARC.
- A confirmed active result shows ARC ACTIVE, today's saved title or Rest day, and the next scheduled workout/day. Start My ARC is hidden.
- Today's training-day history shows completed, in progress, session ended or not completed today. `WorkoutSessionService.currentDayStatus()` reads only status, filtered by current user and workout-day ID. It uses local-day boundaries converted to UTC and includes either sessions started today or sessions completed today, including cross-midnight completion. Completed takes precedence when multiple sessions exist.
- Failed plan reads show a safe retry state. Failed history reads retain the confirmed active plan with a separate status-unavailable/retry message; they do not claim that the workout is untouched.

## Refresh and isolation

- Existing `WorkoutService.changes` activation events refresh matching owners immediately, including while the builder route is open. Builder return avoids duplicating a refresh already requested by activation.
- A new UI-only `WorkoutSessionService.changes` event fires after a successful save, never a failed save. The RPC name, payload, revisions, ownership validation, draft reconciliation and terminal persistence contract are unchanged.
- HomeShell supplies `isActive: index == 0`. Returning to Home refetches, including after a session route within Train. Hidden Home defers event/resume reads until it becomes visible.
- A WidgetsBindingObserver refreshes visible Home on resume. Same-frame requests coalesce; events during an in-flight read queue at most one further read. Individual existing plan queries and the new history query have 20-second timeouts.
- Account changes/logout immediately clear the prior owner's view. Request generations, current-owner comparisons and mounted checks reject old completions. Subscriptions and lifecycle observers are disposed.

## Files changed by this task

Production:

- `lib/home_page.dart`: replace the hardcoded training header and separate CTA with the authoritative status component inside the existing card. Meal/macros and other Home content remain as before.
- `lib/main.dart`: pass Home tab visibility to HomePage.
- `lib/widgets/start_arc_entry.dart`: owner-scoped plan/status view, refreshes, guards and safe errors.
- `lib/data/workout_session_service.dart`: read-only daily status helper and successful-save UI notification.

Verification:

- `test/home_training_status_test.dart`: 12 new focused cases.
- `test/start_arc_test.dart`: existing mock now supports the shared plan reader's workout-day read.
- `test/workout_test.dart`: prove failed saves do not notify and successful saves/retries/completion do notify.
- `tools/home_status_android_probe.dart`: offline Android fixture using actual WorkoutService/WorkoutSessionService and TrainPage with mocked HTTP only.

No generator, activation RPC, database schema, exercise catalog, auth/onboarding, Train, SessionPlayer, Rehab, Coach, AI or mascot implementation was changed by this task. No hosted queries, writes, migration execution or live account changes were performed.

## Verification

- Home focused suite: **12 passed**. Covers no-plan/active states, rest/next workout, activation before route return, resume, Train return, save invalidation, owner filtering, error/retry, history error, account switch/stale completion, logout, concurrent invalidation/disposal and date/owner-scoped history reads.
- Focused Home + Start ARC + activation + workout + Home variant + Train + exercise navigation regression suite: **80 passed**.
- Final full Flutter suite: **201 passed**.
- `flutter analyze`: **0 errors, 15 warnings, 70 info items**, exit 1 due to the pre-existing repository baseline. No new diagnostics in the new component, service, test or probe. Unrelated diagnostics were preserved.
- Normal `lib/main.dart` Android debug APK: **build passed**, at `build/app/outputs/flutter-apk/app-debug.apk`.
- Android emulator API 36 offline fixture: **PASS** for no-plan CTA, Confirm/activation invalidation, actual Train tab and return, successful save notification/completion, Home/background/resume, switching to a no-plan owner, logout and failed-read retry UI without a no-plan guess. The manual visual check confirmed readable dark-theme text.

The emulator run initially encountered an Android ANR reporting `executing service in.arc.arc/com.baseflow.geolocator.GeolocatorLocationService, waited 20004ms`. Choosing Wait recovered the fixture; subsequent status checks passed. That startup/service condition was not investigated or modified as part of this scoped task. The normal ARC APK is restored separately after the probe and is not automatically launched into the existing hosted session.

One-run evidence files were removed during repository cleanup; the results and retained reproduction tools are summarized in this report.

## Remaining real-device checks

The fixture mocks activation responses/catalog/history and uses locally recovered synthetic sessions. It does not prove hosted end-to-end generation, activation, persistence or real account routing. On the updated normal Android build:

1. Sign into an account with no active plan; Home offers Start My ARC.
2. Generate and Confirm an ARC; return Home and verify active status without restarting.
3. Open Train and a scheduled workout, then return Home; verify today's title or Rest day and next workout.
4. Complete/save a real workout, then return Home; verify fresh completion. A failed save must not claim completion.
5. Background/resume and close/reopen ARC; verify the active plan is reloaded.
6. Log out and switch accounts; verify prior plan/completion disappears. Test a network interruption and retry; no-plan CTA must not appear from a failed read.

If the geolocator startup ANR repeats on a physical device, retain its trace for a separate investigation.
