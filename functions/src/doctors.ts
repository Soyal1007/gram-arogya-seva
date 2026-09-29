import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {defineBoolean} from "firebase-functions/params";
import * as crypto from "crypto";
import {
  AADHAAR_HMAC_SECRET,
  COL,
  DOCTOR_STATUS,
  RUNTIME,
  TRIGGER_RUNTIME,
  ROLE,
  db,
  optionalString,
  parseSlotMinutes,
  requireCaller,
  requireSchemaDate,
  requireString,
  serverTimestamp,
} from "./common";
import {NOTIF, createNotification, notifyAdmins} from "./notifications";

/**
 * When true (the default, and the only correct production setting) a doctor
 * cannot register without a server-recorded ABDM Aadhaar OTP verification.
 *
 * It exists as a parameter because NHA production credentials take 4–8 weeks
 * (SRS §A-3) and pilots must be able to onboard doctors before then. Turning
 * it off records `abdmVerified: false` on the doctor document so the approving
 * admin can see the credential was never machine-verified — the escape hatch
 * is auditable rather than silent.
 */
const ABDM_VERIFICATION_REQUIRED = defineBoolean("ABDM_VERIFICATION_REQUIRED", {
  default: true,
});

/** How long an ABDM verification stays usable for a registration submission. */
const VERIFICATION_TTL_MS = 30 * 60_000;

const AADHAAR_PATTERN = /^\d{12}$/;

/**
 * Creates the doctor profile and promotes the user's role.
 *
 * Both writes must happen server-side:
 *
 *  1. The Aadhaar HMAC key is a *server* secret (SRS §7.10). A key shipped in
 *     the APK via `--dart-define` is recoverable from the binary, which makes
 *     the HMAC no stronger than a plain hash over a 12-digit space.
 *  2. Role assignment cannot be granted to the client without also granting
 *     self-promotion to `admin` — the exact defect this replaces
 *     (TECHNICAL_ASSESSMENT.md §11.1, §11.2).
 *
 * SRS §11.2 D-FLOW-01.
 */
export const submitDoctorRegistration = onCall(
  {...RUNTIME, secrets: [AADHAAR_HMAC_SECRET]},
  async (request) => {
    const caller = await requireCaller(request);
    const data = (request.data ?? {}) as Record<string, unknown>;

    const name = requireString(data, "name", 120);
    const specialization = requireString(data, "specialization", 120);
    const mobile = requireString(data, "mobile", 10);
    const nmrId = requireString(data, "nmrId", 64);
    const hprId = requireString(data, "hprId", 64);
    const aadhaarNumber = requireString(data, "aadhaarNumber", 12);
    const photoBase64 = optionalString(data, "photoBase64", 400_000);

    if (!/^[6-9]\d{9}$/.test(mobile)) {
      throw new HttpsError("invalid-argument", "Invalid mobile number");
    }
    if (!AADHAAR_PATTERN.test(aadhaarNumber)) {
      throw new HttpsError("invalid-argument", "Invalid Aadhaar number");
    }

    const villages = data.villages;
    if (!Array.isArray(villages) || villages.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Select at least one village to serve"
      );
    }
    const villageIds = villages.map((id) => {
      if (typeof id !== "string" || id.length === 0) {
        throw new HttpsError("invalid-argument", "Invalid village");
      }
      return id;
    });

    // A doctor who is already approved cannot silently re-register.
    const existing = await db.collection(COL.doctors).doc(caller.uid).get();
    if (
      existing.exists &&
      existing.data()?.status === DOCTOR_STATUS.active
    ) {
      throw new HttpsError(
        "already-exists",
        "You already have an approved doctor profile"
      );
    }

    const aadhaarLastFour = aadhaarNumber.slice(8);
    const verificationRequired = ABDM_VERIFICATION_REQUIRED.value();
    let abdmTxnId: string | null = null;

    if (verificationRequired) {
      const verification = await db
        .collection(COL.abdmRateLimits)
        .doc(caller.uid)
        .get();
      const record = verification.data();
      const verifiedAt = record?.verifiedAt?.toDate?.()?.getTime() ?? 0;

      if (
        !record?.verifiedTxnId ||
        record.aadhaarLastFour !== aadhaarLastFour ||
        Date.now() - verifiedAt > VERIFICATION_TTL_MS
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Aadhaar verification is missing or has expired"
        );
      }
      abdmTxnId = record.verifiedTxnId as string;
    }

    // The plaintext Aadhaar exists only in this function's memory: it is
    // hashed here and never written anywhere (SRS §7.10, UIDAI guidance).
    const secret = AADHAAR_HMAC_SECRET.value();
    if (!secret) {
      throw new HttpsError(
        "failed-precondition",
        "Server is not configured for Aadhaar verification"
      );
    }
    const aadhaarHash = crypto
      .createHmac("sha256", secret)
      .update(aadhaarNumber)
      .digest("hex");

    const batch = db.batch();
    batch.set(
      db.collection(COL.doctors).doc(caller.uid),
      {
        doctorId: caller.uid,
        name,
        specialization,
        mobile,
        nmrId,
        hprId,
        aadhaarHash,
        aadhaarLastFour,
        abdmTxnId,
        abdmVerified: verificationRequired,
        photoBase64,
        villages: villageIds,
        status: DOCTOR_STATUS.pendingApproval,
        rejectionNote: null,
        approvedBy: null,
        approvedAt: null,
        createdAt: existing.exists ?
          existing.data()?.createdAt :
          serverTimestamp(),
        updatedAt: serverTimestamp(),
        updatedBy: caller.uid,
      },
      {merge: true}
    );
    batch.set(
      db.collection(COL.users).doc(caller.uid),
      {role: ROLE.doctor, name, updatedAt: serverTimestamp()},
      {merge: true}
    );
    await batch.commit();

    await notifyAdmins({
      type: NOTIF.doctorPending,
      relatedId: caller.uid,
      arg: name,
    });

    return {doctorId: caller.uid, status: DOCTOR_STATUS.pendingApproval};
  }
);

/**
 * Returns a rejected registration to the approval queue (SRS §D-FLOW-01
 * step 7). `status` is admin-owned in the security rules, so the doctor
 * cannot perform this transition directly.
 */
export const resubmitDoctorRegistration = onCall(
  RUNTIME,
  async (request) => {
    const caller = await requireCaller(request);
    if (caller.role !== ROLE.doctor) {
      throw new HttpsError("permission-denied", "Not a doctor account");
    }

    const ref = db.collection(COL.doctors).doc(caller.uid);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "No registration found");
    }
    if (snap.data()?.status !== DOCTOR_STATUS.rejected) {
      throw new HttpsError(
        "failed-precondition",
        "Only a rejected registration can be resubmitted"
      );
    }

    await ref.update({
      status: DOCTOR_STATUS.pendingApproval,
      rejectionNote: null,
      updatedAt: serverTimestamp(),
      updatedBy: caller.uid,
    });

    await notifyAdmins({
      type: NOTIF.doctorPending,
      relatedId: caller.uid,
      arg: (snap.data()?.name as string) ?? "",
    });

    return {status: DOCTOR_STATUS.pendingApproval};
  }
);

/**
 * Writes a doctor's availability for one date.
 *
 * Server-side because a naive client `set()` overwrites the whole document
 * and silently un-books any slot booked since the screen loaded
 * (TECHNICAL_ASSESSMENT.md §11.9). Here, already-booked slots are merged
 * forward and cannot be removed, and the health centre is mandatory — without
 * it the patient never learns where to go (§11.10).
 *
 * SRS §11.2 D-FLOW-02. Operators may act as a fallback (SRS §5.1 Operator).
 */
export const setDoctorAvailability = onCall(
  RUNTIME,
  async (request) => {
    const caller = await requireCaller(request);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const doctorId = requireString(data, "doctorId", 128);
    const date = requireSchemaDate(data, "date");
    const healthCenterId = requireString(data, "healthCenterId", 128);

    const isOwningDoctor =
      caller.role === ROLE.doctor && doctorId === caller.uid;
    const mayManageOthers =
      caller.role === ROLE.admin || caller.role === ROLE.operator;
    if (!isOwningDoctor && !mayManageOthers) {
      throw new HttpsError("permission-denied", "Not permitted");
    }

    const times = data.slots;
    if (!Array.isArray(times)) {
      throw new HttpsError("invalid-argument", "slots must be a list");
    }
    // Normalise, validate and de-duplicate the requested times.
    const requested = Array.from(
      new Set(
        times.map((time) => {
          if (typeof time !== "string") {
            throw new HttpsError("invalid-argument", "Invalid slot");
          }
          parseSlotMinutes(time); // throws on malformed input
          return time.trim();
        })
      )
    ).sort((a, b) => parseSlotMinutes(a) - parseSlotMinutes(b));

    const [doctorSnap, centerSnap] = await Promise.all([
      db.collection(COL.doctors).doc(doctorId).get(),
      db.collection(COL.healthCenters).doc(healthCenterId).get(),
    ]);

    if (!doctorSnap.exists) {
      throw new HttpsError("not-found", "Doctor not found");
    }
    if (!centerSnap.exists || centerSnap.data()?.isActive !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Health centre is not active"
      );
    }

    const doctorVillages = (doctorSnap.data()?.villages ?? []) as string[];
    if (!doctorVillages.includes(centerSnap.data()?.villageId)) {
      throw new HttpsError(
        "failed-precondition",
        "That health centre is not in a village this doctor serves"
      );
    }

    const ref = db.collection(COL.availability).doc(`${doctorId}_${date}`);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const existing = (snap.data()?.slots ?? []) as Array<{
        time: string;
        isBooked?: boolean;
        appointmentId?: string | null;
      }>;
      const bookedByTime = new Map(
        existing
          .filter((slot) => slot.isBooked === true)
          .map((slot) => [slot.time, slot])
      );

      // Booked slots survive regardless of what the client sent.
      const merged = [
        ...requested.map(
          (time) => bookedByTime.get(time) ?? {
            time,
            isBooked: false,
            appointmentId: null,
          }
        ),
        ...Array.from(bookedByTime.entries())
          .filter(([time]) => !requested.includes(time))
          .map(([, slot]) => slot),
      ].sort((a, b) => parseSlotMinutes(a.time) - parseSlotMinutes(b.time));

      tx.set(
        ref,
        {
          doctorId,
          healthCenterId,
          date,
          slots: merged,
          createdAt: snap.exists ? snap.data()?.createdAt : serverTimestamp(),
          lastUpdatedBy: caller.uid,
          updatedAt: serverTimestamp(),
        },
        {merge: true}
      );
    });

    return {ok: true};
  }
);

/**
 * Notifies a doctor when an admin approves or rejects their registration.
 *
 * Approval remains a client-side write because it touches a single document
 * and is fully expressible in security rules. The notification, however, must
 * be trustworthy, so it is produced here rather than by the approving client
 * (SRS §11.1 A-FLOW-02, §6.2 "all notifications created by Cloud Functions").
 */
export const onDoctorStatusChanged = onDocumentUpdated(
  {...TRIGGER_RUNTIME, document: "doctors/{doctorId}"},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;

    const doctorId = event.params.doctorId;

    if (after.status === DOCTOR_STATUS.active) {
      await createNotification({
        userId: doctorId,
        type: NOTIF.doctorApproved,
        relatedId: doctorId,
      });
    } else if (after.status === DOCTOR_STATUS.rejected) {
      await createNotification({
        userId: doctorId,
        type: NOTIF.doctorRejected,
        relatedId: doctorId,
        arg: (after.rejectionNote as string) ?? "",
      });
    }
  }
);
