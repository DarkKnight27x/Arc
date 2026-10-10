# ARC authentication and new-user onboarding audit

Reviewed **2026-10-10, Asia/Calcutta**. Target: `nbojicqbpqgotdmdayku`.

**Ready for a controlled first-time-user device test after rebuilding with these fixes. Hosted end-to-end signup/email/login has not been executed.** No live user was created, no private profile row retrieved, and no real user/profile, database schema, Auth configuration or migration history was modified.

## Results for the requested flow

| Area | Code/test evidence | Hosted evidence and limits |
| --- | --- | --- |
| Signup | PASS: trimmed email/name and password go to SDK signup; confirmation response with user/no session stays outside the app; errors are shown | Public Auth settings: signup allowed, email provider enabled, `mailer_autoconfirm = false`. Actual signup and mail delivery not attempted |
| Login | PASS: password sign-in populates SDK session; invalid credentials are surfaced; pending requests disable repeated submission/navigation; disposed screens ignore late results | Real credentials/session issuance not tested |
| Session persistence | PASS: mocked SharedPreferences plus the real Flutter SDK persist, restore and clear the session, including immediate logout after restoration | Device storage, process death and lifecycle token refresh need physical-device verification |
| Initial profile | PASS: actual AFTER INSERT signup trigger calls `public.handle_new_user()`, inserting `public.profiles.user_id`, display name and explicit false completion; column is NOT NULL DEFAULT false | Read-only live catalog verified; trigger exercised only with synthetic local identities |
| Onboarding save | PASS: all current required answers validate, then one owner-filtered update writes answers and true completion atomically; returned row must match owner, answers and completion | Columns and diet constraint match Flutter. No live profile update attempted |
| AuthGate routing | PASS: no session -> login; expired/error session -> recovery; unresolved/missing/error profile -> loading or retry/sign-out; incomplete -> onboarding; confirmed complete -> app | Real Data API/JWT and device routing still require manual testing |
| Logout/account switching | PASS: identity keys discard old gate/onboarding/app state; late profile results do not admit another identity; pushed signed-in routes are removed on logout | Actual devices and remote token revocation/network behavior need testing |
| Training deployment impact | PASS by catalog comparison: profile columns and signup function are unchanged from the pre-training audit | Remote migration history contains only `20261009174458_arc_phase_2a_2b_training_variants`; all three training tables exist |

ARC consistently uses the existing **`onboarding_complete`** column.

## Confirmed defects and focused fixes

1. **False save success:** onboarding previously issued UPDATE without a returned-row check. A missing/RLS-filtered profile could update zero rows and still invoke completion. `ProfileService.completeOnboarding` now verifies the saved row and rejects missing/mismatched responses. It updates only an incomplete owned profile; an identical completed row can acknowledge a retry after a lost response, while a different completed profile is not overwritten.
2. **Invalid required numbers:** nonempty height/weight strings previously passed and could be stored as null, negative or nonfinite values; age lacked an upper bound. Validation now rejects those values and validates every required answer again at final save. Bounds match existing ARC profile validation: age 13–120, height 80–250 cm, weight 20–350 kg. Age is integral. Training days and choice values follow the existing wizard.
3. **Account-switch state reuse:** `_ProfileGate` and onboarding lacked identity keys. The gate/app/onboarding are now scoped to the user ID, and saves capture that identity and check it before and after requests. Prior-account answers or results cannot complete another user's onboarding.
4. **Routes surviving logout:** app routes previously used the outer navigator above AuthGate. Signed-in routes now live in a scoped navigator removed with the identity; `NavigatorPopHandler` preserves nested system-back handling.
5. **Late asynchronous screen errors:** login/signup/onboarding could call `setState` or completion callbacks after disposal. Mounted/identity guards, bounded requests and duplicate-submission protection now handle those results safely.
6. **Missing/unresponsive profile:** missing rows no longer enter a wizard that cannot persist. The gate waits up to 20 seconds, fails closed, and offers retry/sign-out. Retrying handles delayed availability without inserting or resetting profiles automatically. The actual signup trigger is transactional: a trigger failure rejects signup rather than creating a normal auth-only account.
7. **Startup recovery/logout race:** a real SDK + mock-storage test reproduced a restored session appearing again after immediate logout. `AuthSessionStorage` keeps the same SharedPreferences key/format, but rejects a stale background recovery read if identity changed or initialization has finished with no current session. Persistence is retained and the regression test passes.
8. **Wizard viewport overflow:** the allergy step overflowed the test viewport. Existing step content now scrolls within its allocated space, retaining the UI design. A sign-out control also lets an incomplete user leave the wizard.

Signup guidance now says to check for a verification link and return to sign in, and acknowledges existing accounts. This avoids claiming that an obfuscated duplicate-signup response proves a new account was created. No metadata-based authorization was introduced.

## Profile data and partial completion

Signup's trigger stores display name and identity. The wizard writes `fitness_goal`, `gender`, `age`, `height_cm`, `weight_kg`, `experience_level`, `train_days`, `diet_type`, `allergies`, and `onboarding_complete`. Every column exists with compatible live types. Other nullable fields such as workout location, date of birth and session duration are not collected by this existing wizard and remain unchanged.

Intermediate wizard steps do not write completion or partial server data. Answers remain in widget state when a normal save/network failure occurs; Retry resends validated answers. Closing the app or logging out before completion starts the wizard again on next login. This intentionally does not invent draft persistence. A committed update whose acknowledgement is lost may already have true completion in Supabase; restart/reload reads that authoritative profile, and an identical in-session retry is supported.

Home is shown only after a fetched profile for the current identity has true completion. Loading, missing rows, network errors and expired-session recovery do not fall back to Home. Onboarding is a product-flow gate, not a server authorization boundary against a user manually editing their own allowed profile fields through the API.

## Read-only Supabase and security evidence

- [auth_profile_database_audit.json](auth_profile_database_audit.json): actual profile column/default/nullability, constraints, signup trigger/function, grants, RLS policy and deployed training table names; metadata only.
- Remote history response: version `20261009174458`, name `arc_phase_2a_2b_training_variants`.
- Live `profiles` RLS is enabled. The only profile policy is ALL to authenticated, with both USING and WITH CHECK `user_id = auth.uid()`. SELECT and UPDATE grants exist. Other users' rows fail the ownership predicate; ownership reassignment fails WITH CHECK. Anonymous sign-in is disabled in the public settings.
- The exact audited policy/trigger and profile column/constraint definitions were exercised in an independent PostgreSQL 18 fixture with two synthetic users and anon. Cross-owner reads/updates/reassignment were denied; invalid diet/completion updates rolled back atomically. This is local RLS execution, not live impersonation or hosted JWT verification.
- Main uses a publishable client key. No service-role credential was introduced. Editable user metadata is used only for the signup display name.

Existing profiles grants include TRUNCATE/REFERENCES/TRIGGER for client roles. RLS does not protect TRUNCATE, though this audit did not establish an exposed arbitrary-SQL endpoint that could invoke it. A narrowly scoped, optional [privilege hardening SQL proposal](sql/auth_profile_privilege_hardening_proposal.sql) is provided separately and tested locally; it is **not applied and not placed in automatic migrations**. It preserves normal profile CRUD/owner RLS. Trigger `search_path = public` and broad profile field permissions are existing server-hardening considerations; no authentication schema change is necessary for the repaired normal onboarding flow. This is not a whole-project security sign-off.

## Automated verification

| Check | Result |
| --- | --- |
| Focused auth/onboarding and persisted-session tests | PASS: 17 tests |
| Full Flutter suite | PASS: 72/72 |
| Disposable profile trigger/default/RLS/atomicity tests | PASS on PostgreSQL 18; successful fixture deleted and owned cluster stopped |
| Flutter analyzer | FAIL exit 1: zero errors, 15 existing warnings + 72 existing infos (87 baseline diagnostics); no added diagnostics |
| Git whitespace check | PASS |

Tests use HTTP mocks, synthetic JWTs/identities and mock SharedPreferences. The Flutter SDK/GoTrue versions examined are 2.17.2/2.27.2, with Supabase client 2.16.1. PKCE storage is supplied in fixtures to match the application's Flutter initialization. No test targets live Auth or a real profile.

Commands:

```text
flutter test test/auth_onboarding_test.dart test/auth_session_persistence_test.dart
flutter test
flutter analyze
python test/sql/auth_onboarding_local_pg_test.py
```

The SQL fixture is pinned to `127.0.0.1:55439` and creates an isolated random database. It cannot select a live project through command arguments. Its synthetic `account_type` enum includes the needed client value; it is not a complete production Auth-server replica.

## Manual first-time-user device test

Rebuild/reinstall or otherwise deploy this Flutter code, then use a genuinely new email address under the user's control. This audit has not performed these account operations.

1. Open with no session. Confirm login is shown and Home is inaccessible.
2. Sign up; confirm there is no authenticated session or Home access before verification. Verify actual email receipt, spam/rate-limit behavior and confirmation link validity.
3. Follow the email link, then return manually to ARC and sign in. Signup currently uses Supabase's configured SITE_URL; Android/iOS files have no custom Auth callback scheme and signup supplies no `emailRedirectTo`. Automatic email-to-app return is not configured or asserted. Validate the hosted redirect target; manual return/login is the supported test path.
4. Confirm the new own profile exists with false completion and correct name; observe onboarding rather than Home. Do not inspect other users' records.
5. Try missing/invalid answers and Back navigation. Complete all existing steps. Interrupt connectivity on final save: answers should remain and Home should stay unavailable until the saved profile is confirmed. Restore connectivity and retry.
6. Verify the own profile's saved answers and true completion, then Home routing. Restart the app/process and confirm no repeated onboarding.
7. Log out/log in again, including with an app route open. Confirm old app routes disappear and completed onboarding is retained. Sign in as an incomplete account and confirm no prior-account answers or Home access.
8. Test invalid credentials, duplicate signup, expired/revoked session, background/foreground refresh, offline reopen and rapid account switching on each supported platform. Check keyboard, small screens, accessibility scale and system Back navigation.

SMTP delivery/rate limits, SITE_URL/redirect allowlist, actual confirmation tokens, real JWT refresh, native storage/lifecycle, native callback behavior and hosted Data API execution remain manual checks. Current [Supabase signup documentation](https://supabase.com/docs/reference/dart/auth-signup) confirms the user-without-session confirmation response and duplicate-signup behavior; [Auth event guidance](https://supabase.com/docs/reference/dart/auth-onauthstatechange) covers session/error events. These documents were checked alongside the installed SDK source and the current changelog.

Changes are confined to authentication, onboarding, their profile persistence helper, initialization's session storage, focused tests and audit/proposal documentation. Mascot, AI/LLM, Coach, Train, Rehab and unrelated feature behavior were not changed by this audit. Existing unrelated working-tree changes were retained.
