# Roadmap — from here to villages

> Companion to [TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md).
> This document answers: what stage are we at, what runs in the cloud, what
> should change to make it practical at village scale, and what stands between
> today and a live pilot.

---

## 1. Where the build actually stands

Against the SRS's seven blocks:

| Block | Scope | State |
|---|---|---|
| 1 | Foundation — Firebase, models, router, i18n, rules | ✅ Complete |
| 2 | Auth & doctor registration | ✅ Complete (was broken; registration could not finish) |
| 3 | Admin module | ✅ Functional — missing pagination and the admin-side bulk cancel entry point |
| 4 | Doctor module | ✅ Complete, including Cancel All for Date |
| 5 | Patient module | ✅ Complete, including Health Records |
| 6 | Operator module | ✅ Complete — register, book, assisted list with cancel, availability fallback |
| 7 | Notifications, polish, testing | ✅ Substantially complete — FCM, 24h reminders, Crashlytics, App Check, Remote Config force-update, in-app inbox, unit tests, rules tests. Pagination and an integration test remain |

**Plain statement of status:** every SRS MVP feature now exists, across all
four roles, and the security model is sound and tested. The app is *not* yet
pilot-ready, for one reason above all others —

> **Nothing has been deployed or run against a live Firebase project since the
> write path moved to Cloud Functions.** `bookAppointment` has never executed
> outside the emulator. It compiles, it type-checks, its rules are tested — but
> it has not booked a real appointment.

Everything else on this roadmap is downstream of closing that gap.

---

## 2. The immediate next step

**Deploy to `gram-aarogya-dev` and walk one appointment end to end.** Half a
day, and it will surface things no amount of static checking can.

```bash
# 1. Secrets (one time)
firebase functions:secrets:set AADHAAR_HMAC_SECRET
firebase functions:secrets:set ABDM_CLIENT_SECRET
firebase functions:secrets:set ADMIN_BOOTSTRAP_SECRET

# 2. Coupled deploy — rules deny what the functions perform
firebase deploy --only firestore:rules,firestore:indexes,functions

# 3. Bootstrap the first admin, then delete that function
```

Then, on a real device, in one sitting:

1. Log in by OTP → land on the patient dashboard
2. Complete a patient profile
3. Admin: add a village, add a health centre
4. Register a doctor → approve as admin → confirm the doctor is notified
5. Doctor: set availability at that centre
6. Patient: book → doctor accepts → check the notification and prep note
7. Patient: cancel (>2h out) → confirm the slot is freed and rebookable
8. Try to cancel inside 2 hours → confirm the server refuses
9. Doctor: complete a past appointment with a summary → confirm it appears in
   the patient's Health Records

Expect breakage on the first pass — first deploys always find something.
Likely candidates: missing composite index (Firestore prints the exact index
to create), ABDM sandbox credentials rejecting requests (set
`ABDM_VERIFICATION_REQUIRED=false` to unblock), cold-start latency on the first
booking.

---

## 3. How the cloud side actually works

```
Android app
   │
   ├── reads ──────────► Firestore (asia-south1) ──► offline SQLite cache
   │                     authorised by firestore.rules
   │
   ├── writes ─────────► Cloud Functions (asia-south1, HTTPS callable)
   │                       bookAppointment, cancelAppointment,
   │                       updateAppointmentStatus, cancelDoctorDay,
   │                       submitDoctorRegistration, setDoctorAvailability
   │                          │
   │                          ├─► Firestore (Admin SDK — bypasses rules)
   │                          ├─► notifications/{id}  (localised at write time)
   │                          └─► ABDM gateway (Aadhaar OTP, secrets server-side)
   │
   └── auth ───────────► Firebase Phone Auth (OTP SMS)

Firestore trigger: onDoctorStatusChanged → notification to the doctor
Secrets: Secret Manager (Aadhaar HMAC, ABDM client, bootstrap)
```

**Cost model.** Blaze plan is required (Cloud Functions need it for outbound
calls to ABDM), but usage sits inside the free allowances:

| Service | Free allowance | Expected at ~500 users |
|---|---|---|
| Firestore reads | 50K/day | the number to watch — see §4 |
| Firestore writes | 20K/day | comfortable (~5 writes per appointment lifecycle) |
| Cloud Functions | 2M invocations/month | comfortable (<20K) |
| Phone Auth SMS | 10K/month (India) | comfortable |
| Storage | 5 GB | unused today (photos live in Firestore — see §4.4) |

---

## 4. What should change to make it practical and efficient

Ordered by real impact at village scale. The first item is a cost I introduced
in the last pass and should be paid back before it hurts.

### 4.1 Reference data should be one document, not two collections ⭐

`villagesByIdProvider` and `healthCentersByIdProvider` currently stream **whole
collections** to every user so that names can replace raw ids in the UI. That
was the right call for correctness and the wrong shape for cost.

Offline persistence softens it — listeners resume from cache and fetch only
deltas — but every cold app start still pays for the full collection, on every
screen that resolves a name.

**Fix:** a single `reference/current` document holding all active villages and
health centres, rebuilt by a Firestore trigger whenever an admin edits either
collection. At realistic volumes (tens of villages, ~100 centres) that is well
under Firestore's 1 MB document limit.

*Effect:* ~150 reads per cold start → 1. Also simplifies the providers.

### 4.2 Dashboard counts should be a stats document

The admin dashboard fires six `count()` aggregations on every open. SRS §10.3
already anticipated this: maintain `stats/current` from Firestore triggers and
read one document. *Effect:* 6 reads → 1, and the numbers become live rather
than refresh-on-pull.

### 4.3 Pagination, properly

Every list uses `limit(20)`, which truncates rather than pages — the data is
simply wrong past 20 rows. `startAfterDocument` on the admin lists, appointment
history and patient search. This is correctness as much as efficiency.

### 4.4 Photos to Firebase Storage

Profile photos are base64 strings inside Firestore documents. A 20-row patient
search therefore transfers megabytes — on a 2G connection that is the
difference between usable and not, and it inflates every read of those
documents whether or not the photo is shown. Move to Storage, keep a thumbnail
URL on the document. Needs a migration for existing records.

### 4.5 Push notifications (FCM) — *implemented, needs field testing*

Delivered: permission prompt, token registration and refresh, token cleared on
sign-out (shared phones), tap-to-route, stale-token cleanup server-side, and
an hourly 24-hour reminder job.

Two things still need real-device verification: that pushes actually arrive on
a low-end phone with battery optimisation enabled, and that the notification
channel renders correctly. Neither can be proven from an emulator.

### 4.6 Cheap operational wins

- **TTL policies** on `abdm_rate_limits` and notifications older than 90 days —
  free cleanup, configured in the console.
- **App Check** — without it the Firestore REST endpoint is reachable by anyone
  with the (public) config. Rules still protect the *data*, but App Check is
  what stops someone burning your free tier.
- **Budget alert at ₹100** in Google Cloud Console (SRS §17.2). Do this before
  the pilot, not after.
- **Scheduled backup export** of `appointments`, `patients`, `doctors` to
  Storage (SRS §19.1).

### 4.7 Cold starts

Booking now costs a function invocation, so the first booking in a session may
take 1–2 s. `minInstances: 1` would remove it but costs money and breaks the
₹0 target. Recommendation: accept it, keep the functions small (they are), and
note that the hourly reminder scheduler will incidentally keep containers
warmer once it exists. The UI already shows a loading state.

---

## 5. The path to a village pilot

Technical work is roughly 40% of what remains. The rest is operational, and it
is what actually decides whether the pilot succeeds.

### Phase A — Prove it works (days)

Deploy to dev; walk the end-to-end script in §2; fix what breaks.
**Exit criterion:** one appointment booked, accepted, completed and one
cancelled, on a real device, against real Firebase.

### Phase B — Make it supportable (mostly done)

| Work | Status |
|---|---|
| FCM push | ✅ Implemented — needs on-device verification |
| Crashlytics | ✅ Implemented |
| Remote Config force-update | ✅ Implemented — set `minimum_app_version` before release |
| App Check | ✅ Implemented — register the debug token per test device |
| Reminder scheduler | ✅ Implemented (hourly, 24h horizon) |
| Operator module completion | ✅ Implemented |
| Pagination | ⬜ Outstanding — lists silently wrong past 20 rows |
| Reference-data read cost (§4.1) | ⬜ Outstanding |
| Photos to Storage (§4.4) | ⬜ Outstanding |

### Phase C — Make it releasable (1–2 weeks, overlaps B)

- **Create `gram-aarogya-prod`.** Only `gram-aarogya-dev` exists today
  (`.firebaserc`). SRS §17.1 requires both.
- **Start the ABDM/NHA production application now.** 4–8 weeks, and it is the
  one item on the critical path that effort cannot compress. Until it lands,
  run with `ABDM_VERIFICATION_REQUIRED=false`, which records
  `abdmVerified: false` on the doctor so the approving admin can see the
  credential was never machine-verified.
- **Play Store**: developer account (~₹1,500), listing and screenshots in three
  languages, internal testing track first.
- **Privacy policy and consent.** Non-optional. The system handles Aadhaar
  hashes and clinical data for real villagers under India's DPDPA. Needs a
  named data controller, consent language in Marathi/Hindi, and a stated
  retention position. The SRS defers this to "policy level" — for a live
  deployment that deferral has to end.
- **Device testing** on genuine low-end hardware: Android 8, 2 GB RAM, 2G.

### Phase D — The part that is not code

- **Pick one village.** Not five. One doctor, one operator, one health centre.
- **Verify connectivity at the health centre before anything else.** SRS
  assumption A-7 ("intermittent internet exists in target villages") is the
  single highest-risk unvalidated assumption in the project. Booking requires a
  live network. If the centre has no usable signal, the operator flow — the
  route for villagers without smartphones — does not work at all, and no amount
  of app development fixes it. A signal survey costs one afternoon and could
  change the architecture.
- **Someone sits at the centre for the first week.** Onboarding a low-literacy
  user base is in-person work.
- **Agree the paper fallback** for when the app is unavailable, and the phone
  escalation path.
- **Name the owners**: who holds the admin account, who is on call, who talks
  to the doctor when a booking goes wrong.

### Suggested sequence

```
Now      → Phase A (deploy + end-to-end walk)   ← do this next
+1 week  → Phase B, and start the NHA application the same week
+3 weeks → Phase C, plus the village connectivity survey
+5 weeks → Pilot in one village, one doctor, supported in person
+8 weeks → Review, fix, then consider a second village
```

The NHA application and the connectivity survey should both start in week one
even though they belong to later phases — they are the two items whose lead
time is outside your control.

---

## 6. Keeping this document honest

Update §1 when a block changes state, and
[TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md) §19 when work lands. When a
direction changes, add a short entry under `docs/decisions/`. The value of
these files is entirely in whether they are true.
