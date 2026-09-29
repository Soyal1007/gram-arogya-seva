# Gram Aarogya Seva
## Document 2 — Paid Services, Infrastructure & Cost Requirements

**Prepared for:** Project Review Panel
**Date:** 5 August 2026
**Audience:** Technical and non-technical reviewers

> **Pricing note.** All figures are indicative and were correct at the time of
> writing. Cloud pricing changes; every number below should be confirmed
> against the provider's current price list before any budget is committed.
> Rupee conversions assume approximately ₹84 to the US dollar.

---

## 1. Executive Summary

The project was deliberately designed to run at **near-zero recurring cost** at
village scale. That goal still holds.

| Category | Expected monthly cost |
|---|---|
| Cloud services (Firebase / Google Cloud) | **₹0** at the pilot's expected usage |
| One-time costs | **≈ ₹2,100** (Google Play developer account) |
| Optional / future services | ₹0 today |
| **Total recurring for the pilot** | **≈ ₹0 per month** |

The design achieves this by staying inside the free allowances every service
offers, and by choosing services whose free tiers are generous enough for a few
hundred users.

### 1.1 One Decision the Panel Must Confirm

The project needs Google's **Blaze plan**, not the free **Spark plan**.

This is not a request for spending — Blaze is *pay-as-you-go*, and at our usage
the bill is expected to be **₹0**. But the plan must be enabled, because:

| What we need | Available on Spark? |
|---|---|
| Cloud Functions (the code that books appointments) | ❌ **No** |
| Calling the government ABDM service | ❌ **No** |
| Scheduled appointment reminders | ❌ **No** |

**Without Blaze, the application cannot function at all.** Booking,
cancellation and doctor registration all run through Cloud Functions, which
Spark does not support.

> ⚠️ **Discrepancy to resolve.** A Firebase console summary provided to the team
> reports the project as being on the **Spark** plan, while the project owner
> has stated it is on **Blaze**. These cannot both be true. This must be
> confirmed in the Firebase console before deployment, as it is the difference
> between a working application and a non-functional one.

### 1.2 The Real Financial Risk

The risk is not the monthly bill. It is **an accident on a pay-as-you-go plan**
— a runaway loop, or someone abusing the SMS system. Three protections are
recommended in §7, all free, and all should be in place before the pilot.

---

## 2. Services Currently In Use

### 2.1 Firebase Authentication (Phone / OTP)

| | |
|---|---|
| **Purpose** | Proves a user controls a mobile number, and identifies them on every visit |
| **Why required** | Every role signs in this way. There are no passwords in the system |
| **Depends on it** | All four roles — the app cannot be used without it |
| **Mandatory / Optional** | **Mandatory** |
| **Free tier** | Approximately 10,000 SMS verifications per month for Indian numbers |
| **Free tier limits** | Beyond that, charged per SMS |
| **Paid pricing** | Roughly $0.01–0.06 per verification depending on route (≈ ₹1–5) |
| **Expected usage** | ~500 verifications/month at 500 users — comfortably free |
| **When an upgrade is needed** | Only past ~10,000 sign-ins per month, far beyond pilot scale |
| **Risk of staying free** | None at our scale. The genuine risk is **SMS abuse** — an attacker triggering thousands of OTPs and exhausting the allowance so real users cannot log in |
| **Recommended plan** | Included with Blaze; no separate purchase |
| **Alternatives** | Twilio, MSG91, Fast2SMS — all charge per SMS from the first message, so all are more expensive |
| **Advantages** | Free at our scale; built into the app framework; Google handles OTP generation, expiry and retry limits |
| **Disadvantages** | Tied to Google; SMS delivery in remote areas depends on the mobile network |

### 2.2 Cloud Firestore (Database)

| | |
|---|---|
| **Purpose** | Stores every record — patients, doctors, appointments, villages, health centres, notifications |
| **Why required** | It is the system's memory. It also lets the app work offline by keeping a copy on the phone |
| **Depends on it** | Every screen |
| **Mandatory / Optional** | **Mandatory** |
| **Free tier** | 50,000 reads/day · 20,000 writes/day · 1 GB stored |
| **Free tier limits** | Above these, charged per operation |
| **Paid pricing** | ≈ $0.06 per 100,000 reads, $0.18 per 100,000 writes (≈ ₹5 and ₹15) |
| **Expected usage** | 15,000–25,000 reads/day at 100 users — inside the free tier, but this is **the number to watch** |
| **When an upgrade is needed** | Reads are the first limit we would reach, likely somewhere between 300 and 500 active users |
| **Risk of staying free** | Exceeding the daily read limit causes the app to stop loading data until midnight. Three optimisations (§7.3) have already been designed to push this ceiling much higher |
| **Recommended plan** | Included with Blaze |
| **Alternatives** | Supabase (no Indian data centre); self-hosted PostgreSQL (₹500–800/month plus staff time) |
| **Advantages** | Data stored in Mumbai, meeting Indian data-residency expectations; offline support built in; no servers to maintain |
| **Disadvantages** | Costs scale with how often data is read, so careless screens get expensive |

### 2.3 Cloud Functions

| | |
|---|---|
| **Purpose** | Runs the trusted logic on Google's servers rather than on the phone — booking, cancellation, doctor registration, reminders |
| **Why required** | Two reasons. **Security:** the phone cannot be trusted to enforce rules such as "only cancel more than two hours ahead". **Correctness:** booking must create an appointment *and* reserve the slot together, or neither |
| **Depends on it** | Booking · cancellation · accept/reject · doctor registration · availability · reminders · ABDM verification |
| **Mandatory / Optional** | **Mandatory — and the reason Blaze is required** |
| **Free tier** | 2,000,000 calls/month, plus generous compute allowances |
| **Free tier limits** | **Not available on Spark at all** |
| **Paid pricing** | ≈ $0.40 per million calls beyond the free allowance |
| **Expected usage** | Under 20,000 calls/month at 500 users — about 1% of the free allowance |
| **When an upgrade is needed** | Realistically never at this project's scale |
| **Risk of staying free** | None, provided limits are capped (§7.1) |
| **Recommended plan** | Blaze, with a spending cap and instance limits |
| **Alternatives** | A rented server (₹500–800/month, plus maintenance and security patching) |
| **Advantages** | No servers to run; scales automatically; free at our volume |
| **Disadvantages** | Requires Blaze; a "cold start" adds 1–2 seconds to the first booking of a session |

### 2.4 Firebase Cloud Messaging (Push Notifications)

| | |
|---|---|
| **Purpose** | Tells a patient their appointment was accepted, or reminds them the day before |
| **Why required** | Without it, a patient learns of a change only by opening the app. On a shared phone with mobile data usually switched off, that fails the core promise |
| **Depends on it** | All notifications and the 24-hour reminder |
| **Mandatory / Optional** | **Mandatory for a good experience.** The app still works without it — every message is also stored in the in-app inbox |
| **Free tier** | **Unlimited and free** |
| **Paid pricing** | None |
| **Risk** | None financially. Delivery is best-effort, which is why the in-app inbox exists as a backstop |
| **Alternatives** | OneSignal (free tier available); SMS notifications (charged per message) |
| **Advantages** | Free, unlimited, already integrated |
| **Disadvantages** | Requires the phone to have internet at some point; some low-end phones aggressively restrict background delivery |

### 2.5 Cloud Scheduler

| | |
|---|---|
| **Purpose** | Runs the reminder job every hour |
| **Why required** | Sends the 24-hour appointment reminder |
| **Depends on it** | Reminder notifications |
| **Mandatory / Optional** | **Mandatory** for reminders; the rest of the app works without it |
| **Free tier** | 3 scheduled jobs free per month |
| **Paid pricing** | ≈ $0.10 per job per month beyond three |
| **Expected usage** | **1 job** — inside the free tier |
| **Risk of staying free** | None |
| **Note** | Requires Blaze |

### 2.6 Firebase Crashlytics

| | |
|---|---|
| **Purpose** | Reports automatically when the app crashes on a real phone |
| **Why required** | Pilot users will not file bug reports — they will simply stop using the app. Without this, a crash affecting one phone model is invisible |
| **Mandatory / Optional** | Strongly recommended |
| **Free tier** | **Completely free, unlimited** |
| **Paid pricing** | None |
| **Alternatives** | Sentry (free tier, then ~$26/month) |

### 2.7 Firebase App Check

| | |
|---|---|
| **Purpose** | Confirms requests come from our genuine app, not a script |
| **Why required** | The app's configuration is public by design. Without App Check, anyone could use it to hammer our database and exhaust the free allowance |
| **Mandatory / Optional** | Strongly recommended before public release |
| **Free tier** | **Free** (uses Google Play Integrity, also free) |
| **Paid pricing** | None |
| **Risk of not using it** | Someone could exhaust the daily free quota, taking the app offline for real users |

### 2.8 Firebase Remote Config

| | |
|---|---|
| **Purpose** | Lets us block outdated app versions without publishing a new release |
| **Why required** | Villagers do not update apps on their own, and there is no support desk. If a serious bug ships, this is the only lever available |
| **Mandatory / Optional** | Recommended |
| **Free tier** | **Free, unlimited** |
| **Paid pricing** | None |

### 2.9 ABDM / National Health Authority (Government)

| | |
|---|---|
| **Purpose** | Verifies a doctor's Aadhaar by OTP during registration |
| **Why required** | Establishes that the person registering is genuinely the licensed professional they claim to be |
| **Depends on it** | Doctor registration |
| **Mandatory / Optional** | Mandatory for verified doctor onboarding |
| **Cost** | **Free** — a government service |
| **Current state** | Using the free **test** environment |
| **What is needed** | An application to the National Health Authority for production access: app details, privacy policy, security assessment. **Takes 4–8 weeks and should be started immediately** |
| **Risk** | This is the longest lead-time item in the project and is outside our control |
| **Interim measure** | The system can run with a documented setting that marks a doctor as *not machine-verified*, so an approving admin can see the credential was checked by a human rather than by the government service |

### 2.10 Google Play Developer Account

| | |
|---|---|
| **Purpose** | Required to publish an Android app |
| **Mandatory / Optional** | **Mandatory** to distribute the app |
| **Cost** | **$25 one-time (≈ ₹2,100)** — not recurring |
| **Alternatives** | Distributing the installer file directly. Not recommended: no automatic updates, and users must disable a security setting to install |

---

## 3. Summary of Current Costs

| Service | Mandatory | Free tier covers us? | Expected cost |
|---|:--:|:--:|---|
| Firebase Authentication | Yes | ✅ | ₹0 |
| Cloud Firestore | Yes | ✅ (watch reads) | ₹0 |
| Cloud Functions | Yes | ✅ | ₹0 |
| Cloud Messaging | Recommended | ✅ Always free | ₹0 |
| Cloud Scheduler | Yes | ✅ 1 of 3 jobs | ₹0 |
| Crashlytics | Recommended | ✅ Always free | ₹0 |
| App Check | Recommended | ✅ Always free | ₹0 |
| Remote Config | Recommended | ✅ Always free | ₹0 |
| ABDM (government) | Yes | ✅ Free service | ₹0 |
| Google Play account | Yes | — | **₹2,100 one-time** |
| **Total recurring** | | | **₹0 per month** |

**Blaze must be enabled**, but at this usage the monthly invoice is expected to
be zero.

---

## 4. Potential Future Costs

Services **not currently used**, which may become necessary.

### 4.1 Cloud Storage (Likely — Next 1–2 Months)

| | |
|---|---|
| **Purpose** | Store profile photographs properly |
| **Why it will be needed** | Photos are currently kept inside database records. That makes every list slower to load, which matters most on the weak connections our users have |
| **Free tier** | 5 GB stored · 1 GB downloaded per day |
| **Paid pricing** | ≈ $0.026 per GB/month |
| **Expected usage** | Well inside the free tier |
| **Expected cost** | **₹0** |

### 4.2 Google Analytics for Firebase (Recommended Before Pilot)

| | |
|---|---|
| **Purpose** | Measure how many patients actually complete a booking |
| **Why it will be needed** | Nothing currently tells us whether people succeed or give up halfway. For a pilot, that is the most important question |
| **Cost** | **Free, unlimited** |

### 4.3 Separate Test and Live Environments (Recommended Before Pilot)

| | |
|---|---|
| **Purpose** | Keep testing away from real patient data |
| **Why it will be needed** | Only one environment exists. Testing today would mean test bookings against real patient records |
| **Cost** | **₹0** — each project has its own free allowance |
| **Risk of not doing it** | A mistake during testing could affect live patient data |

### 4.4 Data Backup (Recommended Before Pilot)

| | |
|---|---|
| **Purpose** | Scheduled export of patient, doctor and appointment records |
| **Why it will be needed** | Clinical data with no backup is an unacceptable risk |
| **Cost** | Storage only, well inside the free tier |
| **Expected cost** | **₹0** |

### 4.5 Services That May Be Needed Later

| Service | When | Indicative cost |
|---|---|---|
| Apple Developer Account | Only if an iPhone version is built. Not planned | $99/year (≈ ₹8,300) |
| Custom domain name | If a public website is added | ₹800–1,500/year |
| SSL certificate | Included free with Firebase Hosting | ₹0 |
| Firebase Hosting | If a website or admin portal is added | Free tier: 10 GB storage, 360 MB/day |
| Advanced search (Algolia / Typesense) | Beyond ~100,000 patient records | From ~$50/month |
| Paid monitoring (Sentry, Datadog) | If free logging proves insufficient | From ~$26/month |

### 4.6 Services Explicitly **Not** Required

Listed to prevent budget being set aside unnecessarily:

| Service | Why not needed |
|---|---|
| **Payment gateway** | Care at these centres is free or government-subsidised. No payments anywhere in the system |
| **Video consultation** | Out of scope by decision — rural connectivity makes in-person the model |
| **Google Maps** | Not used. Health centres are identified by name, which is what a villager needs |
| **Email service** | Not used. All communication is by push notification and SMS OTP |
| **AI / language model APIs** | Not used anywhere |
| **Separate backend servers** | Cloud Functions replace them entirely |
| **Database hosting** | Firestore is fully managed |
| **Load balancers / CDN** | Handled by Google automatically |

---

## 5. Cost Projections by Scale

| Users | Reads/day | Within free tier? | Expected monthly cost |
|---|---|:--:|---|
| **100** (pilot, one village) | 15,000–25,000 | ✅ | **₹0** |
| **500** (several villages) | 40,000–60,000 | ⚠️ At the limit | ₹0–400 |
| **500 after planned optimisations** | 10,000–20,000 | ✅ Comfortable | **₹0** |
| **2,000** (district-wide) | 80,000–150,000 | ❌ Exceeds | ₹800–2,500 |

**Interpretation for the panel:** even at four times the pilot's size, the
expected cost is under ₹2,500 per month. Three optimisations already designed
(§7.3) would push the free-tier ceiling out to roughly 500 users.

---

## 6. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Project is on Spark, not Blaze | **Unresolved** | **Application does not function** | Confirm in the console before deployment (§1.1) |
| Unexpected bill from a runaway process | Low | Medium | Spending limits on every function (already configured) |
| SMS allowance exhausted by abuse | Medium | Real users cannot log in | Enable App Check; restrict SMS to India; set a budget alert |
| Daily read limit exceeded | Medium at 500 users | App stops loading data until midnight | Apply the planned optimisations (§7.3) |
| NHA approval delayed | Medium | Doctors cannot be government-verified | Apply now; documented interim measure exists |
| Free tier terms change | Low | Costs appear unexpectedly | Budget alert gives early warning |

---

## 7. Recommendations

### 7.1 Before Deployment — All Free, All Essential

| # | Action | Why |
|---|---|---|
| 1 | **Confirm the billing plan is Blaze** | Nothing works on Spark |
| 2 | **Set a budget alert at ₹100** | Early warning; costs nothing |
| 3 | **Restrict OTP messages to India only** | Prevents international SMS fraud, the main financial risk |
| 4 | **Enable App Check** | Stops scripts exhausting the free quota |
| 5 | **Complete the app fingerprint registration** | Currently the reason real phone numbers cannot log in |

### 7.2 Before the Pilot

| # | Action | Cost |
|---|---|---|
| 6 | Create separate test and live environments | ₹0 |
| 7 | Enable analytics for the booking flow | ₹0 |
| 8 | Set up scheduled data backup | ₹0 |
| 9 | Purchase the Google Play developer account | ₹2,100 one-time |
| 10 | Begin the NHA application | ₹0, 4–8 weeks |

### 7.3 Cost Optimisations Already Designed

Three changes would reduce daily database reads by an estimated 60–80%:

1. **Combine reference data into a single record** — villages and health centres
   are currently read separately by every user on every app start
2. **Pre-calculate dashboard totals** — the admin dashboard currently counts
   records live on each visit
3. **Move photographs to file storage** — removes large images from every
   database read

The first of these is already implemented; the others are planned.

---

## 8. Conclusion for the Panel

1. **The project runs at zero recurring cost** at the intended scale. This was a
   design goal from the start and it has been met.
2. **The only committed spend is ₹2,100 once**, for the Google Play developer
   account.
3. **The Blaze plan must be enabled** — pay-as-you-go, expected bill ₹0, but
   without it the application cannot function.
4. **The main financial risk is accidental, not structural**, and is fully
   addressed by three free protections that should be in place before the pilot.
5. **No payment, video, mapping or AI services are required**, and none should
   be budgeted for.

---

## 9. Completeness Check

| Check | Result |
|---|---|
| Every service currently in use documented | ✅ 10 services |
| Free tiers and limits stated for each | ✅ |
| Mandatory vs optional identified | ✅ |
| Upgrade triggers stated | ✅ |
| Alternatives considered | ✅ |
| Unused services listed separately | ✅ §4 |
| Services explicitly *not* needed listed | ✅ §4.6 |
| Cost projections by scale | ✅ §5 |
| Risks and mitigations | ✅ §6 |
| Pricing flagged as requiring verification | ✅ Header note |
