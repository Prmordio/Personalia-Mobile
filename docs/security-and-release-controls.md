# Security & release controls

Runbook for the controls added in 2026-11: server-side paywall, Firebase App Check,
minimum app version, offline mode and the store-rating prompt.

## 1. Paywall enforced on the server

`personalia-trainer` → `AppFeatureAccessGuard` (uses `CheckAppFeatureAccessUseCase`) protects
the AI endpoints: `assistant/message`, `assistant/message-stream`, `assistant/photo`,
`execution-analysis` (POST + GET). Without a valid subscription → `403 { reason: 'subscription_required' }`.
Fails closed: if the payment service errors, the request is denied.

Demo / store-review accounts: the trainer reads the **same Remote Config key** the app uses,
`unlimited_access_email_hashes` (default value; sha256 hex of the lowercased, trimmed email,
comma-separated), via `firebase-admin` with the `FIREBASE_PROJECT_ID / FIREBASE_CLIENT_EMAIL /
FIREBASE_PRIVATE_KEY` service account (same one as the notifier, already in `personalia-secrets`).
Cached 5 min; if Firebase is unreachable the last value is kept. The service account needs read
access to Remote Config (the default Firebase Admin SDK account has it). Remote Config is the
**only** source: there is no env-var fallback, so without the `FIREBASE_*` credentials (e.g. local
dev with an empty `.env`) the allowlist is empty and demo accounts are treated like any other user.

The app also fails closed now: a failing `/app/subscription` call no longer unlocks paid areas.

## 2. Firebase App Check (anti-tampering)

App: `lib/core/security/app_check.dart` — Play Integrity (Android) and App Attest with
DeviceCheck fallback (iOS) in release; debug provider in debug. Sends `X-Firebase-AppCheck`.

Gateway: `src/auth/guards/app-check.guard.ts`, app routes only (`/app/*`, `/auth/*`, agent media).

| `APP_CHECK_MODE` | Behavior |
|---|---|
| `off` | No verification (default when `FIREBASE_PROJECT_NUMBER` is empty; dev) |
| `monitor` | Verifies, counts in `gateway_app_check_requests_total{result}`, lets everything through (prod default) |
| `enforce` | Rejects missing/invalid tokens with `401 { reason: 'app_check_failed' }` |

### One-time console setup
1. Firebase console → App Check → register the Android app with **Play Integrity** (link the
   Play Console project; add the app-signing SHA-256 from Play Console → App integrity).
2. Register the iOS app with **App Attest** (and DeviceCheck as fallback; DeviceCheck needs the
   `.p8` key from the Apple Developer account).
3. App Attest proper: the *App Attest* capability is enabled on the App ID, the `PersonaliA AppStore`
   profile was regenerated with it (CI secret `PROVISIONING_PROFILE_BASE64` updated), and
   `ios/Runner/Runner.entitlements` has `com.apple.developer.devicecheck.appattest-environment` =
   `production`. If the profile is ever regenerated, keep the capability or signing breaks.
4. Debug builds print a debug token in the log; add it under App Check → Manage debug tokens to
   test against a gateway in `enforce`.

### Rollout to enforce
1. Ship an app version with App Check and set `min_app_version` to it (section 3) so old
   clients (which send no token) update first.
2. Watch `gateway_app_check_requests_total` in Grafana until `result!="valid"` is ~0.
3. `kubectl patch configmap personalia-config --type merge -p '{"data":{"APP_CHECK_MODE":"enforce"}}'`
   then `kubectl rollout restart deployment <gateway>`.

## 3. Minimum / recommended app version

Remote Config keys (strings, e.g. `3.5.0`; empty = no requirement):
- `min_app_version` — below it the app shows a blocking "Update" screen.
- `recommended_app_version` — below it the app shows a dismissible card (once per version).

Use Remote Config *conditions* by platform if Android and iOS releases land on different days.
Bump `min_app_version` only after the new version is live in **both** stores.

## 4. Offline mode

`lib/core/connectivity/connectivity.dart`: a banner when the device has no network. Workout
logging was already offline-first (`workout_session_cache`); when the connection returns the
pending sync runs immediately instead of waiting for the 60s timer.

## 5. Store-rating prompt

`lib/features/workout/state/review_prompt.dart`: after finishing a workout, from the 3rd
completed workout on, never after a negative mood (😤 😑), at most every 120 days. The
OS (Play / App Store) still applies its own quota, so the dialog may not appear every time.

## 6. Build hardening

- Android: `allowBackup=false` + `data_extraction_rules.xml` (no cloud backup / device transfer
  of tokens, cache or preferences).
- Release builds refuse a non-`https` `API_BASE_URL` (`resolveBaseUrl`).
- CI release builds fail if `key.properties` is missing (they used to fall back silently to the debug key).
- Dart obfuscation stays off on purpose (see `.github/TELEMETRY.md`): it needs `--split-debug-info`
  symbols uploaded to Crashlytics, and App Check is the actual tamper control.
