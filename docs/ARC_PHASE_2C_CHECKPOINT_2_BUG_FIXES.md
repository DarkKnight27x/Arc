# ARC Checkpoint 2 — Generate feedback and contrast fixes

Repository cleanup note (2026-10-11): this is a historical report. Disposable run evidence was removed; required test inputs, reproduction tools and the results below are retained.

10 October 2026. Scope ends at these Checkpoint 2 fixes. No activation, eligibility, generator, validator, catalog/database, auth, onboarding, Train, SessionPlayer, Rehab or Coach changes.

## Confirmed causes and trace

The pre-fix reproduction tests established two UI defects:

1. `StartArcPage` reused its long configuration `ListView` when changing to the preview/result step. After pressing Generate near the bottom, the result heading was outside the visible viewport. The regression test failed on the visibility of `30-day ARC journey` before the fix.
2. ARC's existing `arcDarkTheme()` supplies `GoogleFonts.spaceGroteskTextTheme()` without recoloring its default text. The builder relied on those defaults for body text, controls and result messages. A test using the actual ARC dark theme found near-black `#1D1B20` body text where `ArcColors.dark.ink` (`#F4F1EA`) was required. Tests using plain `ThemeData(brightness: dark)` had missed this app-theme mismatch.

These are confirmed causes of hidden/illegible feedback, rather than evidence that the generator failed to run. The precise branch taken by the user's earlier hosted Android attempt cannot be reconstructed without that attempt's diagnostics. No unsupported claim of a Supabase/RLS/auth failure is made.

Trace: the enabled button calls `generate()`; configuration validation produces visible recoverable feedback; valid input constructs `TrainingPlanConfig` inside the guarded async operation; the unchanged source performs its existing reads and runs the unchanged generator/validator; results update state to preview/unavailable; catalog-fetch issues and thrown exceptions show visible retryable errors. There is no unconditional early return after a valid result. The account/request guards continue to discard only invalidated/disposed work. No logs, tokens, credentials or profile data were added to diagnostics.

## Corrections

- Guard `generate()` itself with `busy`, preventing a second tap before the disabled frame.
- Display a full-screen spinner and `Generating your plan…` as soon as an async generation starts.
- Use a distinct viewport key for each step, making the result start at its heading.
- Put recoverable errors in a live-region banner outside the scrolling form so feedback remains visible.
- Clear `busy` in `finally` for the current mounted request, including exceptions and timeouts; ignore late completions after timeout/disposal.
- Keep structured issues internally. Catalog-fetch failure is a retryable error, not a claim that exercise coverage is missing.
- List **all missing required muscle areas**, even when no priorities were selected; retain the separate selected-priority explanation.
- Provide edit configuration, edit priorities and retry generation from unavailable states.

## Contrast scope

`ArcPlanTheme` recolors only the Phase 2C surfaces using existing ARC tokens. It covers body/primary text, app bar/icons, card backgrounds, dropdown values/popups, input labels/helpers/errors, buttons including disabled states, chips including selected/unselected labels, progress indicators and dialog/popup defaults. Primary text is `c.ink`, secondary/disabled text is `c.muted`, surfaces are `c.page`/`c.surface`/`c.chip`, and selected buttons/chips use the high-contrast `c.ink`/`c.page` pair. No new visual design or global theme change was made.

The Home entry gets the same local button theme. Anatomy uses the local theme **only in priority-selection mode**, preserving default Browse behavior. Its selected-state summary already uses `c.ink`; retry/loading/disabled controls now inherit compatible colors.

## Files changed in this fix

Paths relative to `C:/Users/ivang/ARC VSCODE/Arc`:

- `lib/start_arc_page.dart`
- `lib/widgets/arc_plan_theme.dart` (new scoped theme)
- `lib/widgets/start_arc_entry.dart`
- `lib/anatomy_test_page.dart` (priority-mode theme only)
- `test/start_arc_feedback_test.dart` (new regression tests)
- `docs/ARC_PHASE_2C_CHECKPOINT_2_BUG_FIXES.md` (this report)

Earlier dirty/untracked work is preserved. No live Supabase operations or database changes were performed.

## Automated verification

- Start My ARC tests: **22 passed** — 12 existing flow tests plus 10 new feedback/contrast regression tests.
- Full Flutter suite: **141 passed**.
- Changed-file analyzer: **no issues**.
- Full `flutter analyze`: **0 errors, 15 existing warnings, 72 existing infos**. It still exits nonzero for the repository's existing diagnostics.
- Actual anatomy JavaScript regression harness: **PASS**; Browse toggle protocol, priority cap, reset and front/back are preserved.

New tests cover invocation, visible loading, duplicate taps before a new frame, successful preview, real-catalog snapshot unavailable UI without priorities, missing hamstring/quadriceps explanation, visible validation error, sanitized exception and retry, catalog failure, timeout and late completion, disposal, actual ARC dark-theme text, dropdown popups, selected/unselected chips and disabled button contrast. Existing narrow-screen/larger-text tests remain passing.

## Android check and remaining manual verification

An APK built successfully and was manually exercised on `emulator-5554` using a **separate temporary package, `in.arc.arc.cp2smoke`**. It copied the actual production widgets/assets and used a synthetic profile plus the saved public exercise-library snapshot. Its fixture source introduced a two-second read delay solely to capture loading feedback. It did not initialize Supabase, authenticate, read real profiles or replace the installed ARC package. This is test infrastructure outside the repository, not a production demo/generation path.

Verified on the emulator:

- Fixture entry -> production Start My ARC -> actual native anatomy WebView.
- Chest/Hamstrings selection, readable summary, front/back and preserved selections on edit.
- Readable configuration labels/values, selected/unselected chips and 30/60/90-day dropdown popup; selected 60 days.
- Generate immediately shows the visible loading spinner/message, then the unavailable result at the top.
- The real catalog snapshot lacks direct leg coverage. With Bodyweight selected, the result honestly also lists additional areas unavailable under that equipment restriction. Hamstrings and Quadriceps appear in the readable required-area explanation.
- Retry repeats loading/unavailable; Edit configuration returns to the top with choices preserved; Edit priorities reopens the map with highlights/summary preserved.
- Android Back returns from the map to configuration without changing priorities, then returns to the fixture entry screen.
- No black-on-black content was observed in these production Phase 2C screens. A successful full preview remains covered by automated synthetic fixtures because the actual catalog cannot currently produce one.

One-run evidence files were removed during repository cleanup; the results and retained reproduction tools are summarized in this report.

**Still required on the user's real ARC build/account:** signed-in Home's active-plan check, live profile prefills and catalog/context fetches, network interruption against the hosted service, and the original physical Android device. No hosted end-to-end or physical-device success is claimed. The remaining boundary is verification, not an unresolved failure reproduced in the corrected UI.

Cleanup: the isolated emulator test package was uninstalled and its on-device screenshots/XML were removed. Automatic approval review rejected removal of the temporary host directory with reason `blocked by policy`; `C:/Users/ivang/AppData/Local/Temp/arc_cp2_feedback_android_smoke` remains. Production ARC was not replaced or uninstalled.
