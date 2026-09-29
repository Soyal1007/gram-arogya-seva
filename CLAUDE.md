# Working notes for Gram Aarogya Seva

Read this first. It is deliberately short — it exists so that a session can
start from decisions rather than from code archaeology. Detail lives in
[TECHNICAL_ASSESSMENT.md](TECHNICAL_ASSESSMENT.md) and [ROADMAP.md](ROADMAP.md).

## What this is

Rural healthcare appointment app (Flutter + Firebase, `asia-south1`) for
Unnat Bharat Abhiyan. Four roles: admin, doctor, patient, operator. Three
languages: en, mr, hi. Target user is on a low-end Android phone, on a slow
network, possibly sharing the device. The end goal is deployment in real
Maharashtra villages, not a demo.

## The one architectural rule

**Reads on the client. Cross-document writes on the server.**

`FirestoreService` owns reads and single-document writes that
`firestore.rules` can fully validate. Everything else goes through
`FunctionsService` → a Cloud Function, and the rules *deny that write from the
client*:

| Operation | Function |
|---|---|
| Book | `bookAppointment` |
| Cancel | `cancelAppointment` |
| Accept / reject / complete / no-show | `updateAppointmentStatus` |
| Cancel a doctor's whole day | `cancelDoctorDay` |
| Doctor registration / resubmission | `submitDoctorRegistration`, `resubmitDoctorRegistration` |
| Save availability | `setDoctorAvailability` |

Rules can validate a document. They cannot express "change these two documents
together or neither". If a change spans documents, it belongs on the server —
adding it to `FirestoreService` will only produce permission errors.

Corollaries:

- `cloud_firestore` is imported by exactly **two** files:
  `core/services/firestore_service.dart` and
  `core/converters/timestamp_converter.dart`. Nothing else.
- `notifications` documents are written **only** by Cloud Functions.
- Never put a secret in the client. The Aadhaar HMAC key is a Cloud Functions
  secret; `--dart-define` values are recoverable from the APK.

## Conventions that bite if you miss them

- **Slot times are 24-hour `HH:mm`.** Display via
  `AppDateUtils.formatSlotForDisplay`. The parser also accepts legacy
  `hh:mm a`. A mismatch here previously disabled cancellation app-wide.
- **All `DateFormat`s are pinned to `en_US`** — they are a storage format, not
  copy. An unpinned formatter binds `Intl.defaultLocale` and breaks in mr/hi.
- **Every user-facing string goes through `tr()`.** `assets/l10n/{en,mr,hi}.json`
  must stay in exact key parity — check before committing.
- **Errors are typed.** Throw/catch `AppException` subclasses; render
  `tr(error.messageKey)`. Never string-match on exception text.
- **Nothing is ever deleted** (DP-5). Status fields only.
- **Availability doc id is `{doctorId}_{YYYY-MM-DD}`.** This is the contention
  point of the whole system; changing its shape is expensive.

## Verify before you claim done

```bash
flutter analyze                            # must be clean
flutter test                               # Dart unit tests
cd functions && npx eslint --ext .ts src && npx tsc --noEmit -p tsconfig.json
cd firestore-tests && npm test             # rules tests (needs JDK + emulator)
```

If those four are green the state is known-good, regardless of what anyone
remembers. If the emulator port is taken, kill stray `java` processes.

## Deployment is coupled

Rules and functions ship **together**. The rules deny what the functions
perform, so deploying one without the other breaks the app.

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## Where change is cheap and where it is expensive

| Cheap | Medium | Expensive |
|---|---|---|
| Business rules inside a function | New collection + screen | Availability document shape |
| Validation, new statuses | New role | Auth model |
| Notification types and copy | New Cloud Function | `{doctorId}_{date}` convention |
| UI copy (l10n) | Index changes | Anything requiring a data migration |

The callable boundary exists precisely so requirements can change without
touching 24 screens. Prefer changing a function over changing the schema.

## Keeping context across sessions

- Decisions go in files, not in chat. `TECHNICAL_ASSESSMENT.md` §19 is the
  running implementation log; `ROADMAP.md` is the plan; `docs/decisions/` holds
  one short entry per direction change.
- The SRS (`GAS_SRS_Final_v3.md`) is authoritative for *requirements*. Where
  the SRS and the code disagree, `TECHNICAL_ASSESSMENT.md` §12 records which is
  right and why. Do not silently "fix" code to match a stale doc.
- Work in vertical slices: one flow end-to-end, verified, docs updated — then
  stop. A half-finished horizontal layer is what makes the next session
  expensive.
