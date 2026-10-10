# ARC exercise detail navigation fix

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

## Reproduced root cause

The defect is a **wrong-navigator pop**, reproduced in a widget test and on the Android 16/API 36 emulator using an isolated Train fixture and ARC's signed-in nested-navigator structure. No hosted account, plan or catalog was created or changed.

Train `_MoveRow._showGif` called `showDialog` with its default root navigator. Its Close callback captured the underlying Train context and called `Navigator.pop(context)`. That context belonged to the signed-in child navigator, not the dialog. `FocusWorkoutPage._showGif`, reached through Browse Anatomy, had the same defect.

| Action | Root stack | Signed-in stack |
|---|---|---|
| Before tap | `/` | `/home-train` |
| Open exercise | `/`, unnamed DialogRoute | `/home-train` |
| Press old Close | `/`, unnamed DialogRoute | empty |
| Press system Back | `/` | empty; black screen |
| Open fixed detail | `/`, `/exercise-detail` | `/home-train` |
| Fixed Close, app Back or system Back | `/` | `/home-train` |

The emulator process stayed alive. Opening the fixture detail initially worked; the reproduced collapse occurred on Close, followed by Back. **No Flutter runtime exception or exception screen occurred**, so there is no runtime exception stack trace for this route corruption. The pre-fix regression failed because the root dialog remained after Close; the old emulator log recorded `signed-in stack=[]` and a black screen. No evidence of a GIF crash or catalog-ID mismatch was found in this reproduction.

## Tap-path audit

- Train's selected scheduled workout renders `_RegionTile` → `_MoveRow`; the play icon previously opened `_showGif`. Icon and row/name taps now use the shared detail dialog. Home variants rendered through the same move builder use the same correction.
- Browse Anatomy pushes `FocusWorkoutPage` with ordinary `Navigator.push`; its media thumbnail previously opened a second copy of the broken dialog. Row/name and thumbnail taps now use the shared detail.
- SessionPlayer renders media and instructions inline. It has no exercise-detail tap route. Its existing back/save confirmation and persistence behavior were not changed.
- No detail tap uses pushReplacement, clears the route stack, replaces the app root or calls popUntil. The detail route has no PopScope/WillPopScope blocker.
- Train sends `move.exerciseId` (the actual library UUID), never `move.id` (the persisted prescription UUID), for current demo lookup. Browse sends the catalog row ID. The generated-plan regression parses the PostgreSQL 17 persisted relation fixture and asserts/query-checks the correct UUID.

## Focused correction and files

Production:

- `lib/widgets/exercise_detail_dialog.dart` — shared, named, ordinary root DialogRoute. Its own widget context closes that route. Bounded scrollable body, pinned Back/Close controls, existing ARC metal/colors, name, target, equipment and instructions. Optional malformed/absent display metadata has readable fallbacks.
- `lib/train_page.dart` — uses shared detail with the existing loaded prescription/catalog metadata; makes exercise row/name tappable.
- `lib/focus_workout_page.dart` — same correction for Browse; includes existing catalog `instructions` in its read query and handles non-string optional IDs safely in media display.

Verification:

- `test/exercise_detail_navigation_test.dart` — 12 focused regression cases.
- `tools/exercise_navigation_android_probe.dart` — standalone local-only fixture with route observers. It uses a non-hosted client and existing widgets; its diagnostics are not imported by the app.
- This report and `docs/exercise_detail_*` logs/screenshots.

The detail uses already-loaded metadata rather than introducing a new detail-data request. Its only optional asynchronous request is the existing current demo lookup: errors/timeouts retain metadata and COMING SOON/snapshot media, offer Retry, never expose raw exceptions and never block Back. Existing media loading remains bounded to 15 seconds. Missing/invalid assets and URLs retain the existing shared fallback. No generator, activation RPC, schema, session persistence, authentication, onboarding, exercise catalog, SessionPlayer or mascot code/assets were changed by this task.

## Verification results

- **Pre-fix reproduction: FAIL as expected**, wrong navigator popped. The previously existing single-navigator Train media test passed before the fix and therefore did not cover this defect.
- **Focused suite: 56 passed**, navigation/details, media, Train variants, sessions and plan activation integration.
- **Full Flutter suite: 189 passed**, including all 12 new cases.
- **Flutter analyzer: exit 1**, unchanged repository baseline of 0 errors, 15 warnings and 70 info items. No diagnostics in the changed production/test/probe files. Unrelated diagnostics were left untouched.
- **Android emulator manual fixture: PASS** for null media and valid animated GIF, multiple exercises, row/icon taps, Close, app Back, system Back and repeated open/close. Route logs show the signed-in route remained intact in every fixed cycle. The valid GIF is an existing local asset used only by the disposable probe, not a claim that a hosted exercise GIF was checked.
- Browse Anatomy navigation and metadata were exercised in nested-navigator widget tests. SessionPlayer has no detail route; its regression suite passed.

One-run evidence files were removed during repository cleanup; the results and retained reproduction tools are summarized in this report.

## Remaining device check

The emulator test used fixtures, not your live activated plan or a physical device. Install the updated normal ARC build and repeat **Home → Train → scheduled workout → exercise → Back** for several exercises, a missing GIF and a real hosted GIF. Test Close/app arrow/system Back, repeat openings, and check Browse Anatomy. This task neither signed into a hosted test account nor wrote any hosted data.
