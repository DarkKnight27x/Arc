# ARC Android authentication regression investigation

Reviewed **2026-10-10, Asia/Calcutta**. **Device login recovery is not yet verified.** No live account, profile, database record, migration or Auth setting was created, deleted or modified during this investigation. Android diagnostics were read-only; no app-data clearing, reinstall, logout or login was performed on the device.

## Established evidence and remaining root-cause gap

The user reported the generic error below the Android login inputs. Before this correction, that exact message came from `_LoginPageState._submit`'s non-AuthException catch. The awaited operation is SDK password sign-in with a 20-second UI timeout, followed by `onLoggedIn`. The production callback is empty. Profile retrieval and route building occur later in AuthGate and have separate error UI; their asynchronous failures cannot directly produce this login-field message.

An authorized Android device was connected, ARC was installed, and the ARC process was not running when inspected. ARC-only historical Logcat, filtered by package UID and sanitized before output, contained:

| Device log time (10 October) | Sanitized finding |
| --- | --- |
| 01:17:50.265 | AuthRetryableFetchException / ClientException / SocketException; Failed host lookup for ARC's configured Supabase hostname; token refresh endpoint |
| 01:17:50.270 | Same refresh/DNS failure |
| 01:18:14.437 | Same refresh/DNS failure |

These are **actual device DNS failures during Auth refresh**, not mocked failures. They are not password-grant records, so they do not establish the exact exception from the reported password attempt. The previous generic catch did not log it. No logged storage-initialization or Supabase-uninitialized signature was found in the available ARC logs. Absence of a signature is not proof of absence of an unlogged failure.

The configured project hostname and publishable key are unchanged from Git HEAD. The workstation's read-only GET of `/auth/v1/settings` returned HTTP 200. This proves workstation reachability only, not Android reachability or credential validity. A read-only Android DNS/ping probe did not complete within 10 seconds and was terminated; no successful current DNS result was obtained. Airplane mode was off and Wi-Fi/mobile-data flags enabled, which do not prove working internet access. No network settings were changed.

The installed GoTrue 2.27.2 source and an actual SDK/mock-transport test show network fetch failures are wrapped in AuthRetryableFetchException, an AuthException subtype. The prior AuthException branch would show its message rather than the generic catch. Therefore it would be incorrect to label the refresh DNS records alone as a proven cause of this particular generic password error. A 20-second timeout, response parsing exception or another non-AuthException remains possible until a fresh stage log is captured.

## Recent change review

| Change from the prior audit | Assessment |
| --- | --- |
| Login now calls AuthService | Same trimmed-email/password SDK method; no changed credentials/project/key |
| New 20-second login timeout | Can produce the previous generic message when a request stalls; explicitly reproduced in a disposable widget test. Device timing has not been established |
| Guarded SharedPreferences session storage | Same persistence key/format. Guard affects startup reads; SDK persistence writes run in a separately caught Auth listener and are not awaited by password sign-in. No device evidence ties this guard to the reported error |
| User-keyed gate/onboarding | Preserves identity isolation; does not run before the Auth HTTP operation |
| Scoped app navigator and verified profile loading | Downstream of SDK authentication; no demonstrated link to login's generic catch |

No broad authentication rollback was made. The deadline, storage guard, onboarding verification, user isolation and logout protections are retained.

## Corrections made

- `lib/auth/login_page.dart`, `_LoginPageState._submit`: replace the silent generic catch with sanitized stage diagnostics and distinct safe messages for network, timeout, local platform-storage and other failures. Auth errors no longer expose raw server messages. Separate the post-login callback catch so a navigation callback error is logged as navigation rather than authentication.
- `lib/data/auth_diagnostics.dart`: debug-only stage/type/category metadata, validated HTTP status, allowlisted Auth/PostgREST codes and up to three ARC source locations. Never emits exception messages, HTTP bodies, URLs, email/password, session objects/tokens, route arguments or profile values.
- `lib/data/auth_service.dart`: identify actual password/signup/reset/refresh/logout operation start, completion and failure.
- `lib/data/auth_session_storage.dart`: identify initialization/read/write/removal success and exceptions without logging stored content. Preserve guard/key/format behavior.
- `lib/auth/auth_gate.dart`: trace profile loads/RLS errors and missing rows, Auth stream/gate failures, session recovery, routing decisions and scoped navigation events. Fail closed on a synchronous gate exception. Existing owner/completion routing remains intact.
- `lib/auth/signup_page.dart` and `lib/auth/forgot_page.dart`: the other two occurrences of the generic text now use the same sanitized diagnostics/messages. Password-reset errors also respect widget disposal.
- `lib/main.dart`: disable the SDK's automatic raw debug output; ARC's sanitized diagnostics remain active in debug builds. No Auth configuration or endpoint/key changed.

These corrections fix misleading/unsafe error reporting and separate the failing stages. **They do not repair Android DNS or establish that the existing account can now log in.** No credential validation, transport bypass, account reset, session-storage reset or onboarding bypass was added.

## Automated results

| Check | Result |
| --- | --- |
| Focused regression + login/onboarding/session/profile widget tests | PASS: 33/33 |
| Full Flutter suite | PASS: 83/83 |
| Analyzer | Exit 1: zero errors, 15 existing warnings and 72 existing infos; no added diagnostics |
| Git whitespace check | PASS |
| Android debug APK build | PASS; built 10 October 2026 at 01:38:06 local host time; not installed or tested on the device |

`test/auth_regression_test.dart` adds ten tests for secret-free diagnostics, actual SDK transport wrapping, DNS/network/timeout/storage/auth/response-format UI categories, the 20-second deadline and a navigation callback exception. Existing tests still cover completed-account routing, fresh-user onboarding, persisted session restoration, immediate logout, expired-session recovery, account switching and onboarding-save retries. All Auth HTTP and SharedPreferences test fixtures are disposable/mocked. No live password attempt was issued.

An additional `test/auth_session_persistence_test.dart` fixture makes storage persistence throw inside the actual SDK Auth listener. It verifies that password sign-in still returns a session, while the separate storage failure produces sanitized diagnostics. This confirms the asynchronous storage behavior discussed above; it does not establish the device's storage state.

The rebuilt debug artifact is `build/app/outputs/flutter-apk/app-debug.apk` (237,767,067 bytes). It contains the sanitized diagnostics and is ready for manual device verification. Build warnings concern existing plugin Kotlin/Gradle compatibility; no plugin versions were changed.

APK SHA-256: `C21851A8DBAE5E589C2CD0196436FB6737E8EA187E1D3CA53652C2449E6B0DFB`.

## Evidence needed on the real device

Use a rebuilt **debug** app and attempt login manually with the existing account. Do not share credentials or raw Supabase logs. A fresh sequence of only `[ARC_AUTH]` lines distinguishes:

```text
stage=loginRequest category=auth status=400 code=invalid_credentials
stage=loginRequest category=network type=AuthRetryableFetchException status=none
stage=loginUi category=timeout type=TimeoutException
stage=storageWrite category=platform_storage type=PlatformException
stage=profileLoad category=profile_api code=42501
stage=navigation category=unexpected type=StateError
```

These lines are examples, not fabricated device observations. Successful operation markers then show storage/profile/routing progression. Storage persistence is asynchronous: a write failure can coexist with a successful SDK sign-in and must not be mistaken for bad credentials. A UI deadline does not cancel the underlying SDK request, so a later request completion may still emit an Auth session event.

Retry on a known-working internet connection if the fresh log confirms network/DNS failure. Do not clear ARC app data or reset the account to investigate it. Verify existing-account Home routing, new-user onboarding, reopen persistence and logout/account switching manually after the specific failure is resolved. Automatic account operations remain outside this investigation.

The [Supabase password-login API](https://supabase.com/docs/reference/dart/auth-signinwithpassword) was checked against the installed SDK implementation. The latest changelog was reviewed in the immediately preceding audit; no SDK dependency/version changes were introduced here.
