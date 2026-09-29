# Gram Aarogya Seva â€” SRS v3.0 (Part 1 of 4)

**Sections:** 1â€“5 | Problem, Objectives, Stakeholders, Scope, Architecture

---

## 1. Executive Summary

Gram Aarogya Seva is a production-grade rural healthcare appointment platform under Unnat Bharat Abhiyan. It connects villagers across Maharashtra to verified doctors through village health centres via a single Android-first Flutter app.

**Four roles:** Admin, Doctor, Patient, Operator. **Three languages:** Hindi, Marathi, English. **ABDM-integrated** doctor verification. **Zero recurring cost** at expected scale. **Offline-tolerant reads** with honest connectivity requirements for writes.

---

## 2. Problem Statement & Vision

### 2.1 The Problem

Rural healthcare suffers from structural coordination failure. Doctors travel to multiple villages on different days. Patients cannot know when a doctor will be available, which health centre they will visit, or whether a slot exists. Staff manage schedules on paper. Villagers with chronic conditions delay care until emergencies.

### 2.2 The Vision

Any villager can, in under three minutes, know when a verified doctor is available at their nearest health centre, book a confirmed slot, and receive a reminder â€” even on 2G networks and shared devices.

### 2.3 Design Principles

| # | Principle | Specification |
|---|---|---|
| DP-1 | Rural-first UX | Icon+text on every action. Min 56dp tap targets. Min 18sp font. 3 languages from any screen. |
| DP-2 | Offline-tolerant reads | Appointments, schedules, records readable offline via Firestore cache. |
| DP-3 | Honest write connectivity | Transactional writes (booking) require network. Disable booking when offline. Show "No network" banner. |
| DP-4 | Zero-trust security | Every access rule enforced at database level. UI is secondary. |
| DP-5 | No record deletion | All state changes use status fields. Audit trail preserved always. |
| DP-6 | Cost discipline | â‚¹0 recurring at expected scale. Blaze plan needed for Cloud Functions; budget alert at â‚¹100. |

---

## 3. Objectives & Success Criteria

| ID | Objective | Measurable Target |
|---|---|---|
| OBJ-1 | Enable appointment booking for rural villagers | Booking completed in < 3 minutes |
| OBJ-2 | Provide doctors structured schedule visibility | Organised daily appointment list visible |
| OBJ-3 | Support non-smartphone users via operators | Operator registers + books in < 5 minutes |
| OBJ-4 | Verify doctor credentials via government IDs | 100% doctors ABDM Aadhaar OTP verified |
| OBJ-5 | Operate at zero recurring cost | Monthly Firebase bill = â‚¹0 at â‰¤500 users |
| OBJ-6 | Function on low-end devices | Runs on Android 8.0+, 2GB RAM, 2G network |

**Launch Criteria:**
- All 4 roles complete primary use cases end-to-end
- Double-booking prevention verified via concurrent transaction test
- All 3 language files complete (zero missing keys)
- Security rules tested for all scenarios via Rules Simulator
- Crashlytics integrated and reporting

---

## 4. Stakeholders & Actors

### 4.1 In-App Actors

| Role | Who | Responsibility | Device |
|---|---|---|---|
| **Admin** | UBA programme coordinator | System bootstrap, doctor approval, village/centre management, monitoring | Personal/shared Android |
| **Doctor** | Licensed NMR/HPR professional | Availability management, appointment processing | Personal Android |
| **Patient** | Villager in registered village | Booking appointments, accessing records | Low-end Android or shared device |
| **Operator** | ASHA worker / front desk staff | Registering offline patients, booking on behalf, fallback availability | Centre's shared phone/tablet |

### 4.2 Operational Roles (Not In-App)

| Role | Responsibility |
|---|---|
| **System Administrator** | Firebase Console management, Cloud Function deployment, security rule deployment, first admin bootstrap, Git main branch, billing monitoring |
| **Programme Supervisor** | Offline coordination with admin/operators/doctors via WhatsApp/phone |

### 4.3 Admin Bootstrap (Critical â€” System Cannot Start Without This)

Default role is `patient`. Only admins can change roles. First admin must be bootstrapped externally.

**Method A (Simplest):** System Admin opens Firebase Console â†’ Firestore â†’ `users/{uid}` â†’ set `role` to `"admin"`.

**Method B (Cloud Function):**
```typescript
export const bootstrapAdmin = functions.https.onRequest(async (req, res) => {
  if (req.body.secret !== functions.config().admin.bootstrap_secret) {
    res.status(403).send('Forbidden'); return;
  }
  await admin.firestore().doc(`users/${req.body.uid}`).set(
    { role: 'admin' }, { merge: true }
  );
  res.send('Admin created');
});
```

### 4.4 Operator Onboarding

Operators cannot self-promote. After login (defaults to `patient`), Admin uses Role Management to search by phone number and promote to `operator`.

---

## 5. Scope Definition

### 5.1 MVP â€” Must Build Before Launch

**Authentication & Onboarding**
- OTP-based login for all roles (Firebase Phone Auth)
- Doctor self-registration: NMR ID, HPR ID, Aadhaar, village selection
- ABDM Aadhaar OTP verification via Cloud Function (Sandbox for dev)
- Doctor `pending_approval` state â€” invisible to patients until approved
- Patient/Operator registration with OTP only
- **Mandatory patient profile completion before first booking**
- Role-based automatic routing post-auth

**Admin Module**
- Dashboard: live stat cards (pending approvals, pending appointments, active doctors, patients)
- Pending Doctor Approvals: review NMR/HPR, approve/reject with note
- Village Management: add, view, deactivate
- Health Centre Management: add, view, deactivate (linked to villages)
- Manage Doctors: view all, activate/deactivate
- View Patients: read-only, **prefix-based server search** (not client-side filter)
- Monitor Appointments: filterable by all 6 statuses, admin can mark complete
- Role Management: search users by phone, change role with confirmation
- **Doctor Day Cancellation:** bulk-cancel all appointments for a doctor on a date

**Doctor Module**
- Dashboard: pending requests badge
- Appointment Requests: accept (+optional prep note) or reject (+required reason). **Rejection frees the slot.**
- Upcoming Appointments: chronological with patient details + health centre
- Appointment History: completed, rejected, no_show, cancelled
- Set Availability: calendar â†’ date â†’ health centre dropdown (filtered to doctor's villages) â†’ time slots â†’ save. Cannot remove booked slots.
- **Cancel All for Date:** bulk-cancel with FCM to all affected patients
- Profile: view/edit non-credential fields

**Patient Module**
- Home Dashboard: next appointment card, action buttons
- Book Appointment (6-step): reason â†’ doctor â†’ date â†’ slot (with health centre) â†’ intake form â†’ confirm. **Requires network. Disabled when offline.**
- My Appointments: upcoming/history. Cancel â‰¥2 hours before (**enforced server-side via `request.time`**). **Cancellation frees the slot.**
- Health Records: visit summaries from completed appointments
- Profile: personal details, emergency contact, language, medical background

**Operator Module**
- Dashboard: today's assisted bookings count
- Register Patient: name, DOB, gender, village, mobile (**mobile optional** for non-phone patients). **Duplicate detection** by mobile before creating.
- Book for Patient: search â†’ booking flow â†’ flagged as centre-created. Redirect to Register if patient not found.
- Manage Doctor Availability: fallback, **scoped to operator's village health centres**
- Assisted Appointments: view centre-created, **operator can cancel own-created appointments**

**Infrastructure**
- FCM push notifications for all critical events
- Firestore offline persistence (reads; booking disabled offline)
- Three-language UI with runtime switching
- Firestore security rules (authoritative access control)
- Firestore transactions for booking (double-booking prevention)
- Cloud Functions: ABDM proxy, reminders, **server-side notification creation**
- Firebase Crashlytics for crash reporting
- Firebase App Check for APK integrity
- Force-update mechanism via Firebase Remote Config
- **Slot freeing on cancellation and rejection** (transactional)

### 5.2 Phase 2 â€” After MVP Stable

| Feature | Reason Deferred |
|---|---|
| Doctor-patient messaging | Core booking must validate first |
| Prescription upload | Storage UX adds scope; text summary sufficient |
| Follow-up appointment (one-tap) | Scheduling extension |
| Dependent profiles (parentâ†’child) | Operator handles manually |
| Weekly recurring availability | After per-date system proven |
| Audio prompts (Marathi/Hindi) | Accessibility enhancement |
| Admin reports/charts | Stat cards sufficient |
| Hierarchical admin scoping | Single level sufficient for MVP |
| CI/CD pipeline | Manual deployment acceptable at team size |

### 5.3 Out of Scope

Video/teleconsultation, payment module, insurance verification, HMIS export, multi-district management, GDPR deletion UI, analytics charts.

### 5.4 Assumptions

| # | Assumption |
|---|---|
| A-1 | All users have Android device access (personal or shared) |
| A-2 | Firebase Phone Auth OTP delivery works for Indian mobile numbers |
| A-3 | ABDM Sandbox available for dev; production approval 4-8 weeks |
| A-4 | Usage stays within Firestore free tier (â‰¤500 users, â‰¤50K reads/day) |
| A-5 | UBA provides at least one coordinator as Admin |
| A-6 | All doctors have NMR/HPR IDs and Aadhaar with linked mobile |
| A-7 | Intermittent internet exists in target villages |

---

*Continued in Part 2: System Architecture, Data Model, Security Rules*
# Gram Aarogya Seva â€” SRS v3.0 (Part 2 of 4)

**Sections:** 6â€“9 | Architecture, Data Model, Security, ABDM Integration

---

## 6. System Architecture

### 6.1 Architecture Overview

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                   FLUTTER APPLICATION                         â”‚
â”‚                 (Single Codebase â€” Android First)              â”‚
â”‚                                                                â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”            â”‚
â”‚  â”‚ Admin  â”‚  â”‚ Doctor â”‚  â”‚Patient â”‚  â”‚ Operator â”‚            â”‚
â”‚  â”‚Dashboardâ”‚  â”‚Dashboardâ”‚  â”‚Dashboardâ”‚  â”‚Dashboard â”‚            â”‚
â”‚  â””â”€â”€â”€â”¬â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”¬â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”¬â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜            â”‚
â”‚      â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                  â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”     â”‚
â”‚  â”‚     GoRouter + RoleGuard + AuthGuard + ConnGuard     â”‚     â”‚
â”‚  â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤     â”‚
â”‚  â”‚     Riverpod 2.x State Layer (Providers, Notifiers)  â”‚     â”‚
â”‚  â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤     â”‚
â”‚  â”‚     FirestoreService â€” Single Data Access Layer       â”‚     â”‚
â”‚  â”‚     (ONLY file that imports cloud_firestore)          â”‚     â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜     â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                           â”‚ Firebase SDK (asia-south1)
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                   FIREBASE BACKEND                             â”‚
â”‚              Region: asia-south1 (Mumbai)                      â”‚
â”‚                                                                â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚ Firestore â”‚ â”‚ Firebase â”‚ â”‚ FCM  â”‚ â”‚Storage â”‚ â”‚Remote   â”‚ â”‚
â”‚  â”‚ +Offline  â”‚ â”‚  Auth    â”‚ â”‚ Push â”‚ â”‚(Ph.2)  â”‚ â”‚Config   â”‚ â”‚
â”‚  â”‚ Cache     â”‚ â”‚ (OTP)    â”‚ â”‚      â”‚ â”‚        â”‚ â”‚(ForceUp)â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚ Cloud Functions                                          â”‚ â”‚
â”‚  â”‚ - abdmRequestAadhaarOtp() + rate limiting                â”‚ â”‚
â”‚  â”‚ - abdmVerifyAadhaarOtp()                                 â”‚ â”‚
â”‚  â”‚ - sendAppointmentReminders() (scheduled hourly)          â”‚ â”‚
â”‚  â”‚ - cancelDoctorDay() (bulk cancel + FCM)                  â”‚ â”‚
â”‚  â”‚ - onAppointmentCreated() â†’ FCM to doctor                 â”‚ â”‚
â”‚  â”‚ - onAppointmentStatusChanged() â†’ FCM to patient          â”‚ â”‚
â”‚  â”‚ - onDoctorRegistered() â†’ FCM to admin                    â”‚ â”‚
â”‚  â”‚ - bootstrapAdmin() (one-time setup)                      â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                          â”‚
â”‚  â”‚ Crashlytics  â”‚  â”‚  App Check   â”‚                          â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                          â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                           â”‚ HTTPS (Cloud Functions only)
                â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                â”‚  ABDM Sandbox API   â”‚
                â”‚  (Aadhaar OTP)      â”‚
                â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 6.2 Key Architectural Rules

| Rule | Enforcement |
|---|---|
| `FirestoreService` is the **only** file importing `cloud_firestore` | Convention + lint rule |
| All notifications created by Cloud Functions, not client | Security rules block unscoped client creates |
| Booking requires network connectivity | `ConnectivityGuard` disables booking button offline |
| All Firestore queries use `limit()` | Never unbounded collection fetches |
| All list screens use pagination | `startAfterDocument` pattern |

---

## 7. Canonical Data Model (Firestore Schema)

This is the single authoritative schema. All modules use these exact collection and field names.

### 7.1 villages/{villageId}

| Field | Type | Notes |
|---|---|---|
| villageId | String | Auto-generated doc ID |
| name | String | "Karanja" |
| taluka | String | |
| district | String | |
| state | String | "Maharashtra" |
| isActive | Boolean | false = deactivated (never deleted) |
| createdAt | Timestamp | |
| createdBy | String | Admin UID |
| updatedAt | Timestamp | Set on every write |
| updatedBy | String | UID of last modifier |

### 7.2 health_centers/{centerId}

| Field | Type | Notes |
|---|---|---|
| centerId | String | Auto-generated doc ID |
| name | String | "Karanja Primary Health Centre" |
| villageId | String | â†’ villages/{villageId} |
| address | String | |
| phone | String | |
| isActive | Boolean | |
| createdAt | Timestamp | |
| createdBy | String | Admin UID |
| updatedAt | Timestamp | |
| updatedBy | String | |

### 7.3 users/{uid}

| Field | Type | Notes |
|---|---|---|
| uid | String | Firebase Auth UID (doc ID) |
| name | String | |
| phone | String | 10-digit, no country code |
| role | String | "admin" \| "doctor" \| "patient" \| "operator" |
| villageId | String | For patient and operator |
| language | String | "en" \| "mr" \| "hi" |
| fcmToken | String | Refreshed on every login |
| createdAt | Timestamp | |
| updatedAt | Timestamp | |

### 7.4 doctors/{doctorId}

| Field | Type | Notes |
|---|---|---|
| doctorId | String | Same as users/{uid} |
| name | String | |
| specialization | String | |
| mobile | String | |
| nmrId | String | National Medical Register ID |
| hprId | String | Health Professional Registry ID |
| aadhaarHash | String | **HMAC-SHA-256** (with server secret), NEVER plaintext |
| aadhaarLastFour | String | "XXXX XXXX 1234" for display |
| abdmTxnId | String | From successful OTP verification |
| villages | String[] | Village IDs doctor serves |
| status | String | "pending_approval" \| "active" \| "inactive" \| "rejected" |
| rejectionNote | String? | If rejected |
| approvedBy | String? | Admin UID |
| approvedAt | Timestamp? | |
| createdAt | Timestamp | |
| updatedAt | Timestamp | |
| updatedBy | String | |

### 7.5 patients/{patientId}

| Field | Type | Notes |
|---|---|---|
| patientId | String | Firestore auto-ID (NOT Auth UID) |
| userId | String? | Auth UID. **null** if registered by operator for non-phone patient |
| name | String | |
| dob | String | "YYYY-MM-DD" |
| gender | String | "male" \| "female" \| "other" |
| villageId | String | â†’ villages/{villageId} |
| mobile | **String?** | **Nullable** for operator-registered patients without phones |
| emergencyContact | Map | {name: String, phone: String} |
| medicalBackground | Map | {conditions: String[], medications: String[], allergies: String[]} |
| createdBy | String | "self" \| "health_center" |
| createdByOperatorId | String? | Operator UID if centre-created |
| createdAt | Timestamp | |
| updatedAt | Timestamp | |

### 7.6 doctor_availability/{doctorId}_{YYYY-MM-DD}

| Field | Type | Notes |
|---|---|---|
| doctorId | String | â†’ doctors/{doctorId} |
| healthCenterId | String | â†’ health_centers/{centerId} |
| date | String | "YYYY-MM-DD" |
| slots | Array | [{time: "09:00 AM", isBooked: Boolean, appointmentId: String?}] |
| createdAt | Timestamp | |
| lastUpdatedBy | String | Doctor or operator UID |
| updatedAt | Timestamp | |

**Doc ID convention:** `{doctorId}_{YYYY-MM-DD}` enables O(1) lookup.

### 7.7 appointments/{appointmentId}

| Field | Type | Notes |
|---|---|---|
| appointmentId | String | |
| patientId | String | â†’ patients/{patientId} |
| **patientUserId** | **String?** | **Firebase Auth UID of patient** (denormalized for security rules) |
| patientName | String | Denormalized for doctor display |
| doctorId | String | â†’ doctors/{doctorId} |
| healthCenterId | String | â†’ health_centers/{centerId} |
| villageId | String | Denormalized for admin queries |
| date | String | "YYYY-MM-DD" |
| timeSlot | String | "09:00 AM" |
| reason | String | "Fever" \| "Checkup" \| "Follow-up" \| "Other" |
| status | String | **"pending" \| "accepted" \| "rejected" \| "completed" \| "cancelled" \| "no_show"** |
| createdBy | String | "self" \| "health_center" |
| createdByOperatorId | String? | |
| prepInstructions | String? | Set by doctor on accept |
| rejectionReason | String? | Set by doctor on reject |
| cancelledAt | Timestamp? | When cancelled |
| cancelledBy | String? | UID of who cancelled |
| intakeForm | Map | {symptoms: String, duration: String, severity: "mild"\|"moderate"\|"severe"} |
| visitSummary | Map? | {notes, prescription, nextSteps, followUpDate} â€” Phase 2 |
| **reminderSent** | **Boolean** | Default false. Set true by reminder Cloud Function. |
| createdAt | Timestamp | |
| updatedAt | Timestamp | |

### 7.8 notifications/{notificationId}

| Field | Type | Notes |
|---|---|---|
| userId | String | Recipient Auth UID |
| type | String | See notification types below |
| title | String | Localised at creation time |
| message | String | |
| relatedId | String | appointmentId or doctorId |
| isRead | Boolean | |
| createdAt | Timestamp | |

**Notification types:** `doctor_registration_pending`, `doctor_approved`, `doctor_rejected`, `appointment_booked`, `appointment_accepted`, `appointment_rejected`, `appointment_cancelled`, `appointment_reminder_24h`, `appointment_completed`, `appointment_no_show`

### 7.9 abdm_rate_limits/{uid}

| Field | Type | Notes |
|---|---|---|
| lastRequestTime | Timestamp | For rate limiting ABDM OTP requests (60s cooldown) |

### 7.10 Schema Design Decisions

- **`patients` separate from `users`:** Operators create patient records for villagers without phone accounts (`userId = null`). Clinical data security scoped independently.
- **`{doctorId}_{date}` as availability doc ID:** O(1) lookup, deterministic transaction locking.
- **`healthCenterId` on both availability and appointment:** Denormalization avoids extra reads. Patient always knows where to go.
- **`patientUserId` on appointment:** Simplifies security rules. Eliminates expensive `get()` call in rule evaluation.
- **`patientName` on appointment:** Doctors see patient name without reading patients collection.
- **Aadhaar as HMAC-SHA-256:** Plain SHA-256 is vulnerable to rainbow tables over 12-digit space. HMAC with server secret makes this infeasible.
- **`mobile` nullable on patients:** Operator-registered patients may not have a phone number.
- **`updatedAt` on all mutable collections:** Required for debugging stale data and audit trails.

---

## 8. Firestore Security Rules (Corrected)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuth() { return request.auth != null; }
    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    function isAdmin() { return isAuth() && userDoc().role == 'admin'; }
    function isDoctor() { return isAuth() && userDoc().role == 'doctor'; }
    function isPatient() { return isAuth() && userDoc().role == 'patient'; }
    function isOperator() { return isAuth() && userDoc().role == 'operator'; }
    function isOwner(uid) { return isAuth() && request.auth.uid == uid; }
    function onlyChanges(keys) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(keys);
    }

    // VILLAGES
    match /villages/{villageId} {
      allow read: if isAuth();
      allow create, update: if isAdmin();
      allow delete: if false;
    }

    // HEALTH CENTRES
    match /health_centers/{centerId} {
      allow read: if isAuth();
      allow create, update: if isAdmin();
      allow delete: if false;
    }

    // USERS
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId);
      allow update: if (isOwner(userId) && !onlyChanges(['role']))
        || (isAdmin() && onlyChanges(['role']));
      allow delete: if false;
    }

    // DOCTORS â€” added doctor read access for patients needing to see active doctors
    match /doctors/{doctorId} {
      allow read: if isAuth()
        && (isAdmin() || isOperator()
            || resource.data.status == 'active'
            || isOwner(doctorId));
      allow create: if isOwner(doctorId);
      allow update: if
        (isOwner(doctorId)
          && onlyChanges(['name','specialization','mobile','villages','updatedAt','updatedBy']))
        || (isAdmin()
          && onlyChanges(['status','approvedBy','approvedAt','rejectionNote','updatedAt','updatedBy']));
      allow delete: if false;
    }

    // PATIENTS â€” ADDED: isDoctor() for appointment patient lookup
    match /patients/{patientId} {
      allow read: if isAdmin() || isOperator() || isDoctor()
        || (isPatient() && resource.data.userId == request.auth.uid);
      allow create: if isPatient() || isOperator();
      allow update: if isAdmin() || isOperator()
        || (isPatient() && resource.data.userId == request.auth.uid);
      allow delete: if false;
    }

    // DOCTOR AVAILABILITY
    match /doctor_availability/{availabilityId} {
      allow read: if isAuth();
      allow create: if isAdmin()
        || (isDoctor() && request.resource.data.doctorId == request.auth.uid)
        || isOperator();
      allow update: if isAdmin()
        || (isDoctor() && resource.data.doctorId == request.auth.uid)
        || isOperator()
        || isPatient(); // Patients update isBooked via transaction
      allow delete: if false;
    }

    // APPOINTMENTS â€” FIXED: uses patientUserId, added cancelled/no_show
    match /appointments/{appointmentId} {
      allow read: if isAdmin() || isOperator()
        || (isDoctor() && resource.data.doctorId == request.auth.uid)
        || (isPatient() && resource.data.patientUserId == request.auth.uid);
      allow create: if isPatient() || isOperator();
      allow update: if
        (isDoctor() && resource.data.doctorId == request.auth.uid
          && onlyChanges(['status','prepInstructions','rejectionReason',
                          'visitSummary','updatedAt']))
        || (isPatient()
          && onlyChanges(['status','updatedAt','cancelledAt','cancelledBy'])
          && request.resource.data.status == 'cancelled')
        || (isOperator()
          && resource.data.createdByOperatorId == request.auth.uid
          && onlyChanges(['status','updatedAt','cancelledAt','cancelledBy'])
          && request.resource.data.status == 'cancelled')
        || (isAdmin() && onlyChanges(['status','updatedAt']));
      allow delete: if false;
    }

    // NOTIFICATIONS â€” RESTRICTED: server-side creation preferred
    match /notifications/{notificationId} {
      allow read: if isAuth() && resource.data.userId == request.auth.uid;
      allow create: if isAdmin(); // Most creates via Cloud Functions (admin SDK bypasses rules)
      allow update: if isAuth() && resource.data.userId == request.auth.uid
        && onlyChanges(['isRead']);
      allow delete: if false;
    }

    // ABDM RATE LIMITS
    match /abdm_rate_limits/{uid} {
      allow read, write: if false; // Cloud Functions only (admin SDK)
    }
  }
}
```

---

## 9. ABDM Integration

### 9.1 Scope

ABDM used **only** for doctor Aadhaar OTP verification during registration. Not used for patients. Sandbox for dev; production requires NHA app registration (4-8 weeks).

### 9.2 Cloud Functions with Rate Limiting

```typescript
// abdmRequestAadhaarOtp â€” with 60-second rate limit
export const abdmRequestAadhaarOtp = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
  const { aadhaarNumber } = data;
  if (!/^\d{12}$/.test(aadhaarNumber))
    throw new functions.https.HttpsError('invalid-argument', 'Invalid Aadhaar');

  // Rate limit: 60 seconds between requests
  const db = admin.firestore();
  const rateDoc = await db.doc(`abdm_rate_limits/${context.auth.uid}`).get();
  if (rateDoc.exists) {
    const last = rateDoc.data()!.lastRequestTime.toDate();
    if (Date.now() - last.getTime() < 60000)
      throw new functions.https.HttpsError('resource-exhausted', 'Wait 60 seconds');
  }
  await db.doc(`abdm_rate_limits/${context.auth.uid}`).set({ lastRequestTime: admin.firestore.FieldValue.serverTimestamp() });

  const tokenRes = await axios.post(`${ABDM_BASE}/v0.5/sessions`, {
    clientId: functions.config().abdm.client_id,
    clientSecret: functions.config().abdm.client_secret,
  });
  const otpRes = await axios.post(
    `${ABDM_BASE}/v0.5/registration/aadhaar/generateOtp`,
    { aadhaar: aadhaarNumber },
    { headers: { Authorization: `Bearer ${tokenRes.data.accessToken}`, 'X-CM-ID': 'sbx' } }
  );
  return { txnId: otpRes.data.txnId };
});
```

### 9.3 Production Path

1. Register app with NHA at abdm.gov.in
2. Submit app details, privacy policy, security assessment
3. NHA reviews â†’ issues production clientId/clientSecret
4. Update Cloud Function endpoint to `live.abdm.gov.in`
5. Update firebase functions config with production credentials

Timeline: 4â€“8 weeks. Start early.

---

*Continued in Part 3: Tech Stack, User Flows, Error Handling, Testing*
# Gram Aarogya Seva â€” SRS v3.0 (Part 3 of 4)

**Sections:** 10â€“14 | Tech Stack, User Flows, Error Handling, Testing Strategy

---

## 10. Complete Tech Stack

### 10.1 Core Framework & Backend

| Technology | Purpose | Cost |
|---|---|---|
| Flutter 3.22+ / Dart 3.x | Cross-platform UI (Android first) | Free |
| Firebase Firestore (asia-south1) | Primary database + offline persistence | Free (Spark thresholds) |
| Firebase Auth (Phone OTP) | Authentication | Free (10K SMS/month India) |
| Firebase Cloud Messaging | Push notifications | Free |
| Firebase Cloud Functions | ABDM proxy, reminders, notification triggers | Free (2M invocations/month) |
| Firebase Crashlytics | Crash reporting | Free |
| Firebase App Check | APK integrity verification | Free |
| Firebase Remote Config | Force-update mechanism | Free |
| Firebase Storage | Document storage (Phase 2) | Free (5GB) |

### 10.2 Flutter Packages

**State Management & Navigation**

| Package | Purpose | Version |
|---|---|---|
| `flutter_riverpod` | State management | ^2.5.x |
| `riverpod_annotation` | @riverpod code generation | ^2.3.x |
| `riverpod_generator` | Build runner target | ^2.4.x |
| `go_router` | Declarative routing + redirect guards | ^13.x |

**Data Layer**

| Package | Purpose |
|---|---|
| `freezed` + `freezed_annotation` | Immutable data models |
| `json_serializable` | fromJson/toJson generation |
| `cloud_firestore` | Firestore SDK |
| `firebase_auth` | Auth SDK |
| `firebase_messaging` | FCM SDK |
| `cloud_functions` | Cloud Functions client SDK |
| `firebase_crashlytics` | **NEW** â€” Crash reporting SDK |
| `firebase_app_check` | **NEW** â€” APK integrity SDK |
| `firebase_remote_config` | **NEW** â€” Force-update config SDK |

**UI & UX**

| Package | Purpose |
|---|---|
| `easy_localization` | Three-language runtime switching |
| `table_calendar` | Date picker for availability + booking |
| `flutter_svg` | SVG icons |
| `shimmer` | Loading skeleton states |
| `flutter_local_notifications` | Local notification display |
| `connectivity_plus` | **NEW** â€” Network state detection for ConnectivityGuard |

**Utilities**

| Package | Purpose |
|---|---|
| `intl` | Date/number formatting |
| `shared_preferences` | Language and session preferences |
| `uuid` | Unique ID generation |
| `crypto` | HMAC-SHA-256 Aadhaar hashing |
| `phone_form_field` | Indian phone number input |

**Development & Testing**

| Package | Purpose |
|---|---|
| `build_runner` | Code generation (Riverpod + Freezed) |
| `flutter_lints` | Lint rules |
| `fake_cloud_firestore` | **NEW** â€” Mock Firestore for unit tests |
| `mocktail` | **NEW** â€” Mocking framework for tests |
| Firebase CLI | Deploy rules and Cloud Functions |
| FlutterFire CLI | Generate firebase_options.dart |

### 10.3 Infrastructure Cost (Honest Assessment)

| Service | Free Tier Limit | Expected Usage (100 users) | Status |
|---|---|---|---|
| Firestore reads | 50K/day | ~15Kâ€“25K (streams multiply reads) | âš ï¸ Moderate headroom |
| Firestore writes | 20K/day | ~2Kâ€“5K | âœ… Comfortable |
| Firestore storage | 1 GB | ~50 MB | âœ… Comfortable |
| Cloud Functions | 2M/month | ~10K/month | âœ… Comfortable |
| Firebase Auth | 10K SMS/month | ~500/month | âœ… Comfortable |

**Blaze plan is required** for Cloud Functions and outbound network calls (ABDM). Usage stays within free tier thresholds. Set budget alert at â‚¹100 in Google Cloud Console.

**Mitigation for read limits:**
- All queries use `limit()` (never unbounded)
- Paginate patient/appointment lists (20 per page)
- Consider `stats/{date}` doc updated by Cloud Function for dashboard counts

---

## 11. Complete User Flows

### 11.1 Admin Flows

**A-FLOW-01: System Bootstrap**
```
1. System Admin deploys Cloud Functions + security rules
2. First user logs in via OTP â†’ users/{uid} created with role: "patient"
3. System Admin sets role to "admin" via Firebase Console or bootstrapAdmin function
4. Admin logs in â†’ GoRouter redirects to /admin/dashboard
5. Admin adds villages (name, taluka, district, state)
6. Admin adds health centres linked to villages
7. System is now ready for doctor registrations
```

**A-FLOW-02: Doctor Approval**
```
1. Admin receives FCM: "New doctor pending approval"
2. Opens Pending Approvals screen
3. Reviews: name, specialisation, NMR ID, HPR ID, aadhaarLastFour, villages
4a. Approve â†’ ConfirmationDialog â†’ doctor.status = "active" â†’ FCM to doctor
4b. Reject + note â†’ ConfirmationDialog â†’ doctor.status = "rejected" â†’ FCM with note
Edge case: If status already changed (another admin), show "Already processed"
```

**A-FLOW-03: Doctor Day Cancellation (Emergency)**
```
1. Admin opens Monitor Appointments
2. Selects "Cancel Doctor Day" action
3. Selects doctor â†’ selects date â†’ sees count of affected appointments
4. ConfirmationDialog: "This will cancel X appointments. All patients will be notified."
5. Calls cancelDoctorDay Cloud Function:
   - Batch updates appointments to status: "cancelled"
   - Frees all slots (isBooked = false)
   - FCM to all affected patients
```

### 11.2 Doctor Flows

**D-FLOW-01: Registration & Approval**
```
1. Doctor downloads app â†’ Splash â†’ Phone number â†’ OTP â†’ verified
2. users/{uid} created with role: "patient"
3. Taps "Register as Doctor"
4. Multi-step form:
   Step 1: Name, Specialisation (dropdown), Mobile (pre-filled)
   Step 2: NMR ID, HPR ID, Aadhaar (12 digits, masked input)
   Step 3: Village selection (multi-select from active villages, â‰¥1 required)
   Step 4: "Verify with Aadhaar OTP" â†’ Cloud Function â†’ OTP to Aadhaar-linked mobile
           Doctor enters OTP â†’ verify via Cloud Function
           NOTE ON SCREEN: "OTP sent to mobile linked to your Aadhaar, which may differ from this phone"
5. On success:
   - Aadhaar hashed (HMAC-SHA-256 with server secret via Cloud Function)
   - doctors/{uid} created with status: "pending_approval"
   - users/{uid}.role = "doctor"
   - Cloud Function sends FCM to admin
   - Redirect to Awaiting Approval screen (listens to doctor doc stream)
6. On approval: auto-navigates to Doctor Dashboard
7. On rejection: shows rejection note + "Resubmit" button (updates doc back to pending_approval)
```

**D-FLOW-02: Set Availability**
```
1. Doctor opens Set Availability
2. TableCalendar â†’ selects date
3. If availability doc exists for this date, loads it. Shows booked slots as locked.
4. Health Centre dropdown: filtered to centres in doctor's registered villages
5. Time slot builder: enters times (e.g., "09:00 AM"), displayed as chips. Cannot remove booked slots.
6. Save â†’ writes doctor_availability/{doctorId}_{date}
7. Slots immediately visible to patients
```

**D-FLOW-03: Process Appointments**
```
Accept:
1. Open Appointment Requests (pending status)
2. Review: patient name, reason, intake form, date, time, health centre
3. ConfirmationDialog + optional prep instructions text field
4. updateAppointmentStatus("accepted") â†’ FCM to patient

Reject:
1. ConfirmationDialog + required reason text field
2. updateAppointmentStatus("rejected")
3. **TRANSACTION: frees slot** (isBooked = false, appointmentId = null on availability doc)
4. FCM to patient with reason

Mark Complete:
1. After appointment time passed, "Mark Complete" appears on accepted appointments
2. updateAppointmentStatus("completed") â†’ FCM to patient

Mark No-Show:
1. After appointment time passed, "No Show" appears on accepted appointments
2. updateAppointmentStatus("no_show")
```

### 11.3 Patient Flows

**P-FLOW-01: First Login & Profile**
```
1. Install app â†’ Language selection (En/Mr/Hi)
2. Phone number â†’ OTP â†’ verified
3. users/{uid} created with role: "patient"
4. **Mandatory** profile completion (blocks dashboard access):
   - Name (required), DOB (date picker), Gender (radio buttons)
   - Village (VillagePicker searchable dropdown)
   - Mobile (pre-filled), Emergency contact (name + phone)
5. Creates patients/{newId} with userId = auth.uid
6. Dashboard accessible
```

**P-FLOW-02: Book Appointment (6-Step, Requires Network)**
```
Pre-check: If offline â†’ show "No network" banner, booking button disabled.
Pre-check: If no patient profile â†’ redirect to profile completion.

Step 1 â€” Reason: Icon grid (ðŸ¤’ Fever | ðŸ” Checkup | ðŸ” Follow-up | â“ Other)
Step 2 â€” Doctor: List filtered by patient.villageId. If empty: "No doctors in your village."
Step 3 â€” Date: TableCalendar. Green dots on dates with unbooked slots. Max 30 days ahead.
Step 4 â€” Slot: SlotPickerWidget. Shows "09:00 AM â€” Karanja PHC". If all booked: "Try another date."
Step 5 â€” Intake: Symptoms (text, optional), Duration (text, optional), Severity (mild/moderate/severe, required)
Step 6 â€” Confirm: Summary card. "Confirm Booking" button.
         â†’ Firestore TRANSACTION:
            1. Read availability doc
            2. Verify slot.isBooked == false (else throw "Slot just got booked")
            3. Write appointments/{newId} with patientUserId + patientName
            4. Update slot.isBooked = true, slot.appointmentId = newId
         â†’ Cloud Function triggers FCM to doctor
         â†’ Success screen

Back navigation: preserves form state through all steps.
```

**P-FLOW-03: Cancel Appointment**
```
1. My Appointments â†’ tap appointment â†’ Cancel button
2. If appointment < 2 hours away: button disabled, tooltip "Cannot cancel within 2 hours"
3. ConfirmationDialog: "Cancel appointment with Dr. X on [date] at [time]?"
4. TRANSACTION:
   - Update appointment status = "cancelled", cancelledAt, cancelledBy
   - Free slot: availability doc â†’ slot.isBooked = false, slot.appointmentId = null
5. FCM to doctor (via Cloud Function)
```

### 11.4 Operator Flows

**O-FLOW-01: Register Offline Patient**
```
1. Villager arrives without smartphone
2. Operator â†’ Register Patient
3. Pre-check: search by mobile (if provided) for duplicate detection
   If match found: "Patient already exists â€” [Name]" with option to use existing record
4. Form: Name, DOB, Gender, Village, Mobile (optional)
5. Save â†’ patients/{newId} with createdBy: "health_center", userId: null
```

**O-FLOW-02: Book on Behalf**
```
1. Operator â†’ Book for Patient
2. Search existing patients by name or mobile (prefix-based)
3. If not found: "Register New Patient" button â†’ redirects to O-FLOW-01 â†’ returns
4. Select patient â†’ same 6-step booking flow
5. appointment.createdBy = "health_center", createdByOperatorId = operator.uid
6. "Via Health Centre" badge on all cards system-wide
7. If patient has no phone (userId: null): no FCM possible.
   System marks appointment with "No phone notification" indicator.
   Operator verbally informs patient.
```

---

## 12. Error Handling Strategy

### 12.1 Principles

- Every error shows a user-friendly, **localised** SnackBar (never raw Firebase codes)
- All errors logged to Crashlytics with context
- Form data preserved in Riverpod state across errors (user never re-enters data)
- Connectivity state drives UI (booking disabled offline, "No network" banner)

### 12.2 Scenario Matrix

| Scenario | User Experience | Technical Handling |
|---|---|---|
| OTP send fails | "Unable to send OTP. Check network and try again." + retry button | Catch `FirebaseAuthException`, log to Crashlytics |
| OTP rate limited | "Too many attempts. Wait X minutes." | Firebase Auth returns rate limit error; show countdown |
| ABDM API timeout | "Verification service temporarily unavailable. Try in a few minutes." | 30s timeout, 2 retries with exponential backoff in Cloud Function |
| ABDM API down | Same as above | Cloud Function returns graceful error, not 500 |
| Booking transaction fails (slot taken) | "This slot was just booked. Pick another." + auto-refresh slot list | Transaction throws â†’ catch â†’ refresh â†’ show message |
| Network drops during form | Form preserved in memory. "No network" banner. Submit queues when possible. | Riverpod state holds form. `connectivity_plus` listener toggles banner. |
| Network drops during booking | "Booking requires internet. Please try when connected." | Transaction fails immediately offline. Booking button pre-disabled. |
| FCM delivery fails | No user impact â€” status visible via Firestore stream | Log silently. FCM is best-effort. |
| FCM token stale | No impact | Refresh token on every login. Handle delivery failures silently. |
| Doctor doc not found during role guard | Redirect to registration flow | Null check in role guard, fallback route |
| Patient profile missing during booking | Redirect to profile creation | Pre-check in booking flow entry point |
| Firestore security rule denies write | "You don't have permission to do this." | Catch `FirebaseException` code `permission-denied` |
| App version outdated | Force-update dialog with Play Store link, cannot dismiss | Remote Config check on app launch |

---

## 13. Testing Strategy

### 13.1 Approach (Realistic for Beginner Team)

Don't aim for 100% coverage. Test what kills you: booking integrity, security rules, data validators, and the critical user path.

### 13.2 Unit Tests (Mandatory)

**Target:** `FirestoreService` methods, all validators, crypto utils

```dart
// Example: test double-booking prevention
test('createAppointment rejects already-booked slot', () async {
  final fakeFirestore = FakeFirebaseFirestore();
  final service = FirestoreService(fakeFirestore);

  // Pre-populate availability with booked slot
  await fakeFirestore.doc('doctor_availability/doc1_2026-05-01').set({
    'slots': [{'time': '09:00 AM', 'isBooked': true, 'appointmentId': 'existing'}]
  });

  expect(
    () => service.createAppointment(/* slot: 09:00 AM */),
    throwsA(isA<SlotAlreadyBookedException>()),
  );
});
```

**Files to test:**
- `validators.dart` â€” NMR format, HPR format, Aadhaar 12-digit, phone 10-digit
- `crypto_utils.dart` â€” HMAC-SHA-256 output format
- `date_utils.dart` â€” Slot time parsing, 2-hour cancellation window calculation
- `firestore_service.dart` â€” All CRUD methods with `fake_cloud_firestore`

### 13.3 Widget Tests (Recommended)

- Booking flow multi-step wizard: test forward/backward navigation, state preservation
- Role guard: test routing for all roles + doctor pending_approval state
- SlotPickerWidget: test booked slot filtering
- LanguageSwitcher: test locale change

### 13.4 Integration Test (One Critical Path)

End-to-end booking flow on a real device/emulator:
```
Login â†’ Profile â†’ Book Appointment (all 6 steps) â†’ Verify appointment in Firestore
```

### 13.5 Security Rules Tests

Use `@firebase/rules-unit-testing` npm package:

```typescript
// test: patient cannot read another patient's data
it('denies patient reading other patient doc', async () => {
  const db = testEnv.authenticatedContext('patient1', { role: 'patient' }).firestore();
  const doc = db.doc('patients/other-patient-id');
  await assertFails(doc.get());
});
```

**Minimum 20 scenarios to test:**
- Unauthenticated read â†’ DENY (all collections)
- Patient reads own user doc â†’ ALLOW
- Patient reads other user doc â†’ DENY
- Patient reads active doctor â†’ ALLOW
- Patient reads pending doctor â†’ DENY
- Doctor reads own patient's data â†’ ALLOW
- Admin changes role â†’ ALLOW
- Patient changes own role â†’ DENY
- Patient creates appointment â†’ ALLOW
- Patient cancels own appointment â†’ ALLOW
- Patient cancels other's appointment â†’ DENY
- Doctor rejects own appointment â†’ ALLOW
- Doctor rejects other doctor's appointment â†’ DENY
- Operator creates patient â†’ ALLOW
- Notification: user reads own â†’ ALLOW
- Notification: user reads other's â†’ DENY
- Delete on any collection â†’ DENY

### 13.6 Manual Testing Checklist

Before release, walk every screen against:
- [ ] Every button: LargeButton with icon+text, â‰¥56dp, full width
- [ ] Every font: â‰¥18sp body, â‰¥22sp heading
- [ ] Every string: `tr()` â€” zero hardcoded strings
- [ ] Every async call: loading indicator
- [ ] Every error: user-friendly localised SnackBar
- [ ] Every destructive action: ConfirmationDialog
- [ ] Every screen: Logout visible in AppBar
- [ ] Language switcher accessible from every screen
- [ ] All three language files: zero missing keys
- [ ] High-contrast colours (test in sunlight)

---

*Continued in Part 4: Implementation Plan, Deployment, Risks, Maintenance*
# Gram Aarogya Seva â€” SRS v3.0 (Part 4 of 4)

**Sections:** 15â€“21 | Implementation, Project Structure, Deployment, Risks, Maintenance, Checklist

---

## 15. Implementation Plan (Block-Based)

Blocks are sequential â€” do not begin Block N+1 until Block N is complete and tested.

### Block 1 â€” Foundation (Week 1â€“2)

| Step | Task | Output |
|---|---|---|
| 1.1 | Create **two** Firebase projects: `gram-aarogya-dev` + `gram-aarogya-prod`. Region: asia-south1. Enable Firestore, Auth (Phone), FCM, Cloud Functions (Blaze), Crashlytics, App Check, Remote Config. | Two configured Firebase projects |
| 1.2 | Flutter project creation: `flutter create gram_aarogya_seva --org com.uba --platforms android`. Run `flutterfire configure` for dev project. | Flutter project with Firebase connected |
| 1.3 | Install all packages from Section 10 in `pubspec.yaml`. Run `flutter pub get` + `build_runner build`. | Zero build errors |
| 1.4 | Deploy security rules from Section 8 to dev project. Test 20+ scenarios in Rules Simulator. | Rules deployed and verified |
| 1.5 | Set up easy_localization: `en.json`, `mr.json`, `hi.json` with initial key set. Configure `main.dart` with EasyLocalization + ProviderScope + Firebase init + Firestore offline persistence + Crashlytics. | Localisation working |
| 1.6 | GoRouter + Role Guard skeleton. Handle: not authenticated, no user doc, doctor pending_approval, all 4 role routes. Add ConnectivityGuard (disables booking offline). | Routing for all states |
| 1.7 | All 8+ Freezed data models from Section 7 schema. Run build_runner. | Models compiled |
| 1.8 | FirestoreService skeleton with all method signatures (throw UnimplementedError). Single data access layer. | Data layer contract defined |
| 1.9 | Bootstrap first admin via Firebase Console or bootstrapAdmin Cloud Function. | Working admin account |

**Block 1 Deliverable:** App connects to Firebase, routes by role, models compile, rules deployed, localisation works, admin exists.

### Block 2 â€” Authentication & Doctor Registration (Week 3)

| Step | Task |
|---|---|
| 2.1 | Phone OTP flow: phone_input_screen + otp_verification_screen. Post-OTP: check/create users/{uid}. |
| 2.2 | Doctor registration form (4-step): basic info â†’ government IDs â†’ village selection â†’ ABDM OTP. |
| 2.3 | ABDM Cloud Functions: abdmRequestAadhaarOtp (with rate limiting) + abdmVerifyAadhaarOtp. Deploy to dev. |
| 2.4 | On verification: hash Aadhaar (HMAC-SHA-256), create doctors/{uid}, update user role, FCM to admin. |
| 2.5 | Awaiting Approval screen: shows details, streams doctor doc, auto-navigates on approval. |
| 2.6 | Rejection handling: show note + "Resubmit" button to update doc back to pending_approval. |

### Block 3 â€” Admin Module (Week 4â€“5)

| Step | Task |
|---|---|
| 3.1 | Admin Dashboard: live stat cards via streams (with `limit()` on queries). |
| 3.2 | Pending Approvals: review + approve/reject with note. Status check before update (prevent double-processing). |
| 3.3 | Village Management: add, view, deactivate. ConfirmationDialog with active appointment count. |
| 3.4 | Health Centre Management: add, view, deactivate (linked to villages). |
| 3.5 | Manage Doctors: all approved doctors, activate/deactivate. |
| 3.6 | View Patients: prefix-based search (server-side, not client filter). Paginated. |
| 3.7 | Monitor Appointments: filter by all 6 statuses. Admin mark complete. Doctor Day Cancellation. |
| 3.8 | Role Management: search user by phone, change role with ConfirmationDialog. |

### Block 4 â€” Doctor Module (Week 5â€“6)

| Step | Task |
|---|---|
| 4.1 | Doctor Dashboard: 4 nav buttons with live badge counts. |
| 4.2 | Set Availability: TableCalendar + HealthCentrePicker + slot builder. Protect booked slots. |
| 4.3 | Appointment Requests: accept (prep note) / reject (reason + **free slot**). |
| 4.4 | Upcoming Appointments: filtered to accepted, sorted. Mark Complete / Mark No-Show. |
| 4.5 | Appointment History: completed + rejected + no_show + cancelled. |
| 4.6 | Cancel All for Date: bulk cancel with FCM via Cloud Function. |

### Block 5 â€” Patient Module (Week 6â€“7)

| Step | Task |
|---|---|
| 5.1 | Patient profile completion (mandatory before dashboard). Create patients/{newId}. |
| 5.2 | Patient Dashboard: next appointment card, action buttons. |
| 5.3 | Book Appointment (6-step): full flow with ConnectivityGuard. Firestore transaction. |
| 5.4 | My Appointments: upcoming/history. Cancel with slot freeing transaction. 2-hour enforcement. |
| 5.5 | Health Records: visit summaries from completed appointments. |

### Block 6 â€” Operator Module (Week 7â€“8)

| Step | Task |
|---|---|
| 6.1 | Operator Dashboard: today's assisted count. |
| 6.2 | Register Patient: with duplicate detection + optional mobile. |
| 6.3 | Book on Behalf: patient search â†’ booking flow. Redirect to register if not found. |
| 6.4 | Manage Availability: fallback for doctors. Scoped to operator's village centres. |
| 6.5 | Assisted Appointments: view + cancel own-created. |

### Block 7 â€” Notifications, Polish & Testing (Week 8â€“9)

| Step | Task |
|---|---|
| 7.1 | FCM integration: token refresh, foreground/background handling, navigation on tap. |
| 7.2 | Cloud Functions: sendAppointmentReminders (hourly scheduler), onAppointmentCreated, onAppointmentStatusChanged. |
| 7.3 | Force-update check via Remote Config on app launch. |
| 7.4 | Firestore composite indexes deployment. |
| 7.5 | Rural UX audit (all screens against checklist). |
| 7.6 | Unit tests: FirestoreService, validators, crypto utils. |
| 7.7 | Security rules tests: 20+ scenarios via @firebase/rules-unit-testing. |
| 7.8 | Integration test: end-to-end booking flow. |
| 7.9 | Three-language completion audit: verify zero missing keys. |

---

## 16. Flutter Project Structure

```
gram_aarogya_seva/
â”œâ”€â”€ android/
â”œâ”€â”€ functions/                         â† Cloud Functions (TypeScript)
â”‚   â”œâ”€â”€ src/
â”‚   â”‚   â”œâ”€â”€ abdm.ts                    â† ABDM proxy + rate limiting
â”‚   â”‚   â”œâ”€â”€ notifications.ts           â† Reminder scheduler + FCM triggers
â”‚   â”‚   â”œâ”€â”€ admin.ts                   â† bootstrapAdmin, cancelDoctorDay
â”‚   â”‚   â””â”€â”€ index.ts                   â† Exports
â”‚   â”œâ”€â”€ test/                          â† Security rules tests
â”‚   â”œâ”€â”€ package.json
â”‚   â””â”€â”€ tsconfig.json
â”œâ”€â”€ firestore.rules
â”œâ”€â”€ firestore.indexes.json
â”œâ”€â”€ firebase.json
â”œâ”€â”€ test/                              â† Flutter unit + widget tests
â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â””â”€â”€ firestore_service_test.dart
â”‚   â”œâ”€â”€ utils/
â”‚   â”‚   â”œâ”€â”€ validators_test.dart
â”‚   â”‚   â””â”€â”€ crypto_utils_test.dart
â”‚   â””â”€â”€ widgets/
â”‚       â””â”€â”€ slot_picker_test.dart
â”œâ”€â”€ integration_test/                  â† Flutter integration tests
â”‚   â””â”€â”€ booking_flow_test.dart
â””â”€â”€ lib/
    â”œâ”€â”€ main.dart
    â”œâ”€â”€ app.dart
    â”œâ”€â”€ core/
    â”‚   â”œâ”€â”€ config/
    â”‚   â”‚   â”œâ”€â”€ app_constants.dart      â† Roles, statuses, collections, routes
    â”‚   â”‚   â””â”€â”€ firebase_options.dart   â† Generated (DO NOT EDIT)
    â”‚   â”œâ”€â”€ router/
    â”‚   â”‚   â”œâ”€â”€ app_router.dart
    â”‚   â”‚   â”œâ”€â”€ role_guard.dart
    â”‚   â”‚   â””â”€â”€ connectivity_guard.dart â† NEW: network-aware booking
    â”‚   â”œâ”€â”€ providers/
    â”‚   â”‚   â”œâ”€â”€ auth_providers.dart
    â”‚   â”‚   â”œâ”€â”€ service_providers.dart
    â”‚   â”‚   â””â”€â”€ connectivity_provider.dart â† NEW
    â”‚   â”œâ”€â”€ services/
    â”‚   â”‚   â”œâ”€â”€ firestore_service.dart  â† ONLY file importing cloud_firestore
    â”‚   â”‚   â”œâ”€â”€ notification_service.dart
    â”‚   â”‚   â”œâ”€â”€ abdm_service.dart
    â”‚   â”‚   â””â”€â”€ update_service.dart     â† NEW: force-update check
    â”‚   â”œâ”€â”€ models/                     â† Freezed models
    â”‚   â”œâ”€â”€ theme/
    â”‚   â””â”€â”€ utils/
    â”‚       â”œâ”€â”€ date_utils.dart
    â”‚       â”œâ”€â”€ validators.dart
    â”‚       â””â”€â”€ crypto_utils.dart
    â”œâ”€â”€ features/
    â”‚   â”œâ”€â”€ auth/
    â”‚   â”œâ”€â”€ doctor_registration/
    â”‚   â”œâ”€â”€ admin/
    â”‚   â”œâ”€â”€ doctor/
    â”‚   â”œâ”€â”€ patient/
    â”‚   â””â”€â”€ health_center/
    â””â”€â”€ shared/
        â”œâ”€â”€ widgets/
        â”‚   â”œâ”€â”€ large_button.dart
        â”‚   â”œâ”€â”€ rural_card.dart
        â”‚   â”œâ”€â”€ slot_picker_widget.dart
        â”‚   â”œâ”€â”€ appointment_card.dart
        â”‚   â”œâ”€â”€ status_badge.dart
        â”‚   â”œâ”€â”€ village_picker.dart
        â”‚   â”œâ”€â”€ health_center_picker.dart
        â”‚   â”œâ”€â”€ language_switcher.dart
        â”‚   â”œâ”€â”€ confirmation_dialog.dart
        â”‚   â”œâ”€â”€ nmr_hpr_info_card.dart
        â”‚   â”œâ”€â”€ no_network_banner.dart  â† NEW
        â”‚   â””â”€â”€ force_update_dialog.dart â† NEW
        â””â”€â”€ l10n/
            â”œâ”€â”€ en.json
            â”œâ”€â”€ mr.json
            â””â”€â”€ hi.json
```

---

## 17. Deployment Plan

### 17.1 Environment Strategy

| Environment | Firebase Project | Purpose |
|---|---|---|
| Development | `gram-aarogya-dev` | Development, testing, ABDM Sandbox |
| Production | `gram-aarogya-prod` | Live deployment, ABDM Production (after NHA approval) |

Switch via `flutterfire configure --project=<project-id>` and Flutter build flavors.

### 17.2 Pre-Launch Deployment Steps

1. **Security rules:** `firebase deploy --only firestore:rules` (to prod project)
2. **Composite indexes:** `firebase deploy --only firestore:indexes`
3. **Cloud Functions:** `firebase deploy --only functions`
4. **ABDM credentials:** `firebase functions:config:set abdm.client_id="..." abdm.client_secret="..."`
5. **Admin bootstrap:** Set first admin role in prod Firestore
6. **Remote Config:** Set `minimum_app_version` to `1.0.0`
7. **Budget alert:** Google Cloud Console â†’ Budgets â†’ â‚¹100 alert

### 17.3 Play Store Release

1. Generate signed APK: `flutter build apk --release`
2. Create Google Play Developer account (~â‚¹1,500 one-time)
3. Create app listing: title, description (3 languages), screenshots, privacy policy
4. Upload APK â†’ Internal testing track first
5. Test on 3+ devices (low-end, mid-range, different Android versions)
6. Promote to Production track with staged rollout (25% â†’ 50% â†’ 100%)

### 17.4 Versioning

- Semantic versioning: `1.0.0`, `1.1.0`, `1.2.0`
- `pubspec.yaml` version field: `version: 1.0.0+1` (version+buildNumber)
- Maintain `CHANGELOG.md` with every release
- Git tags for releases: `v1.0.0`

---

## 18. Risk Matrix

| # | Risk | Severity | Probability | Mitigation |
|---|---|---|---|---|
| R-1 | Double-booking race condition | Critical | Low (after transaction) | Firestore transaction. Verified with concurrent test. |
| R-2 | Security rules too permissive | Critical | Medium | Deploy before code. Test 20+ scenarios. Review on every change. |
| R-3 | Cancelled slots permanently lost | Critical | High (if unfixed) | **FIXED:** Slot freeing transaction on cancel/reject. |
| R-4 | Admin bootstrap deadlock | Critical | Certain (if unfixed) | **FIXED:** Manual Console set or bootstrapAdmin Cloud Function. |
| R-5 | ABDM Sandbox OTP not delivered | High | Low | Sandbox provides test Aadhaar numbers. Handle errors gracefully. |
| R-6 | NHA production approval delayed | Medium | Medium | Start application early. Sandbox fully functional for testing. |
| R-7 | FCM tokens stale | Medium | Medium | Refresh on every login. Handle failures silently (stream is backup). |
| R-8 | GoRouter redirect loop | High | Medium | Explicit handling for every state including missing Firestore doc. |
| R-9 | build_runner failures | High (for beginners) | High | Run after every model/provider change. Never run app with errors. |
| R-10 | Firestore read limit exceeded | Medium | Medium | Use `limit()`, pagination, stats doc for dashboard counts. |
| R-11 | Offline booking appears successful | High | Medium | **FIXED:** Booking disabled offline. ConnectivityGuard. |
| R-12 | Aadhaar hash reversed (rainbow table) | High | Low | **FIXED:** HMAC-SHA-256 with server secret instead of plain SHA-256. |
| R-13 | Patient data leaked via doctor access | Medium | Low | **FIXED:** Doctor read access properly scoped. patientUserId denormalized. |
| R-14 | Notification spam by malicious user | Medium | Low | **FIXED:** Client-side creates restricted. Cloud Functions create notifications. |
| R-15 | Doctor no-show | High | High | **FIXED:** Cancel All for Date flow. no_show appointment status. |
| R-16 | App crash in production, no visibility | High | Medium | **FIXED:** Crashlytics integration. |
| R-17 | Users stuck on old app version | Medium | High | **FIXED:** Force-update via Remote Config. |

---

## 19. Maintenance & Operations

### 19.1 Data Backup

**Method (Blaze plan required, which is already active):**
- Cloud Function runs daily via Cloud Scheduler
- Exports critical collections (appointments, patients, doctors) to JSON in Firebase Storage
- Retains last 30 days of backups
- Cost: negligible at this data volume

### 19.2 Monitoring

| What | Tool | Frequency |
|---|---|---|
| App crashes | Firebase Crashlytics | Real-time alerts |
| Cloud Function errors | Google Cloud Logging | Check weekly |
| Firestore usage | Firebase Console â†’ Usage | Check weekly |
| Billing | Google Cloud Budgets | Alert at â‚¹100 |
| Security rules | Manual review | On every change |

### 19.3 Operational Runbook

| Event | Procedure |
|---|---|
| New admin needed | Existing admin â†’ Role Management â†’ search by phone â†’ change to admin |
| New operator needed | Admin â†’ Role Management â†’ search by phone â†’ change to operator |
| Doctor falls sick | Admin or Doctor â†’ Cancel All for Date â†’ all patients notified via FCM |
| Admin phone lost | System Admin revokes tokens via Firebase Auth Console. Creates new admin. |
| Operator device stolen | Admin deactivates operator account. System Admin revokes auth tokens. |
| ABDM down during registration | Doctor shown "Try again later" message. Form data preserved in state. |
| Firestore usage spike | Check query patterns. Add limits/pagination. Consider stats doc for dashboard. |
| Critical bug found | Deploy hotfix to Cloud Functions immediately. Push app update. Set force-update version. |
| ABDM production migration | Update Cloud Function endpoint + credentials. Test with production Aadhaar. |

---

## 20. Firestore Composite Indexes

```json
{
  "indexes": [
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "doctorId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "patientUserId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "createdBy", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "doctors",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "villages", "arrayConfig": "CONTAINS" }
      ]
    }
  ]
}
```

---

## 21. Production Readiness Checklist

### Infrastructure
- [ ] Two Firebase projects created (dev + prod), region asia-south1
- [ ] Security rules deployed and tested (20+ scenarios)
- [ ] Composite indexes deployed
- [ ] Cloud Functions deployed (ABDM + reminders + notifications + admin)
- [ ] ABDM Sandbox credentials in Firebase config
- [ ] Crashlytics enabled and reporting
- [ ] App Check enabled
- [ ] Remote Config: minimum_app_version set
- [ ] Budget alert set at â‚¹100
- [ ] First admin bootstrapped

### Auth & Routing
- [ ] OTP login works for all 4 roles end-to-end
- [ ] Doctor registration with ABDM OTP completes
- [ ] Pending doctor sees awaiting screen, not dashboard
- [ ] Approved doctor auto-redirects without re-login
- [ ] Rejected doctor sees note + resubmit option
- [ ] Role guard handles all states without redirect loops
- [ ] Logout clears session and redirects

### Admin Module
- [ ] Add/deactivate villages and health centres
- [ ] Approve/reject doctors with note + FCM
- [ ] Activate/deactivate approved doctors
- [ ] View patients (prefix search, paginated)
- [ ] Filter appointments by all 6 statuses
- [ ] Mark appointment complete (edge case)
- [ ] Doctor Day Cancellation with FCM to patients
- [ ] Role management (search by phone, change with confirmation)
- [ ] Stat cards are live (stream-based)

### Doctor Module
- [ ] Set availability with health centre selection
- [ ] Accept appointment with prep note + FCM to patient
- [ ] Reject appointment with reason + **slot freed** + FCM to patient
- [ ] Mark complete + FCM
- [ ] Mark no-show
- [ ] Cancel All for Date with FCM
- [ ] Cannot modify other doctor's data

### Patient Module
- [ ] Mandatory profile before booking
- [ ] 6-step booking completes end-to-end
- [ ] Slot picker shows health centre name
- [ ] Booked slots hidden correctly
- [ ] Booking transaction prevents double-booking
- [ ] Cancel â‰¥2 hours: works, **frees slot**
- [ ] Cancel <2 hours: blocked (client + server)
- [ ] Booking disabled when offline
- [ ] FCM for acceptance, rejection, cancellation, 24h reminder
- [ ] Health records from completed appointments

### Operator Module
- [ ] Register patient with duplicate detection
- [ ] Register patient with optional mobile
- [ ] Book on behalf (redirects to register if not found)
- [ ] "Via Health Centre" badge on all views
- [ ] Cancel own-created appointments
- [ ] Manage availability scoped to operator's village
- [ ] View today's assisted bookings

### Cross-Cutting
- [ ] All 3 languages switch at runtime from any screen
- [ ] Zero hardcoded strings (all use `tr()`)
- [ ] All 3 language files complete
- [ ] Offline reads work (cached data readable)
- [ ] All buttons: LargeButton (â‰¥56dp, full width, icon+text)
- [ ] All body text: â‰¥18sp
- [ ] All async operations: loading indicator
- [ ] All errors: localised SnackBar (no Firebase codes)
- [ ] All destructive actions: ConfirmationDialog
- [ ] Logout visible on every screen
- [ ] No Firestore import outside FirestoreService
- [ ] Runs on Android 8.0+ (API 26+), 2GB RAM
- [ ] Force-update dialog works when version outdated
- [ ] Crashlytics reports crashes correctly

---

**End of SRS v3.0**

*Document Version: 3.0 | Gram Aarogya Seva | Flutter + Firebase (asia-south1)*
*Integrates all corrections from Senior Architect Review*
*Total scope: 4 parts, 21 sections, implementation-ready*
