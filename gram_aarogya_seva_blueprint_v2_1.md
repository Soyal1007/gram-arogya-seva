# Gram Aarogya Seva — Production Blueprint v2.0
### Rural Healthcare Appointment System | Unnat Bharat Abhiyan
**Architecture Version:** 2.0 — Full Revision  
**Stack:** Flutter + Firebase | **Target:** Production-grade deployment  
**Region:** asia-south1 (Mumbai) — data locality for India

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement & Product Vision](#2-problem-statement--product-vision)
3. [Tech Stack Decision & Justification](#3-tech-stack-decision--justification)
4. [What Changed from v1.0 and Why](#4-what-changed-from-v10-and-why)
5. [Target Users & Use Cases](#5-target-users--use-cases)
6. [Complete Feature Set — MVP vs Phase 2](#6-complete-feature-set--mvp-vs-phase-2)
7. [System Architecture](#7-system-architecture)
8. [Canonical Firestore Schema](#8-canonical-firestore-schema)
9. [Module Definitions & Interactions](#9-module-definitions--interactions)
10. [ABDM Integration Architecture](#10-abdm-integration-architecture)
11. [Complete Tech Stack](#11-complete-tech-stack)
12. [Firestore Security Rules](#12-firestore-security-rules)
13. [Flutter Project Structure](#13-flutter-project-structure)
14. [Step-by-Step Implementation Guide](#14-step-by-step-implementation-guide)
15. [Risks, Mitigations & Hard Decisions](#15-risks-mitigations--hard-decisions)
16. [Definition of Done — Production Checklist](#16-definition-of-done--production-checklist)

---

## 1. Executive Summary

**Gram Aarogya Seva** is a production healthcare appointment platform built under the Unnat Bharat Abhiyan initiative. It connects rural villagers across Maharashtra and beyond to verified, government-registered doctors through a network of village health centres — all via a single cross-platform Flutter application.

The system solves two compounding problems: villagers with no reliable way to book appointments, and doctors with no structured visibility into their schedule across multiple villages. The design is built around one central insight — a significant portion of end users will not own smartphones, will have low literacy, and will access the system through health centre operators. This is not a constraint to accommodate; it is a core architectural requirement.

The platform has four distinct user roles (Admin, Doctor, Patient, Operator), an ABDM-integrated doctor verification pipeline, a geographically anchored village + health centre data model, and a three-language interface (Hindi, Marathi, English). The entire infrastructure runs at zero recurring cost within Firebase's free tier for the foreseeable scale of village-level healthcare.

---

## 2. Problem Statement & Product Vision

### The Problem

Rural healthcare in India suffers from a structural coordination failure. Doctors travel to multiple villages across a district on different days. Patients have no reliable way to know when a doctor will be available, which health centre they will visit, or whether a slot exists before making the journey. Health centre staff manage schedules manually on paper. The result is predictable: patients miss doctors, doctors arrive to empty or overcrowded centres, and the system is perceived as unreliable by the very communities it is meant to serve.

The downstream effect is that villagers — especially those with chronic conditions — delay care until emergencies, at which point the cost in money and health is far higher than any appointment would have been.

### The Vision

A platform where any villager in a registered village can, in under three minutes, know exactly when a verified doctor is available at their nearest health centre, book a confirmed time slot, and receive a reminder before the appointment. Where the doctor arrives to an organised day. Where the health centre staff have complete visibility. Where all of this works even on slow 2G networks and shared devices.

### Design Principles (Non-Negotiable)

These principles govern every product and architectural decision in this document.

- **Rural-first UX.** Icon + text on every action. Minimum 56dp tap targets. 18sp minimum font. Marathi, Hindi, and English switchable from any screen. No feature that requires a stable high-speed connection for its primary function.
- **Offline-tolerant reads.** Appointments, prescriptions, and doctor schedules must be readable when offline. Writes queue and sync when connectivity returns.
- **Zero-trust security.** Every data access rule is enforced at the database level, not just in the UI. No role can read or write data outside its defined scope, regardless of how the app is used.
- **No record deletion.** No doctor, patient, appointment, or village is ever deleted. All state changes use status fields. Audit trail is preserved at all times.
- **Cost discipline.** Every infrastructure choice is evaluated against the goal of ₹0 recurring cost. All current choices fit within Firebase's Spark free tier at expected usage volume. The only mandatory spend is the Google Play Store one-time registration fee (~₹1,500).

---

## 3. Tech Stack Decision & Justification

### The Question

The previous blueprint used Firebase as a default assumption. This is the point to justify or change that decision with full reasoning.

### Firebase vs. Alternatives — Evaluated

| Criterion | Firebase (Firestore) | Supabase (PostgreSQL) | Self-hosted (VPS + Postgres) |
|---|---|---|---|
| **Phone OTP Auth** | Native, free, India-grade | Requires Twilio (₹/SMS) | Requires SMS vendor (₹/SMS) |
| **Offline persistence** | Built-in, production-proven | Not native | Not available |
| **Real-time streams** | Native (SnapshotListeners) | Available (Realtime) | Requires custom WebSocket |
| **Rural network tolerance** | Excellent (Firebase SDK handles retry) | Good | Requires engineering |
| **Free tier** | Generous (50K reads/day, 20K writes/day) | Limited (project pauses after inactivity) | VPS costs ₹500–800/month |
| **FCM push notifications** | Native, free | Requires third-party | Requires third-party |
| **Data locality (India)** | asia-south1 (Mumbai) available | Singapore region, no India | Full control |
| **Ops overhead** | Zero | Low | High |
| **ABDM API calls** | Via Cloud Functions (secure) | Via Edge Functions | Via API layer |
| **SQL query power** | No (NoSQL) | Full SQL | Full SQL |
| **Scale cost predictability** | Pay-as-you-go above free tier | $25/month Pro | Fixed VPS cost |

### Decision: Firebase, with Mumbai Region Selection

Firebase is the correct choice for this specific application. The decisive factors are:

**Phone Auth:** This application's primary auth mechanism is OTP to Indian mobile numbers. Firebase Phone Auth is free for up to 10,000 SMS verifications per month in India, has no per-SMS charge, and is integrated directly into the Flutter SDK. Every alternative requires a paid SMS vendor (Twilio, MSG91, Fast2SMS), adding both cost and complexity.

**Offline persistence:** Rural Maharashtra has significant zones of poor or no connectivity. Firestore's offline persistence is a first-class, SDK-level feature that requires one line of configuration. It caches the user's data locally using SQLite and syncs automatically when connectivity returns. No competing free-tier database provides this at the SDK level.

**Ops overhead:** The team does not have server management capacity. Firebase requires zero server configuration, zero deployment pipelines, zero monitoring setup for the database. This is not a concession — it is the correct architectural decision for a lean team.

**Data locality:** By selecting `asia-south1` as the Firestore region during Firebase project creation, all data is stored in Mumbai. This addresses data sovereignty requirements for Indian health data.

**The NoSQL limitation is not a real constraint at this scale.** The concern with Firestore vs SQL is around complex joins and aggregations. At village health centre scale — hundreds of patients, dozens of doctors, thousands of appointments — every query in this application is either a point read, a simple range filter, or a stream. No joins are needed. The schema in Section 8 is designed to avoid the Firestore anti-patterns.

**ABDM API calls** will be routed through Firebase Cloud Functions, which keeps ABDM credentials server-side and never exposed in the client app bundle.

### Firebase Configuration Requirement

When creating the Firebase project, select **Firestore region: `asia-south1` (Mumbai)**. This cannot be changed after creation. All other Firebase services (Auth, FCM, Storage) will follow. This is a one-time configuration step with permanent implications.

---

## 4. What Changed from v1.0 and Why

This section documents every significant change from the previous blueprint so no context is lost.

### 4.1 Project Framing
- **v1.0:** Framed as a student project with beginner-appropriate scope reductions
- **v2.0:** Full production application. No features were cut because of developer experience. Features are included or deferred based only on user value and architecture complexity.

### 4.2 Languages
- **v1.0:** Marathi + English
- **v2.0:** Hindi + Marathi + English. Three language files (`en.json`, `mr.json`, `hi.json`). All three must be complete at launch. Language selection on first launch, switchable from any screen.

### 4.3 Doctor Onboarding — Self-Registration with Government ID Verification
- **v1.0:** Admin creates doctor profiles; doctor self-registration was cut
- **v2.0:** Doctors self-register with NMR ID, HPR ID, and Aadhaar number. OTP is sent to the mobile linked to the doctor's Aadhaar via the ABDM sandbox API. After OTP verification, the registration enters `pending_approval` status. Admin reviews and approves or rejects. Only approved doctors appear to patients. Admin retains the ability to deactivate approved doctors.

**Why the change:** Doctor self-registration with government ID verification is the correct trust model for a healthcare application. An admin manually entering doctor credentials without verification is a weaker system. NMR and HPR IDs are verifiable through the ABDM ecosystem and establish that a doctor is a licensed professional. This is not added complexity — it is a basic requirement for a healthcare platform.

### 4.4 Doctor Village Assignment
- **v1.0:** No village-doctor relationship defined beyond a `village` field on the doctor document
- **v2.0:** During registration, doctors select the villages they serve from a list maintained in the database. This drives which health centres appear in their availability scheduler and which patients can discover them.

### 4.5 Admin Village & Health Centre Management
- **v1.0:** Villages and health centres were referenced but not managed in-app
- **v2.0:** Admin has a full management screen for both villages and health centres. Villages are the geographic anchor of the entire system. Health centres belong to villages. Doctors register for villages. Admin can add or deactivate villages and health centres. No village or centre is ever deleted — only deactivated, preserving historical appointment records.

### 4.6 Healthcare Centre Dropdown in Doctor Availability
- **v1.0:** Availability was stored without a health centre association
- **v2.0:** When a doctor sets their availability for a date, they select which health centre they will be at. This is filtered to only health centres in the villages the doctor has registered for. This information flows to the patient booking screen, so patients know exactly where to go.

### 4.7 Appointment Schema Update
- **v1.0:** Appointment stored `date` and `timeSlot` with no health centre link
- **v2.0:** Appointments store the health centre ID from the availability slot, giving patients a complete picture: doctor name + health centre location + date + time.

### 4.8 ABDM Integration — Properly Scoped
- **v1.0:** ABDM was cut entirely
- **v2.0:** ABDM Sandbox is used for doctor Aadhaar OTP verification during registration. This is done through Firebase Cloud Functions to protect credentials. Production ABDM integration requires NHA app registration — this is noted in the implementation guide with the exact steps.

---

## 5. Target Users & Use Cases

### Role Definitions

| Role | Who They Are | Primary Responsibility | Typical Device |
|---|---|---|---|
| **Admin** | UBA programme coordinator or healthcare centre supervisor | System configuration, doctor approval, village management, system health monitoring | Personal or shared Android device |
| **Doctor** | Licensed medical professional registered with NMR/HPR | Managing availability, accepting/rejecting appointments, recording visit outcomes | Personal Android phone |
| **Patient** | Villager in a registered village | Booking appointments, accessing records, pre-visit intake | Personal phone (low-end Android) or shared centre device |
| **Operator** | ASHA worker or health centre front desk staff | Registering offline patients, booking on their behalf, updating doctor availability as fallback | Centre's shared phone or tablet |

### Core Use Cases (MVP)

**UC-01 — Patient Books an Appointment**
Patient opens app → OTP login → selects reason → selects doctor (filtered to their village) → sees available dates and which health centre the doctor will be at → selects a time slot → confirms → receives notification. Doctor receives booking notification and accepts or rejects.

**UC-02 — Operator Registers an Offline Villager and Books**
Operator logs in → Register Patient (name, DOB, village, mobile) → Book for Patient → selects the patient → selects doctor → date → slot → confirms. Appointment created with `created_by: health_center` flag visible to doctor and admin.

**UC-03 — Doctor Registers and Gets Approved**
Doctor downloads app → registers with name, specialisation, NMR ID, HPR ID, Aadhaar number, mobile number, selects villages they serve → receives OTP on Aadhaar-linked mobile via ABDM → verifies OTP → registration in `pending_approval` state. Admin receives notification, reviews, approves. Doctor can now log in and set availability.

**UC-04 — Doctor Sets Availability at a Specific Health Centre**
Doctor logs in → Set Availability → selects date → selects health centre (dropdown filtered to centres in doctor's registered villages) → adds time slots → saves. Slots are now visible to patients in those villages when booking.

**UC-05 — Admin Onboards a New Village**
Admin logs in → Manage Villages → Add Village (name, district, taluka) → saves. Village is now available for doctor village selection and patient registration. Admin separately adds health centres linked to that village.

**UC-06 — Admin Approves a New Doctor**
Admin receives FCM notification: new doctor pending approval. Admin opens Pending Approvals → reviews NMR ID, HPR ID, name, specialisation → approves or rejects with a note. Doctor receives notification of the outcome.

**UC-07 — Admin Monitors System Health**
Admin dashboard shows live: pending doctor approvals, pending appointments count, total active doctors, total registered patients. Admin taps into appointment monitor, filters by status. Identifies a doctor with 10 pending appointments — contacts doctor offline.

---

## 6. Complete Feature Set — MVP vs Phase 2

### MVP Core — Must Build Before Launch

#### Authentication & Onboarding
- OTP-based login for all roles (Firebase Phone Auth)
- Doctor self-registration with NMR ID, HPR ID, Aadhaar number, village selection
- ABDM Aadhaar OTP verification for doctors (via Cloud Function, Sandbox for dev)
- Doctor pending approval state — not visible to patients until approved
- Patient and Operator self-registration with OTP only (no government ID required)
- Role-based automatic routing post-authentication

#### Admin Module
- Dashboard with live stat cards: pending approvals, pending appointments, active doctors, registered patients
- **Pending Doctor Approvals:** Review NMR/HPR details, approve or reject with note
- **Village Management:** Add, view, and deactivate villages (name, district, taluka, state)
- **Health Centre Management:** Add, view, and deactivate health centres linked to villages
- **Manage Doctors:** View all doctors, activate/deactivate, view associated villages
- **View Patients:** Read-only list with search by name/village/mobile
- **Monitor Appointments:** Full system appointment view, filterable by status, admin can mark complete
- **Role Management:** Change a user's role (with confirmation)

#### Doctor Module
- Dashboard: pending requests badge, navigation to all sub-screens
- **Appointment Requests:** Accept (with optional prep note) or reject with reason
- **Upcoming Appointments:** Chronological list of accepted appointments with patient details and health centre
- **Appointment History:** All completed/rejected appointments
- **Set Availability:** Calendar → select date → select health centre (filtered to doctor's villages) → add time slots → save
- **Profile:** View registered details. NMR/HPR/Aadhaar fields read-only after verification. Can update name, specialisation, contact

#### Patient Module
- **Home Dashboard:** Next appointment card, primary action buttons
- **Book Appointment:** Reason selection (icon grid) → doctor list (filtered to patient's village) → date picker → slot picker (shows health centre for each slot) → intake form (3 questions) → confirmation → submit
- **My Appointments:** Upcoming / History tabs. Cancel up to 2 hours before.
- **Health Records:** Prescriptions and visit summaries from completed appointments
- **Profile:** Edit personal details, emergency contact, language preference, medical background

#### Operator Module
- **Dashboard:** Today's assisted bookings count, navigation buttons
- **Register Patient:** Assisted registration for villagers without phones
- **Book for Patient:** Patient search → same booking flow → appointment flagged as centre-created
- **Manage Doctor Availability:** Fallback availability update when doctor cannot use app
- **Assisted Appointments:** View all centre-created appointments (today by default)

#### Infrastructure
- FCM push notifications for all critical events (booking, approval, acceptance, rejection, completion, reminder)
- Firestore offline persistence enabled (reads cached locally, writes queue when offline)
- Three-language UI (Hindi, Marathi, English) with runtime switching
- Firestore security rules enforced at database level
- Firestore transactions for appointment booking (double-booking prevention)
- Firebase Cloud Functions for ABDM API calls and appointment reminder scheduling

### Phase 2 — After MVP is Live and Stable

| Feature | Why Deferred |
|---|---|
| Doctor-patient text messaging | Core booking flow must be validated first |
| Prescription upload by doctor | Storage UX adds scope; visit summary text is sufficient for MVP |
| Follow-up appointment (one-tap from visit summary) | Scheduling logic extension; low friction add after booking flow is stable |
| Dependent profile (parent books for child) | Profile management complexity; operator can handle this manually |
| Doctor profile edit screen (admin) | Add/deactivate covers MVP management needs |
| Appointment summary report (admin) | Stat cards sufficient for initial monitoring |
| Operator appointment rescheduling | Read-mostly operator flow is sufficient for MVP |
| Offline booking queue (operator) | Requires local DB + sync state machine; adds complexity |
| Marathi/Hindi audio prompts | Accessibility enhancement for Phase 2 |
| Weekly recurring availability (doctor) | Simplifies doctor experience; can be added after slot system is proven |
| Lab result upload | Requires test coordination beyond app scope for MVP |
| SMS fallback for notifications | FCM + WhatsApp numbers in centre are sufficient for MVP |

### Not In Scope

| Feature | Reason |
|---|---|
| Video/voice calling | Rural connectivity makes in-person the primary model; teleconsultation requires ABDM telemedicine standards and is a significant separate undertaking |
| Payment module | Healthcare at these centres is free or government-subsidised |
| Insurance/coverage verification | Not applicable to this context |
| QR code check-in | Network-dependent; operational complexity outweighs benefit at this scale |
| HMIS/government data export | Future compliance requirement; not needed for operational launch |
| Multi-centre management (cross-district admin) | Single-district system for Phase 1 |
| Waitlist management | Appointment volume per centre does not justify the complexity |
| GDPR/data deletion workflows | Governed by India's DPDPA; handled at policy level, not UI level, for MVP |
| Doctor HR/salary | This is not an HR system |
| Analytics charts (admin) | Live stat cards are sufficient; chart library adds bundle size with no operational gain |

---

## 7. System Architecture

### Architecture Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION                             │
│                  (Single Codebase — Android First)                 │
│                                                                    │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌─────────────┐   │
│   │  Admin   │   │  Doctor  │   │ Patient  │   │  Operator   │   │
│   │Dashboard │   │Dashboard │   │Dashboard │   │  Dashboard  │   │
│   └────┬─────┘   └────┬─────┘   └────┬─────┘   └──────┬──────┘   │
│        │               │               │                │          │
│   ─────────────────────────────────────────────────────────────   │
│   │          GoRouter + RoleGuard + AuthGuard                  │   │
│   ─────────────────────────────────────────────────────────────   │
│        │               │               │                │          │
│   ─────────────────────────────────────────────────────────────   │
│   │              Riverpod 2.x State Layer                      │   │
│   │  (Providers, AsyncNotifiers, StreamProviders)              │   │
│   ─────────────────────────────────────────────────────────────   │
│        │               │               │                │          │
│   ─────────────────────────────────────────────────────────────   │
│   │         FirestoreService — Single Data Access Layer        │   │
│   │         (All Firestore reads/writes go through here)       │   │
│   ─────────────────────────────────────────────────────────────   │
└────────────────────────┬───────────────────────────────────────────┘
                         │  Firebase SDK (asia-south1)
┌────────────────────────▼───────────────────────────────────────────┐
│                    FIREBASE BACKEND                                │
│               Region: asia-south1 (Mumbai)                        │
│                                                                    │
│  ┌──────────────┐  ┌───────────┐  ┌─────────┐  ┌──────────────┐  │
│  │  Firestore   │  │  Firebase │  │   FCM   │  │   Firebase   │  │
│  │  Database    │  │  Auth     │  │  Push   │  │   Storage    │  │
│  │  + Offline   │  │  (Phone   │  │  Notif. │  │  (Docs,      │  │
│  │  Persistence │  │   OTP)    │  │         │  │   Prescrip.) │  │
│  └──────────────┘  └───────────┘  └─────────┘  └──────────────┘  │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Firebase Cloud Functions                        │ │
│  │  - abdmVerifyAadhaarOtp()   (secure ABDM API proxy)         │ │
│  │  - sendAppointmentReminders() (scheduled, 24hr before)      │ │
│  │  - onDoctorApproved()        (triggers FCM to doctor)       │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────┬───────────────────────────────────────────┘
                         │ HTTPS (Cloud Functions only)
              ┌──────────▼──────────┐
              │   ABDM Sandbox API  │
              │   (NHA, Aadhaar     │
              │    OTP for doctors) │
              └─────────────────────┘
```

### Authentication & Role Routing Flow

```
App Launch
    │
    ▼
Splash Screen (2s, logo + tagline)
    │
    ▼
Firebase Auth State Check
    │
    ├── No active session ──────────────────────────────► Phone Input Screen
    │                                                          │
    └── Active session                                         ▼
              │                                         OTP Verification
              │                                               │
              │                                    ┌──────────▼──────────┐
              │                                    │ Read users/{uid}    │
              │                                    │ from Firestore      │
              │                                    └──────────┬──────────┘
              │                                               │
              │                                    First login? Create user doc
              │                                    role = "patient" (default)
              │                                               │
              └──────────────────────────────────────────────┘
                              │
              ┌───────────────▼───────────────┐
              │        Role Guard             │
              ├───────────────────────────────┤
              │ admin    → /admin/dashboard   │
              │ doctor   → /doctor/dashboard  │
              │   (+ check: status ==         │
              │    pending_approval →         │
              │    /doctor/awaiting)          │
              │ patient  → /patient/dashboard │
              │ operator → /operator/dashboard│
              └───────────────────────────────┘
```

### Appointment Booking Transaction Flow

```
Patient / Operator selects slot
         │
         ▼
SlotPickerWidget reads
doctor_availability/{doctorId}_{date}
Displays slots where isBooked == false
Includes health centre name for each available slot
         │
         ▼
User confirms booking
         │
         ▼
FirestoreService.createAppointment()
runs Firestore TRANSACTION:
  ┌────────────────────────────────────────┐
  │ 1. Read availability doc               │
  │ 2. Verify target slot isBooked == false│
  │    If already booked → throw error     │
  │    Show "Slot just got booked, pick    │
  │    another" to user                    │
  │ 3. Write appointments/{newId}          │
  │ 4. Update slot.isBooked = true         │
  │ All 4 steps atomic                     │
  └────────────────────────────────────────┘
         │
         ▼
On transaction success:
  - Write notification for doctor
  - FCM sent to doctor's fcmToken
         │
         ▼
Doctor accepts/rejects
  - FCM sent to patient
  - Appointment status updated
```

### Doctor Registration & Approval Flow

```
Doctor opens app → "Register as Doctor"
         │
         ▼
Registration Form:
  Name, Specialisation, NMR ID, HPR ID,
  Aadhaar Number, Mobile, Village Selection
         │
         ▼
"Verify with Aadhaar OTP"
         │
         ▼
Flutter app calls Firebase Cloud Function:
abdmRequestAadhaarOtp(aadhaarNumber)
         │
         ▼
Cloud Function calls ABDM Sandbox API
OTP sent to doctor's Aadhaar-linked mobile
         │
         ▼
Doctor enters OTP
Flutter calls: abdmVerifyAadhaarOtp(otp, txnId)
         │
         ├── OTP invalid → Show error, allow retry
         │
         └── OTP valid →
              Create doctors/{docId} with
              status: "pending_approval"
              Store: name, specialisation,
                     nmrId, hprId,
                     aadhaarHash (SHA-256),
                     villages[], mobile
              Create users/{uid} with
              role: "doctor"
                         │
                         ▼
              Admin receives FCM notification
              "New doctor pending approval"
                         │
                         ▼
              Admin reviews → Approve / Reject
                         │
              ┌──────────┴──────────┐
              │                     │
           Approved              Rejected
              │                     │
     status: "active"      status: "rejected"
     FCM → Doctor:         FCM → Doctor:
     "Approved, you can    "Registration
      now set availability" rejected: [note]"
```

---

## 8. Canonical Firestore Schema

This is the single authoritative schema. All modules use these exact collection names and field names. No deviations.

```
// ══════════════════════════════════════════════════
// VILLAGES — Master geographic anchor of the system
// Managed exclusively by Admin
// ══════════════════════════════════════════════════
villages/{villageId}
  villageId:    String        // Auto-generated Firestore doc ID
  name:         String        // "Karanja"
  taluka:       String        // "Karanja"
  district:     String        // "Washim"
  state:        String        // "Maharashtra"
  isActive:     Boolean       // false = deactivated (never deleted)
  createdAt:    Timestamp
  createdBy:    String        // admin uid

// ══════════════════════════════════════════════════
// HEALTH_CENTRES — Physical locations where doctors visit
// Each centre belongs to one village
// Managed exclusively by Admin
// ══════════════════════════════════════════════════
health_centers/{centerId}
  centerId:     String
  name:         String        // "Karanja Primary Health Centre"
  villageId:    String        // → villages/{villageId}
  address:      String
  phone:        String
  isActive:     Boolean
  createdAt:    Timestamp
  createdBy:    String        // admin uid

// ══════════════════════════════════════════════════
// USERS — Auth identity for all roles
// Created on first OTP login
// ══════════════════════════════════════════════════
users/{uid}
  uid:          String        // Firebase Auth UID (document ID)
  name:         String
  phone:        String        // 10-digit, no country code prefix
  role:         String        // "admin" | "doctor" | "patient" | "operator"
  villageId:    String        // patient and operator: their village
  language:     String        // "en" | "mr" | "hi"
  fcmToken:     String        // Refreshed on every login
  createdAt:    Timestamp

// ══════════════════════════════════════════════════
// DOCTORS — Doctor professional profile
// Created by doctor during self-registration
// status controls visibility to patients
// ══════════════════════════════════════════════════
doctors/{doctorId}
  doctorId:         String    // Same as users/{uid} (Firebase Auth UID)
  name:             String
  specialization:   String
  mobile:           String
  nmrId:            String    // National Medical Register ID (plaintext — not sensitive beyond display)
  hprId:            String    // Health Professional Registry ID
  aadhaarHash:      String    // SHA-256 hash of Aadhaar — NEVER store plaintext Aadhaar
  aadhaarLastFour:  String    // "XXXX XXXX 1234" — for display/verification only
  abdmTxnId:        String    // ABDM transaction ID from successful OTP verification
  villages:         String[]  // [villageId, villageId, ...] — villages doctor serves
  status:           String    // "pending_approval" | "active" | "inactive" | "rejected"
  rejectionNote:    String?   // Filled by admin if status == "rejected"
  approvedBy:       String?   // Admin uid
  approvedAt:       Timestamp?
  createdAt:        Timestamp

// ══════════════════════════════════════════════════
// PATIENTS — Patient profile (separate from users for clinical data)
// Created by patient (self) or operator (assisted)
// ══════════════════════════════════════════════════
patients/{patientId}
  patientId:        String    // Firestore auto-ID (NOT the Firebase Auth UID)
  userId:           String?   // Firebase Auth UID — null if registered by operator for non-phone patient
  name:             String
  dob:              String    // "YYYY-MM-DD"
  gender:           String    // "male" | "female" | "other"
  villageId:        String    // → villages/{villageId}
  mobile:           String
  emergencyContact: {
    name:           String
    phone:          String
  }
  medicalBackground: {
    conditions:     String[]  // Free-text tags: ["diabetes", "hypertension"]
    medications:    String[]
    allergies:      String[]
  }
  createdBy:        String    // "self" | "health_center"
  createdByOperatorId: String? // uid of operator if createdBy == "health_center"
  createdAt:        Timestamp

// ══════════════════════════════════════════════════
// DOCTOR_AVAILABILITY — Per-date slot availability
// Document ID convention: {doctorId}_{YYYY-MM-DD}
// ══════════════════════════════════════════════════
doctor_availability/{availabilityId}
  doctorId:         String    // → doctors/{doctorId}
  healthCenterId:   String    // → health_centers/{centerId}
                              // Which centre the doctor will be at on this date
  date:             String    // "YYYY-MM-DD"
  slots: [
    {
      time:         String    // "09:00 AM"
      isBooked:     Boolean   // Updated atomically by booking transaction
      appointmentId: String?  // Populated when booked — links back to the appointment
    }
  ]
  createdAt:        Timestamp
  lastUpdatedBy:    String    // uid of who last updated (doctor or operator)

// ══════════════════════════════════════════════════
// APPOINTMENTS — Booking record
// Created by patient or operator; status updated by doctor
// ══════════════════════════════════════════════════
appointments/{appointmentId}
  appointmentId:    String
  patientId:        String    // → patients/{patientId}
  doctorId:         String    // → doctors/{doctorId}
  healthCenterId:   String    // → health_centers/{centerId}
  villageId:        String    // Denormalized for admin queries
  date:             String    // "YYYY-MM-DD"
  timeSlot:         String    // "09:00 AM"
  reason:           String    // "Fever" | "Checkup" | "Follow-up" | "Other"
  status:           String    // "pending" | "accepted" | "rejected" | "completed"
  createdBy:        String    // "self" | "health_center"
  createdByOperatorId: String?
  prepInstructions: String?   // Set by doctor when accepting (optional)
  rejectionReason:  String?   // Set by doctor when rejecting
  intakeForm: {               // Filled by patient pre-visit
    symptoms:       String
    duration:       String
    severity:       String    // "mild" | "moderate" | "severe"
  }
  visitSummary: {             // Filled by doctor post-visit (Phase 2: doctor fills this)
    notes:          String
    prescription:   String
    nextSteps:      String
    followUpDate:   String?
  }
  createdAt:        Timestamp
  updatedAt:        Timestamp

// ══════════════════════════════════════════════════
// NOTIFICATIONS — Per-user notification inbox
// ══════════════════════════════════════════════════
notifications/{notificationId}
  userId:           String    // Recipient (Firebase Auth UID)
  type:             String    // See types below
  title:            String    // Localised title (stored in user's language at time of creation)
  message:          String
  relatedId:        String    // appointmentId or doctorId depending on type
  isRead:           Boolean
  createdAt:        Timestamp

// Notification types:
// "doctor_registration_pending"  → to admin
// "doctor_approved"              → to doctor
// "doctor_rejected"              → to doctor
// "appointment_booked"           → to doctor
// "appointment_accepted"         → to patient
// "appointment_rejected"         → to patient
// "appointment_reminder_24h"     → to patient (scheduled via Cloud Function)
// "appointment_completed"        → to patient
```

### Schema Design Decisions

**Why `patients` is separate from `users`:** The `users` collection holds auth identity (role, FCM token, language preference). The `patients` collection holds clinical and demographic data. Keeping them separate means operators can create patient records for villagers who don't have phone accounts (userId = null), and the security rules for clinical data can be scoped independently from auth identity.

**Why `doctor_availability` uses `{doctorId}_{date}` as the document ID:** This naming scheme makes availability lookup O(1) — a single document read with a known ID, rather than a query. It also makes Firestore transactions on slots simpler because the document to lock is always deterministic.

**Why `healthCenterId` is on both availability and appointments:** A doctor's availability is linked to a specific health centre. When that slot is booked as an appointment, the health centre is inherited. This denormalization means the patient's appointment card always shows where to go without an additional read.

**Why `aadhaarHash` and not plaintext Aadhaar:** UIDAI guidelines prohibit storing Aadhaar numbers in plaintext. SHA-256 hash + last-four display is the correct pattern. The full number is only ever used in transit to the ABDM API (via Cloud Function) and never stored.

---

## 9. Module Definitions & Interactions

### Responsibility Matrix

| Action | Admin | Doctor | Patient | Operator |
|---|---|---|---|---|
| Add / deactivate village | ✅ | ❌ | ❌ | ❌ |
| Add / deactivate health centre | ✅ | ❌ | ❌ | ❌ |
| Approve / reject doctor registration | ✅ | ❌ | ❌ | ❌ |
| Activate / deactivate approved doctor | ✅ | ❌ | ❌ | ❌ |
| Change user role | ✅ | ❌ | ❌ | ❌ |
| Register self (with Aadhaar) | ❌ | ✅ | ❌ | ❌ |
| Set own availability (with health centre) | ❌ | ✅ | ❌ | ✅ (fallback) |
| Accept / reject appointment requests | ❌ | ✅ | ❌ | ❌ |
| Mark appointment complete | ✅ (edge case) | ✅ | ❌ | ❌ |
| Book own appointment | ❌ | ❌ | ✅ | ❌ |
| Register offline patient | ❌ | ❌ | ❌ | ✅ |
| Book appointment on patient's behalf | ❌ | ❌ | ❌ | ✅ |
| View all system appointments | ✅ | ❌ | ❌ | ❌ |
| View own / assigned appointments | ❌ | ✅ | ✅ | ✅ (assisted) |
| View all patients (read) | ✅ | ❌ | ❌ | ✅ (name/village/mobile only) |
| Delete any record | ❌ | ❌ | ❌ | ❌ |

### Module Interaction Map

```
ADMIN
  │ manages
  ├──► villages/{id}         (add/deactivate)
  ├──► health_centers/{id}   (add/deactivate)
  ├──► doctors/{id}.status   (approve/activate/deactivate)
  └──► users/{id}.role       (role management)

DOCTOR
  │ self-registers ──► doctors/{id} (pending_approval)
  │ on approval reads
  ├──► villages[]            (to filter health centre dropdown)
  ├──► health_centers[]      (for availability scheduling)
  └──► writes doctor_availability/{doctorId}_{date}
         with healthCenterId

PATIENT / OPERATOR
  │ reads
  ├──► doctors[]             (active only, filtered by village)
  ├──► doctor_availability[] (to show slots + health centre)
  └──► writes appointments/{id}
         (via Firestore transaction)
         copies healthCenterId from availability slot

DOCTOR reads appointments/{id} where doctorId == own
  └──► updates status: accepted / rejected / completed

ADMIN reads all appointments (monitoring only)
  └──► can update status to "completed" (edge case only)
```

### Shared Widget Contract

These widgets are implemented once in `shared/widgets/` and used across all modules without modification.

| Widget | Modules | Purpose |
|---|---|---|
| `LargeButton` | All | 56dp minimum height, full-width, icon + label, loading state, disabled state |
| `RuralCard` | All | Standard card container for list items with consistent padding/elevation |
| `SlotPickerWidget` | Patient, Operator | Fetches `doctor_availability/{doctorId}_{date}`, filters `isBooked == false`, displays slots with health centre name |
| `AppointmentCard` | Doctor, Admin, Patient, Operator | Renders appointment with colour-coded status badge, `createdBy` indicator |
| `StatusBadge` | Admin, Doctor | Colour-coded chip: pending=orange, accepted=blue, completed=green, rejected=red |
| `VillagePicker` | Doctor (registration), Patient (profile) | Searchable dropdown of active villages from Firestore stream |
| `HealthCentrePicker` | Doctor (availability) | Dropdown filtered to health centres in doctor's registered villages |
| `LanguageSwitcher` | All | En/Mr/Hi toggle, persists to SharedPreferences and updates `users/{uid}.language` |
| `ConfirmationDialog` | All | Reusable confirm/cancel for all destructive or significant actions |
| `NmrHprInfoCard` | Admin (doctor approvals) | Displays NMR ID, HPR ID in a formatted card for admin review |

---

## 10. ABDM Integration Architecture

### What ABDM Is

ABDM (Ayushman Bharat Digital Mission) is India's national digital health infrastructure operated by the National Health Authority (NHA). It includes:
- **ABDM Sandbox** — Free development/testing environment
- **HPR (Health Professional Registry)** — Database of all licensed health professionals
- **NMR (National Medical Register)** — Database of registered doctors under NMC
- **Aadhaar OTP** — ABDM-mediated OTP to the mobile linked to a professional's Aadhaar

### How It Is Used in This Application

ABDM is used **only** for doctor registration verification. Specifically: to send an OTP to the mobile number linked to the doctor's Aadhaar, confirming that the person registering controls the Aadhaar they provided. This is one-time, at registration.

Patient auth uses standard Firebase Phone Auth. ABDM is not used for patients.

### Cloud Function: ABDM Proxy (Critical Security Pattern)

ABDM API calls **must not** originate from the Flutter client app. The ABDM client ID and client secret must never appear in app code or app bundles, which are inspectable. All ABDM calls go through Firebase Cloud Functions, which have access to secrets stored in Firebase environment config.

```javascript
// Cloud Function: functions/src/abdm.ts

import * as functions from 'firebase-functions';
import axios from 'axios';

const ABDM_BASE = 'https://dev.abdm.gov.in/gateway'; // Sandbox URL
// Production: 'https://live.abdm.gov.in/gateway'

// Step 1: Request OTP for doctor's Aadhaar
export const abdmRequestAadhaarOtp = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');

  const { aadhaarNumber } = data;
  // Validate format: 12 digits
  if (!/^\d{12}$/.test(aadhaarNumber)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid Aadhaar format');
  }

  // Get ABDM access token
  const tokenRes = await axios.post(`${ABDM_BASE}/v0.5/sessions`, {
    clientId: functions.config().abdm.client_id,
    clientSecret: functions.config().abdm.client_secret,
  });
  const accessToken = tokenRes.data.accessToken;

  // Request Aadhaar OTP
  const otpRes = await axios.post(
    `${ABDM_BASE}/v0.5/registration/aadhaar/generateOtp`,
    { aadhaar: aadhaarNumber },
    { headers: { Authorization: `Bearer ${accessToken}`, 'X-CM-ID': 'sbx' } }
  );

  // Return only the txnId to the client — never return the access token
  return { txnId: otpRes.data.txnId };
});

// Step 2: Verify the OTP entered by the doctor
export const abdmVerifyAadhaarOtp = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');

  const { otp, txnId } = data;

  const tokenRes = await axios.post(`${ABDM_BASE}/v0.5/sessions`, {
    clientId: functions.config().abdm.client_id,
    clientSecret: functions.config().abdm.client_secret,
  });
  const accessToken = tokenRes.data.accessToken;

  try {
    const verifyRes = await axios.post(
      `${ABDM_BASE}/v0.5/registration/aadhaar/verifyOTP`,
      { otp, txnId },
      { headers: { Authorization: `Bearer ${accessToken}`, 'X-CM-ID': 'sbx' } }
    );
    // OTP verified successfully
    return {
      verified: true,
      txnId: verifyRes.data.txnId, // New txnId for the next step if needed
    };
  } catch (e) {
    return { verified: false, message: 'OTP verification failed' };
  }
});
```

### ABDM Sandbox Setup (Development)

1. Register at [sandbox.abdm.gov.in](https://sandbox.abdm.gov.in)
2. Create an application → receive `clientId` and `clientSecret`
3. Store in Firebase environment: `firebase functions:config:set abdm.client_id="..." abdm.client_secret="..."`
4. ABDM Sandbox provides test Aadhaar numbers for development without using real Aadhaar

### ABDM Production Path

When moving to production:
1. Register your app with NHA as an approved Health Application at [abdm.gov.in](https://abdm.gov.in)
2. Submit app details, privacy policy, security assessment
3. NHA reviews and issues production `clientId` and `clientSecret`
4. Update Cloud Function to use production ABDM endpoint (`live.abdm.gov.in`)
5. Update `firebase functions:config:set` with production credentials

This process typically takes 4–8 weeks. Plan accordingly.

---

## 11. Complete Tech Stack

### Core Framework & Backend

| Technology | Purpose | Cost |
|---|---|---|
| Flutter 3.22+ / Dart 3.x | Cross-platform UI | Free |
| Firebase Firestore (asia-south1) | Primary database + offline persistence | Free (Spark) |
| Firebase Auth (Phone OTP) | Authentication for all roles | Free (10K SMS/month in India) |
| Firebase Cloud Messaging (FCM) | Push notifications | Free |
| Firebase Storage | Document/prescription storage (Phase 2) | Free (5GB) |
| Firebase Cloud Functions | ABDM proxy, appointment reminders | Free (2M invocations/month) |

### Flutter Packages

**State Management & Navigation**

| Package | Purpose | Version |
|---|---|---|
| `flutter_riverpod` | State management | ^2.5.x |
| `riverpod_annotation` | `@riverpod` code generation | ^2.3.x |
| `riverpod_generator` | Build runner target | ^2.4.x |
| `go_router` | Declarative routing + redirect guards | ^13.x |

**Data Layer**

| Package | Purpose | Version |
|---|---|---|
| `freezed` | Immutable data models | ^2.5.x |
| `freezed_annotation` | `@freezed` annotation | ^2.4.x |
| `json_serializable` | `fromJson`/`toJson` generation | ^6.8.x |
| `cloud_firestore` | Firestore SDK | ^4.x |
| `firebase_auth` | Auth SDK | ^4.x |
| `firebase_messaging` | FCM SDK | ^14.x |
| `cloud_functions` | Cloud Functions client SDK | ^4.x |
| `firebase_storage` | Storage SDK (Phase 2) | ^11.x |

**UI & UX**

| Package | Purpose | Version |
|---|---|---|
| `easy_localization` | Three-language (en/mr/hi) runtime switching | ^3.0.x |
| `table_calendar` | Date picker for availability + booking | ^3.1.x |
| `flutter_svg` | SVG icons throughout the app | ^2.0.x |
| `shimmer` | Loading skeleton states | ^3.0.x |
| `flutter_local_notifications` | Local notification display | ^17.x |

**Utilities**

| Package | Purpose | Version |
|---|---|---|
| `intl` | Date/number formatting, locale support | ^0.19.x |
| `shared_preferences` | Language and session preference storage | ^2.2.x |
| `uuid` | Unique ID generation | ^4.4.x |
| `crypto` | SHA-256 Aadhaar hashing (client-side) | ^3.0.x |
| `phone_form_field` | Indian phone number input with validation | ^9.x |

**Development**

| Tool | Purpose |
|---|---|
| `build_runner` | Code generation (Riverpod + Freezed) |
| `flutter_lints` | Lint rules |
| Firebase CLI | Deploy Firestore rules and Cloud Functions |
| FlutterFire CLI | Generate `firebase_options.dart` |

### Infrastructure Cost Summary

| Service | Plan | Monthly Cost |
|---|---|---|
| Firestore | Spark (free) — 50K reads/day, 20K writes/day, 1GB | ₹0 |
| Firebase Auth | Free — 10K phone verifications/month (India) | ₹0 |
| FCM | Free — unlimited notifications | ₹0 |
| Cloud Functions | Free — 2M invocations/month | ₹0 |
| Firebase Storage | Free — 5GB | ₹0 |
| **Recurring total** | | **₹0 / month** |
| Google Play Store | One-time developer registration | ~₹1,500 (once) |

---

## 12. Firestore Security Rules

These rules are deployed to Firebase before writing any application code. They are the authoritative access control layer — the app UI is secondary.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Core helper functions
    function isAuth() {
      return request.auth != null;
    }

    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function isAdmin() {
      return isAuth() && userDoc().role == 'admin';
    }

    function isDoctor() {
      return isAuth() && userDoc().role == 'doctor';
    }

    function isPatient() {
      return isAuth() && userDoc().role == 'patient';
    }

    function isOperator() {
      return isAuth() && userDoc().role == 'operator';
    }

    function isOwner(uid) {
      return isAuth() && request.auth.uid == uid;
    }

    function onlyChanges(keys) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(keys);
    }

    // ── VILLAGES
    match /villages/{villageId} {
      allow read: if isAuth();              // All roles read villages (for pickers)
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if false;              // Never delete — deactivate only
    }

    // ── HEALTH CENTRES
    match /health_centers/{centerId} {
      allow read: if isAuth();
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if false;
    }

    // ── USERS
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId);    // User creates own doc on first login
      // User updates own non-role fields; Admin updates role field only
      allow update: if (isOwner(userId) && !onlyChanges(['role']))
        || (isAdmin() && onlyChanges(['role']));
      allow delete: if false;
    }

    // ── DOCTORS
    match /doctors/{doctorId} {
      // Public read only for active doctors (patients/operators need to see them)
      allow read: if isAuth()
        && (isAdmin() || isOperator()
            || resource.data.status == 'active'
            || isOwner(doctorId));           // Doctor can always read own doc
      allow create: if isOwner(doctorId);   // Doctor self-creates on registration
      // Doctor edits own non-status fields; Admin edits status and approval fields
      allow update: if
        (isOwner(doctorId)
          && onlyChanges(['name','specialization','mobile','villages','lastUpdatedAt']))
        || (isAdmin()
          && onlyChanges(['status','approvedBy','approvedAt','rejectionNote']));
      allow delete: if false;
    }

    // ── PATIENTS
    match /patients/{patientId} {
      // Admin reads all; Operator reads all (for patient search);
      // Patient reads own record only
      allow read: if isAdmin() || isOperator()
        || (isPatient() && resource.data.userId == request.auth.uid);
      allow create: if isPatient() || isOperator();
      allow update: if isAdmin() || isOperator()
        || (isPatient() && resource.data.userId == request.auth.uid);
      allow delete: if false;
    }

    // ── DOCTOR AVAILABILITY
    match /doctor_availability/{availabilityId} {
      allow read: if isAuth();             // All roles read for booking/display
      // Doctor creates/updates own; Operator updates as fallback; Admin can manage
      allow create: if isAdmin()
        || (isDoctor() && request.resource.data.doctorId == request.auth.uid)
        || isOperator();
      allow update: if isAdmin()
        || (isDoctor() && resource.data.doctorId == request.auth.uid)
        || isOperator()
        || isPatient();                    // Patients update isBooked via transaction
      allow delete: if false;
    }

    // ── APPOINTMENTS
    match /appointments/{appointmentId} {
      // Doctor reads own; Patient reads own; Admin + Operator read all
      allow read: if isAdmin() || isOperator()
        || (isDoctor() && resource.data.doctorId == request.auth.uid)
        || (isPatient() && resource.data.patientId ==
            get(/databases/$(database)/documents/patients/
              $(resource.data.patientId)).data.userId);
      allow create: if isPatient() || isOperator();
      // Doctor updates status + clinical fields; Patient updates status (cancel);
      // Admin updates status only (mark complete)
      allow update: if
        (isDoctor() && resource.data.doctorId == request.auth.uid
          && onlyChanges(['status','prepInstructions','rejectionReason',
                          'visitSummary','updatedAt']))
        || (isPatient()
          && onlyChanges(['status','updatedAt'])
          && request.resource.data.status == 'cancelled')
        || (isAdmin() && onlyChanges(['status','updatedAt']));
      allow delete: if false;
    }

    // ── NOTIFICATIONS
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuth();
      allow update: if isOwner(resource.data.userId)
        && onlyChanges(['isRead']);
      allow delete: if false;
    }
  }
}
```

---

## 13. Flutter Project Structure

```
gram_aarogya_seva/
├── android/                           ← Standard Flutter Android project
├── ios/                               ← Deferred — Android first
├── functions/                         ← Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── abdm.ts                    ← ABDM Aadhaar OTP proxy functions
│   │   ├── notifications.ts           ← Appointment reminder scheduler
│   │   └── index.ts                   ← Exports all functions
│   ├── package.json
│   └── tsconfig.json
├── firestore.rules                    ← Security rules (from Section 12)
├── firestore.indexes.json             ← Composite indexes for queries
├── firebase.json                      ← Firebase CLI config
│
└── lib/
    ├── main.dart                      ← Firebase init, ProviderScope, runApp
    ├── app.dart                       ← MaterialApp.router + theme + localization
    │
    ├── core/
    │   ├── config/
    │   │   ├── app_constants.dart     ← ALL string constants: roles, statuses,
    │   │   │                             collection names, route paths
    │   │   └── firebase_options.dart  ← Generated by FlutterFire CLI (DO NOT EDIT)
    │   │
    │   ├── router/
    │   │   ├── app_router.dart        ← GoRouter instance, all routes
    │   │   └── role_guard.dart        ← Redirect logic (auth + role + doctor status)
    │   │
    │   ├── providers/
    │   │   ├── auth_providers.dart    ← authStateProvider, currentUserProvider
    │   │   │                             currentRoleProvider
    │   │   └── service_providers.dart ← firestoreServiceProvider,
    │   │                                 notificationServiceProvider
    │   │
    │   ├── services/
    │   │   ├── firestore_service.dart ← ALL Firestore reads/writes.
    │   │   │                             No other file imports Firestore directly.
    │   │   ├── notification_service.dart ← FCM token mgmt, local notification display
    │   │   └── abdm_service.dart      ← Calls Cloud Functions for ABDM OTP
    │   │
    │   ├── models/                    ← Freezed models (auto-generated .g.dart files)
    │   │   ├── user_model.dart
    │   │   ├── doctor_model.dart
    │   │   ├── patient_model.dart
    │   │   ├── appointment_model.dart
    │   │   ├── availability_model.dart
    │   │   ├── village_model.dart
    │   │   ├── health_center_model.dart
    │   │   └── notification_model.dart
    │   │
    │   ├── theme/
    │   │   ├── app_theme.dart         ← MaterialTheme (green/white, high contrast)
    │   │   ├── app_colors.dart        ← Colour constants
    │   │   └── app_text_styles.dart   ← Text style constants (min 18sp)
    │   │
    │   └── utils/
    │       ├── date_utils.dart        ← Date formatting, slot time parsing
    │       ├── validators.dart        ← NMR/HPR/Aadhaar/phone validators
    │       └── crypto_utils.dart      ← SHA-256 Aadhaar hashing
    │
    ├── features/
    │   ├── auth/
    │   │   ├── screens/
    │   │   │   ├── phone_input_screen.dart      ← Mobile number entry
    │   │   │   └── otp_verification_screen.dart ← 6-digit OTP input
    │   │   └── providers/
    │   │       └── auth_action_provider.dart    ← sendOtp, verifyOtp actions
    │   │
    │   ├── doctor_registration/
    │   │   ├── screens/
    │   │   │   ├── doctor_registration_screen.dart  ← Multi-step: basic info +
    │   │   │   │                                        village selection +
    │   │   │   │                                        Aadhaar OTP verification
    │   │   │   └── awaiting_approval_screen.dart    ← Shown when status ==
    │   │   │                                           pending_approval
    │   │   └── providers/
    │   │       └── doctor_registration_provider.dart
    │   │
    │   ├── admin/
    │   │   ├── screens/
    │   │   │   ├── admin_dashboard_screen.dart
    │   │   │   ├── pending_approvals_screen.dart    ← Doctor approval queue
    │   │   │   ├── manage_villages_screen.dart
    │   │   │   ├── add_village_sheet.dart
    │   │   │   ├── manage_health_centers_screen.dart
    │   │   │   ├── add_health_center_sheet.dart
    │   │   │   ├── manage_doctors_screen.dart
    │   │   │   ├── view_patients_screen.dart
    │   │   │   ├── monitor_appointments_screen.dart
    │   │   │   └── role_management_screen.dart
    │   │   └── providers/
    │   │       └── admin_providers.dart
    │   │
    │   ├── doctor/
    │   │   ├── screens/
    │   │   │   ├── doctor_dashboard_screen.dart
    │   │   │   ├── appointment_requests_screen.dart
    │   │   │   ├── upcoming_appointments_screen.dart
    │   │   │   ├── appointment_history_screen.dart
    │   │   │   ├── set_availability_screen.dart     ← Calendar + health centre
    │   │   │   │                                        dropdown + slot builder
    │   │   │   └── doctor_profile_screen.dart
    │   │   └── providers/
    │   │       └── doctor_providers.dart
    │   │
    │   ├── patient/
    │   │   ├── screens/
    │   │   │   ├── patient_dashboard_screen.dart
    │   │   │   ├── book_appointment_screen.dart     ← Multi-step booking flow
    │   │   │   ├── my_appointments_screen.dart
    │   │   │   ├── health_records_screen.dart
    │   │   │   └── patient_profile_screen.dart
    │   │   └── providers/
    │   │       └── patient_providers.dart
    │   │
    │   └── health_center/
    │       ├── screens/
    │       │   ├── operator_dashboard_screen.dart
    │       │   ├── register_patient_screen.dart
    │       │   ├── book_on_behalf_screen.dart
    │       │   ├── manage_availability_screen.dart  ← Operator fallback availability
    │       │   └── assisted_appointments_screen.dart
    │       └── providers/
    │           └── health_center_providers.dart
    │
    ├── shared/
    │   ├── widgets/
    │   │   ├── large_button.dart
    │   │   ├── rural_card.dart
    │   │   ├── slot_picker_widget.dart              ← Reads doctor_availability,
    │   │   │                                           filters booked slots,
    │   │   │                                           shows health centre name
    │   │   ├── appointment_card.dart
    │   │   ├── status_badge.dart
    │   │   ├── village_picker.dart                  ← Searchable village dropdown
    │   │   ├── health_center_picker.dart            ← Filtered by doctor's villages
    │   │   ├── language_switcher.dart
    │   │   ├── confirmation_dialog.dart
    │   │   └── nmr_hpr_info_card.dart               ← Admin approval display
    │   │
    │   └── l10n/
    │       ├── en.json                              ← English (complete at launch)
    │       ├── mr.json                              ← Marathi (complete at launch)
    │       └── hi.json                              ← Hindi (complete at launch)
    │
    └── assets/
        ├── icons/                                   ← SVG icons (all UI actions)
        └── images/                                  ← App logo, illustrations
```

### Critical Architecture Rule

`FirestoreService` in `core/services/firestore_service.dart` is the **only file** in the project that imports `cloud_firestore`. No feature screen, provider, or widget ever calls `FirebaseFirestore.instance` directly. This is enforced by convention and, if needed, a custom lint rule. This pattern makes testing, debugging, and future migrations straightforward.

---

## 14. Step-by-Step Implementation Guide

Each step builds on the previous. Steps within a block can sometimes be parallelised by different team members, but the block ordering is strict — don't begin Block 2 work until Block 1 is complete and tested.

---

### Block 1 — Foundation (Do this first, do it completely)

The foundation is the non-negotiable starting point. Every feature in every module depends on it. Rushing the foundation creates compounding bugs throughout development.

---

**Step 1.1 — Firebase Project Setup**

Create the Firebase project once, correctly. This cannot be redone without recreating everything.

- Go to [console.firebase.google.com](https://console.firebase.google.com) → New Project → "gram-aarogya-seva"
- Enable Google Analytics: No (unnecessary for this project)
- Add Android app: package name `com.uba.gramaarogya`
- **Enable Firestore:** Cloud Firestore → Create database → Select **`asia-south1` (Mumbai)** → Start in **test mode** (you will harden this with rules in Step 1.4)
- Enable Firebase Auth → Sign-in methods → Phone (enable)
- Enable Cloud Messaging (auto-enabled with Android app)
- Enable Cloud Functions (requires upgrading to Blaze plan — billing is pay-as-you-go beyond free tier thresholds; at this project's scale, cost will remain ₹0)

**Step 1.2 — Flutter Project Creation & FlutterFire Setup**

```bash
flutter create gram_aarogya_seva \
  --org com.uba \
  --project-name gram_aarogya_seva \
  --platforms android

cd gram_aarogya_seva
dart pub global activate flutterfire_cli
flutterfire configure --project=gram-aarogya-seva
# Select Android only. Generates lib/firebase_options.dart
```

**Step 1.3 — Install All Dependencies**

Add all packages from Section 11 to `pubspec.yaml`. Then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
# Should complete with no errors. Fix any errors before proceeding.
```

**Step 1.4 — Deploy Firestore Security Rules**

Copy the complete rules from Section 12 to `firestore.rules`. Deploy immediately, before writing any app code:

```bash
firebase deploy --only firestore:rules
```

Open Firebase Console → Firestore → Rules → Rules Playground. Test these scenarios before proceeding:

- Unauthenticated read of `users/anyId` → should DENY
- Authenticated patient reading their own `users/{uid}` → should ALLOW
- Authenticated patient reading another user's document → should DENY
- Authenticated patient reading `villages/anyId` → should ALLOW (needed for village picker)
- Authenticated doctor reading `doctors/{ownId}` where status == "pending_approval" → should ALLOW

**Step 1.5 — Three-Language Localisation Foundation**

Set up easy_localization with all three language files. This must be done before any UI work, because every string in the app uses `tr()` from day one.

- Create `assets/l10n/en.json`, `mr.json`, `hi.json`
- Start with the keys below as the complete initial set (add more as features are built):

```json
{
  "app_name": "Gram Aarogya Seva",
  "select_language": "Select Language",
  "english": "English",
  "marathi": "मराठी",
  "hindi": "हिंदी",
  "continue_btn": "Continue",
  "enter_mobile": "Enter Mobile Number",
  "enter_otp": "Enter OTP",
  "resend_otp": "Resend OTP",
  "verify": "Verify",
  "logout": "Logout",
  "cancel": "Cancel",
  "confirm": "Confirm",
  "save": "Save",
  "loading": "Please wait...",
  "error_generic": "Something went wrong. Please try again.",
  "error_permission_denied": "You do not have permission to do this.",
  "slot_already_booked": "This slot was just booked. Please select another.",
  "no_slots_available": "No slots available for this date.",
  "booking_confirmed": "Appointment booked successfully.",
  "awaiting_approval_title": "Registration Under Review",
  "awaiting_approval_body": "Your registration has been submitted. An admin will review and approve your account. You will be notified once approved."
}
```

Configure `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('mr'),
        Locale('hi'),
      ],
      path: 'assets/l10n',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: GramAarogyaSevaApp()),
    ),
  );
}
```

**Step 1.6 — GoRouter + Role Guard Skeleton**

Create `app_router.dart` with all route paths as constants and stub `ConsumerWidget` screens for every route. The role guard must handle all redirect cases from the start.

The role guard must handle these states:
- Not authenticated → `/auth/phone`
- Authenticated, no Firestore user doc yet → create doc, then redirect
- `role == "doctor"` AND `doctors/{uid}.status == "pending_approval"` → `/doctor/awaiting-approval`
- `role == "doctor"` AND `doctors/{uid}.status == "active"` → `/doctor/dashboard`
- `role == "admin"` → `/admin/dashboard`
- `role == "patient"` → `/patient/dashboard`
- `role == "operator"` → `/operator/dashboard`

**Step 1.7 — Data Models (Freezed)**

Build all eight Freezed models from the schema in Section 8. For each model, run `build_runner` after creation.

```dart
// Example: doctor_model.dart
@freezed
class DoctorModel with _$DoctorModel {
  const factory DoctorModel({
    required String doctorId,
    String? userId,
    required String name,
    required String specialization,
    required String mobile,
    required String nmrId,
    required String hprId,
    required String aadhaarHash,
    required String aadhaarLastFour,
    String? abdmTxnId,
    required List<String> villages,
    required String status,
    String? rejectionNote,
    String? approvedBy,
    DateTime? approvedAt,
    required DateTime createdAt,
  }) = _DoctorModel;

  factory DoctorModel.fromJson(Map<String, dynamic> json) =>
      _$DoctorModelFromJson(json);
}
```

**Step 1.8 — FirestoreService Skeleton**

Create `firestore_service.dart` with all method signatures. Implement stubs that throw `UnimplementedError`. You will fill each method as you build the module that needs it. This forces all data access to go through one place from day one.

```dart
class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService(this._db);

  // ── VILLAGES
  Stream<List<VillageModel>> getActiveVillages() => throw UnimplementedError();
  Future<void> addVillage(VillageModel v) => throw UnimplementedError();
  Future<void> setVillageActive(String villageId, bool active) => throw UnimplementedError();

  // ── HEALTH CENTRES
  Stream<List<HealthCenterModel>> getHealthCentersByVillage(String villageId) => throw UnimplementedError();
  Stream<List<HealthCenterModel>> getHealthCentersByVillages(List<String> villageIds) => throw UnimplementedError();
  Future<void> addHealthCenter(HealthCenterModel c) => throw UnimplementedError();

  // ── USERS
  Future<UserModel?> getUser(String uid) => throw UnimplementedError();
  Future<void> createUser(UserModel u) => throw UnimplementedError();
  Future<void> updateUserRole(String uid, String role) => throw UnimplementedError();
  Future<void> updateFcmToken(String uid, String token) => throw UnimplementedError();

  // ── DOCTORS
  Stream<List<DoctorModel>> getActiveDoctors() => throw UnimplementedError();
  Stream<List<DoctorModel>> getDoctorsByVillage(String villageId) => throw UnimplementedError();
  Stream<List<DoctorModel>> getPendingApprovalDoctors() => throw UnimplementedError();
  Future<void> createDoctor(DoctorModel d) => throw UnimplementedError();
  Future<void> approveDoctorRegistration(String doctorId, String adminUid) => throw UnimplementedError();
  Future<void> rejectDoctorRegistration(String doctorId, String note) => throw UnimplementedError();
  Future<void> setDoctorActive(String doctorId, bool active) => throw UnimplementedError();

  // ── PATIENTS
  Stream<List<PatientModel>> getAllPatients() => throw UnimplementedError();
  Stream<List<PatientModel>> searchPatients(String query) => throw UnimplementedError();
  Future<PatientModel?> getPatientByUserId(String userId) => throw UnimplementedError();
  Future<void> createPatient(PatientModel p) => throw UnimplementedError();

  // ── AVAILABILITY
  Future<AvailabilityModel?> getAvailability(String doctorId, String date) => throw UnimplementedError();
  Stream<List<AvailabilityModel>> getAvailabilityRange(String doctorId, DateTime from, DateTime to) => throw UnimplementedError();
  Future<void> setAvailability(AvailabilityModel a) => throw UnimplementedError();

  // ── APPOINTMENTS
  Future<void> createAppointment(AppointmentModel a) => throw UnimplementedError(); // MUST use transaction
  Stream<List<AppointmentModel>> getAppointmentsByDoctor(String doctorId) => throw UnimplementedError();
  Stream<List<AppointmentModel>> getAppointmentsByPatient(String patientId) => throw UnimplementedError();
  Stream<List<AppointmentModel>> getAllAppointments() => throw UnimplementedError();
  Future<void> updateAppointmentStatus(String appointmentId, String status, {String? note}) => throw UnimplementedError();

  // ── NOTIFICATIONS
  Stream<List<NotificationModel>> getNotifications(String userId) => throw UnimplementedError();
  Future<void> createNotification(NotificationModel n) => throw UnimplementedError();
  Future<void> markNotificationRead(String notificationId) => throw UnimplementedError();
}
```

After Block 1 is complete, you have: a working Flutter app that connects to Firebase, has routing, all models compiled, security rules deployed, and localisation working. Nothing visible to users yet, but the entire foundation is solid.

---

### Block 2 — Authentication & Doctor Registration

**Step 2.1 — Phone OTP Flow (All Roles)**

Build `phone_input_screen.dart` and `otp_verification_screen.dart`. These screens serve all four roles — the OTP flow is identical regardless of role.

After OTP verification:
- Check if `users/{uid}` exists in Firestore
- If no → create user document with `role: "patient"` as default
- Then read role → GoRouter handles the redirect

**Step 2.2 — Doctor Registration Form**

Build `doctor_registration_screen.dart` as a multi-step form:

- **Step 1 — Basic Info:** Full name, specialisation (dropdown), mobile (pre-filled from auth)
- **Step 2 — Government IDs:** NMR ID (text field + format validator), HPR ID (text field), Aadhaar number (masked input, 12 digits)
- **Step 3 — Village Selection:** Multi-select list from `getActiveVillages()` stream. Doctor must select at least one village. These villages determine which health centres appear in their availability scheduler and which patients can book with them.
- **Step 4 — ABDM OTP:** "Verify your Aadhaar" button triggers `abdmRequestAadhaarOtp()` Cloud Function → OTP sent to Aadhaar-linked mobile → 6-digit input → verify via `abdmVerifyAadhaarOtp()` Cloud Function

On successful ABDM OTP verification:
- Hash Aadhaar (SHA-256) → store in `aadhaarHash`
- Store last four digits → store in `aadhaarLastFour` ("XXXX XXXX 1234")
- Create `doctors/{uid}` with `status: "pending_approval"`
- Update `users/{uid}.role` to "doctor"
- Create notification for all admins: "New doctor pending approval"
- GoRouter redirects doctor to `awaiting_approval_screen.dart`

**Step 2.3 — Awaiting Approval Screen**

Simple informational screen shown when a doctor's status is `pending_approval`. It should explain the process clearly ("Your registration has been submitted. An admin will review it shortly. You will receive a notification when it is approved."), show the doctor's submitted details, and have a logout button. It should listen to the doctor's Firestore document via a stream so it automatically navigates to the dashboard when `status` changes to `active`.

---

### Block 3 — Admin Module

Build admin first because admin is needed to: approve the first doctor, add villages, add health centres. Without admin working, no other module can be tested end-to-end.

**Step 3.1 — Admin Dashboard**

Live stat cards via Firestore streams:
- Pending doctor approvals (query `doctors` where `status == "pending_approval"`)
- Pending appointments (query `appointments` where `status == "pending"`)
- Active doctors count
- Registered patients count

Navigation buttons: Pending Approvals / Manage Villages / Manage Health Centres / Manage Doctors / View Patients / Monitor Appointments

**Step 3.2 — Pending Approvals Screen**

List of doctors with `status == "pending_approval"`. Each card shows name, specialisation, NMR ID, HPR ID, `aadhaarLastFour`, registered villages, submitted date.

Approve button → `ConfirmationDialog` → `approveDoctorRegistration()` → doctor status → "active" → FCM to doctor

Reject button → `ConfirmationDialog` with text field for rejection note → `rejectDoctorRegistration(doctorId, note)` → doctor status → "rejected" → FCM to doctor with note

**Step 3.3 — Village Management Screen**

List all villages (stream). Add Village: FAB → bottom sheet → name, taluka, district, state fields → `addVillage()`. Deactivate toggle per village with `ConfirmationDialog` ("Deactivating this village means new patients cannot register here and doctors cannot select it. Existing records are preserved.").

**Step 3.4 — Health Centre Management Screen**

List all health centres with their village name. Add Health Centre: FAB → bottom sheet → name, village dropdown (from active villages), address, phone → `addHealthCenter()`. Deactivate toggle per centre.

**Step 3.5 — Manage Doctors Screen**

All approved doctors (active + inactive). Card: name, specialisation, registered villages, status badge. Activate/deactivate with `ConfirmationDialog`. No delete.

**Step 3.6 — View Patients Screen**

Read-only list of all patients. Show name, village, mobile, registration source badge ("Self" or "Via Health Centre"). Search by name/village/mobile (client-side filter on the loaded stream).

**Step 3.7 — Monitor Appointments Screen**

Filter tabs: All / Pending / Accepted / Rejected / Completed. Each `AppointmentCard` shows patient name, doctor name, health centre, date, time slot, status badge, createdBy badge. Admin action: mark complete (only on accepted appointments, only in exceptional circumstances). ConfirmationDialog before any status change.

---

### Block 4 — Doctor Module

By now, there should be at least one approved doctor and at least one village + health centre added by admin.

**Step 4.1 — Doctor Dashboard**

Four navigation buttons with live badge counts where applicable. Pending requests badge reads `getAppointmentsByDoctor(doctorId)` filtered to `status == "pending"`.

**Step 4.2 — Set Availability Screen**

This screen is the most complex in the doctor module.

- `TableCalendar` widget for date selection
- On date selected: load existing `doctor_availability/{doctorId}_{date}` if it exists
- **Health Centre Dropdown (`HealthCentrePicker`):** Loads health centres from villages in `doctor.villages`. If a doctor is registered for 3 villages, this shows all active health centres across those 3 villages. Doctor selects which centre they will be at on this date.
- Time slot builder: text input to add a time slot (format: "09:00 AM") → adds to a local list displayed as deletable chips
- Save: writes `doctor_availability/{doctorId}_{date}` with the selected health centre and slot list

Important: if an availability document already exists for this date and has booked slots, the doctor can still modify the availability but the UI must show which slots are already booked and prevent removing booked slots. Warn the doctor before overwriting.

**Step 4.3 — Appointment Requests Screen**

Stream `getAppointmentsByDoctor(doctorId)` filtered to `pending`. Each card: patient name, date, time, health centre, reason, intake form summary.

Accept: `ConfirmationDialog` with optional prep instructions text field → `updateAppointmentStatus("accepted", note: prepInstructions)` → FCM to patient

Reject: `ConfirmationDialog` with required reason text field → `updateAppointmentStatus("rejected", note: rejectionReason)` → FCM to patient

**Step 4.4 — Upcoming Appointments Screen**

Stream filtered to `accepted`, sorted by date + time. Shows patient name, date, time, health centre, reason, prep instructions they were given. After appointment time has passed, "Mark Complete" button appears → `updateAppointmentStatus("completed")` → FCM to patient.

**Step 4.5 — Appointment History Screen**

Stream filtered to `completed` and `rejected`. Tap to expand: shows intake form, visit summary (if filled), prescription.

---

### Block 5 — Patient Module

**Step 5.1 — Patient Profile & Registration**

After OTP login for a new patient, collect: name, DOB, gender, village (VillagePicker), mobile (pre-filled), emergency contact name + phone. Save to `patients/{newId}` and link `userId`.

**Step 5.2 — Patient Dashboard**

Next appointment card (reads upcoming accepted appointments). Primary action buttons: Book Appointment / My Appointments / My Records / My Profile.

**Step 5.3 — Book Appointment Flow (Multi-Step)**

- **Step 1:** Reason selection — icon grid (🤒 Fever / 🔍 Checkup / 🔁 Follow-up / ❓ Other). Large tap targets, icon + Marathi/Hindi/English label.
- **Step 2:** Doctor selection — list of active doctors filtered to patient's village (`getDoctorsByVillage(patient.villageId)`). Card shows name, specialisation, today's/next availability summary.
- **Step 3:** Date selection — `TableCalendar`. Dates with available (unbooked) slots are highlighted.
- **Step 4:** Slot selection — `SlotPickerWidget` reads `doctor_availability/{doctorId}_{selectedDate}`, displays available slots. Each slot also shows the health centre name ("09:00 AM — Karanja PHC"). Patient taps a slot.
- **Step 5:** Intake form — 3 questions: What are your symptoms? (free text), How long have you had this? (free text), How severe does it feel? (mild / moderate / severe). These are pre-filled to the appointment record.
- **Step 6:** Confirmation screen — summary of all choices. LargeButton "Confirm Booking" → `createAppointment()` transaction → success screen with appointment summary.

**Step 5.4 — My Appointments Screen**

Tabs: Upcoming (pending + accepted) / History (completed + rejected). `AppointmentCard` for each. Cancel button on pending/accepted appointments more than 2 hours away → `ConfirmationDialog` → `updateAppointmentStatus("cancelled")`.

**Step 5.5 — Health Records Screen**

List of visit summaries from completed appointments. Shows doctor name, date, prescription text, next steps. Download/share as PDF is a Phase 2 feature.

---

### Block 6 — Operator Module

**Step 6.1 — Operator Dashboard**

Today's assisted bookings count (stream `getAllAppointments()` filtered to `createdBy == "health_center"` and today's date). Four buttons: Register Patient / Book for Patient / Manage Availability / Assisted Bookings.

**Step 6.2 — Register Patient**

Form: name, DOB, gender, village (VillagePicker), mobile. Save to `patients/{newId}` with `createdBy: "health_center"`, `createdByOperatorId: operator.uid`. `userId` is null (this patient may not have a phone account).

**Step 6.3 — Book on Behalf**

- Search patient: text input → `searchPatients(query)` → display results with name, village, mobile
- Select patient → proceed to same booking flow as patient module (Steps 2–6 of Book Appointment)
- `createAppointment()` with `createdBy: "health_center"`, `createdByOperatorId: operator.uid`
- All appointment cards system-wide show a "Via Health Centre" badge for these appointments

**Step 6.4 — Manage Doctor Availability (Operator Fallback)**

Same UI as doctor's Set Availability screen. Operator selects doctor from a dropdown of active doctors → sets availability as a fallback when the doctor cannot use the app themselves. `lastUpdatedBy` field on the availability document records the operator's uid.

**Step 6.5 — Assisted Appointments Screen**

Stream all appointments where `createdBy == "health_center"`. Filter to today by default. Date picker to change. Read-only — operators cannot cancel or reschedule.

---

### Block 7 — Notifications, Cloud Functions & Polish

**Step 7.1 — FCM Integration**

In `NotificationService`:
- Request FCM permission on app launch
- Get token and save to `users/{uid}.fcmToken`
- Handle foreground messages with `flutter_local_notifications`
- Handle background message tap to navigate to relevant screen

**Step 7.2 — Appointment Reminder Cloud Function**

```typescript
// functions/src/notifications.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Runs every hour (Cloud Scheduler)
export const sendAppointmentReminders = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Find all accepted appointments with date within the next 24 hours
    // that haven't had a reminder sent yet
    const snapshot = await db.collection('appointments')
      .where('status', '==', 'accepted')
      .where('reminderSent', '==', false)
      .get();

    const batch = db.batch();
    const notifications: Promise<any>[] = [];

    for (const doc of snapshot.docs) {
      const appt = doc.data();
      const apptDateTime = new Date(`${appt.date} ${appt.timeSlot}`);
      if (apptDateTime > now && apptDateTime <= in24h) {
        // Get patient's FCM token
        const patientUser = await db.collection('patients').doc(appt.patientId).get();
        const userId = patientUser.data()?.userId;
        if (userId) {
          const userDoc = await db.collection('users').doc(userId).get();
          const fcmToken = userDoc.data()?.fcmToken;
          if (fcmToken) {
            notifications.push(admin.messaging().send({
              token: fcmToken,
              notification: {
                title: 'Appointment Reminder',
                body: `Your appointment is tomorrow at ${appt.timeSlot}`,
              },
              data: { appointmentId: doc.id, type: 'appointment_reminder_24h' },
            }));
          }
        }
        // Mark reminder as sent
        batch.update(doc.ref, { reminderSent: true });
      }
    }

    await Promise.all(notifications);
    await batch.commit();
  });
```

Note: Add `reminderSent: Boolean` field to the appointment schema. Initialise to `false` on creation.

**Step 7.3 — Rural UX Audit**

Before any final testing, walk through every screen against this checklist:

- Every button: `LargeButton` with icon + text, minimum 56dp height, full width
- Every font: minimum 18sp body, minimum 22sp headings
- Every string: `tr()` — zero hardcoded strings in any language in any widget
- Every async call: loading indicator shown (use `isLoading` on `LargeButton`, or `Shimmer` skeleton for lists)
- Every error: user-friendly SnackBar message (not a Firebase error code or stack trace)
- Every destructive action: `ConfirmationDialog` with consequence clearly stated
- Every screen: Logout button visible in AppBar
- Language switcher accessible from every screen
- High-contrast colours (test in direct sunlight conditions if possible)
- All three language files complete — no missing translation keys

**Step 7.4 — Firestore Index Deployment**

Some queries require composite indexes. Create `firestore.indexes.json`:

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

Deploy: `firebase deploy --only firestore:indexes`

---

## 15. Risks, Mitigations & Hard Decisions

### Technical Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Double-booking race condition | Critical | Firestore transaction in `createAppointment()`. Tested with two simultaneous bookings before launch. No exceptions. |
| Firestore security rules too permissive | Critical | Deployed in Block 1 before any data write. Tested with Rules Simulator across all role combinations. |
| ABDM Sandbox OTP not delivered | High | ABDM Sandbox uses test Aadhaar numbers that always receive OTP. For production, ABDM reliability depends on UIDAI uptime — outside our control. The Cloud Function handles errors gracefully. |
| NHA production approval delay | Medium | ABDM Sandbox is fully functional for development and testing. Production ABDM approval process takes 4–8 weeks. Start the application process early. |
| FCM tokens going stale | Medium | Refresh `fcmToken` in Firestore on every login. Handle FCM delivery failures silently (user will see status change in-app via Firestore stream). |
| GoRouter redirect loop | High | Role guard must have explicit handling for every possible state including "user authenticated but Firestore document doesn't exist yet." Test all auth states at the start of Block 2. |
| `build_runner` failures (Freezed/Riverpod) | High for beginners | Run `dart run build_runner build --delete-conflicting-outputs` after every model or provider change. Never run the app without resolving build_runner errors. |
| Firestore `array-contains` limitation | Medium | Firestore cannot filter by multiple values in an array in a single query. The `doctors` query by village uses `array-contains` for one village. If a patient needs doctors from multiple villages (edge case), do multiple queries and merge client-side. |

### Hard Decisions Made

**Doctor availability is per-date, not per-week-recurring.** A doctor could have a different schedule every week — they might be at Village A on Monday this week but Village B on Monday next week. Per-date availability is more flexible and prevents incorrect slot display. Weekly recurring availability is a Phase 2 enhancement where the doctor can set a template and bulk-generate availability documents.

**Aadhaar is never stored in plaintext.** This is non-negotiable. Even the SHA-256 hash is a one-way representation — we never need to retrieve the original Aadhaar number. The `aadhaarLastFour` field exists only to give the admin a partial identifier during the approval review.

**ABDM for doctors only, not patients.** Requiring Aadhaar verification for patients adds friction that would exclude the most vulnerable users — those who may not have Aadhaar, may not remember their Aadhaar number, or whose Aadhaar-linked mobile has changed. Phone OTP is sufficient for patients.

**Health centre is attached to availability slots, not to the doctor document.** A doctor can work at different health centres on different days. Storing the health centre at the slot level is the correct data model. It means the patient always knows exactly where to go for their specific appointment.

**No record deletion for anyone.** Villages are deactivated. Doctors are deactivated. Appointments have a `status` of cancelled/rejected. The only data that ever disappears from a user's view is filtered out by status, not physically deleted. This preserves the audit trail and prevents accidental data loss.

---

## 16. Definition of Done — Production Checklist

### Infrastructure
- [ ] Firebase project uses region `asia-south1`
- [ ] Firestore security rules deployed and tested with Rules Simulator
- [ ] Composite indexes deployed (`firestore.indexes.json`)
- [ ] Cloud Functions deployed (ABDM proxy, reminder scheduler)
- [ ] ABDM Sandbox credentials stored in Firebase environment config (never in code)

### Authentication & Role Routing
- [ ] OTP login works for all four roles end-to-end
- [ ] Doctor registration completes with ABDM OTP verification
- [ ] Doctor in `pending_approval` status sees awaiting screen, not dashboard
- [ ] Approved doctor is automatically redirected to dashboard without re-login
- [ ] Role guard handles all auth states without redirect loops
- [ ] Logout clears session and redirects to phone input

### Admin Module
- [ ] Admin can add and deactivate villages
- [ ] Admin can add and deactivate health centres linked to villages
- [ ] Admin can view, approve, and reject pending doctor registrations (with note)
- [ ] Approved doctor receives FCM notification
- [ ] Rejected doctor receives FCM notification with rejection note
- [ ] Admin can activate/deactivate approved doctors
- [ ] Admin can view all patients (read-only, searchable)
- [ ] Admin can filter appointments by all five status values
- [ ] Admin can mark an accepted appointment as completed
- [ ] Stat cards on dashboard are live (stream-based, no manual refresh)

### Doctor Module
- [ ] Doctor's village selection during registration filters health centre dropdown in Set Availability
- [ ] Doctor can set availability with health centre selection for a specific date
- [ ] Saved availability is immediately visible to patients in slot picker
- [ ] Doctor can accept appointment with optional prep instructions
- [ ] Doctor can reject appointment with required reason
- [ ] Patient receives FCM on acceptance and rejection
- [ ] Doctor can mark appointment as completed
- [ ] Doctor cannot modify another doctor's availability or appointments

### Patient Module
- [ ] Patient booking flow completes end-to-end (reason → doctor → date → slot → intake → confirm)
- [ ] Slot picker shows health centre name alongside each available slot
- [ ] Slot picker hides already-booked slots correctly
- [ ] Booking transaction prevents double-booking (verified with concurrent test)
- [ ] Patient can cancel appointment more than 2 hours before it
- [ ] Patient cannot cancel appointment less than 2 hours before it
- [ ] Patient can view visit summary and prescription from completed appointments
- [ ] Patient receives FCM for acceptance, rejection, and 24-hour reminder

### Operator Module
- [ ] Operator can register a new patient (offline villager, no phone)
- [ ] Operator can search patients by name and mobile
- [ ] Operator can book on behalf of a patient (all booking steps)
- [ ] Appointments booked by operator show "Via Health Centre" badge in all views
- [ ] Operator can update doctor availability as fallback
- [ ] Operator can view today's assisted bookings

### Cross-Cutting
- [ ] All three languages (English, Marathi, Hindi) switch at runtime from any screen
- [ ] Zero hardcoded strings in any language in any widget file (all use `tr()`)
- [ ] All three language files (`en.json`, `mr.json`, `hi.json`) are complete — no missing keys
- [ ] Firestore offline persistence works: cached data readable with network off
- [ ] All buttons are `LargeButton` (56dp minimum height, full width, icon + text)
- [ ] All body text is minimum 18sp
- [ ] All async operations show loading indicator
- [ ] All errors show user-friendly SnackBar (no raw Firebase codes)
- [ ] All destructive actions show `ConfirmationDialog`
- [ ] Logout button visible in AppBar on every screen after login
- [ ] No Firestore read/write outside of `FirestoreService`
- [ ] App runs on Android 8.0+ (API level 26+) on low-end devices (2GB RAM)

---

*Document Version: 2.0 | Gram Aarogya Seva | Flutter + Firebase (asia-south1)*  
*ABDM Integration: Sandbox ready; Production requires NHA registration*  
*Infrastructure cost: ₹0/month recurring | One-time: ~₹1,500 Play Store*
