import {HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {defineString, defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

admin.initializeApp();

/** Shared Firestore handle. Admin SDK — bypasses security rules by design. */
export const db = admin.firestore();

/** All functions are deployed to the Firestore region (SRS §6.1). */
export const REGION = "asia-south1";

/**
 * Shared runtime options for every function.
 *
 * `maxInstances` is the important one. Without a cap, a retry storm or a
 * trigger loop can scale to thousands of concurrent containers and turn a
 * ₹0 project into a real bill before anyone notices. Village-scale traffic
 * needs single-digit concurrency; 10 is generous headroom and a hard ceiling
 * on the worst case.
 *
 * Memory and timeout are pinned rather than left to platform defaults so a
 * future change to those defaults cannot silently alter behaviour.
 */
export const RUNTIME = {
  region: REGION,
  maxInstances: 10,
  memory: "256MiB",
  timeoutSeconds: 60,
} as const;

/** Triggers do less work and should never hold a container open. */
export const TRIGGER_RUNTIME = {
  region: REGION,
  maxInstances: 5,
  memory: "256MiB",
  timeoutSeconds: 30,
} as const;

/** IST is UTC+05:30 and has no DST. Slot times are always local wall clock. */
const IST_OFFSET_MINUTES = 330;

/** Collection names — must mirror `lib/core/config/app_constants.dart`. */
export const COL = {
  users: "users",
  doctors: "doctors",
  patients: "patients",
  villages: "villages",
  healthCenters: "health_centers",
  availability: "doctor_availability",
  appointments: "appointments",
  notifications: "notifications",
  abdmRateLimits: "abdm_rate_limits",
} as const;

export const ROLE = {
  admin: "admin",
  doctor: "doctor",
  patient: "patient",
  operator: "operator",
} as const;

export const APPOINTMENT_STATUS = {
  pending: "pending",
  accepted: "accepted",
  rejected: "rejected",
  completed: "completed",
  cancelled: "cancelled",
  noShow: "no_show",
} as const;

export const DOCTOR_STATUS = {
  pendingApproval: "pending_approval",
  active: "active",
  inactive: "inactive",
  rejected: "rejected",
} as const;

/**
 * Server-side HMAC key for Aadhaar hashing (SRS §7.10).
 * Never ship this to a client: `--dart-define` values are recoverable from
 * the APK, which defeats the point of keying the hash at all.
 *
 * Set with: `firebase functions:secrets:set AADHAAR_HMAC_SECRET`
 */
export const AADHAAR_HMAC_SECRET = defineSecret("AADHAAR_HMAC_SECRET");

/** ABDM gateway base URL — configurable so the sandbox→production switch is
 * a deployment concern rather than a code change (SRS §9.3). */
export const ABDM_BASE_URL = defineString("ABDM_BASE_URL", {
  default: "https://healthidsbx.abdm.gov.in/api",
});

/** Maximum days ahead a slot may be booked (SRS §5.1, AppConstants). */
export const MAX_BOOKING_DAYS_AHEAD = 30;

/** Hours before the slot after which cancelling is refused (P-FLOW-03). */
export const CANCEL_WINDOW_HOURS = 2;

export interface Caller {
  uid: string;
  role: string;
}

/** Asserts the request is authenticated and resolves the caller's role. */
export async function requireCaller(
  request: CallableRequest
): Promise<Caller> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required");
  }
  const uid = request.auth.uid;
  const snap = await db.collection(COL.users).doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError("failed-precondition", "User profile not found");
  }
  return {uid, role: (snap.data()?.role as string) ?? ROLE.patient};
}

/** Reads a required string field, trimmed, or throws `invalid-argument`. */
export function requireString(
  data: Record<string, unknown>,
  field: string,
  maxLength = 500
): string {
  const value = data[field];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} is too long`);
  }
  return trimmed;
}

/** Reads an optional string field, trimmed. Returns null when absent/blank. */
export function optionalString(
  data: Record<string, unknown>,
  field: string,
  maxLength = 2000
): string | null {
  const value = data[field];
  if (typeof value !== "string" || value.trim().length === 0) return null;
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} is too long`);
  }
  return trimmed;
}

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

/** Validates a `YYYY-MM-DD` schema date. */
export function requireSchemaDate(
  data: Record<string, unknown>,
  field: string
): string {
  const value = requireString(data, field, 10);
  if (!DATE_PATTERN.test(value)) {
    throw new HttpsError("invalid-argument", `${field} must be YYYY-MM-DD`);
  }
  return value;
}

/**
 * Parses a slot time into minutes past midnight.
 * Accepts the canonical 24-hour `HH:mm` form and the legacy `hh:mm AM/PM`
 * form written by earlier builds, so historical documents keep working.
 */
export function parseSlotMinutes(timeSlot: string): number {
  const match = timeSlot
    .trim()
    .toUpperCase()
    .match(/^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$/);
  if (!match) {
    throw new HttpsError("invalid-argument", `Unrecognised slot: ${timeSlot}`);
  }
  let hour = Number(match[1]);
  const minute = Number(match[2]);
  const meridiem = match[3];

  if (meridiem) {
    if (hour < 1 || hour > 12) {
      throw new HttpsError("invalid-argument", `Invalid slot: ${timeSlot}`);
    }
    if (meridiem === "AM") hour = hour === 12 ? 0 : hour;
    else hour = hour === 12 ? 12 : hour + 12;
  }

  if (hour > 23 || minute > 59) {
    throw new HttpsError("invalid-argument", `Invalid slot: ${timeSlot}`);
  }
  return hour * 60 + minute;
}

/**
 * Converts a schema date plus a slot time (both IST wall clock) into an
 * absolute instant. This is what makes the cancellation window and the
 * reminder scheduler enforceable server-side (Assessment A17-2).
 */
export function slotStartAt(date: string, timeSlot: string): Date {
  const [year, month, day] = date.split("-").map(Number);
  const minutes = parseSlotMinutes(timeSlot);
  const utcMs = Date.UTC(year, month - 1, day, 0, minutes - IST_OFFSET_MINUTES);
  return new Date(utcMs);
}

/** Today's date in IST as `YYYY-MM-DD`. */
export function todayInIst(now: Date = new Date()): string {
  const shifted = new Date(now.getTime() + IST_OFFSET_MINUTES * 60_000);
  return shifted.toISOString().slice(0, 10);
}

/** Difference in whole days between two `YYYY-MM-DD` strings (b - a). */
export function daysBetween(a: string, b: string): number {
  const parse = (s: string) => {
    const [y, m, d] = s.split("-").map(Number);
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((parse(b) - parse(a)) / 86_400_000);
}

export const serverTimestamp = () =>
  admin.firestore.FieldValue.serverTimestamp();

export {admin};
