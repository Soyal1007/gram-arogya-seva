/**
 * Gram Aarogya Seva — Cloud Functions entry point.
 *
 * Every privileged mutation in the system lives here rather than in the
 * client. Firestore security rules can validate a single document, but they
 * cannot express invariants that span documents — "create this appointment
 * *and* flip exactly this one slot" — so those invariants are enforced by
 * code that owns both writes. See TECHNICAL_ASSESSMENT.md §A17-1.
 *
 * Region: asia-south1 (co-located with Firestore, SRS §6.1).
 *
 * Deployment prerequisites (one-time, per project):
 *   firebase functions:secrets:set AADHAAR_HMAC_SECRET
 *   firebase functions:secrets:set ABDM_CLIENT_SECRET
 *   firebase functions:secrets:set ADMIN_BOOTSTRAP_SECRET
 *   firebase deploy --only firestore:rules,firestore:indexes,functions
 */

export {abdmRequestAadhaarOtp, abdmVerifyAadhaarOtp} from "./abdm";

export {
  submitDoctorRegistration,
  resubmitDoctorRegistration,
  setDoctorAvailability,
  onDoctorStatusChanged,
} from "./doctors";

export {
  bookAppointment,
  cancelAppointment,
  updateAppointmentStatus,
  cancelDoctorDay,
} from "./appointments";

export {sendAppointmentReminders} from "./reminders";

export {
  onVillageWritten,
  onHealthCenterWritten,
  rebuildReferenceData,
} from "./reference";

export {bootstrapAdmin} from "./admin";
