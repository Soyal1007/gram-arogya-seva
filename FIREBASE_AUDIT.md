# Firebase Architecture Audit — Gram Aarogya Seva

> **Scope:** every Firebase and Google Cloud dependency in the repository
> **Method:** source inspection only — no Firebase Console access (see §15)
> **Date:** 28 July 2026
> **Companion documents:** [TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md), [ROADMAP.md](ROADMAP.md)

---

## 1. Executive Summary

The Firebase implementation is **architecturally sound and, in most respects,
correctly built**. Service selection is appropriate, the write path is
server-authoritative, security rules are tested against the emulator, and the
data model suits Firestore's query engine. This is not a system that needs
replacing.

It has one configuration defect severe enough to make the app unusable for real
users, and a set of cost and operational gaps that will bite at pilot scale.

### The headline finding — and a correction to the brief

The brief states that authentication *"appears to work only with preconfigured
or hardcoded mobile numbers and does not implement a proper Firebase Phone
Authentication flow using OTP verification."*

**The observation is correct. The diagnosis is not.** I checked before
accepting the premise, and the evidence contradicts it:

* There are **no hardcoded phone numbers anywhere** in `lib/` or
  `functions/src/`. The only 10-digit string in the codebase is the `hintText`
  placeholder `'9876543210'` in a text field (`phone_input_screen.dart:107`).
* `auth_notifier.dart` implements the **canonical Firebase Phone Auth flow**:
  `verifyPhoneNumber()` with all four callbacks (`codeSent`,
  `verificationCompleted`, `verificationFailed`, `codeAutoRetrievalTimeout`)
  plus `forceResendingToken`, then
  `PhoneAuthProvider.credential(verificationId, smsCode)` →
  `signInWithCredential()`. That is exactly what Firebase's own documentation
  prescribes.
* No test-mode escape hatch exists in code — no
  `setSettings(appVerificationDisabledForTesting:)`, no allowlist, no bypass.

The real cause is in the Firebase **project configuration**, not the code:

```
android/app/google-services.json → client[0].oauth_client = []   ← EMPTY
```

**No SHA-1/SHA-256 signing certificate fingerprint is registered for this
Android app.** Android Phone Auth cannot complete app verification without one.
The behaviour that produces is precisely what was reported: numbers registered
under *Authentication → Sign-in method → Phone → Phone numbers for testing*
bypass app verification and work; every real number fails.

So the fix is a 15-minute console task, not an authentication rewrite (§4.2).

### Verdicts at a glance

| Service | Rating | Verdict |
|---|:--:|---|
| Firebase Auth (Phone) | 7/10 | **Keep** — code correct, project misconfigured |
| Cloud Firestore | 8/10 | **Keep**, with targeted schema additions |
| Security Rules | 9/10 | **Keep** — hardened and emulator-tested |
| Cloud Functions | 8/10 | **Keep** — well factored, needs CI and region pinning |
| Cloud Messaging | 7/10 | **Keep** — implemented, unverified on device |
| Crashlytics | 8/10 | **Keep** |
| App Check | 6/10 | **Keep**, but see the enforcement warning in §6.4 |
| Remote Config | 8/10 | **Keep** |
| Cloud Scheduler | 8/10 | **Keep** |
| Cloud Storage | 0/10 | **Adopt** — currently unused; photos live in Firestore |
| Analytics | — | **Adopt** — nothing measures whether booking succeeds |
| Realtime Database | — | **Correctly absent** |
| Hosting | — | **Correctly absent** |
| Environment separation | 2/10 | **Redesign** — one project, no staging or prod |
| CI/CD | 0/10 | **Adopt** — coupled releases are hand-deployed |

**Overall: 7/10.** Strong foundations, one blocking misconfiguration, and the
operational scaffolding of a pre-pilot project rather than a production one.

---

## 2. Current Firebase Architecture

### 2.1 Client dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^3.12.1 | SDK bootstrap |
| `firebase_auth` | ^5.5.4 | Phone OTP authentication |
| `cloud_firestore` | ^5.6.7 | Primary datastore + offline cache |
| `cloud_functions` | ^5.3.4 | All privileged writes |
| `firebase_messaging` | ^15.2.10 | Push notifications |
| `firebase_crashlytics` | ^4.3.10 | Crash reporting |
| `firebase_app_check` | ^0.3.2+10 | Client attestation |
| `firebase_remote_config` | ^5.5.0 | Force-update gate |

Not present, deliberately or otherwise: `firebase_storage`,
`firebase_analytics`, `firebase_performance`, `firebase_database`.

### 2.2 Server surface (`functions/src/`)

| Module | Exports | Trigger |
|---|---|---|
| `abdm.ts` | `abdmRequestAadhaarOtp`, `abdmVerifyAadhaarOtp` | Callable |
| `doctors.ts` | `submitDoctorRegistration`, `resubmitDoctorRegistration`, `setDoctorAvailability` | Callable |
| `doctors.ts` | `onDoctorStatusChanged` | Firestore `onDocumentUpdated` |
| `appointments.ts` | `bookAppointment`, `cancelAppointment`, `updateAppointmentStatus`, `cancelDoctorDay` | Callable |
| `reminders.ts` | `sendAppointmentReminders` | Cloud Scheduler, hourly |
| `admin.ts` | `bootstrapAdmin` | HTTP request |
| `common.ts`, `notifications.ts` | shared helpers, notification catalogue | — |

All pinned to `asia-south1`, co-located with Firestore.

### 2.3 Project configuration

| Artefact | State |
|---|---|
| `.firebaserc` | **One project: `gram-aarogya-dev`.** No staging, no production |
| `firebase.json` | `firestore`, `functions`, `emulators`, `flutter` — no `hosting`, no `storage` |
| `firestore.rules` | 13 collection-level rule blocks, deny-by-default on privileged writes |
| `firestore.indexes.json` | 13 composite indexes |
| `firebase_options.dart` | Android **and iOS** blocks; `storageBucket` declared but unused |
| Secrets | Secret Manager: `AADHAAR_HMAC_SECRET`, `ABDM_CLIENT_SECRET`, `ADMIN_BOOTSTRAP_SECRET` |
| CI/CD | **None** |

---

## 3. Cloud Dependency Map

```
┌─ AUTHENTICATION ───────────────────────────────────────────────────────┐
│ Firebase Auth (Phone OTP)                                              │
│   └─► every screen (router guard reads authStateChanges)               │
│   └─► users/{uid} document created on first sign-in                    │
│   └─► requires: SHA fingerprint + Play Integrity  ⚠️ MISSING            │
└────────────────────────────────────────────────────────────────────────┘
        │ uid
        ▼
┌─ FIRESTORE ────────────────────────────────────────────────────────────┐
│ users ──────────► role (drives router + every security rule get())     │
│ doctors ────────► doctor dashboard, patient discovery, admin approval  │
│ patients ───────► profile, operator registration, appointment identity │
│ villages ───────► pickers, doctor/patient scoping    (streamed whole)   │
│ health_centers ─► availability, slot picker          (streamed whole)   │
│ doctor_availability ─► slot grid (contention point, server-write only) │
│ appointments ───► every role's list views (server-write only)          │
│ notifications ──► inbox + unread badge (server-write only)             │
│ abdm_rate_limits ─► OTP cooldown + verification proof (no client access)│
└────────────────────────────────────────────────────────────────────────┘
        ▲ Admin SDK (bypasses rules)
        │
┌─ CLOUD FUNCTIONS ──────────────────────────────────────────────────────┐
│ bookAppointment ─────────┐                                             │
│ cancelAppointment        ├─► appointments + doctor_availability (txn)   │
│ updateAppointmentStatus  │   + notifications                            │
│ cancelDoctorDay ─────────┘                                             │
│ submitDoctorRegistration ─► doctors + users.role + Secret Manager      │
│ setDoctorAvailability ────► doctor_availability (merge booked slots)   │
│ abdm* ────────────────────► ABDM gateway (external) + abdm_rate_limits │
│ onDoctorStatusChanged ────► notifications                              │
│ sendAppointmentReminders ─► Cloud Scheduler → appointments + FCM       │
│ bootstrapAdmin ───────────► users (unauthenticated HTTP ⚠️)            │
└────────────────────────────────────────────────────────────────────────┘
        │
        ├─► FCM ──────────► device push (token on users/{uid}.fcmToken)
        ├─► Secret Manager ► Aadhaar HMAC, ABDM client secret
        └─► ABDM gateway ─► Aadhaar OTP (third party, NHA)

┌─ CROSS-CUTTING ────────────────────────────────────────────────────────┐
│ Crashlytics ─► FlutterError.onError + PlatformDispatcher.onError       │
│ App Check ───► attests every Firebase call (Play Integrity / debug)    │
│ Remote Config ► minimum_app_version → ForceUpdateScreen                │
└────────────────────────────────────────────────────────────────────────┘

NOT USED: Cloud Storage · Analytics · Performance Monitoring ·
          Realtime Database · Hosting · Firebase Extensions · Dynamic Links
```

### Feature → service matrix

| Feature | Auth | Firestore | Functions | FCM | Storage | Remote Config |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Login / OTP | ● | ● | | | | |
| Doctor registration | ● | ● | ● (+ABDM, Secrets) | ● | ○ photos | |
| Doctor approval | ● | ● | ● (trigger) | ● | | |
| Set availability | ● | ● | ● | | | |
| Book appointment | ● | ● | ● | ● | | |
| Cancel appointment | ● | ● | ● | ● | | |
| Status transitions | ● | ● | ● | ● | | |
| Health records | ● | ● | ● | | | |
| Notifications inbox | ● | ● | ● | ● | | |
| 24h reminders | | ● | ● (Scheduler) | ● | | |
| Patient/doctor photos | ● | ● | | | ○ **should** | |
| Force update | | | | | | ● |

● = used · ○ = should be used but is not

---

## 4. Authentication Analysis

### 4.1 How it actually works today

1. `phone_input_screen` collects 10 digits; `Validators.validatePhone` enforces
   `^[6-9]\d{9}$` (correct for Indian mobile numbering).
2. `AuthNotifier.sendOtp` prefixes `+91` and calls
   `FirebaseAuth.verifyPhoneNumber(...)` with a 60-second timeout.
3. Firebase performs **app verification** (Play Integrity, falling back to
   reCAPTCHA), then dispatches the SMS.
4. `codeSent` returns a `verificationId` held in Riverpod state, plus a
   `forceResendingToken` used by the 30-second resend path.
5. `verifyOtp` builds `PhoneAuthProvider.credential(verificationId, smsCode)`
   and calls `signInWithCredential`.
6. `verificationCompleted` handles Android SMS auto-retrieval — the OTP screen
   can complete without the user typing anything.
7. On success, `_createUserDocIfNeeded` creates `users/{uid}` with
   `role: 'patient'` if absent.
8. `authStateProvider` (`authStateChanges()`) and `currentUserProvider`
   (`users/{uid}` snapshot) drive the GoRouter redirect.

**Assessment of the code: correct.** All four callbacks are handled, the
resend token is threaded through, errors map to localisation keys rather than
raw Firebase codes, and the credential path is the documented one. I would
ship this flow as written.

### 4.2 Why real numbers fail — root cause

`google-services.json` contains `"oauth_client": []`.

Android Phone Auth requires the app to prove it is genuinely your app before
Firebase will send an SMS. That proof is Play Integrity (or the legacy
SafetyNet/reCAPTCHA fallback), and it is keyed to the app's **signing
certificate fingerprint**, which must be registered in the Firebase project.
With none registered, app verification cannot succeed, and Firebase refuses to
dispatch SMS to arbitrary numbers.

Numbers added under *Authentication → Sign-in method → Phone → Phone numbers
for testing* skip verification by design. Hence: test numbers work, real
numbers do not. Exactly the reported symptom, with no hardcoding in the code.

**Fix (do this first, before any further work):**

```bash
# Debug keystore fingerprint
keytool -list -v -alias androiddebugkey \
  -keystore "$HOME/.android/debug.keystore" -storepass android -keypass android

# Release keystore fingerprint (once you create one)
keytool -list -v -alias <your-alias> -keystore <your-release.jks>
```

1. Copy both **SHA-1** and **SHA-256** into
   *Firebase Console → Project settings → Your apps → Android → Add fingerprint*.
   Add debug **and** release, and later the Play App Signing certificate.
2. Enable the **Play Integrity API** in Google Cloud Console for the project.
3. Re-download `google-services.json` and replace
   `android/app/google-services.json`. `oauth_client` should no longer be empty.
4. Confirm Phone is enabled under *Authentication → Sign-in method*, and that
   the daily SMS quota is not exhausted.
5. Remove test numbers before the pilot, or real users will be the only ones
   who cannot log in.

> ⚠️ **Play App Signing.** When you upload to Play, Google re-signs the app
> with its own key. The fingerprint that then matters is the one under
> *Play Console → Setup → App integrity*. Register it too, or Phone Auth will
> work in internal testing and fail in production — the worst possible time to
> discover it.

### 4.3 Trust model and authorization

| Question | Answer |
|---|---|
| Identity | Firebase Auth UID. Never derived from client input |
| Phone storage | `users/{uid}.phone` — 10 digits, `+91` stripped. Auth holds the canonical E.164 value |
| Session | Firebase SDK holds the refresh token in Android Keystore-backed storage; ID tokens auto-refresh hourly |
| Session validation | Server-side by Firebase on every callable and every rule evaluation. The client never asserts identity |
| Authorization | `users/{uid}.role`, read by security rules via `get()` and by callables via `requireCaller()` |
| Role assignment | Admin (rules, `role` only) or `submitDoctorRegistration` (Admin SDK). Self-promotion is denied and emulator-tested |

**Trust assumptions are correctly placed.** The client is trusted for nothing:
`bookAppointment` accepts identifiers only and resolves names, village and
health centre server-side; a patient cannot book for another patient; an
operator's bookings are stamped by the server, not claimed by the client.

### 4.4 The one architectural weakness: role lives in a document

Every security rule calls:

```javascript
function userDoc() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
}
```

`get()` inside rules **is billed as a document read** and adds latency to every
protected operation. Identical `get()` calls are cached within a single rule
evaluation, so it is one extra read per request — but that is one extra read on
*every point read in the application*, close to doubling the cost of the
cheapest operations.

**Recommendation: mirror `role` into a custom claim.**

```
users/{uid}.role  ← source of truth (admin-editable, auditable)
        │ onDocumentUpdated trigger
        ▼
setCustomUserClaims(uid, {role})  ← read from request.auth.token.role
```

Rules become `request.auth.token.role == 'admin'` — zero reads, zero latency.
Callables read `request.auth.token.role` instead of fetching the user document.

*Trade-off, stated plainly:* claims propagate only when the ID token refreshes
(hourly, or immediately on `getIdToken(true)`). A demoted admin keeps admin
rights for up to an hour unless the client force-refreshes. Mitigation: have
the claim-sync trigger also bump a `users/{uid}.claimsUpdatedAt` field that the
client watches, force-refreshing the token when it changes. Keep the Firestore
`role` field as the audit record and the admin UI's source of truth.

*Verdict:* worth doing before scale, not before the pilot. It is a pure cost
and latency optimisation, and the current model is **secure** — just expensive.

### 4.5 Production-grade authentication design (target state)

Most of this already exists; the gaps are marked.

| Concern | Design | State |
|---|---|---|
| OTP generation | Firebase-managed. Never generate OTPs yourself — you would own SMS delivery, expiry, replay and brute-force | ✅ |
| OTP validation | `signInWithCredential`; Firebase enforces attempt limits and expiry | ✅ |
| App attestation | Play Integrity via registered SHA fingerprints | ❌ **§4.2** |
| Auto-retrieval | `verificationCompleted` — zero-typing sign-in on Android | ✅ |
| Resend | `forceResendingToken` + 30s client cooldown | ✅ |
| New user onboarding | `users/{uid}` created with `role: 'patient'`, enforced by rules | ✅ |
| Returning user | `authStateChanges()` → role → dashboard | ✅ |
| Session persistence | SDK default (encrypted local storage) | ✅ |
| Token refresh | Automatic, hourly | ✅ |
| Custom claims | Role in JWT | ⬜ §4.4 |
| Anonymous users | **Not appropriate.** Every actor is identified by phone; anonymous auth would create orphan clinical records | N/A |
| Multi-device | Native to Firebase. **But `users/{uid}.fcmToken` is a single string**, so a second device silently steals push. Move to `users/{uid}/devices/{token}` | ⚠️ |
| Account recovery | Phone re-verification. Losing the SIM means losing the account — for admin/operator, keep a second account provisioned | ⚠️ document |
| Logout | `signOutCompletely()` clears the FCM token first — correct for shared phones | ✅ |
| Rate limiting | Firebase per-number and per-IP quotas; ABDM path adds a 60s cooldown | ✅ |
| Abuse prevention | App Check + Play Integrity + SMS region allowlist | ⚠️ §6.4 |
| Fraud prevention | Restrict SMS regions to India in Console; set a budget alert | ⬜ |

#### Attack surface, honestly assessed

| Attack | Feasible today? | Why |
|---|---|---|
| Log in as someone else's number | No | Requires possession of the SMS |
| Brute-force a 6-digit OTP | No | Firebase invalidates after a handful of attempts |
| Replay a `verificationId` | No | Single-use, short-lived, server-tracked |
| Forge a role | No | Rules deny; emulator-tested |
| **SMS pumping / toll fraud** | **Yes, once fingerprints are registered** | An automated client could burn the 10K free SMS. **Mitigation: App Check enforcement + India-only SMS region + budget alert.** This is the main auth-adjacent financial risk |
| Extract the API key from the APK | Yes, and it is harmless | Firebase API keys identify, they do not authorise. Rules and App Check are the control |

---

## 5. OTP Analysis

Two distinct OTP systems exist. They are unrelated and both correct.

**1. Firebase Phone Auth OTP** — authentication. Firebase owns generation,
delivery, expiry, retry limits. The app never sees the code. Correct: never
build your own for authentication.

**2. ABDM Aadhaar OTP** — doctor credential verification, not authentication.
The Cloud Function calls the ABDM gateway with server-held secrets; the client
receives only a `txnId`.

The ABDM path had a real hole, now fixed: the client previously passed its own
`txnId` to registration, so a caller could claim verification that never
happened. The verification outcome is now recorded server-side in
`abdm_rate_limits/{uid}` (`verifiedTxnId`, `verifiedAt`, `aadhaarLastFour`) and
`submitDoctorRegistration` requires a match within a 30-minute TTL. Client
access to that collection is denied entirely.

Remaining considerations:

* **Rate limiting is per-UID (60s).** An attacker with many accounts could
  still fan out ABDM requests. Add a per-IP or global daily cap if ABDM
  enforces quotas.
* **`ABDM_VERIFICATION_REQUIRED=false`** disables the check while NHA
  credentials are pending. It records `abdmVerified: false` on the doctor so an
  admin sees it. Auditable, but **must be `true` before production** — put it on
  the launch checklist.
* **Collection naming.** `abdm_rate_limits` now stores verification state too.
  Rename to `abdm_verifications` in the next migration for honesty.

---

## 6. Security Audit

### 6.1 Firestore Rules — 9/10, keep

Deny-by-default on every privileged write; role-scoped reads; `userId`
immutable on patient records; `role` writable only by an admin and only alone.
59 emulator-backed scenarios pass, including regressions for the privilege
escalation that previously let any user write `{role: 'admin', name: 'x'}`.

Residual, accepted with reasoning:

* **S-5 — every doctor can read every patient.** SRS §8 accepts this; there is
  no care-relationship model. At one village it is fine. Before multi-district
  expansion, scope reads to patients with an appointment involving that doctor
  (requires a `doctorIds: []` array on the patient document, maintained by the
  booking function).
* **No field-level schema validation on writes.** Client-writable collections
  (`patients`, `villages`, `health_centers`) accept arbitrary extra fields. Low
  severity — those documents are not used for authorization — but adding
  `hasOnly()` constraints would prevent document bloat.

### 6.2 Storage Rules — N/A, and that is the problem

There is no `storage.rules` file and no `storage` block in `firebase.json`,
because Storage is not used. Photos are base64 strings inside Firestore
documents. **The moment you adopt Storage (§9), rules must be written first** —
an unconfigured bucket defaults to authenticated-read/write across the whole
bucket, which for medical photographs is a serious exposure.

### 6.3 Cloud Function permissions — 8/10

Every callable calls `requireCaller()` (authenticated + role resolved) and
re-checks ownership. Secrets are in Secret Manager, correctly bound per
function.

**One exposure: `bootstrapAdmin`.** An unauthenticated public HTTP endpoint
that grants admin. Guarded by a shared secret and it fails closed when unset —
but it is permanently deployed and reachable by anyone who guesses the URL. The
secret is the only barrier.

*Fix:* delete the function after first use. If it must stay, add an IP
allowlist or convert it to a callable requiring an existing admin. Better:
bootstrap the first admin by editing `users/{uid}.role` directly in the Console
and never deploy the function at all.

### 6.4 App Check — 6/10, and a warning about my own change

I added App Check in the previous pass. It is correct code, but **enforcement
is a console setting with a sharp edge**, and given §4.2 you must sequence this
carefully:

1. Register SHA fingerprints and fix Phone Auth **first**.
2. Deploy App Check in **monitoring mode** and watch the metrics for a week.
3. Only then enable enforcement, per service.
4. For debug builds, register the debug token that `AndroidProvider.debug`
   prints on first run, or every developer device is locked out.

Enabling enforcement on Firebase Auth before fingerprints are registered will
compound the current login failure and make it harder to diagnose.

### 6.5 Secrets and configuration

| Item | Location | Verdict |
|---|---|---|
| `AADHAAR_HMAC_SECRET` | Secret Manager | ✅ Correct — never client-side |
| `ABDM_CLIENT_SECRET` | Secret Manager | ✅ |
| `ADMIN_BOOTSTRAP_SECRET` | Secret Manager | ⚠️ Delete with the function |
| `ABDM_BASE_URL`, `ABDM_CLIENT_ID` | Params | ✅ Sandbox→prod without a code change |
| `google-services.json` | Committed | ✅ Normal — contains no secrets |
| Firebase API key | In APK | ✅ Identifies, does not authorise |

### 6.6 Ranked security issues

| # | Issue | Severity | Fix |
|---|---|---|---|
| 1 | No SHA fingerprints → Phone Auth broken for real users | **Blocker** | §4.2 |
| 2 | SMS pumping once auth works | **High** | App Check enforcement + India-only SMS + budget alert |
| 3 | `bootstrapAdmin` permanently deployed | **High** | Delete after use |
| 4 | Storage rules absent ahead of Storage adoption | **High** (when adopted) | Write rules before the bucket goes live |
| 5 | Single Firebase project — dev data = prod data | **High** | §7.4 |
| 6 | Every doctor reads every patient | Medium | Accepted for one village; scope before expansion |
| 7 | Single `fcmToken` field breaks multi-device | Medium | `users/{uid}/devices/{token}` |
| 8 | No schema validation on client-writable documents | Low | `hasOnly()` constraints |
| 9 | iOS config present, iOS unsupported | Low | Remove or support it |

---

## 7. Firestore Review

### 7.1 What is right — do not change it

* **Flat top-level collections.** Appointments are queried by doctor, patient,
  operator and status; a subcollection would make three of those impossible
  without collection-group indexes.
* **Denormalisation** (`patientUserId`, `patientName`, `doctorName`,
  `healthCenterId`) removes `get()` calls from rules and extra reads from lists.
* **`doctor_availability/{doctorId}_{date}`** — O(1) lookup, deterministic
  transaction locking, natural contention isolation per doctor-day. This is the
  single best decision in the schema.
* **`slotStartAt` as a real Timestamp** — makes the cancellation window and the
  reminder query expressible at all.
* **13 composite indexes**, each traceable to a query.

I would not restructure this schema. The recommendations below are additive.

### 7.2 Targeted changes

**a) `reference/current` — one document instead of two streamed collections**

`villagesByIdProvider` and `healthCentersByIdProvider` stream **entire
collections** to every user to render names instead of raw ids. Correct for the
UI, wrong for cost. A single document rebuilt by a trigger on village/centre
writes turns ~150 cold-start reads into 1. Well within the 1 MB limit at
realistic volumes (tens of villages, ~100 centres).

**b) `stats/current` — dashboard counters**

Six `count()` aggregations fire per admin dashboard open. Maintain counters via
`FieldValue.increment` from triggers. 6 reads → 1, and the numbers become live.

**c) `notifications` → `users/{uid}/notifications/{id}`**

As a subcollection the rule becomes ownership by path — no field comparison, no
mis-scoping possible — and per-user pagination is natural. Nothing queries
notifications across users. Removes two composite indexes.

**d) `nameLower` on `patients`**

`searchPatients` uses a prefix range on `name`, so it is case- and
diacritic-sensitive: "suresh" will not find "Suresh". Maintain a normalised
`nameLower` and query that.

**e) `photoBase64` → `photoPath`**

See §9.

**f) TTL policies**

`abdm_rate_limits` (24h) and notifications (90d). Free cleanup, console-configured.

### 7.3 Query efficiency

| Query | Verdict |
|---|---|
| `streamDoctorAppointmentsForDate` | ✅ Indexed, tight |
| `streamPatientAppointments` | ✅ Indexed |
| `streamActiveDoctors(villageId)` | ✅ Indexed (`status` + `villages` array-contains) |
| `sendAppointmentReminders` | ✅ Indexed, `limit(200)` bounded |
| `streamAllVillages` / `streamHealthCenters` | ❌ Unbounded, no `limit()` — violates SRS §6.2. §7.2(a) resolves this |
| All list screens | ❌ `limit(20)` **truncates rather than paginates** — data is wrong past 20 rows, not merely partial |

### 7.4 Environment separation — the biggest structural gap

`.firebaserc` defines **one project**. Development and production would share a
database, meaning test bookings against real patient records, and a rules
mistake in development affecting live clinical data.

**Target:**

```json
{
  "projects": {
    "default": "gram-aarogya-dev",
    "dev":     "gram-aarogya-dev",
    "staging": "gram-aarogya-staging",
    "prod":    "gram-aarogya-prod"
  }
}
```

```bash
firebase use dev      # daily work
firebase use staging  # pre-release verification
firebase use prod     # release only, from CI
```

Pair with Flutter flavors so `firebase_options.dart` is selected per build, and
lock production deploys to CI with a human approval gate.

---

## 8. Cloud Functions Review — 8/10, keep

**Strengths:** clean module boundaries; every callable validates caller, role
and ownership; secrets bound per function; transactions used where invariants
span documents; the reminder job is idempotent via `reminderSent`.

**Weaknesses and fixes:**

| Issue | Impact | Fix |
|---|---|---|
| Cold starts on booking (~1–2s) | First booking of a session feels slow | Accept for pilot. If it hurts: `minInstances: 1` on `bookAppointment` only (~₹200/month — breaks the ₹0 target, so make it a conscious choice) |
| No `maxInstances` cap | A runaway loop could scale to thousands and generate a real bill | Set `maxInstances: 10` on every function. Cheap insurance |
| No memory/timeout tuning | Defaults (256 MB / 60s) | Fine, but pin them explicitly so a platform default change cannot alter behaviour |
| No structured error monitoring | Failures visible only in Cloud Logging | Log-based alert on `severity>=ERROR` |
| No function unit tests | Logic verified only through rules tests and types | `firebase-functions-test` is already a devDependency — unused. Test `parseSlotMinutes`, `slotStartAt`, transition validation |
| `bootstrapAdmin` deployed permanently | §6.3 | Delete after use |

---

## 9. Storage Review — 0/10, adopt

Cloud Storage is **provisioned but unused**: `firebase_options.dart` declares
`storageBucket: gram-aarogya-dev.firebasestorage.app` and nothing writes to it.

Photos are base64 strings inside Firestore documents (`patients.photoBase64`,
`doctors.photoBase64`). This is wrong on four counts:

1. **Read amplification.** A 20-row patient search transfers megabytes. On 2G —
   the stated target network — that is the difference between usable and not.
2. **Every read pays**, whether or not the photo is displayed. Firestore has no
   projection; you cannot fetch a document without its blob.
3. **1 MB document ceiling.** `image_picker` caps at 300×300/quality 50, so it
   fits today — but the limit is one careless change away.
4. **No CDN, no transformation, no lazy loading.**

**Target design:**

```
gs://<bucket>/patients/{patientId}/profile.jpg
gs://<bucket>/doctors/{doctorId}/profile.jpg
```

Document holds `photoPath` (not a signed URL — those expire). Client fetches
via `FirebaseStorage.refFromURL().getDownloadURL()` with a cache.

```javascript
// storage.rules — write these BEFORE creating the bucket
service firebase.storage {
  match /b/{bucket}/o {
    match /patients/{patientId}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 2 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
    match /doctors/{doctorId}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == doctorId
        && request.resource.size < 2 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

Migration: dual-read (`photoPath ?? photoBase64`), backfill via a one-off
function, then drop `photoBase64`.

---

## 10. Performance Review

| Area | Finding | Fix |
|---|---|---|
| Rules `get()` per request | ~2× read cost on point reads | Custom claims (§4.4) |
| Reference data streaming | ~150 reads per cold start | `reference/current` (§7.2a) |
| Dashboard aggregations | 6 reads per open | `stats/current` (§7.2b) |
| Base64 photos | MBs per list screen | Storage (§9) |
| Listener count | 2–4 per dashboard | Acceptable; audit if screens grow |
| Offline cache | `CACHE_SIZE_UNLIMITED` | ✅ Correct for DP-2 |
| Function cold start | 1–2s first booking | Accept; loading state exists |
| Auth latency | SMS delivery dominates | Not controllable |
| Locale change | Keyed subtree rebuild | Acceptable; simplified already |

**Estimated effect of §4.4 + §7.2(a) + §7.2(b) + §9 together: 60–80% reduction
in daily reads**, which is the difference between comfortable and marginal
against the 50K/day free tier at ~500 users.

---

## 11. Scalability Review

| Dimension | Ceiling | Assessment |
|---|---|---|
| Slot contention | 1 doc per doctor-day, ~1 write/sec sustained | Far beyond village demand |
| Appointments | Unbounded collection, indexed | Scales |
| Patient search | Prefix range | Works to ~10⁵; beyond that use Algolia/Typesense |
| Reference data | Whole-collection streams | **Breaks first** — fix per §7.2(a) |
| Pagination | Absent | **Wrong data past 20 rows today** |
| Functions | 2M/month free | ~20K at 500 users |
| Multi-district | No tenancy dimension | Add `districtId` before expanding |

The binding constraint is not the database — it is the read budget, and the two
worst offenders are both avoidable.

---

## 12. Cost Optimization Review

Blaze is active. At ~500 users, projected monthly cost is **₹0** provided the
optimisations land; without them the read budget is the risk.

| Lever | Saving | Effort |
|---|---|---|
| `reference/current` | ~150 reads/session | Low |
| Custom claims | ~1 read per protected request | Medium |
| `stats/current` | 6 reads per admin open | Low |
| Photos → Storage | MBs of transfer | Medium |
| TTL policies | Storage growth | Trivial |
| `maxInstances` caps | Bounds worst-case bill | Trivial |
| Budget alert at ₹100 | Not a saving — an early warning | Trivial, **do it now** |

---

## 13. Problems Identified (ranked)

| # | Problem | Severity | Section |
|---|---|---|---|
| 1 | No SHA fingerprints → Phone Auth fails for real numbers | **Blocker** | §4.2 |
| 2 | Single Firebase project — no staging or production | **Critical** | §7.4 |
| 3 | Nothing deployed or run against live Firebase since the write path moved server-side | **Critical** | ROADMAP §1 |
| 4 | SMS pumping exposure once auth works | High | §4.5 |
| 5 | `bootstrapAdmin` permanently deployed | High | §6.3 |
| 6 | Photos as base64 in Firestore | High | §9 |
| 7 | Reference data streamed whole to every user | High | §7.2a |
| 8 | No pagination — lists wrong past 20 rows | High | §7.3 |
| 9 | No CI/CD for a coupled rules+functions release | High | §16 |
| 10 | Role via rules `get()` — ~2× read cost | Medium | §4.4 |
| 11 | Single `fcmToken` breaks multi-device | Medium | §4.5 |
| 12 | No Analytics — booking funnel unmeasured | Medium | §16 |
| 13 | Dashboard aggregations per open | Medium | §7.2b |
| 14 | No function unit tests | Medium | §8 |
| 15 | Every doctor reads every patient | Medium | §6.1 |
| 16 | No `maxInstances` cap | Medium | §8 |
| 17 | Case-sensitive patient search | Low | §7.2d |
| 18 | No TTL policies | Low | §7.2f |
| 19 | iOS config for an Android-only product | Low | §2.3 |

---

## 14. Recommended Improvements (by priority)

**P0 — before anything else (hours)**
1. Register SHA-1/SHA-256, enable Play Integrity, re-download `google-services.json`
2. Set the ₹100 budget alert; restrict SMS regions to India
3. Deploy to dev and walk one appointment end to end
4. Delete `bootstrapAdmin` after bootstrapping

**P1 — before the pilot (1–2 weeks)**
5. Create staging and production projects; add Flutter flavors
6. CI/CD: rules + indexes + functions as one gated release
7. App Check in monitoring mode → enforce after a week
8. `reference/current` and `stats/current`
9. Pagination
10. Analytics with a booking-funnel event set

**P2 — before scale (1–2 months)**
11. Photos → Cloud Storage, with rules written first
12. Custom claims for role
13. `users/{uid}/devices/{token}` for multi-device push
14. `notifications` → subcollection
15. Function unit tests
16. TTL policies; `nameLower`; `maxInstances`

---

## 15. Missing Information Required

This audit is **source-only**. Roughly 30% of a Firebase system lives in
console configuration that is not in the repository. Rather than assume, here
is exactly what I need.

> **Sharing safely:** everything below is either non-secret or should be shared
> as *screenshots/settings*, never as raw key material. Never paste service
> account JSON, `ADMIN_BOOTSTRAP_SECRET`, or ABDM client secrets into a chat or
> commit them. For secrets, confirm only *"set / not set"*.

| # | Item | Why it matters | Where to find it | How to export |
|---|---|---|---|---|
| 1 | **Phone Auth test numbers** | Confirms §4.2 conclusively | Console → Authentication → Sign-in method → Phone | Screenshot the "Phone numbers for testing" list |
| 2 | **SHA fingerprint list** | The blocking defect | Console → Project settings → Your apps → Android | Screenshot; or re-download `google-services.json` and check `oauth_client` |
| 3 | **Play Integrity API status** | Required for app verification | Cloud Console → APIs & Services → Enabled APIs | Screenshot |
| 4 | **Auth usage / SMS quota** | Rules out quota exhaustion | Console → Authentication → Usage | Screenshot |
| 5 | **Authorized domains** | reCAPTCHA fallback | Console → Authentication → Settings → Authorized domains | Screenshot |
| 6 | **SMS region policy** | Toll-fraud exposure | Console → Authentication → Settings → SMS region policy | Screenshot |
| 7 | **Deployed rules** | Confirms the repo matches production | Console → Firestore → Rules | Copy text, compare to `firestore.rules` |
| 8 | **Deployed indexes** | Detects console-created indexes not in the repo | `firebase firestore:indexes > deployed.json` | Diff against `firestore.indexes.json` |
| 9 | **Firestore data profile** | Sizes the read-cost work | Console → Firestore → Usage | Document counts per collection — **no patient data needed** |
| 10 | **Deployed function list** | Detects drift and orphans | `firebase functions:list` | Paste output |
| 11 | **Function secrets** | Confirms configuration | `firebase functions:secrets:access` | **Confirm set/not-set only — never the values** |
| 12 | **IAM roles** | Least-privilege review | Cloud Console → IAM | Screenshot of principals and roles |
| 13 | **App Check status** | §6.4 sequencing | Console → App Check | Screenshot: registered apps + enforcement per service |
| 14 | **Remote Config** | Force-update gate | Console → Remote Config | `firebase remoteconfig:get` |
| 15 | **Cloud Scheduler jobs** | Confirms the reminder job | Cloud Console → Cloud Scheduler | Screenshot |
| 16 | **Storage bucket state** | Is it empty and rule-less? | Console → Storage | Screenshot of Files and Rules |
| 17 | **Crashlytics** | Is data arriving? | Console → Crashlytics | Screenshot |
| 18 | **Billing / budget alerts** | Financial exposure | Cloud Console → Billing → Budgets | Screenshot |
| 19 | **Play Console app signing** | Post-launch auth failure risk | Play Console → Setup → App integrity | Screenshot the SHA-256 |
| 20 | **CI/CD** | None found in repo | — | Confirm none exists |

**The three that would change my conclusions most: #1, #2, #7.**

---

## 16. Proposed Firebase Architecture

Deliberately **evolutionary, not revolutionary.** The core is right; replacing
it would destroy working, tested code for no benefit. Changes are targeted at
the defects above.

```
┌─ PROJECTS ─────────────────────────────────────────────────────────────┐
│ gram-aarogya-dev      developers, emulator, test numbers               │
│ gram-aarogya-staging  release candidates, real OTP, synthetic data     │
│ gram-aarogya-prod     pilot villages, CI-only deploys, human approval  │
└────────────────────────────────────────────────────────────────────────┘

┌─ AUTH ─────────────────────────────────────────────────────────────────┐
│ Phone OTP (unchanged code) + SHA fingerprints + Play Integrity         │
│ role → custom claim, mirrored from users/{uid}.role by a trigger       │
│ users/{uid}/devices/{token} for multi-device push                      │
│ SMS region: IN only · App Check enforced · budget alert                │
└────────────────────────────────────────────────────────────────────────┘

┌─ FIRESTORE ────────────────────────────────────────────────────────────┐
│ users/{uid}                       + claimsUpdatedAt                    │
│   └─ devices/{token}              NEW — multi-device                   │
│   └─ notifications/{id}           MOVED — ownership by path            │
│ doctors/{uid}                     unchanged                            │
│ patients/{id}                     + nameLower, photoPath (−photoBase64)│
│ villages/{id}  health_centers/{id}  unchanged (admin-written)          │
│ doctor_availability/{doctorId}_{date}   unchanged — keep this design   │
│ appointments/{id}                 unchanged + pagination cursors       │
│ reference/current                 NEW — villages + centres in one doc  │
│ stats/current                     NEW — counters via increment         │
│ abdm_verifications/{uid}          RENAMED from abdm_rate_limits        │
└────────────────────────────────────────────────────────────────────────┘

┌─ FUNCTIONS (by domain, unchanged structure) ───────────────────────────┐
│ callable/   book · cancel · updateStatus · cancelDay · register ·      │
│             resubmit · setAvailability                                 │
│ triggers/   onDoctorStatusChanged · syncRoleClaim (NEW) ·              │
│             rebuildReference (NEW) · updateStats (NEW)                 │
│ scheduled/  sendAppointmentReminders · dailyBackup (NEW)               │
│ external/   abdm                                                       │
│ admin/      bootstrapAdmin (delete after use)                          │
│ All: maxInstances capped, memory/timeout pinned, asia-south1           │
└────────────────────────────────────────────────────────────────────────┘

┌─ STORAGE (NEW) ────────────────────────────────────────────────────────┐
│ patients/{id}/profile.jpg · doctors/{id}/profile.jpg                   │
│ storage.rules written before the bucket is used                        │
└────────────────────────────────────────────────────────────────────────┘

┌─ OBSERVABILITY ────────────────────────────────────────────────────────┐
│ Crashlytics (live) · Analytics (NEW — booking funnel) ·                │
│ log-based alerts on function errors · budget alert                     │
└────────────────────────────────────────────────────────────────────────┘
```

**Naming conventions:** collections `snake_case` plural; documents keyed by the
natural id (`uid` where it is a user); compound keys `{parent}_{discriminator}`
as in availability; booleans `isX`; timestamps `xAt`; denormalised copies named
for their source (`doctorName`).

**Rules architecture:** deny-by-default; reads scoped by claim or ownership
path; client writes only where a single document can be fully validated;
everything else server-side. Every rule change ships with an emulator test.

---

## 17. Migration Strategy

All steps are backward-compatible and independently revertible.

| Step | Change | Method | Risk |
|---|---|---|---|
| 1 | SHA fingerprints | Console + re-download JSON | None |
| 2 | Staging/prod projects | `firebase use` + flavors | None — additive |
| 3 | CI/CD | GitHub Actions, gated prod | None |
| 4 | `reference/current` | Trigger builds it; client dual-reads, then switches | Low |
| 5 | `stats/current` | Trigger + one-off backfill; dashboard switches | Low |
| 6 | Custom claims | Trigger sets claims; rules accept **claim OR document** during transition; drop the `get()` once all tokens have refreshed | Medium — needs the dual-accept window |
| 7 | Photos → Storage | Dual-read `photoPath ?? photoBase64`; backfill; drop base64 | Medium |
| 8 | Notifications subcollection | Write to both; migrate; switch reads; delete old | Medium |
| 9 | `nameLower` | Backfill + maintain on write | Low |
| 10 | Rename `abdm_rate_limits` | New collection; old expires by TTL | Low |

**Never migrate two of these at once.** Each has a distinct rollback.

---

## 18. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Fingerprints registered for debug but not Play App Signing | **High** | Auth works in testing, fails in production | Register the Play signing SHA-256 before release |
| App Check enforced too early | Medium | Total lockout, hard to diagnose | Monitoring mode first, one week |
| Custom-claim migration locks out admins | Medium | Admin cannot administer | Dual-accept window; keep a break-glass admin |
| SMS pumping | Medium | Quota exhausted, real users cannot log in | App Check + IN-only + budget alert |
| Read budget exceeded at pilot | Medium | Throttling or unexpected bill | §7.2 optimisations |
| First live deploy fails | **High** | Half a day lost | Expected — ROADMAP §2 lists the likely causes |
| Storage adopted without rules | Low | Medical photo exposure | Rules before bucket, in the same commit |
| Rules/functions deployed out of step | Medium | App broken between deploys | Single coupled CI job |

---

## 19. Implementation Roadmap

**Week 1 — unblock**
SHA fingerprints · Play Integrity · budget alert · SMS region policy · deploy to
dev · end-to-end walk · delete `bootstrapAdmin`

**Week 2 — environments**
Staging + prod projects · Flutter flavors · CI/CD with gated prod · App Check in
monitoring mode

**Weeks 3–4 — cost and correctness**
`reference/current` · `stats/current` · pagination · Analytics funnel · App Check
enforcement · function unit tests

**Weeks 5–6 — pilot readiness**
Photos → Storage (+ rules) · daily backup job · TTL policies · `maxInstances` ·
log-based alerts · on-device push verification

**Post-pilot — scale**
Custom claims · multi-device tokens · notifications subcollection ·
patient-read scoping · `districtId` tenancy

---

## 20. Final Verdict

**Keep this Firebase architecture. Fix its configuration.**

The instinct behind the brief — that something is fundamentally wrong with
authentication — is understandable given the symptom, but the evidence does not
support it. The Phone Auth implementation is textbook-correct. What is missing
is a signing certificate fingerprint in the Firebase project, which takes
fifteen minutes to fix and requires no code changes at all. Rewriting the auth
system would have consumed weeks and left you with the same broken login,
because the defect was never in the code.

That distinction is the most valuable output of this audit.

The genuine architectural gaps are elsewhere and mostly operational: one
Firebase project doing the work of three, no CI/CD for a release whose parts
must ship together, Cloud Storage provisioned and ignored while medical photos
sit inside database documents, and a read-cost profile that will strain the free
tier before user growth does.

None of that requires redesign. It requires the configuration and operational
discipline that separates a working prototype from a system you can put in front
of villagers who are relying on it to see a doctor.

Ratings: **implementation 8/10, configuration 3/10, operational maturity 2/10.**
Fix the second and third. Leave the first alone.
