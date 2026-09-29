# Gram Aarogya Seva
## Document 1 — Project Progress & Complete Application Workflow

**Prepared for:** Project Review Panel
**Project:** Rural Healthcare Appointment Platform, Unnat Bharat Abhiyan
**Date:** 5 August 2026
**Audience:** Technical and non-technical reviewers

---

## 1. Project Overview

### 1.1 Purpose

Rural healthcare in India suffers from a coordination problem rather than a
medical one. Doctors travel between villages on different days. Villagers have
no reliable way to know when a doctor will visit, which health centre they will
be at, or whether a slot is free — so they travel and hope, or they delay care
until it becomes an emergency.

**Gram Aarogya Seva** lets any villager find out when a verified doctor will be
at their nearest health centre, book a confirmed time slot, and be told if
anything changes — on a low-end Android phone, over a slow connection, in
Hindi, Marathi or English.

### 1.2 Current Development Status

| Aspect | Status |
|---|---|
| Application build | **Feature-complete** for the planned launch scope |
| Screens built | **27** |
| User roles | **4** — Patient, Doctor, Admin, Operator |
| Languages | **3** — English, Marathi, Hindi (complete, 274 phrases each) |
| Automated tests | **94** application tests + **61** database security tests, all passing |
| Deployed to live servers | **No — see §1.5. This is the key remaining step.** |
| Ready for real users | **Not yet** — two setup items outstanding (§1.5) |

### 1.3 Completed Modules

| Module | Status |
|---|---|
| Login and identity (mobile OTP) | ✅ Complete |
| Patient module | ✅ Complete |
| Doctor module | ✅ Complete |
| Admin module | ✅ Complete |
| Operator (health-centre staff) module | ✅ Complete |
| Notifications (in-app + push) | ✅ Complete |
| Appointment reminders | ✅ Complete |
| Three-language support | ✅ Complete |
| Security and access control | ✅ Complete and independently tested |

### 1.4 Modules Under Development

| Item | Status |
|---|---|
| Photo storage improvement | Planned — photos currently stored inside the database |
| Usage analytics | Planned — nothing currently measures how many bookings complete |
| On-device testing of push notifications | Pending — cannot be proven without a real deployment |

### 1.5 Two Items Standing Between Us and Real Users

Stated plainly, because they matter more than anything else in this document:

**1. The application has never run against the live server.**
Everything has been built and tested against a local simulator. The code is
verified; the live behaviour is not. The first deployment always finds
something, and we have not yet had that opportunity.

**2. Mobile OTP login currently works only for pre-registered test numbers.**
The cause is a **project setting**, not a defect in the application: Google
requires an app's security fingerprint to be registered before it will send
OTP messages to arbitrary phone numbers. That registration has not been done.
It is roughly fifteen minutes of configuration work and requires no code
changes.

---

## 2. The Four Roles at a Glance

| Role | Who they are | What they do |
|---|---|---|
| **Patient** | A villager in a registered village | Books and cancels appointments, reads visit records |
| **Doctor** | A licensed NMR/HPR professional | Publishes availability, accepts or declines appointments, records visit outcomes |
| **Admin** | UBA programme coordinator | Approves doctors, manages villages and health centres, monitors the system |
| **Operator** | ASHA worker or health-centre desk staff | Registers and books for villagers who have no smartphone |

> **Note for the panel:** the brief asked about three roles. The application
> has a fourth — the **Operator**. It exists because a significant share of the
> intended users do not own a smartphone, and without a staffed route into the
> system they would be excluded entirely. It is documented in §7.

---

## 3. Authentication — Shared by All Roles

Every user enters the application the same way. There are no passwords
anywhere in the system.

```
App opens
   ↓
Splash Screen
   ↓
Mobile Number Entry  →  OTP sent by SMS
   ↓
OTP Verification
   ↓
System identifies the role
   ↓
Patient / Doctor / Admin / Operator dashboard
```

### 3.1 Splash Screen

| | |
|---|---|
| **Purpose** | Shows the app name and logo while the system checks whether the user is already signed in |
| **How reached** | Automatically, when the app opens |
| **Actions** | None — informational |
| **What happens next** | Already signed in → straight to their dashboard. Not signed in → mobile number screen |
| **Status** | ✅ Implemented |

### 3.2 Mobile Number Entry

| | |
|---|---|
| **Purpose** | Collect the user's mobile number so an OTP can be sent |
| **How reached** | From the splash screen when not signed in |
| **Information entered** | 10-digit Indian mobile number (+91 fixed) |
| **Actions** | Enter number and continue · switch language · tap "Register as Doctor" |
| **Validation** | Must be 10 digits beginning 6–9. Anything else is refused with a clear message before an SMS is sent |
| **Error cases** | Too many attempts, invalid number, no internet — each shown as a plain message in the user's own language, never a technical code |
| **Next screen** | OTP Verification |
| **Status** | ✅ Implemented |

### 3.3 OTP Verification

| | |
|---|---|
| **Purpose** | Confirm the person controls the mobile number they entered |
| **How reached** | After requesting an OTP |
| **Information entered** | 6-digit code |
| **Actions** | Enter code · resend after a 30-second countdown · go back |
| **Automatic behaviour** | On most Android phones the code is read automatically and the user is signed in without typing |
| **Validation** | Wrong code, expired code and network failure are each explained in the user's language |
| **What happens next** | First-time users get an account created automatically as a **Patient**. Returning users go to whichever dashboard matches their role |
| **Status** | ✅ Implemented — **but see §1.5**: real numbers cannot yet receive an OTP until the project setting is completed |

### 3.4 Logout

Available from every dashboard. Signing out also removes the notification
registration from the device — important because phones are frequently shared
in the target villages, and the next user must not receive the previous user's
appointment messages.

**Status:** ✅ Implemented

> **Password reset:** Not applicable. The system has no passwords — identity is
> proved by possession of the mobile number each time.

---

## 4. Patient Journeys

### 4.1 New Patient — First-Time Journey

```
Mobile number  →  OTP  →  Patient Dashboard (no profile yet)
                                  ↓
                        "Complete your profile" prompt
                                  ↓
                          Profile Screen (create)
                                  ↓
                          Patient Dashboard
                                  ↓
                      Book Appointment (3 steps)
                                  ↓
                        Appointment confirmed
```

A new patient signing in for the first time lands on the dashboard with an
amber card telling them their profile is incomplete. Booking is blocked until
the profile exists, because an appointment carries the patient's name and
village to the doctor.

### 4.2 Existing Patient — Returning Journey

```
App opens  →  Splash  →  Patient Dashboard (signed in already)
                              ↓
        ┌─────────────┬───────┴────────┬──────────────┐
        ↓             ↓                ↓              ↓
   Book appointment  Health Records  Notifications  Cancel an
                                                    appointment
```

A returning patient is taken straight to their dashboard — no login step,
because the session persists on the device.

### 4.3 Patient Screens

#### 4.3.1 Patient Dashboard

| | |
|---|---|
| **Purpose** | The patient's home. Shows who they are, their appointments, and the main actions |
| **How reached** | Automatically after signing in |
| **What is shown** | Profile card with name and **village name**; list of appointments, upcoming first; a notification bell with unread count |
| **Actions** | Book appointment · Health records · Edit profile · Register as doctor · Cancel an appointment · Change language · Log out · Pull down to refresh |
| **Empty state** | "No appointments yet" with an icon, rather than a blank screen |
| **Ordering** | Upcoming appointments appear first, soonest at the top; past ones follow underneath |
| **Status** | ✅ Implemented |

#### 4.3.2 Patient Profile

| | |
|---|---|
| **Purpose** | Create or update the patient's personal and medical details |
| **How reached** | From the dashboard — the profile card, the edit icon, or the prompt when booking without a profile |
| **Information entered** | Photo (optional) · full name · date of birth · gender · mobile · village · emergency contact name and number · allergies · long-term conditions |
| **Validation** | Name, date of birth and village are required. Mobile numbers, where entered, must be genuine 10-digit numbers — this applies to the emergency contact too, since that is the number somebody rings in an emergency |
| **Error cases** | If the village list has not loaded, saving is blocked **with an explanation** rather than silently doing nothing |
| **Next screen** | Returns to the dashboard with a confirmation message |
| **Status** | ✅ Implemented |

#### 4.3.3 Book Appointment — Three Steps

| | |
|---|---|
| **Purpose** | Book a confirmed slot with a verified doctor |
| **How reached** | "Book Appointment" on the dashboard |
| **Requires** | A completed profile and an internet connection |
| **Status** | ✅ Implemented |

```
Step 1: Choose a doctor
   Village filter (defaults to the patient's own village)
   List of approved, active doctors
        ↓
Step 2: Choose a date and time
   Next 8 days, starting today
   Available slots, with the health centre named
        ↓
Step 3: Reason and confirmation
   Reason · symptoms · duration · severity
   Summary card  →  Confirm
        ↓
   Appointment created with status "Pending"
   Doctor is notified
```

**Step 1 — Doctor selection.** The list is filtered to the patient's own
village by default, because that is almost always what they want. They can
widen it to all villages. If no doctor serves their village, the screen says
so plainly rather than showing an empty list.

**Step 2 — Date and slot.** Slots already booked by someone else are hidden.
**Slots earlier today are also hidden**, so a patient at 4pm is not offered a
9am appointment. The health centre name is shown above the slots — this is the
single most important piece of information in the product, because it tells the
villager where to physically go.

**Step 3 — Confirmation.** A summary card shows the doctor, date and time
before the patient commits.

| Situation | What the patient sees |
|---|---|
| No internet | Red banner at the top; the Confirm button is disabled and explains why |
| Someone books the slot first | "This slot was just booked. Please select another" — and they are returned to the slot list with their doctor and date kept |
| No availability on that date | "No availability for this date" |
| All slots taken | "All slots booked — try another date" |

#### 4.3.4 Health Records

| | |
|---|---|
| **Purpose** | Show what the doctor recorded at each completed visit |
| **How reached** | "Health Records" on the dashboard |
| **What is shown** | For each completed visit: date, doctor, health centre, the doctor's notes, the prescription, next steps and any follow-up date |
| **Empty state** | "Your completed visits with a doctor's summary will appear here" |
| **Long histories** | A "Load more" button reveals older visits |
| **Status** | ✅ Implemented |

> **On prescriptions:** the doctor records the prescription as written text when
> closing an appointment, and the patient reads it here. Uploading a scanned or
> printed prescription is **Not Yet Implemented**.

#### 4.3.5 Cancelling an Appointment

```
Dashboard  →  appointment card  →  Cancel  →  Confirmation dialogue  →  Cancelled
                                                                            ↓
                                                              Slot released for others
                                                              Doctor notified
```

Cancellation is allowed up to **2 hours before** the appointment. The card
shows one of three things, and never the wrong one:

| Situation | What is shown |
|---|---|
| More than 2 hours away | A Cancel button |
| Less than 2 hours away | "Cannot cancel within 2 hours of appointment time" |
| Already past | Nothing — the patient cannot act until the doctor records the outcome |

**Status:** ✅ Implemented

---

## 5. Doctor Journeys

### 5.1 New Doctor — Registration and Approval

```
Mobile number  →  OTP  →  Patient Dashboard
                              ↓
                    "Register as Doctor"
                              ↓
        ┌─────────────────────────────────────────┐
        │  Step 1  Name, specialisation, mobile   │
        │  Step 2  NMR ID, HPR ID, Aadhaar        │
        │  Step 3  Villages served                │
        │  Step 4  Aadhaar OTP verification       │
        └─────────────────────────────────────────┘
                              ↓
                  Submitted  →  Admin is notified
                              ↓
                    Awaiting Approval Screen
                              ↓
            ┌─────────────────┴─────────────────┐
            ↓                                   ↓
      Admin approves                      Admin rejects
            ↓                                   ↓
    Doctor Dashboard              Reason shown + Resubmit option
```

#### 5.1.1 Doctor Registration (4 steps)

| | |
|---|---|
| **Purpose** | Let a doctor register themselves with verifiable government credentials |
| **How reached** | "Register as Doctor" from the login screen or the patient dashboard |
| **Step 1** | Photo, full name, specialisation, mobile number |
| **Step 2** | NMR ID, HPR ID, Aadhaar number (entered masked) |
| **Step 3** | Which villages they serve — at least one required |
| **Step 4** | Aadhaar OTP verification through the government ABDM service |
| **Important note shown on screen** | The OTP goes to the mobile linked to the doctor's Aadhaar, which may differ from the phone in their hand |
| **Validation** | Each step validates before allowing the next. Aadhaar must be 12 digits; IDs must be present |
| **Privacy** | The Aadhaar number is **never stored**. It is converted into an irreversible code on the server and only the last four digits are kept for display |
| **Next screen** | Awaiting Approval |
| **Status** | ✅ Implemented — ABDM verification runs against the government **test** environment; production access requires an application to the National Health Authority (§10) |

#### 5.1.2 Awaiting Approval

| | |
|---|---|
| **Purpose** | Hold the doctor while an admin reviews their credentials |
| **What is shown** | Their submitted details and current status |
| **Automatic behaviour** | The moment an admin approves, the screen moves them to the doctor dashboard — no need to close and reopen the app |
| **If rejected** | The admin's written reason is displayed, with a **Resubmit** button that returns them to the approval queue |
| **Status** | ✅ Implemented |

### 5.2 Existing Doctor — Daily Journey

```
App opens  →  Doctor Dashboard
                    ↓
   ┌────────────┬───┴────────┬─────────────┐
   ↓            ↓            ↓             ↓
Set          Appointment   History      Profile
availability   requests
```

### 5.3 Doctor Screens

#### 5.3.1 Doctor Dashboard

| | |
|---|---|
| **Purpose** | The doctor's home — today's patients at a glance |
| **What is shown** | Greeting, today's appointment queue, counts of Pending / Accepted / Done, and a red badge showing how many requests are waiting |
| **Actions** | Manage availability · View appointments · History · Profile · Notifications · Language · Log out |
| **Empty state** | "No appointments today" |
| **Status** | ✅ Implemented |

#### 5.3.2 Manage Availability

| | |
|---|---|
| **Purpose** | Publish which times the doctor is available, and at which health centre |
| **How reached** | Doctor dashboard |
| **Actions** | Pick a date from a calendar · choose a health centre · tap time slots on or off · save · **Cancel All for Date** |
| **Slot times** | 14 preset times from 09:00 to 17:00 |
| **Protection** | A slot already booked by a patient **cannot be removed** — it is shown in red and locked |
| **Validation** | A health centre must be chosen before saving. The centre must be in a village the doctor serves |
| **Cancel All for Date** | Cancels every open appointment that day and notifies every affected patient. Intended for the most likely real-world problem: the doctor cannot travel |
| **Status** | ✅ Implemented |

#### 5.3.3 Appointment Requests & History

| | |
|---|---|
| **Purpose** | Accept, decline and close out appointments |
| **How reached** | Doctor dashboard |
| **Filters** | All · Pending · Accepted · Completed · Rejected · Cancelled · No-show |
| **What each card shows** | Patient name, date and time, reason, symptoms, health centre, and whether an operator booked it |
| **Status** | ✅ Implemented |

**Available actions depend on the appointment's state:**

| State | Actions | What happens |
|---|---|---|
| Pending | **Accept** (with optional preparation note) | Patient is notified; note appears on their card |
| Pending | **Reject** (reason required) | Patient is notified with the reason; **the slot is released** for someone else |
| Accepted, time not yet passed | None | Message explains the outcome can be recorded after the appointment time |
| Accepted, time passed | **Completed** (with visit summary) or **No-show** | Patient is notified; a completed visit with a summary becomes the patient's health record |

**Visit summary** captured on completion: doctor's notes, prescription, next
steps.

#### 5.3.4 Doctor Profile

| | |
|---|---|
| **Purpose** | View registered details and update the ones that may change |
| **Editable** | Photo (view / change / remove), name, specialisation, mobile |
| **Locked** | NMR ID, HPR ID, Aadhaar, villages and approval status — these were verified at registration and cannot be self-edited |
| **Status** | ✅ Implemented |

---

## 6. Admin Journeys

### 6.1 System Setup — The Very First Journey

```
First admin account created by the system administrator
                     ↓
              Admin Dashboard
                     ↓
              Add villages
                     ↓
        Add health centres to those villages
                     ↓
        System is ready for doctors to register
```

> The very first admin must be created directly on the server, because only an
> admin can grant the admin role. This is a one-time setup step.

### 6.2 Admin Screens

#### 6.2.1 Admin Dashboard

| | |
|---|---|
| **Purpose** | System overview and the gateway to all management screens |
| **What is shown** | Live counts: villages, active doctors, doctors awaiting approval, registered patients |
| **Navigation** | Seven management screens (below) |
| **Status** | ✅ Implemented |

#### 6.2.2 Pending Doctor Approvals

| | |
|---|---|
| **Purpose** | Review and decide on doctor registrations |
| **What is shown** | Name, specialisation, mobile, NMR ID, HPR ID, masked Aadhaar, number of villages, and whether Aadhaar verification succeeded |
| **Actions** | **Approve** (confirmation required) or **Reject** (written reason required) |
| **What happens next** | The doctor is notified either way. Approved doctors become visible to patients immediately; rejected doctors see the reason and may resubmit |
| **Empty state** | "No pending approvals" |
| **Status** | ✅ Implemented |

#### 6.2.3 Village Management

| | |
|---|---|
| **Purpose** | Maintain the villages the programme covers |
| **Actions** | Add a village (name, taluka, district, state) · deactivate one |
| **Important rule** | Villages are **never deleted**, only deactivated — so historical appointments keep making sense |
| **Status** | ✅ Implemented |

#### 6.2.4 Health Centre Management

| | |
|---|---|
| **Purpose** | Maintain the health centres where doctors hold clinics |
| **Actions** | Add a centre (name, village, address, phone) · filter by village · deactivate |
| **Status** | ✅ Implemented |

#### 6.2.5 Manage Doctors

| | |
|---|---|
| **Purpose** | Oversee all registered doctors |
| **What is shown** | Name, specialisation, mobile, NMR/HPR IDs, number of villages, current status |
| **Actions** | Activate or deactivate a doctor, each with a confirmation step |
| **Effect** | A deactivated doctor immediately disappears from every patient's booking list |
| **Status** | ✅ Implemented |

#### 6.2.6 View Patients

| | |
|---|---|
| **Purpose** | Look up a registered patient |
| **Actions** | Search by name |
| **What is shown** | Name, date of birth, gender, mobile, village name |
| **Limitation** | Search is case-sensitive — "suresh" will not find "Suresh" |
| **Status** | ✅ Implemented |

#### 6.2.7 Monitor Appointments

| | |
|---|---|
| **Purpose** | System-wide view of every appointment |
| **Actions** | Filter by any of the six states · load more |
| **Status** | ✅ Implemented |

#### 6.2.8 Role Management

| | |
|---|---|
| **Purpose** | Promote a user to Operator or Admin |
| **Actions** | Search by phone number, then change the role with confirmation |
| **Deliberate restriction** | An admin **cannot** grant the Doctor role here. Doctor accounts are only created through the registration flow, because that is what carries the credential verification |
| **Status** | ✅ Implemented |

---

## 7. Operator Journeys

The operator is the route into the system for villagers who have no smartphone.

```
Operator Dashboard
        ↓
   ┌────────────┬────────────┬──────────────┬──────────────┐
   ↓            ↓            ↓              ↓
Register a   Book for a   Assisted      Manage a doctor's
patient      patient      appointments  availability
```

| Screen | Purpose | Status |
|---|---|---|
| **Operator Dashboard** | Today's assisted bookings and the four actions | ✅ Implemented |
| **Register Patient** | Register a walk-in villager. Mobile number is optional, because many have no phone. Warns if a patient with that number already exists | ✅ Implemented |
| **Book for Patient** | Find a patient by mobile, then run the same booking flow on their behalf. The appointment is marked as booked by the health centre | ✅ Implemented |
| **Assisted Appointments** | Everything this operator booked, with the ability to cancel. Appointments for patients with no phone are flagged **"No phone — inform the patient in person"** | ✅ Implemented |
| **Manage Availability** | Publish a doctor's slots on their behalf when the doctor cannot use the app | ✅ Implemented |

---

## 8. Notifications

### 8.1 How Users Are Informed

Every important event produces both a **message inside the app** and a **push
notification to the phone**.

| Event | Who is told |
|---|---|
| New doctor registration submitted | Admins |
| Doctor approved | The doctor |
| Doctor rejected (with reason) | The doctor |
| Appointment booked | The doctor |
| Appointment accepted | The patient |
| Appointment rejected (with reason) | The patient |
| Appointment cancelled | The other party |
| Visit completed | The patient |
| Marked as no-show | The patient |
| **Reminder, 24 hours before** | The patient |

### 8.2 Notification Inbox

| | |
|---|---|
| **How reached** | Bell icon on every dashboard, showing an unread count |
| **Actions** | Read one · mark all as read |
| **Language** | Each message is written in the recipient's chosen language at the moment it is created |
| **Status** | ✅ Implemented — push delivery has not yet been proven on a physical phone, because that requires a live deployment |

---

## 9. Cross-Cutting Behaviour

| Behaviour | Detail | Status |
|---|---|---|
| **Language switching** | English, Marathi, Hindi from any screen; takes effect immediately | ✅ |
| **Works without internet** | Appointments, records and schedules remain readable offline from the phone's cache | ✅ |
| **Honest about connectivity** | Booking and cancelling require internet. The app disables the button and explains why, rather than pretending to succeed | ✅ |
| **Nothing is ever deleted** | Cancellations and deactivations change status only, preserving the record | ✅ |
| **Large text and buttons** | Designed for low-literacy users on small screens | ✅ |
| **Forced update** | If a critical fix ships, older versions can be blocked from running | ✅ |
| **Crash reporting** | Crashes on real devices are reported automatically | ✅ |

---

## 10. Current Development Progress

### 10.1 Completed Features

- Mobile OTP login for all four roles
- Patient: profile, booking, cancellation, health records
- Doctor: self-registration with government ID verification, approval workflow, availability publishing, appointment handling, visit summaries, whole-day cancellation
- Admin: doctor approvals, village and health-centre management, doctor oversight, patient lookup, appointment monitoring, role management
- Operator: patient registration, assisted booking, assisted cancellation, availability fallback
- Notifications: in-app inbox, push delivery, 24-hour reminders
- Three complete languages
- Security rules with 61 independent tests
- 94 automated application tests

### 10.2 Features Under Development

| Feature | Note |
|---|---|
| Photo storage | Photos are stored inside the database, which makes lists slower to load on weak connections. Moving them to dedicated file storage is planned |
| Usage analytics | Nothing currently measures how many patients complete a booking |

### 10.3 Planned Features

| Feature | Status |
|---|---|
| Uploading scanned prescriptions or lab reports | Not Yet Implemented |
| Doctor–patient messaging | Not Yet Implemented — deferred by design |
| Follow-up booking in one tap | Not Yet Implemented |
| Family or dependant profiles | Not Yet Implemented |
| Weekly repeating availability | Not Yet Implemented |
| Reports and charts for admins | Not Yet Implemented |
| Dedicated Settings screen | Not Yet Implemented — language and logout live in the top bar |
| Video consultation | Out of scope by decision |
| Payments | Out of scope — care at these centres is free or government-subsidised |

### 10.4 Explicitly Not Built

To avoid any misunderstanding at review:

- There is **no** payment or billing feature
- There is **no** video or voice consultation
- There is **no** map or navigation feature
- There is **no** separate reports module
- There is **no** password — identity is proved by mobile OTP each time

---

## 11. Known Limitations

| # | Limitation | Impact | Resolution |
|---|---|---|---|
| 1 | **Not yet deployed to live servers** | Real behaviour unproven | Half a day of deployment and walkthrough |
| 2 | **OTP works only for test numbers** | Real users cannot yet log in | ~15 minutes of project configuration; no code change |
| 3 | Government ABDM verification uses the test environment | Doctor credentials are not yet verified against live records | Application to the National Health Authority, 4–8 weeks |
| 4 | Photos stored inside the database | Slower lists on weak connections | Move to dedicated file storage |
| 5 | Patient search is case-sensitive | Admin must match capitalisation | Small change, planned |
| 6 | Every approved doctor can see every patient record | Acceptable at single-village scale; needs narrowing before expansion | Planned before multi-district rollout |
| 7 | Push notifications unverified on a physical phone | Cannot be tested without deployment | Follows item 1 |
| 8 | Only one server environment exists | Testing and real use would share a database | Create separate test and live environments |

---

## 12. Future Roadmap

| Phase | Work | Timing |
|---|---|---|
| **1 — Go live on test servers** | Deploy; complete OTP configuration; walk one appointment end to end | Immediate |
| **2 — Prepare for real users** | Separate test and live environments; automated release process; verify push on real phones | ~1 week |
| **3 — Release readiness** | Google Play listing in three languages; privacy policy; testing on low-end phones; begin the NHA application | ~2–3 weeks |
| **4 — Village pilot** | One village, one doctor, one operator, supported in person | ~5 weeks |
| **5 — Review and expand** | Act on pilot findings, then consider a second village | ~8 weeks |

> Two items should start immediately even though they belong to later phases,
> because their timing is outside our control: the **National Health Authority
> application** (4–8 weeks) and a **mobile signal survey at the target health
> centre**. Booking requires a live connection; if the centre has no usable
> signal, the operator route does not work, and no amount of development fixes
> that.

---

## 13. Presentation Talking Points

### Opening
- Rural healthcare fails on coordination, not medicine — patients cannot find out when a doctor will be in their village
- Four roles, three languages, built for a low-end phone on a slow connection
- 27 screens, all four modules complete

### Patient Module
- A villager books a confirmed slot in under three minutes
- The health centre **name** is shown before booking — that is the single most useful fact in the product
- The app is honest about connectivity: it disables booking offline rather than faking success
- Cancellation is allowed up to two hours before, and the slot immediately returns to the pool

### Doctor Module
- Doctors register themselves using government NMR and HPR IDs, verified by Aadhaar OTP
- The Aadhaar number is never stored — only an irreversible code and the last four digits
- No doctor is visible to patients until an admin approves them
- One button cancels an entire day and notifies every affected patient — the most likely real-world problem

### Admin Module
- Villages and health centres are the foundation; everything else hangs off them
- Nothing is ever deleted, only deactivated, so history stays intact
- Admins cannot create doctor accounts directly — that would bypass credential verification

### Operator Module
- Many intended users own no smartphone; the operator is their route in
- Patients with no phone are flagged so staff know to inform them in person

### Engineering Quality
- 94 application tests and 61 independent security tests, all passing
- Security is enforced on the server, not in the app, so it holds even if the app is tampered with
- Complete translations in all three languages, kept exactly in step

### Honest Status
- Everything is built; nothing is live yet
- Two setup items stand between us and real users — one takes fifteen minutes, the other is a government application we should start this week
- The pilot plan is one village, one doctor, supported in person — not a wide launch

---

## 14. Completeness Check

| Check | Result |
|---|---|
| Every user role covered | ✅ Patient, Doctor, Admin, Operator |
| Every screen documented | ✅ 27 of 27 |
| Every navigation route documented | ✅ 26 of 26 |
| New and returning journeys separated | ✅ Patient and Doctor |
| Success, empty and error states covered | ✅ |
| Approval and rejection flows covered | ✅ |
| Logout flow covered | ✅ |
| Unimplemented features clearly marked | ✅ §10.3, §10.4 |
| No invented functionality | ✅ Verified against the source code |
