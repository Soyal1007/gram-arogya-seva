# Gram Aarogya Seva

Rural healthcare appointment platform for **Unnat Bharat Abhiyan**. An
Android-first Flutter app that lets a villager find out when a verified doctor
will be at their nearest health centre, book a confirmed slot, and be told if
anything changes — on a low-end phone, on a slow network, in Hindi, Marathi or
English.

**Region:** `asia-south1` (Mumbai) · **Backend:** Firebase · **Status:** pre-launch

---

## Contents

- [How the system is put together](#how-the-system-is-put-together)
- [Where authority lives](#where-authority-lives)
- [Repository layout](#repository-layout)
- [Getting set up](#getting-set-up)
- [Running the app](#running-the-app)
- [Testing](#testing)
- [Deployment](#deployment)
- [Documentation map](#documentation-map)

---

## How the system is put together

```
┌──────────────────────────── Flutter (Android) ────────────────────────────┐
│  GoRouter (role guard)  →  Riverpod providers  →  FirestoreService  (reads)│
│                                                 →  FunctionsService (writes)│
└───────────────────────────────────┬───────────────────────────────────────┘
                                    │  Firebase SDK · asia-south1
┌───────────────────────────────────▼───────────────────────────────────────┐
│  Firestore (+ offline cache)   Auth (Phone OTP)                           │
│  Cloud Functions ── booking · cancellation · status · registration        │
│                  └─ ABDM Aadhaar OTP proxy  ──────────────► ABDM gateway   │
└───────────────────────────────────────────────────────────────────────────┘
```

Four roles, each with its own dashboard and flows:

| Role | Does |
|---|---|
| **Admin** | Approves doctors, manages villages and health centres, monitors appointments, assigns roles |
| **Doctor** | Self-registers with ABDM Aadhaar verification, sets per-date availability at a named centre, accepts/rejects/closes appointments |
| **Patient** | Completes a profile, books and cancels appointments, reads visit summaries |
| **Operator** | Registers villagers who have no phone and books on their behalf |

## Where authority lives

This is the single most important thing to understand before changing code.

**Reads and single-document writes** go through `FirestoreService`
(`lib/core/services/firestore_service.dart`) and are authorised by
`firestore.rules`.

**Every mutation whose correctness spans more than one document** goes through
`FunctionsService` (`lib/core/services/functions_service.dart`) to a Cloud
Function, and the security rules deny that write from the client entirely:

| Operation | Function | Why it cannot be a client write |
|---|---|---|
| Book an appointment | `bookAppointment` | Creates the appointment **and** flips exactly one slot, atomically |
| Cancel | `cancelAppointment` | Frees the slot; enforces the ≥2-hour window server-side |
| Accept / reject / complete / no-show | `updateAppointmentStatus` | State machine; rejection frees the slot |
| Cancel a doctor's day | `cancelDoctorDay` | Bulk cancel + free every slot + notify |
| Doctor registration | `submitDoctorRegistration` | Hashes Aadhaar with a **server** secret and assigns the role |
| Resubmit after rejection | `resubmitDoctorRegistration` | `status` is admin-owned in the rules |
| Save availability | `setDoctorAvailability` | Must merge already-booked slots forward |

Two more functions run without a client caller: `onDoctorStatusChanged`
(Firestore trigger — notifies a doctor when an admin approves or rejects them)
and `sendAppointmentReminders` (hourly Cloud Scheduler job, 24-hour horizon,
idempotent via `reminderSent`).

Security rules can validate a document; they cannot express "change these two
documents together or neither". Where an invariant spans documents, the write
belongs on the server. Full reasoning: [TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md) §A17-1.

Two further conventions:

- `cloud_firestore` is imported by exactly two files — `firestore_service.dart`
  and `core/converters/timestamp_converter.dart`. Nothing else touches the SDK.
- Notifications are written **only** by Cloud Functions, so the inbox is a
  record of what the system did rather than of what a client claimed. Each one
  is localised into the recipient's language at write time and pushed via FCM;
  push is best-effort, the Firestore document is authoritative.
- Sign out through `LogoutButton` / `signOutCompletely`, never
  `FirebaseAuth.signOut()` directly — the device's push token has to be cleared
  first or the next user of a shared phone receives the previous user's
  notifications.

## Repository layout

```
lib/
  main.dart, app.dart          Firebase init, offline persistence, i18n, router
  core/
    config/app_constants.dart  Collections, roles, statuses, routes, label keys
    converters/                Firestore Timestamp ↔ DateTime
    errors/app_exception.dart  Typed error taxonomy (each carries an l10n key)
    models/                    Freezed + json_serializable domain models
    providers/                 Auth, connectivity, locale, reference data
    router/app_router.dart     GoRouter with role-based redirects
    services/                  FirestoreService (reads) · FunctionsService (writes)
                               NotificationService (FCM) · UpdateService (force-update)
    theme/                     Colours, typography, ThemeData
    utils/                     Dates and slots, validators, Aadhaar display
  features/
    auth/ doctor_registration/ admin/ doctor/ patient/ operator/ notifications/
  shared/widgets/              LargeButton, RuralCard, StatusBadge, …
functions/src/                 Cloud Functions (TypeScript)
  common.ts                    Shared helpers, params, slot/time maths
  abdm.ts doctors.ts appointments.ts admin.ts notifications.ts reminders.ts
firestore-tests/               Security-rules tests (emulator)
test/unit/                     Dart unit tests
assets/l10n/                   en · mr · hi (kept in exact key parity)
```

## Getting set up

Prerequisites: Flutter 3.41+, Node 24, a JDK (for the Firestore emulator), and
the Firebase CLI.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after model changes
cd functions && npm install && cd ..
cd firestore-tests && npm install && cd ..
```

Generated `*.freezed.dart` / `*.g.dart` files are committed, so a fresh clone
builds without running the generator first.

### Server secrets (one-time, per Firebase project)

```bash
firebase functions:secrets:set AADHAAR_HMAC_SECRET     # Aadhaar HMAC key
firebase functions:secrets:set ABDM_CLIENT_SECRET      # ABDM gateway
firebase functions:secrets:set ADMIN_BOOTSTRAP_SECRET  # first-admin bootstrap
```

Optional parameters (`firebase functions:config` / `.env`):

| Parameter | Default | Purpose |
|---|---|---|
| `ABDM_BASE_URL` | sandbox | Switch to the production gateway without a code change |
| `ABDM_CLIENT_ID` | — | ABDM client id |
| `ABDM_VERIFICATION_REQUIRED` | `true` | Set `false` **only** while awaiting NHA credentials; doctors then register with `abdmVerified: false` so admins can see the credential was never machine-verified |

### First admin

The default role is `patient` and only an admin can change roles, so the first
one is created out of band (SRS §4.3) — either set `users/{uid}.role` in the
Firebase Console, or `POST` to the `bootstrapAdmin` function with the shared
secret. **Delete that function after first use.**

## Running the app

```bash
flutter run                       # debug
flutter build apk --release       # release
```

## Testing

```bash
flutter analyze                   # must be clean
flutter test                      # Dart unit tests
cd functions && npm run lint && npx tsc --noEmit
cd firestore-tests && npm test    # rules tests against the emulator
```

The rules suite is not optional: `firestore.rules` is the system's authority
(DP-4), and a rule that reads correctly can still behave incorrectly. It covers
the SRS §13.5 scenarios plus regression tests for privilege escalation and
cross-tenant reads.

## Deployment

Rules, indexes and functions are a **single coordinated release** — the rules
deny the client writes that the functions perform, so deploying one without the
other breaks the app.

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Then per SRS §17.2: set `minimum_app_version` in Remote Config, configure the
₹100 budget alert, and bootstrap the first admin.

## Documentation map

| Document | What it is | Status |
|---|---|---|
| [GAS_SRS_Final_v3.md](GAS_SRS_Final_v3.md) | Software requirements specification | **Authoritative** |
| [TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md) | Architecture review, defect analysis, roadmap | Current |
| [FIREBASE_AUDIT.md](FIREBASE_AUDIT.md) | Firebase/GCP audit, auth deep dive, target architecture | Current |
| [ROADMAP.md](ROADMAP.md) | Build status and the path to a village pilot | Current |
| [CLAUDE.md](CLAUDE.md) | Working notes — read first when picking the project up | Current |
| [firebase-context.md](firebase-context.md) | Firebase project and schema reference | Current |
| [gram_aarogya_seva_blueprint_v2_1.md](gram_aarogya_seva_blueprint_v2_1.md) | Original v2.0 blueprint | Superseded by the SRS |
| [context_refresh_document.md](context_refresh_document.md) | July 2026 audit snapshot | Superseded by the assessment |

Where documents disagree, the SRS wins; where the SRS and the code disagree,
[TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md) §12 records which is right
and why.
