# Firebase Project Architecture & Context: gram-aarogya-dev

This document is the Firebase configuration and Firestore schema reference for the *gram-aarogya-dev* project, covering all four system actors: **Patients**, **Doctors**, **Operators**, and **Admins**.

> [!IMPORTANT]
> **Who may write what changed.** Every mutation whose correctness spans more
> than one document — booking, cancellation, appointment status transitions,
> doctor registration, availability — is performed by a Cloud Function and is
> *denied to clients* by `firestore.rules`. The "Rules" line under each
> collection below reflects that. See `TECHNICAL_ASSESSMENT.md` §A17-1 and the
> table in `README.md`.

---

## 1. Project Metadata & Setup

* **Project ID:** `gram-aarogya-dev`
* **Project Number:** `377370846599`
* **Billing Plan:** Spark (no-cost tier)
* **Default Database Location:** `asia-south1` (Mumbai)
* **Package Name (Android):** `com.uba.gram_aarogya_seva`
* **Bundle ID (iOS):** `com.uba.gramaarogya`

---

## 2. Authentication Flow & Role Resolution

* **Primary Auth Method:** Firebase Phone Auth (`+91` OTP verification).
* **Role Management (`/users/{userId}`):**
  - Roles: `'patient'` (default), `'doctor'`, `'operator'`, `'admin'`.
  - Roles dictate client-side navigation (`GoRouter`) and server-side Firestore security rules.
* **Actor Initialization & Navigation:**
  - **Patient**: Phone Login → Check `/users/{uid}` (create if missing with `role: 'patient'`) → Patient Dashboard.
  - **Doctor**: Tap "Doctor Registration" → Complete 4-Step Registration → Creates `/doctors/{uid}` (`status: 'pending_approval'`) and `/users/{uid}` (`role: 'doctor'`) → Awaiting Approval Screen → Admin sets status to `'active'` → Doctor Dashboard.
  - **Operator / Admin**: Log in → Role verified from `/users/{uid}` → Operator / Admin Dashboard.

---

## 3. Comprehensive Database Schema (Cloud Firestore)

### 1. `users`
Central user registry and RBAC mapping.
* **Path:** `/users/{userId}` *(userId = Auth UID)*
* **Rules:** Owner creates their own document on first login, forced to `role: 'patient'`. Owner may edit any field *except* `role`; only an Admin may change `role`, and only on its own. Promotion to `doctor` happens inside `submitDoctorRegistration`.
* **Fields:**
  - `uid` (String): Auth UID
  - `role` (String): `'patient' | 'doctor' | 'operator' | 'admin'`
  - `phone` (String): 10-digit mobile number
  - `fcmToken` (String, optional): Firebase Cloud Messaging push token
  - `name` (String): Display name
  - `language` (String): `'en' | 'mr' | 'hi'` — notifications are localised into this at creation time
  - `createdAt` (Timestamp): Server timestamp, written once on creation
  - `updatedAt` (Timestamp): Server timestamp

### 2. `doctors`
Professional doctor profiles, government credential hashes, assigned villages, and approval state.
* **Path:** `/doctors/{doctorId}` *(doctorId = Auth UID)*
* **Rules:** Read allowed if `status == 'active'` OR caller is owner/admin/operator. **Create is denied to clients** — the profile is written by `submitDoctorRegistration` together with the role promotion and the Aadhaar hash. Owner may update non-credential fields; only an Admin may change `status` and the approval fields.
* **Fields:**
  - `doctorId` (String): Auth UID
  - `name` (String): Full doctor name (e.g. `"Dr. Ramesh Sharma"`)
  - `specialization` (String): e.g. `"General Physician"`, `"Paediatrician"`
  - `mobile` (String): 10-digit phone
  - `nmrId` (String): National Medical Register ID
  - `hprId` (String): Health Professional Registry ID
  - `aadhaarHash` (String): HMAC-SHA-256 hash of Aadhaar number
  - `aadhaarLastFour` (String): Last 4 digits of Aadhaar (for display)
  - `abdmTxnId` (String, optional): ABDM verification transaction ID, recorded server-side
  - `abdmVerified` (Boolean): false when the deployment ran with `ABDM_VERIFICATION_REQUIRED=false` while awaiting NHA credentials — visible to the approving admin
  - `photoBase64` (String, optional): Base64 string of profile photo
  - `villages` (Array of Strings): List of `villageId`s served by this doctor
  - `status` (String): `'pending_approval' | 'active' | 'inactive' | 'rejected'`
  - `rejectionNote` (String, optional): Reason if rejected by Admin
  - `approvedBy` (String, optional): Admin UID who approved
  - `approvedAt` (Timestamp, optional): Time of approval
  - `createdAt` (Timestamp): Server timestamp
  - `updatedAt` (Timestamp): Server timestamp

### 3. `doctor_availability`
Date-based slot availability configured per doctor and assigned health center.
* **Path:** `/doctor_availability/{doctorId}_{date}` *(date format: `YYYY-MM-DD`)*
* **Rules:** Read allowed by all authenticated users. **All writes are denied to clients.** `setDoctorAvailability` merges already-booked slots forward so they cannot be dropped, and `bookAppointment` flips a single slot inside the same transaction that creates the appointment.
* **Fields:**
  - `doctorId` (String): Auth UID of doctor
  - `healthCenterId` (String): Assigned health center ID for this day
  - `date` (String): `YYYY-MM-DD` schema date
  - `slots` (Array of Maps):
    - `time` (String): 24-hour `HH:mm`, e.g. `"09:00"`, `"14:30"`. Rendered as `9:00 AM` by `AppDateUtils.formatSlotForDisplay`; the parser also accepts the legacy `"09:00 AM"` form written by earlier builds.
    - `isBooked` (Boolean): `true | false`
    - `appointmentId` (String, optional): back-reference to the booking that holds the slot

### 4. `patients`
Demographic and medical profiles of registered patients.
* **Path:** `/patients/{patientId}` *(Auto-generated document ID)*
* **Rules:** Read allowed for Admin, Operator, Doctor, or the owner (`userId == request.auth.uid`). Create allowed for an Operator (walk-ins, `userId: null`) or for a user creating their own profile. Update allowed for Admin, Operator or owner — but `userId` is immutable, so a record can never be reassigned to a different person.
* **Fields:**
  - `patientId` (String): Firestore document ID
  - `userId` (String): Auth UID of patient (or operator if created by operator)
  - `name` (String): Full patient name
  - `dob` (String): Date of birth (`YYYY-MM-DD`)
  - `gender` (String): `'Male' | 'Female' | 'Other'` (SRS §7.5 documents lowercase; the capitalised form is what production data uses and is authoritative)
  - `mobile` (String, optional): Contact number
  - `villageId` (String): Assigned village ID
  - `photoBase64` (String, optional): Base64 photo string
  - `emergencyContact` (Map):
    - `name` (String)
    - `phone` (String)
  - `medicalBackground` (Map):
    - `allergies` (Array of Strings)
    - `conditions` (Array of Strings)
  - `createdAt` (Timestamp): Server timestamp
  - `updatedAt` (Timestamp): Server timestamp

### 5. `appointments`
Full appointment lifecycle record between Patient, Doctor, and Health Center.
* **Path:** `/appointments/{appointmentId}` *(Auto-generated document ID)*
* **Rules:** Read by the patient (`patientUserId`), the assigned doctor, an operator, or an admin. **All writes are denied to clients** — `bookAppointment`, `cancelAppointment`, `updateAppointmentStatus` and `cancelDoctorDay` own the state machine and the paired slot updates.
* **Fields:**
  - `appointmentId` (String): Document ID
  - `patientId` (String): Reference to `patients/{patientId}`
  - `patientUserId` (String): Auth UID of patient
  - `patientName` (String): Denormalized patient name for fast rendering
  - `doctorId` (String): Auth UID of assigned doctor
  - `healthCenterId` (String): Assigned health center
  - `villageId` (String): Patient/Center village ID
  - `date` (String): `YYYY-MM-DD`
  - `timeSlot` (String): 24-hour `HH:mm`, e.g. `"09:30"`
  - `slotStartAt` (Timestamp): absolute instant of the slot, computed server-side from `date` + `timeSlot` in Asia/Kolkata. This is what makes the 2-hour cancellation window and the reminder scheduler enforceable; string date/time cannot be compared.
  - `reason` (String): `"Fever" | "Checkup" | "Follow-up" | "Other"`
  - `status` (String): `'pending' | 'accepted' | 'rejected' | 'completed' | 'cancelled' | 'no_show'`
  - `createdBy` (String): `'self' | 'health_center'`
  - `createdByOperatorId` (String, optional): Operator UID if booked by operator
  - `prepInstructions` (String, optional): Instructions sent by doctor on accept
  - `rejectionReason` (String, optional): Required reason if doctor rejects
  - `cancelledAt` (Timestamp, optional)
  - `cancelledBy` (String, optional): UID of user who cancelled
  - `intakeForm` (Map):
    - `symptoms` (String)
    - `duration` (String)
    - `severity` (String: `'mild' | 'moderate' | 'severe'`)
  - `visitSummary` (Map, optional):
    - `notes` (String)
    - `prescription` (String)
    - `nextSteps` (String)
    - `followUpDate` (String, optional)
  - `reminderSent` (Boolean): Default `false`
  - `createdAt` (Timestamp)
  - `updatedAt` (Timestamp)

### 6. `villages`
Administrative list of rural villages covered by Gram Aarogya Seva.
* **Path:** `/villages/{villageId}`
* **Fields:** `villageId`, `name`, `taluka`, `district`, `pincode`, `isActive` (Boolean)

### 7. `health_centers`
Primary health centres linked to villages.
* **Path:** `/health_centers/{centerId}`
* **Fields:** `centerId`, `name`, `villageId`, `address`, `phone`, `isActive` (Boolean)

### 8. `notifications`
System alerts for status changes (appointments, approvals, reminders).
* **Path:** `/notifications/{notificationId}`
* **Rules:** Read by the recipient only. **Create is denied to clients** — documents are written by Cloud Functions, so the inbox records what the system did rather than what a client asserted. The recipient may update `isRead` and nothing else.
* **Fields:** `notificationId`, `userId`, `type`, `title`, `message`, `relatedId`, `isRead` (Boolean), `createdAt` (Timestamp)
* **Note:** copy is localised into the recipient's `users/{uid}.language` at creation time, because a stored notification is a historical record and cannot be re-translated later without its original parameters.

### 9. `abdm_rate_limits`
OTP cooldown **and** the server's record that an Aadhaar verification succeeded.
* **Path:** `/abdm_rate_limits/{uid}`
* **Rules:** No client access at all. If a client could write here it could forge its own verification.
* **Fields:** `lastRequestTime`, `requestedTxnId`, `aadhaarLastFour`, `verifiedTxnId`, `verifiedAt`

---

## 4. Required Composite Indexes

Ensure the following composite indexes exist in Firebase Console:

| Collection | Field 1 | Field 2 | Field 3 | Scope |
|---|---|---|---|---|
| `appointments` | `patientUserId` (ASC) | `date` (DESC) | `__name__` (DESC) | Collection |
| `appointments` | `doctorId` (ASC) | `date` (DESC) | `__name__` (DESC) | Collection |
| `appointments` | `doctorId` (ASC) | `status` (ASC) | `date` (DESC) | Collection |
| `appointments` | `createdByOperatorId` (ASC) | `date` (DESC) | `__name__` (DESC) | Collection |
| `doctors` | `status` (ASC) | `villages` (array-contains) | — | Collection |
| `appointments` | `doctorId` (ASC) | `date` (ASC) | — | Collection |
| `notifications` | `userId` (ASC) | `isRead` (ASC) | — | Collection |
| `notifications` | `userId` (ASC) | `createdAt` (DESC) | `__name__` (DESC) | Collection |

---

## 5. System Actor Execution Matrix

| Feature / Action | Patient | Doctor | Operator | Admin |
|---|:---:|:---:|:---:|:---:|
| **Self-Registration** | Automatic on OTP | 4-step Registration Form | Admin Assigned | Pre-configured |
| **Manage Profile** | Personal & Medical details | Editable basic info (Credentials read-only) | Managed by Admin | Full system |
| **Manage Availability** | View available slots | Set date slots & assign Health Center | View schedules | Override schedules |
| **Appointments** | Book & Cancel (2h window) | Accept (with prep info), Reject (required reason), Mark Complete / No-Show | Book for patients, Cancel on behalf | Monitor all |
| **Approval Management** | N/A | Receives approval status notification | N/A | Approve/Reject Doctor registrations |