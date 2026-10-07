You are taking over an existing Flutter + Firebase healthcare project called **GRAM AROGYA SEVA**.

Repository:
https://github.com/Soyal1007/gram-arogya-seva

Your job is NOT to redesign the project from scratch.

Your job is to **fully audit, complete, harden, enhance, and make the existing application genuinely functional end-to-end**, while preserving all working functionality and the existing architecture wherever it is technically sound.

The final result should be a **working, production-oriented rural healthcare platform**, not a collection of mock screens.

---

# 1. FIRST: AUDIT THE ENTIRE EXISTING PROJECT

Before changing anything:

1. Read the complete repository.
2. Inspect:
   - Flutter source
   - Firebase configuration
   - Firestore structure
   - Firestore security rules
   - Cloud Functions
   - Authentication
   - Providers
   - Models
   - Services
   - Routing
   - UI/screens
   - Localization
   - Tests
   - README
   - SRS
   - ROADMAP
   - technical documentation
3. Identify every currently implemented feature.
4. Identify which features are:
   - Fully functional
   - Partially functional
   - UI-only/mock
   - Backend-only
   - Broken
   - Missing
5. Do not replace functioning code unnecessarily.
6. Do not create duplicate implementations of existing services.
7. Reuse the existing architecture and naming conventions wherever possible.

Create an internal implementation checklist before modifying the code.

---

# 2. CORE REQUIREMENT

Every visible feature in the application must actually work.

Do NOT create:

- Fake buttons
- Placeholder screens
- Dummy success messages
- Hardcoded appointment results
- Fake doctor data
- Fake notifications
- Mock analytics presented as real analytics
- UI controls that do nothing
- "Coming soon" screens for features that are supposed to be implemented

If a feature appears in the UI, it must have the necessary:

Flutter UI
→ provider/state
→ service
→ Cloud Function/backend where appropriate
→ Firestore/storage
→ security rules
→ error handling
→ loading state
→ empty state
→ success state
→ failure state

---

# 3. PRESERVE THE EXISTING SECURITY MODEL

The current project uses Firebase and server-side Cloud Functions for important mutations.

Do NOT revert this architecture.

Sensitive or privileged operations must remain server-authoritative.

Never trust:

- user IDs supplied blindly by the client
- doctor approval status supplied by the client
- appointment ownership supplied by the client
- slot availability supplied by the client
- admin privileges supplied by the client
- role changes supplied by the client

Use authenticated Firebase users and server-side authorization.

Maintain:

- Firestore security rules
- Firebase App Check
- Cloud Functions validation
- Firestore transactions
- Crashlytics
- Remote Config
- secure secret handling

Never place private API keys, HMAC secrets, service credentials, or production secrets inside Flutter source code.

---

# 4. COMPLETE THE CURRENT PATIENT EXPERIENCE

Enhance the patient application without destroying the existing flow.

## Authentication

Support:

- Phone OTP
- OTP resend
- OTP timeout
- invalid OTP handling
- network failure handling
- logout
- session restoration
- account deletion/request deletion

Make authentication robust rather than just visually functional.

---

# 5. PATIENT PROFILE

Improve patient profiles.

Include:

- Full name
- Date of birth
- Age
- Gender
- Phone
- Village
- Health centre
- Address
- Emergency contact
- Preferred language
- Blood group
- Allergies
- Existing conditions
- Current medications
- Optional profile photo

Validate all fields properly.

Allow profile editing.

Do not expose unnecessary sensitive information to other users.

---

# 6. VILLAGE DATABASE — IMPORTANT

Create a proper structured village/health-centre system.

Do NOT hardcode villages inside Flutter.

Create Firestore collections such as:

villages
health_centres
districts
talukas

Use relationships such as:

District
→ Taluka
→ Village
→ Health Centre

The application must dynamically retrieve this data.

---

# 7. ADD REAL MAHARASHTRA VILLAGE DATA

Populate the initial database with a useful dataset of Maharashtra locations.

At minimum structure:

Maharashtra
→ District
→ Taluka
→ Village
→ Health Centre

Start with the project target region and expand the dataset systematically.

Do not invent fake villages.

Where exact government health-centre information is required, use authoritative government/public datasets.

Store:

- district
- taluka
- village name
- village code where available
- pincode where available
- latitude
- longitude
- health-centre name
- health-centre type
- address
- contact number where publicly available
- active/inactive status

Build the application so additional districts can be added later without changing application code.

---

# 8. VILLAGE SELECTION

Patient registration should allow:

District
→ Taluka
→ Village
→ Health Centre

Use dependent dropdown/search controls.

Example:

Select District
↓
Select Taluka
↓
Search/select Village
↓
Show available Health Centres
↓
Select preferred Health Centre

Do not load thousands of villages into memory unnecessarily.

Use search and pagination where appropriate.

---

# 9. PATIENT HOME

Create a useful rural-health dashboard.

Show:

- Greeting
- Profile completion
- Next appointment
- Appointment status
- Doctor information
- Health-centre information
- Notifications
- Health records
- Quick booking
- Emergency assistance
- Language selector

Keep the UI simple enough for first-time smartphone users.

---

# 10. DOCTOR DISCOVERY

Enhance doctor discovery.

Allow patients to search/filter by:

- Village
- Health centre
- Specialty
- Doctor name
- Available date
- Available time
- Language

Doctor cards should show:

- Name
- Specialty
- Verification status
- Health centre
- Village
- Languages
- Available days
- Next available slot

Do not display private verification information such as Aadhaar.

---

# 11. APPOINTMENT SYSTEM

Harden the existing appointment system.

Support:

- Create appointment
- View appointment
- Reschedule
- Cancel
- Accept
- Reject
- Complete
- No-show
- Doctor cancellation
- Health-centre cancellation
- Admin cancellation

Use server-side validation.

Prevent:

- double booking
- booking past dates
- booking unavailable slots
- booking inactive doctors
- booking outside allowed booking window
- unauthorized cancellation
- unauthorized status changes

Use Firestore transactions where race conditions are possible.

---

# 12. RESCHEDULING

Add proper appointment rescheduling.

Flow:

Existing appointment
→ Reschedule
→ Select new date
→ Select new available slot
→ Confirm
→ Atomically release old slot
→ Atomically reserve new slot
→ Update appointment
→ Notify patient
→ Notify doctor
→ Record audit event

Never release the old slot before the new slot has successfully been secured.

---

# 13. DOCTOR AVAILABILITY

Enhance doctor availability.

Support:

- Single-day availability
- Weekly recurring availability
- Multiple time slots
- Break periods
- Leave dates
- Holiday dates
- Health-centre-specific availability
- Maximum appointments per slot
- Emergency closure

Example:

Monday
09:00–12:00
14:00–17:00

Tuesday
10:00–13:00

etc.

Allow doctors to modify future availability without affecting already confirmed appointments.

---

# 14. DOCTOR MODULE

Enhance the doctor dashboard.

Include:

- Today's appointments
- Upcoming appointments
- Pending requests
- Completed visits
- Cancelled appointments
- No-show appointments
- Patient details required for treatment
- Availability management
- Leave management
- Profile
- Notifications
- Messaging

Doctor should be able to:

Accept appointment
Reject appointment with reason
Start consultation
Complete consultation
Mark no-show
Add clinical notes
Add prescription
Add follow-up
Refer patient

---

# 15. DIGITAL HEALTH RECORDS

Upgrade the current health-record functionality.

Each completed visit should support:

- Visit date
- Doctor
- Health centre
- Symptoms/reason
- Clinical notes
- Diagnosis
- Prescription
- Medicines
- Dosage
- Frequency
- Duration
- Instructions
- Follow-up date
- Referral
- Attachments

Patients should be able to view their historical records chronologically.

Doctors should only see records they are authorized to access.

---

# 16. PRESCRIPTION DOCUMENTS

Implement actual prescription file support.

Use Firebase Storage.

Support:

- PDF
- JPG
- PNG

Doctor:

Upload prescription
→ Save securely
→ Attach to visit record

Patient:

Open health record
→ View prescription
→ Download/share where appropriate

Do not expose public storage URLs.

Use authenticated access rules.

---

# 17. FOLLOW-UP APPOINTMENTS

Add:

"Book Follow-up"

button on completed consultations.

Automatically prefill:

- Doctor
- Health centre
- Patient
- Reason
- Relevant previous visit

Patient only needs to choose:

Date
→ Slot
→ Confirm

---

# 18. FAMILY / DEPENDENT PROFILES

Implement family members.

One account can manage:

- Self
- Child
- Parent
- Spouse
- Other dependent

Each dependent must have their own:

- Profile
- Appointments
- Health records
- Prescriptions

Clearly show whose appointment is being booked.

Do not mix family members' medical records.

---

# 19. OPERATOR MODULE

Improve assisted healthcare.

Operator should be able to:

- Search existing patients
- Register new patients
- Create patient profile
- Book appointments
- Reschedule appointments
- Cancel appointments
- View upcoming appointments
- View health-centre schedule
- Help patients retrieve records
- Print appointment details
- Send appointment confirmation

Maintain an audit trail showing:

Patient
Operator
Action
Timestamp
Health centre

Operators must NOT have unrestricted admin privileges.

---

# 20. ADMIN MODULE

Build a serious administration dashboard.

Include:

### Dashboard

Show real data:

- Total patients
- Active doctors
- Pending doctors
- Villages
- Health centres
- Today's appointments
- Completed appointments
- Cancelled appointments
- No-shows
- Appointment trends

Do not use fake numbers.

---

# 21. ADMIN ANALYTICS

Implement real analytics using Firestore data.

Charts:

- Appointments per day
- Appointments per village
- Doctor utilization
- Cancellation rate
- No-show rate
- Patient registrations
- Doctor registrations
- Health-centre activity
- Most requested specialties

Add date filters:

Today
7 days
30 days
90 days
Custom range

Avoid loading huge datasets directly into the client.

Use aggregated statistics where necessary.

---

# 22. ADMIN LOCATION MANAGEMENT

Admin should be able to manage:

Districts
Talukas
Villages
Health Centres

Operations:

Create
Edit
Activate
Deactivate
Search
Filter

Use soft deletion rather than destructive deletion where historical records depend on the entity.

---

# 23. DOCTOR VERIFICATION

Improve doctor verification.

Support:

- NMR verification
- HPR verification
- ABDM integration where credentials/API access exists
- Aadhaar verification where legally and technically appropriate
- Document verification
- Admin manual review
- Approval
- Rejection
- Resubmission

Do not claim a credential is "verified" merely because the user entered an ID.

Verification status must represent an actual verification result.

---

# 24. MESSAGING

Implement secure patient-doctor messaging.

Support:

- Text messages
- Appointment-linked conversations
- Read/unread status
- Message timestamps
- Basic moderation/reporting
- Message notifications

Only allow conversations between authorized patient/doctor pairs.

Do not make messaging an unrestricted social chat system.

---

# 25. NOTIFICATIONS

Enhance notifications.

Support:

- Appointment booked
- Appointment accepted
- Appointment rejected
- Appointment cancelled
- Appointment rescheduled
- Appointment reminder
- Doctor approval
- Doctor rejection
- Follow-up reminder
- Prescription uploaded
- New message
- Health-centre announcement

Provide:

- Push notification
- In-app notification
- Read/unread
- Mark all as read

Notifications must be generated from authoritative backend events.

---

# 26. REMINDERS

Implement:

- 24-hour appointment reminder
- 2-hour appointment reminder
- Follow-up reminder
- Medication reminder if medication schedule is available

Avoid duplicate notifications.

Use Cloud Scheduler / scheduled Cloud Functions where appropriate.

---

# 27. MEDICATION MANAGEMENT

Add medication tracking.

Patient can see:

Medicine
Dosage
Frequency
Duration
Instructions

Allow reminders.

Example:

Medicine: Paracetamol
Dose: 500 mg
Frequency: 2 times/day
Duration: 5 days

Do not generate medical recommendations using AI.

The system should only remind users about prescriptions provided by authorized healthcare professionals.

---

# 28. EMERGENCY / SOS

Add a simple emergency module.

Support:

- Emergency call
- Saved emergency contacts
- Nearest health centre
- Nearest hospital
- Location sharing
- Emergency instructions

Clearly distinguish this from normal appointment booking.

Do NOT pretend the application itself is an ambulance dispatch system unless an actual backend/partner integration exists.

---

# 29. HEALTHCARE FACILITY DIRECTORY

Create a searchable directory.

Facilities:

- Health centres
- PHCs
- Hospitals
- Clinics
- Pharmacies
- Diagnostic centres

Information:

Name
Type
Address
Phone
Village
Taluka
District
Coordinates
Opening hours
Services

Allow:

Call
Directions
View details

Use real verified data.

---

# 30. MAP INTEGRATION

Add map support for healthcare facilities.

Patients should be able to:

- View nearby facilities
- View health centres
- Open navigation
- See distance

Do not constantly track users in the background.

Only request location permission when necessary.

---

# 31. MULTILINGUAL SUPPORT

Maintain:

English
Marathi
Hindi

Ensure translations cover the ENTIRE application.

Do not leave:

"TODO"
"Coming soon"
English-only error messages
English-only validation

Translate:

Buttons
Errors
Notifications
Appointment statuses
Forms
Doctor information labels
Settings
Help content

---

# 32. RURAL ACCESSIBILITY

Optimize for rural users.

Include:

- Large touch targets
- Simple navigation
- High readability
- Clear icons
- Minimal text where possible
- Low-bandwidth optimization
- Offline cached information
- Retry buttons
- Helpful error messages
- Optional audio prompts

Do not make the UI unnecessarily sophisticated.

Healthcare usability is more important than flashy animations.

---

# 33. OFFLINE SUPPORT

Improve offline functionality.

Cache:

- User profile
- Upcoming appointment
- Health-centre information
- Doctor information
- Previous health records
- Notifications

Clearly indicate:

ONLINE
OFFLINE
SYNCING

Never tell the user an appointment was successfully booked while offline.

---

# 34. SEARCH

Implement proper search across:

Patients
Doctors
Villages
Health centres
Appointments
Health records

Use server-side/paginated queries where necessary.

Do not retrieve an entire Firestore collection just to perform client-side search.

---

# 35. AUDIT LOGGING

Implement audit logs for sensitive actions.

Record:

- Who performed the action
- Role
- Action
- Target
- Timestamp
- Relevant metadata

Examples:

Doctor approved
Appointment cancelled
Patient record accessed
Doctor profile modified
Village deactivated
Admin changed role

Audit logs should be append-only and restricted to authorized administrators.

---

# 36. DATA PRIVACY

Treat health information as highly sensitive.

Implement:

- Least-privilege Firestore rules
- Secure Storage rules
- Role-based access
- Patient ownership validation
- Doctor authorization
- Operator restrictions
- Admin restrictions
- Secure callable functions
- No sensitive data in logs
- No medical information in notification text unless necessary

Never expose Aadhaar numbers unnecessarily.

Never expose private medical records through public URLs.

---

# 37. ERROR HANDLING

Every network/backend operation must have:

Loading state
Success state
Empty state
Error state
Retry

Handle:

- No internet
- Firebase errors
- Timeout
- Permission denied
- Invalid input
- Function unavailable
- Authentication expiry
- Firestore unavailable
- Storage failure

Use user-friendly localized error messages.

Do not expose raw Firebase stack traces to users.

---

# 38. UI/UX ENHANCEMENT

Improve the existing UI without making it unnecessarily flashy.

Design goals:

- Professional
- Clean
- Trustworthy
- Healthcare-focused
- Rural-friendly
- Accessible
- Fast
- Consistent

Use a consistent design system for:

- Typography
- Buttons
- Cards
- Forms
- Dialogs
- Bottom navigation
- App bars
- Empty states
- Error states

Use subtle animations only where useful.

Do not turn a healthcare application into a gaming UI.

---

# 39. SECURITY TESTING

Review and strengthen:

Firestore rules
Storage rules
Cloud Functions authorization
Role validation
Appointment ownership
Patient record access
Doctor record access
Operator permissions
Admin permissions

Add tests for privilege escalation.

Attempt cases such as:

Patient tries to access another patient's records.
Patient tries to approve a doctor.
Doctor tries to modify another doctor's availability.
Operator tries to access admin functionality.
Doctor tries to access unrelated patient records.
User tries to manipulate appointment IDs.

All must fail securely.

---

# 40. TESTING

Create/expand automated tests.

Unit tests:

- Appointment logic
- Date validation
- Slot validation
- Profile validation
- Role validation
- Notification logic

Widget tests:

- Login
- Booking
- Cancellation
- Doctor approval
- Patient records

Integration tests:

Patient registration
→ Doctor approval
→ Availability
→ Booking
→ Acceptance
→ Consultation
→ Health record
→ Follow-up

Also test:

Cancellation
Rescheduling
No-show
Offline mode
Notification delivery

---

# 41. SEED DATA / DEVELOPMENT DATA

Create a controlled seed-data system.

Include:

- Sample admin
- Sample operators
- Sample doctors
- Sample patients
- Sample villages
- Sample health centres
- Sample appointments

Clearly separate DEVELOPMENT seed data from production data.

Never insert fake production healthcare information.

---

# 42. FIREBASE DEPLOYMENT READINESS

Verify:

Firebase Authentication
Firestore
Storage
Cloud Functions
FCM
App Check
Crashlytics
Remote Config

Make sure Cloud Functions compile and deploy.

Fix:

TypeScript errors
Flutter analyzer errors
Dependency conflicts
Firebase configuration problems

Document required environment variables and secrets.

Never commit secrets.

---

# 43. PERFORMANCE

Optimize:

- Firestore queries
- Pagination
- Images
- Firebase Storage
- Provider rebuilds
- App startup
- Offline cache
- Notification processing

Avoid unnecessary Firestore listeners.

Avoid loading entire collections.

Use indexes where required.

---

# 44. DATA MODEL

Review the existing schema.

Use consistent collections such as:

users
patients
doctors
operators
admins
villages
talukas
districts
health_centres
appointments
availability
health_records
prescriptions
medications
notifications
messages
audit_logs
facilities

Do not blindly create new collections if an equivalent existing collection already exists.

Migrate existing data safely if schema changes are necessary.

---

# 45. DOCUMENTATION

Update:

README.md
Architecture documentation
Firebase setup
Environment variables
Database schema
Cloud Functions
Deployment guide
Testing guide
Admin setup
Seed-data guide
Production checklist

Document every new feature.

---

# 46. DO NOT OVERENGINEER

Do not add unnecessary technology simply because it sounds impressive.

Prefer the existing:

Flutter
Firebase
Firestore
Cloud Functions
Firebase Storage
FCM
Riverpod

Only introduce another backend/service when there is a genuine technical reason.

---

# 47. IMPORTANT IMPLEMENTATION RULE

Work in phases.

Do NOT attempt to generate thousands of lines of code blindly in one pass.

Phase 1:
Audit and stabilize current implementation.

Phase 2:
Location/village infrastructure.

Phase 3:
Appointment and availability improvements.

Phase 4:
Patient health records and prescriptions.

Phase 5:
Messaging and notifications.

Phase 6:
Family/dependent profiles.

Phase 7:
Emergency and healthcare directory.

Phase 8:
Admin analytics.

Phase 9:
Security hardening.

Phase 10:
Testing and production deployment.

After each phase:

1. Run Flutter analyzer.
2. Run tests.
3. Fix errors.
4. Check Firebase rules.
5. Check Cloud Functions.
6. Check navigation.
7. Verify affected user flows.
8. Only then continue.

---

# 48. DEFINITION OF DONE

Do not consider the project complete because screens exist.

The project is complete only when:

PATIENT:

Register
→ Complete profile
→ Select village
→ Find doctor
→ View availability
→ Book
→ Receive confirmation
→ Receive reminder
→ Attend
→ View health record
→ View prescription
→ Book follow-up

DOCTOR:

Register
→ Verify
→ Admin approval
→ Configure availability
→ Receive appointment
→ Accept/reject
→ Consult
→ Add clinical record
→ Add prescription
→ Complete appointment
→ Manage follow-up

OPERATOR:

Register/search patient
→ Assist booking
→ Manage appointment
→ View health-centre schedule

ADMIN:

Manage users
→ Verify doctors
→ Manage villages
→ Manage health centres
→ Monitor appointments
→ View analytics
→ Manage facilities
→ Review audit logs

All of these must work against the actual Firebase backend.

---

# 49. FINAL QUALITY STANDARD

At the end, perform a complete end-to-end audit.

For every button, form, screen and workflow ask:

"Does this actually perform the intended action against the backend?"

If the answer is no, fix it.

Do not hide incomplete functionality.

Do not mark a feature complete merely because the UI exists.

Do not use placeholder data where real database data should be used.

Do not break existing working functionality while adding new features.

Do not remove security restrictions for convenience.

Do not expose private health information.

Do not invent medical functionality.

The final application should feel like a **real rural healthcare coordination product**, not a college project with a collection of screens.

At the end of the implementation, produce a final report containing:

1. Features completed
2. Features enhanced
3. Features still unavailable
4. Firebase changes
5. Firestore schema changes
6. Cloud Function changes
7. Security changes
8. New dependencies
9. Tests added
10. Known limitations
11. Deployment instructions
12. Production readiness checklist

Most importantly:

**Make the application functional first. Make it beautiful second.**