# Gram Aarogya Seva — Technical Assessment & Ownership Plan

> **Author:** Engineering lead (inherited codebase review)
> **Date:** 28 July 2026
> **Baseline commit:** `14223c1` (branch `main`)
> **Sources cross-referenced:** `GAS_SRS_Final_v3.md` (v3.0, authoritative), `gram_aarogya_seva_blueprint_v2_1.md` (v2.0, superseded), `firebase-context.md`, `context_refresh_document.md` (July 2026 audit), and every file under `lib/`, `functions/`, `test/`, `_archived/`.

---

## 1. Project purpose

Gram Aarogya Seva (GAS) is an Android-first Flutter + Firebase application built under **Unnat Bharat Abhiyan** that digitises doctor–patient appointment coordination for rural Maharashtra. Villages are the geographic anchor; health centres belong to villages; verified doctors declare per-date availability at a named centre; villagers (or an operator acting for them) book a specific slot.

It exists to solve a **coordination failure**, not a clinical one: doctors rotate across villages, patients cannot know when or where a doctor will be, and schedules live on paper.

## 2. Product vision

From SRS §2.2 — *any villager can, in under three minutes, know when a verified doctor is available at their nearest health centre, book a confirmed slot, and receive a reminder — even on 2G and shared devices.*

Six non-negotiable design principles govern every decision (SRS §2.3):

| ID | Principle | Practical consequence |
|---|---|---|
| DP-1 | Rural-first UX | ≥56dp targets, ≥18sp body text, icon+text, 3 languages from any screen |
| DP-2 | Offline-tolerant reads | Firestore persistence; all reads work from cache |
| DP-3 | Honest write connectivity | Booking requires network and says so; never fake success |
| DP-4 | Zero-trust security | Every rule enforced at the database, not the UI |
| DP-5 | No record deletion | Status fields only; audit trail preserved |
| DP-6 | Cost discipline | ₹0 recurring at ≤500 users |

### Vision evolution across documents

The docs are internally consistent in *direction* but the older ones are stale in detail. Where they disagree, **SRS v3.0 wins**:

* Blueprint v2.0 → SRS v3.0 added `patientUserId` denormalisation, `cancelled`/`no_show` statuses, `reminderSent`, nullable `patients.mobile`, HMAC-SHA-256 (not plain SHA-256) for Aadhaar, slot-freeing on cancel/reject, ConnectivityGuard, Crashlytics/App Check/Remote Config, and an explicit admin-bootstrap escape from the "only admins can create admins" deadlock.
* Blueprint's appointment read rule used an expensive nested `get()` on `patients`; SRS replaced it with the denormalised `patientUserId`. The deployed rules follow the SRS. ✅
* `context_refresh_document.md` describes a `backend/` Dart Shelf service as live architecture. **It is not** — that code now sits in `_archived/backend/` and nothing calls it. The document is out of date.

## 3. Current development stage

**Late Block 5 / early Block 6** of the SRS's 7-block plan. All four role modules exist end to end at the screen level; the app compiles clean (`flutter analyze`: 0 issues) and 23 unit tests pass. What is missing is not screens — it is **server-side enforcement, notifications, and several MVP flows** (health records, bulk day cancellation, operator availability fallback).

Critically, three flows that the module map claims are complete **cannot succeed against the committed security rules** (§11). The project is closer to "demo-complete, production-incomplete" than the prior audit suggests.

## 4. Major components

| Layer | Location | Responsibility |
|---|---|---|
| App shell | `lib/main.dart`, `lib/app.dart` | Firebase init, offline persistence, EasyLocalization, ProviderScope, `MaterialApp.router` |
| Routing | `lib/core/router/app_router.dart` | 21 routes, role-based `redirect`, refresh driven by auth + user-doc + doctor-doc streams |
| Data access | `lib/core/services/firestore_service.dart` | The only file importing `cloud_firestore` (plus `TimestampConverter`) |
| Domain models | `lib/core/models/*.dart` | 8 Freezed + `json_serializable` models with `TimestampConverter` |
| State | Riverpod providers per feature | `StreamProvider`/`FutureProvider`/`StateNotifier` |
| Design system | `lib/core/theme/*` | "Healing deep green" M3 palette, typography scale, status colours |
| Features | `lib/features/{auth,doctor_registration,admin,doctor,patient,operator}` | 24 screens/notifiers |
| Shared widgets | `lib/shared/widgets/*` | 7 widgets (LargeButton, RuralCard, StatusBadge, …) |
| i18n | `assets/l10n/{en,mr,hi}.json` | 176 keys, **all three files complete and in parity** ✅ |
| Serverless | `functions/src/index.ts` | ABDM OTP request/verify, `bootstrapAdmin` |
| Security | `firestore.rules`, `firestore.indexes.json` | Role-based rules; 8 composite indexes |
| Dead code | `_archived/backend/` | Dart Shelf API — superseded, unreferenced |

## 5. System architecture (as built)

```
Flutter (Android)
  GoRouter (role guard)  →  Riverpod  →  FirestoreService  →┐
  cloud_functions client (ABDM only) ───────────────────────┼→ Firebase asia-south1
                                                             │   Firestore (+offline cache)
                                                             │   Auth (Phone OTP)
                                                             └─→ Cloud Functions → ABDM Sandbox
```

The intended architecture (SRS §6.1) additionally includes FCM, Crashlytics, App Check, Remote Config, and **eight** Cloud Functions. Only three functions exist and none of the four Firebase SDKs above are in `pubspec.yaml`.

**The decisive architectural gap:** every privileged mutation currently executes **on the client**. Booking, cancellation, appointment status transitions, doctor-record creation, role assignment, and Aadhaar hashing all run in the app and are guarded only by rules that (as shown in §11) do not hold. For a healthcare system whose first design principle is zero-trust, this is the defining structural problem, not a detail.

## 6. Strengths

1. **The data model is right.** Denormalising `patientUserId`, `patientName`, `doctorName`, `healthCenterId` onto appointments removes rule-time `get()` calls and extra reads. `{doctorId}_{date}` as the availability doc ID gives O(1) lookup and deterministic transaction locking. These are the decisions that matter at scale and they were made correctly.
2. **Single data-access layer is genuinely respected.** `cloud_firestore` is imported in exactly two files. This is rare discipline and it is what makes the refactor in §17 tractable.
3. **Typed models throughout.** Freezed + `json_serializable` with a centralised `TimestampConverter` that tolerates both `Timestamp` and ISO strings.
4. **i18n is complete and in parity** — 176 keys × 3 languages, zero missing. The infrastructure is done even though many screens bypass it.
5. **Booking is transactional.** Read-verify-write inside `runTransaction` genuinely prevents double-booking (verified by an existing test).
6. **Design system is coherent and rural-appropriate** — 60dp buttons, high-contrast greens, status colour semantics, large type.
7. **Clean build.** Zero analyzer issues, 23 green tests, no TODO-littered code.

## 7. Weaknesses

1. Client-side authority over every privileged write (§5).
2. The `users` update rule is logically inverted, producing both a privilege-escalation hole and two broken flows (§11.1–11.3).
3. Slot time format is inconsistent between writer and parser, which silently disables appointment cancellation (§11.4).
4. Foreign keys are rendered raw to users — `villageId`, `healthCenterId` and sometimes `doctorId` are shown where a human-readable name belongs.
5. `limit(20)` + `orderBy(date desc)` is used as a substitute for real queries; "today's appointments" is computed by client-side filtering of that window and silently loses data.
6. Roughly 90 user-facing strings bypass `tr()` despite complete translation files.
7. No pagination anywhere; `limit()` is a truncation, not a page.
8. Error handling leaks raw exception text (`'[${e.code}] ${e.message}'`, `'Error: $e'`) to users, contradicting SRS §12.1.
9. Photos are stored as base64 inside Firestore documents.
10. No FCM, Crashlytics, App Check, or Remote Config — four SRS-mandated infrastructure pieces.

## 8. Risks

| # | Risk | Severity | Likelihood | Notes |
|---|---|---|---|---|
| R-A | Any authenticated user can promote themself to `admin` | **Critical** | High once the APK is distributed | §11.1 |
| R-B | Any patient can overwrite any doctor's entire availability document | **Critical** | Medium | Rules grant blanket `isPatient()` update |
| R-C | Doctor registration cannot complete | **Critical** | Certain | §11.2 — blocks the whole doctor onboarding funnel |
| R-D | Patients can never cancel | High | Certain | §11.4 — every cancel button is permanently hidden |
| R-E | Aadhaar HMAC secret shipped in the APK | High | Certain | `--dart-define` values are recoverable from the binary |
| R-F | Silent data loss in dashboards past 20 records | Medium | High at scale | §11.6 |
| R-G | Doctor and patient writing availability concurrently loses slots | Medium | Medium | Whole-document `set()` with no transaction |
| R-H | No crash visibility in production | Medium | Certain | Crashlytics commented out in `main.dart` |
| R-I | ABDM sandbox endpoint hardcoded | Medium | Certain at launch | URL is a source constant, not config |

## 9. Technical debt

| Item | Location | Cost of leaving it |
|---|---|---|
| `_archived/backend/` — 1,000+ lines of unreferenced Dart Shelf service | `_archived/` | Reviewer confusion; docs still describe it as live |
| `hs_err_pid7236.log` (81 KB JVM crash dump), `android/hs_err_pid11768.log`, 10 Kotlin error logs, stray `gram_aarogya_seva` file, `build/` — all committed | repo root | Noise in every diff and clone |
| Generated `*.g.dart` / `*.freezed.dart` committed | `lib/core/models/` | Merge conflicts on every model change |
| `README.md` is still the `flutter create` template | root | New engineers get nothing |
| `context_refresh_document.md` describes archived architecture as current | root | Actively misleading |
| Duplicated appointment-card widgets in 5 screens | `lib/features/*` | Blueprint specifies one shared `AppointmentCard` |
| `dynamic` parameter in `_cancelAppointment` | `patient_dashboard_screen.dart:291` | Type safety lost on a critical path |
| Debug `debugPrint` blocks with `===` banners | auth notifier, patient profile | Leaks internals; noise in release logs |

## 10. Missing features (vs SRS §5.1 MVP)

| Feature | SRS ref | Status |
|---|---|---|
| FCM push for all critical events | §5.1 Infrastructure | ❌ Not started |
| Server-side notification creation | §6.2 | ❌ Not started |
| In-app notification inbox | §7.8 | ❌ Model + rules + index exist; no writer, no UI |
| Health Records (visit summaries) | §5.1 Patient | ❌ `VisitSummary` model exists; no doctor entry UI, no patient view |
| Doctor "Cancel All for Date" | §5.1 Doctor/Admin, A-FLOW-03 | ❌ Not started |
| Operator availability fallback | §5.1 Operator, O-FLOW-04 | ❌ Not started |
| Operator cancels own-created appointments | §5.1 Operator | ❌ Rule allows it; no UI |
| Operator patient search by name | O-FLOW-02 | ⚠️ Search exists; no "register new" redirect |
| 24h appointment reminders | §5.1, §6.1 | ❌ Not started |
| Crashlytics / App Check / Remote Config force-update | §5.1 | ❌ Not started |
| Mandatory profile completion gate | §5.1 Patient | ⚠️ Advisory only — dashboard is reachable without a profile |
| Pagination on all list screens | §6.2 | ❌ `limit()` only |
| Prefix search for patients | §5.1 Admin | ✅ Implemented server-side |
| Health-centre name in slot picker | P-FLOW-02 Step 4 | ❌ Shows time only |
| Doctors filtered to patient's village | P-FLOW-02 Step 2 | ❌ Defaults to "All Villages" |

## 11. Bugs and inconsistencies (verified by reading, ordered by severity)

### 11.1 🔴 Privilege escalation: any user can make themself admin
`firestore.rules:37-38`
```javascript
allow update: if (isOwner(userId) && !onlyChanges(['role']))
  || (isAdmin() && onlyChanges(['role']));
```
`onlyChanges(['role'])` is true only when the affected key set is **exactly a subset of** `{role}`. Negating it therefore permits any write whose key set is *not* a subset of `{role}` — which includes `{role, name}`. A user writing `{role: 'admin', name: 'x'}` passes the owner branch. `FirestoreService.createOrUpdateUser` already issues a merge-`set` containing `role`, so the escalation path is reachable with the app's own data layer.

**Correct predicate:** the owner branch must assert `role` is *absent* from the diff, not that the diff is not exactly `role`.

### 11.2 🔴 Doctor registration cannot complete
`doctor_registration_screen.dart:507` calls `updateUserRole(uid, 'doctor')`, which writes exactly `{role: …}`. Owner branch: `!onlyChanges(['role'])` → `!true` → **false**. Admin branch: false. The write is **denied**. The doctor document has already been created at that point, so the user is left with `doctors/{uid}` in `pending_approval` but `users/{uid}.role == 'patient'` — and the router, seeing the doctor-registration intent flag, sends them back to the registration form. The funnel is closed.

### 11.3 🔴 Rejected doctors cannot resubmit
`awaiting_approval_screen.dart:210` calls `updateDoctorStatus(status: 'pending_approval')` as the doctor. The `doctors` update rule grants `status` only to `isAdmin()`. Denied. SRS §D-FLOW-01 step 7 explicitly requires resubmission.

### 11.4 🔴 Patients can never cancel an appointment
`availability_management_screen.dart:34-38` writes slot times as **`"09:00"`** (24-hour). `AppDateUtils._parseAppointmentDateTime` parses them with `DateFormat('hh:mm a')`, which requires an AM/PM marker and throws. `isWithinCancelWindow` catches and returns `true` ("inside the 2-hour window") as its safe default, so `withinWindow` in `patient_dashboard_screen.dart:220` is always `false` and the Cancel button is never rendered. Both the SRS schema and the seeded test data use `"09:00 AM"`, so writer, parser, spec and tests disagree three ways.

Secondary defect in the same helper: the `DateFormat`s are `static final` with no locale, so they bind whatever `Intl.defaultLocale` is set at first use — parsing becomes locale-dependent in a trilingual app.

### 11.5 🟠 Any patient can destroy any doctor's availability
`firestore.rules:77` — `allow update: … || isPatient();` with no constraint on which document or which fields. A patient can mark every slot booked, or empty `slots` entirely, for any doctor on any date. This is unavoidable while the booking transaction runs on the client.

### 11.6 🟠 "Today's queue" silently drops appointments
`doctor_providers.dart:22-27` streams `streamDoctorAppointments(uid)` — `orderBy('date', descending: true).limit(20)` — then filters for today in the widget. Because ordering is *descending*, future-dated appointments occupy the window first; once a doctor has 20 appointments dated after today, today's queue renders empty. The same pattern affects the patient dashboard and admin monitor.

### 11.7 🟠 Aadhaar HMAC secret lives in the client
`crypto_utils.dart:25` reads `String.fromEnvironment('HMAC_SECRET')`. `--dart-define` values are compiled into the binary and trivially extracted, which defeats the entire purpose of HMAC-over-SHA256 (SRS §7.10 says "with **server** secret"). Worse, the default is `''`: in release builds the `assert` is stripped, so a missing define silently produces HMACs keyed with an empty string.

### 11.8 🟠 `createdAt` is destroyed on every write
`FirestoreService.createOrUpdateUser` sets `createdAt: serverTimestamp()` on every merge, so it is really "last login". `updatePatient` is handed `patient.toJson()` whose `createdAt` is `null`, nulling the stored value. `setAvailability` writes a full document with no `createdAt`/`lastUpdatedBy`. DP-5's audit trail is not actually preserved.

### 11.9 🟠 Availability save is a lost-update race
`_saveAvailability` performs an unconditional whole-document `set()` from local state. A booking committed between load and save is overwritten — the slot reverts to unbooked while the appointment still exists.

### 11.10 🟡 Health centre is optional where the SRS makes it mandatory
`availability_management_screen.dart:224` writes `healthCenterId: _selectedHealthCenterId ?? ''`. Every downstream appointment then inherits an empty centre, and the patient never learns where to go — the single most important output of the whole flow.

### 11.11 🟡 Booking omits the patient's village and same-day slots
`book_appointment_screen.dart:176` generates dates from `i + 1` (tomorrow onward), and the village filter defaults to *All Villages* rather than `patient.villageId` (P-FLOW-02 Step 2). `bookingAvailabilityProvider` is a `FutureProvider` that is never invalidated after a booking, so the slot list goes stale.

### 11.12 🟡 Raw identifiers shown to users
`villageId` where a village name belongs (`patient_dashboard_screen.dart:197`, `view_patients_screen.dart:96`), `doctorId` as a fallback for doctor name, and a generic "Health centre" chip that never names the centre (`doctor_appointments_screen.dart:185`).

### 11.13 🟡 Destructive actions without confirmation
Patient cancel (`patient_dashboard_screen.dart:275`) and doctor deactivate/activate (`manage_doctors_screen.dart:69,86`) fire immediately. SRS §13.6 requires a `ConfirmationDialog` on every destructive action.

### 11.14 🟡 `ConfirmationDialog` swallows async failures
`confirmation_dialog.dart:72-75` calls `onConfirm()` without awaiting and pops immediately. Every rejection/approval that fails server-side reports success to the user.

### 11.15 🟡 "Mark complete"/"No-show" available before the appointment
SRS §D-FLOW-03 gates both on the appointment time having passed; `_buildActions` offers them on any accepted appointment.

### 11.16 🟡 Role change to `doctor` creates an unreachable account
Admin role management can set `role: 'doctor'` for a user with no `doctors/{uid}` document. `_roleBasedRoute` then pins them on `/doctor/awaiting` forever, with no registration entry point.

### 11.17 🟡 `bootstrapAdmin` can create an invalid user document
`functions/src/index.ts:170` merge-writes `{role:'admin'}`. If the document does not exist, the result lacks the `name`/`phone` fields `UserModel` requires and `fromJson` throws — the admin can authenticate but the app cannot deserialise them.

### 11.18 🟢 Miscellaneous
* Raw Firebase codes surfaced to users: `auth_notifier.dart:74`, `patient_profile_screen.dart:337`.
* `_slotsInitialized` inverts its own meaning — the "N slots configured" hint renders only *before* the slots load (`availability_management_screen.dart:133`).
* `appLocaleProvider` duplicates `context.locale`; `app.dart` rebuilds the entire tree via a `KeyedSubtree` key built from both.
* `firestore.indexes.json` carries two `createdByOperatorId` indexes (ASC and DESC on `date`) because `streamOperatorAppointments` changes its sort direction between branches.
* Gender is `'Male'|'Female'|'Other'` in code, `'male'|'female'|'other'` in SRS §7.5.
* `patients.createdBy` is written by the operator flow but never by patient self-registration, which leaves the default `'self'` — correct by accident.

## 12. Documentation inconsistencies

| Claim | Reality |
|---|---|
| `context_refresh_document.md` §3.5: Dart Shelf backend at `backend/` | Archived to `_archived/backend/`; nothing calls it |
| Same, §7 item 2: "Hardcoded HMAC secret in `doctor_registration_screen.dart:495`" | Already moved to `--dart-define` — but that is still client-side (§11.7) |
| Same, §7 item 4: "Resend OTP sends empty phone" | Fixed; `phoneNumberProvider` now carries it |
| Same, §7 item 9: "`todayAppointments` always 0" | Fixed in `admin_providers.dart` |
| Same, §1: "Testing ☆☆☆☆☆ — no tests exist" | 4 test files, 23 passing tests |
| Same, §3.2: `timestamp_converter.dart` is in `core/models/` | It is in `core/converters/` |
| SRS §7.6 / §11.2: slot times are `"09:00 AM"` | Code writes `"09:00"` (§11.4) |
| SRS §7.5: `gender` is lowercase | Code uses capitalised values |
| SRS §10.2: `riverpod_generator`, `flutter_svg`, `shimmer`, `phone_form_field`, `uuid`, `shared_preferences` | None are dependencies; the app does not need them |
| SRS §16: `firebase_options.dart` lives in `core/config/` | It is at `lib/` root (FlutterFire default) |
| `firebase-context.md` §3.3: availability slot field `bookedByPatientId` | Code and SRS use `appointmentId` |
| `README.md` | Untouched `flutter create` template |

## 13. Performance

* **Read amplification is the real cost driver.** Every dashboard opens 2–4 `snapshots()` listeners; the admin dashboard additionally issues six aggregation `count()` queries per refresh. At 100 users the SRS already projects 15–25K reads/day against a 50K free-tier ceiling — "moderate headroom" with no margin for the streams added since.
* `_doctorHealthCentersProvider` streams **all** active health centres and filters client-side by the doctor's villages.
* `allVillagesProvider` streams the entire villages collection (no `limit()`), violating SRS §6.2's "all queries use `limit()`".
* Base64 photos inflate every patient/doctor document read by tens of kilobytes; a 20-row patient search can transfer megabytes.
* `app.dart` keys the whole widget tree on the locale, forcing a full rebuild on language change.
* No pagination: `limit(20)` truncates rather than pages, so the cost is bounded but the data is wrong (§11.6).

## 14. Security

| # | Concern | Severity |
|---|---|---|
| S-1 | Self-service privilege escalation to `admin` (§11.1) | **Critical** |
| S-2 | Unrestricted patient writes to any availability document (§11.5) | **Critical** |
| S-3 | `appointments` create is `isPatient() \|\| isOperator()` with **no field validation** — a patient may forge `patientUserId`, `doctorId`, `status: 'accepted'`, or another patient's name | **High** |
| S-4 | Aadhaar HMAC key distributed in the APK (§11.7) | **High** |
| S-5 | `patients` read is granted to **every** doctor and operator, unscoped by village or care relationship — the full clinical corpus is readable by any approved doctor | Medium (accepted by SRS §8, worth revisiting) |
| S-6 | No Firebase App Check — the REST API is reachable from any client with the (public) config | Medium |
| S-7 | ABDM sandbox endpoint hardcoded in source; credentials default to `"SBX_PLACEHOLDER"` | Medium |
| S-8 | `bootstrapAdmin` is an unauthenticated `onRequest` guarded only by a shared secret that defaults to `""` — with an empty default, `req.body.secret !== ""` blocks it, so it fails closed, but it should be deleted after first use | Medium |
| S-9 | No rate limiting on booking; the only rate limit in the system is ABDM's 60s | Low |
| S-10 | `google-services.json` committed (normal for Firebase, but pairs badly with S-6) | Low |

## 15. Scalability

The **data model** scales to the stated horizon; the **query layer** does not.

* `{doctorId}_{date}` availability documents keep slot contention per-doctor-per-day — correct.
* Appointment queries are all single-field-equality + range on `date`, all indexed — correct.
* But no screen paginates, several stream unbounded collections, and dashboard counts are recomputed per open rather than materialised (SRS §10.3 suggests a `stats/{date}` document).
* `searchPatients` prefix search is case- and diacritic-sensitive; "suresh" will not find "Suresh". A normalised `nameLower` field is the standard fix.
* Multi-district expansion (explicitly out of MVP scope) would require an `districtId` on the hot collections; the current model has no tenancy dimension.

## 16. Code quality

**Good:** consistent file/section structure, meaningful SRS cross-references in doc comments, no dead imports, zero analyzer warnings, immutable models, one data-access layer.

**Weak:** widget duplication (five near-identical appointment cards, three `_MiniStat`, three `_FilterChip`), business logic embedded in widget callbacks rather than notifiers, `setState` + Riverpod mixed within single screens, string-matching on exception text (`e.toString().contains('already booked')`) instead of typed errors, and inconsistent localisation discipline.

The codebase reads as if written quickly but by someone who understood the architecture — the bones are good and the flesh is uneven. That is the best possible starting point for a refactor.

## 17. Recommended architectural improvements

### A17-1 — Move every privileged mutation to Cloud Functions ⭐ primary change

**Why.** DP-4 says every rule is enforced at the database. Firestore rules can validate a document, but they cannot express "flip exactly one slot from free to booked, and only if you are the person creating the matching appointment." That invariant spans two documents, so it can only be enforced by code that owns both writes. Every critical defect in §11 (11.1, 11.2, 11.3, 11.5, 11.7 and S-3) is a symptom of asking rules to do a transaction's job.

**Change.** Client callables replace client transactions for: `submitDoctorRegistration`, `bookAppointment`, `cancelAppointment`, `updateAppointmentStatus`, `cancelDoctorDay`. Firestore rules then become **read-scoping plus deny-by-default on writes** for `appointments`, `doctors`, `doctor_availability` (patient path) and `notifications`.

**Impact.** Closes S-1 through S-4. Makes the 2-hour cancellation window server-enforced (SRS §11.3 P-FLOW-03 requires this). Enables server-created notifications (SRS §6.2). Moves the Aadhaar HMAC key to a server secret. Unblocks doctor registration and resubmission.

**Risks.** One extra network hop and a possible cold start (~1–2 s on `asia-south1`) per booking; booking already requires connectivity per DP-3, so no capability is lost. Function bugs become deployment-coupled — mitigated by keeping the functions thin and unit-testable.

**Cost.** ~5 invocations per appointment lifecycle. At 500 users that is <20K/month against a 2M free-tier allowance. DP-6 holds.

**Dependencies.** Blaze plan (already required for ABDM egress); `firebase deploy --only functions,firestore:rules` must be a single coordinated release.

### A17-2 — Make appointment time a first-class `Timestamp`

**Why.** `date: "2026-07-25"` + `timeSlot: "09:00"` is unorderable, unqueryable and unparseable by security rules. It is the root cause of §11.4 and the reason the cancellation window cannot be enforced server-side.

**Change.** Add `slotStartAt: Timestamp` to `appointments`, computed server-side from date + slot in `Asia/Kolkata`. Keep `date`/`timeSlot` for display and for the availability join.

**Impact.** Chronological ordering without composite gymnastics; enables the reminder scheduler (SRS §7.2) and rule-level time assertions; fixes cancellation.

**Risks.** Additive, so existing documents lack it — the client must tolerate null and fall back to string parsing. Handled.

### A17-3 — Canonicalise slot times as 24-hour `HH:mm`

**Why.** Three formats currently coexist. 24-hour is what the writer already produces, sorts lexicographically, and is locale-independent — the SRS's `"09:00 AM"` is a display concern, not a storage concern.

**Change.** Storage is `HH:mm`; a single `AppDateUtils.formatSlotForDisplay` renders `9:00 AM`; the parser accepts both formats so existing documents keep working.

**Impact.** No migration required. Fixes §11.4 permanently.

### A17-4 — Resolve foreign keys through cached lookup providers

**Why.** Villages and health centres are small, slow-changing reference data being rendered as raw IDs (§11.12). Fetching them per row would multiply reads.

**Change.** `villagesByIdProvider` / `healthCentersByIdProvider` expose `Map<String, Model>` from the streams the app already subscribes to; screens look names up in O(1) with no additional reads.

**Impact.** Removes every raw ID from the UI at zero read cost.

### A17-5 — Typed error taxonomy across the service boundary

**Why.** `e.toString().contains('already booked')` is not error handling. SRS §12.1 requires a localised message for every failure mode.

**Change.** `AppException` hierarchy (`SlotAlreadyBookedException`, `CancelWindowClosedException`, `PermissionDeniedException`, `NetworkUnavailableException`, `ServiceUnavailableException`) mapped from `FirebaseFunctionsException` codes, each with an l10n key.

### A17-6 — Repository seam for testability (deferred, documented)

`FirestoreService` is concrete and constructed directly by a provider. Extracting an interface would allow mock-based widget tests. Deferred: `fake_cloud_firestore` already covers the data layer, and an interface adds indirection without a current consumer.

### A17-7 — Repository hygiene

Delete committed build artefacts and JVM crash dumps, gitignore generated Dart, remove `_archived/backend/`, rewrite `README.md`, and mark the stale audit document as superseded.

## 18. Prioritised implementation roadmap

| # | Work | Why now | Depends on |
|---|---|---|---|
| **P0 — Correctness & security (ship before any pilot)** ||||
| 1 | Rewrite `firestore.rules`: fix the `role` predicate, validate `patients`/`doctors` writes, remove blanket patient write on availability, deny client writes to `appointments`/`notifications` | S-1, S-2, S-3 are exploitable with the shipped app | — |
| 2 | Cloud Functions: `submitDoctorRegistration`, `bookAppointment`, `cancelAppointment`, `updateAppointmentStatus`, `cancelDoctorDay` + server-side notification writes | Unblocks §11.2, §11.3; enforces §11.5, S-3, S-4 | 1 (deploy together) |
| 3 | `FunctionsService` + typed exceptions; retarget the client writes | Client must call the new surface | 2 |
| 4 | Fix slot parsing, `slotStartAt`, cancellation window | §11.4 — cancellation is a core MVP flow that cannot run | 2 |
| 5 | Fix `createdAt` clobbering and availability lost-update race | DP-5 audit trail | 2 |
| **P1 — MVP completeness** ||||
| 6 | Village / health-centre / doctor name resolution everywhere | §11.12; P-FLOW-02 requires the centre name at slot selection | 4 |
| 7 | Correct per-date queries for today's queue and upcoming lists | §11.6 silent data loss | — |
| 8 | Mandatory health centre on availability; village-scoped doctor list; same-day booking | §11.10, §11.11 | 6 |
| 9 | Confirmation dialogs on destructive actions; await async confirmations | §11.13, §11.14 | — |
| 10 | Localise the ~90 remaining hardcoded strings | DP-1, launch criterion | — |
| 11 | Notification inbox (writer already delivered by 2) + unread badge | §7.8 model/rules/index exist unused | 2 |
| 12 | Health Records: doctor visit-summary entry + patient view | SRS §5.1 Patient module | 4 |
| 13 | Doctor/admin "Cancel All for Date" UI | A-FLOW-03, R-15 in the SRS risk matrix | 2 |
| 14 | Operator: cancel own bookings, assisted list, availability fallback | SRS §5.1 Operator | 2 |
| **P2 — Production readiness** ||||
| 15 | FCM: token lifecycle, foreground/background handlers, tap routing, function-side sends | SRS §5.1 Infrastructure | 2, 11 |
| 16 | Scheduled `sendAppointmentReminders` (hourly, 24h horizon) | SRS §6.1 | 15, `slotStartAt` |
| 17 | Crashlytics, App Check, Remote Config force-update | SRS §21 checklist | — |
| 18 | Pagination (`startAfterDocument`) on all list screens; `nameLower` for search | §15 | — |
| 19 | Firebase Storage for photos, replacing base64 | §13 | — |
| 20 | Rules unit tests (≥20 scenarios) + booking integration test | SRS §13.5 launch criterion | 1 |
| 21 | Repository hygiene and documentation rewrite | §17 A17-7 | — |

---

## 19. Implementation log — what has been delivered against this plan

Everything in **P0** and most of **P1** is done. Verification at the time of
writing: `flutter analyze` clean, 53 Dart unit tests passing, 59 security-rules
tests passing against the Firestore emulator, `eslint` + `tsc --noEmit` clean
for Cloud Functions.

### Delivered

| Roadmap | Change |
|---|---|
| 1 | `firestore.rules` rewritten. `doesNotChange('role')` replaces the inverted predicate; `users` create is forced to `role: 'patient'`; `patients.userId` is immutable; client writes to `appointments`, `doctor_availability`, `doctors` (create) and `notifications` (create) are denied outright |
| 2 | Cloud Functions restructured into `common / abdm / doctors / appointments / admin / notifications`. New: `bookAppointment`, `cancelAppointment`, `updateAppointmentStatus`, `cancelDoctorDay`, `submitDoctorRegistration`, `resubmitDoctorRegistration`, `setDoctorAvailability`, `onDoctorStatusChanged` |
| 2 | ABDM verification is now **recorded server-side**; `submitDoctorRegistration` requires proof of it rather than trusting a client-supplied `txnId`. `ABDM_VERIFICATION_REQUIRED` allows an auditable pilot bypass while NHA credentials are pending |
| 2 | Aadhaar HMAC moved to a Cloud Functions secret; the client no longer hashes anything (`crypto_utils.dart` is display-only) |
| 2 | `bootstrapAdmin` now writes a complete, deserialisable user document |
| 3 | `FunctionsService` + sealed `AppException` taxonomy; every screen renders `tr(error.messageKey)` and no raw Firebase code reaches the UI |
| 4 | Slot times canonicalised to 24-hour `HH:mm` with a parser that also accepts the legacy `hh:mm a`; `slotStartAt` added to appointments; cancellation window enforced server-side and explained client-side |
| 5 | `createdAt` no longer clobbered on user/patient updates; availability saves merge booked slots forward transactionally |
| 6 | `villagesByIdProvider` / `healthCentersByIdProvider` resolve names in O(1); no raw ids remain in the UI |
| 7 | `streamDoctorAppointmentsForDate` / `…From` replace fetch-then-filter; today's queue can no longer be pushed out by future bookings |
| 8 | Health centre is mandatory on availability; booking defaults to the patient's village and offers same-day slots; the slot picker names the centre |
| 9 | `ConfirmationDialog` returns a result instead of firing an un-awaited callback; confirmations added to doctor approve/reject, appointment accept/reject/complete/no-show, patient and operator cancel, village/centre/doctor deactivate and activate, role change, and day cancellation |
| 10 | ~90 hardcoded strings localised; `assets/l10n/{en,mr,hi}.json` at 265 keys each, in exact parity |
| 11 | Notification inbox, unread badge, and server-side notification writes for every appointment and doctor-status event |
| 12 | Health Records: doctors record a visit summary when completing; patients read it at `/patient/records` |
| 13 | "Cancel All for Date" in the doctor's availability screen |
| 20 | `firestore-tests/` — 59 emulator-backed rules scenarios, including regressions for the escalation and cross-tenant reads |
| 21 | README rewritten; stale audit marked superseded; `firebase-context.md` corrected; crash dumps and Kotlin error logs removed from version control |

### Deliberate scope decisions

- **`doctor` removed from admin role management.** Granting the role alone
  produces an account with no `doctors/{uid}` document, stranding the user on
  the awaiting screen (§11.16). Doctor accounts are created only by
  `submitDoctorRegistration`, which is also what enforces ABDM verification.
- **Generated Dart stays committed.** `.gitignore` claimed to ignore
  `*.freezed.dart` / `*.g.dart` while they were tracked anyway. Rather than
  breaking fresh-clone builds for a team that deploys from laptops, the policy
  now matches the repository and says why.
- **Gender remains capitalised** (`Male`/`Female`/`Other`). SRS §7.5 says
  lowercase; migrating live patient records for a cosmetic difference is not
  worth it, so the schema doc is corrected instead.

### Second pass — Blocks 6 and 7 completed

Blaze plan confirmed available, which unblocked Cloud Scheduler and App Check.

| Roadmap | Change |
|---|---|
| 14 | **Operator module complete.** Assisted-appointments list with cancel (including a "no phone — tell them in person" marker for accounts with `userId: null`), and the availability fallback for doctors who cannot use the app. Dashboard now exposes all four operator flows |
| 15 | **FCM end-to-end.** Permission prompt, token registration and refresh, token cleared on sign-out (shared phones are normal here), tap-to-route, foreground handled by the existing live streams, stale-token cleanup server-side on `unregistered` |
| 16 | **`sendAppointmentReminders`** — hourly Cloud Scheduler job, 24-hour horizon, idempotent via `reminderSent` so a retry cannot double-notify |
| 17 | **Crashlytics** (Flutter + platform error handlers), **App Check** (Play Integrity in release, debug provider in debug), **Remote Config force-update** with a full-screen non-dismissible gate |
| — | `LogoutButton` replaces four duplicated sign-out call sites, so clearing the push token cannot be forgotten |
| — | `main.dart` no longer imports `cloud_firestore`; persistence moved behind `FirestoreService.configureOfflinePersistence()`, restoring the two-file invariant |
| 9 | Confirmations added to doctor activate/deactivate — the one destructive action the first pass missed |

Verified by an actual `flutter build apk --debug`, not just static analysis:
the five new Firebase plugins integrate with the existing Gradle setup.

### Not yet done — the remaining roadmap

| # | Work | Note |
|---|---|---|
| 18 | Pagination (`startAfterDocument`); `nameLower` for case-insensitive search | Every list still truncates at `limit()` — the data is *wrong* past 20 rows, not merely incomplete |
| — | Reference data as a single document (§13, ROADMAP §4.1) | `villagesByIdProvider` / `healthCentersByIdProvider` stream whole collections; the top avoidable read cost |
| — | Dashboard counts as a `stats/current` document | Six `count()` aggregations per admin dashboard open |
| 19 | Firebase Storage for photos instead of base64 | Needs a migration for existing documents |
| — | Integration test for the booking path (SRS §13.4) | Rules and units are covered; the end-to-end path is not |
| — | Admin-side entry point for day cancellation | The function authorises admins; only the doctor's screen exposes it |
| — | `_archived/backend/` removal | Still tracked; superseded by Cloud Functions |

## Assessment summary

The architecture chosen for this project is **sound and does not need replacing** — Firebase is the right call for phone OTP, offline reads and zero ops at village scale, and the Firestore schema was designed by someone who understood the query patterns. The data model, the single-data-access-layer rule, and the design system are all assets worth preserving.

What must change is **where authority lives**. The system was built as a thick client trusted to enforce healthcare invariants, with security rules retrofitted to approximate that trust. Those rules do not hold: one inverted boolean grants self-service admin, and the same expression blocks the doctor-onboarding funnel entirely. Moving the five privileged mutations behind Cloud Functions resolves that class of defect at the root, costs effectively nothing on the free tier, and is the change on which most of the remaining roadmap depends.

Everything else is ordinary finishing work.
