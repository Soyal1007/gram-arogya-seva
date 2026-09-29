import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  APPOINTMENT_STATUS,
  CANCEL_WINDOW_HOURS,
  COL,
  DOCTOR_STATUS,
  MAX_BOOKING_DAYS_AHEAD,
  RUNTIME,
  ROLE,
  admin,
  daysBetween,
  db,
  optionalString,
  requireCaller,
  requireSchemaDate,
  requireString,
  serverTimestamp,
  slotStartAt,
  todayInIst,
} from "./common";
import {NOTIF, createNotification} from "./notifications";

const REASONS = ["Fever", "Checkup", "Follow-up", "Other"];
const SEVERITIES = ["mild", "moderate", "severe"];

interface SlotRecord {
  time: string;
  isBooked?: boolean;
  appointmentId?: string | null;
}

/** Locates a slot by time within an availability document's slot array. */
function findSlotIndex(slots: SlotRecord[], timeSlot: string): number {
  return slots.findIndex((slot) => slot.time === timeSlot);
}

/**
 * Books an appointment atomically.
 *
 * This runs server-side rather than as a client transaction because the
 * invariant spans two documents — "create this appointment **and** flip
 * exactly this one slot from free to booked" — which Firestore rules cannot
 * express (see TECHNICAL_ASSESSMENT.md A17-1). Running it here also lets the
 * caller-supplied payload be reduced to identifiers: patient name, doctor
 * name, health centre and village are all resolved from the database, so a
 * malicious client cannot forge them.
 *
 * SRS §11.3 P-FLOW-02.
 */
export const bookAppointment = onCall(RUNTIME, async (request) => {
  const caller = await requireCaller(request);
  if (caller.role !== ROLE.patient && caller.role !== ROLE.operator) {
    throw new HttpsError(
      "permission-denied",
      "Only patients and operators may book appointments"
    );
  }

  const data = (request.data ?? {}) as Record<string, unknown>;
  const doctorId = requireString(data, "doctorId", 128);
  const patientId = requireString(data, "patientId", 128);
  const date = requireSchemaDate(data, "date");
  const timeSlot = requireString(data, "timeSlot", 16);
  const reason = requireString(data, "reason", 32);

  if (!REASONS.includes(reason)) {
    throw new HttpsError("invalid-argument", "Unknown appointment reason");
  }

  const intake = (data.intakeForm ?? {}) as Record<string, unknown>;
  const severity = requireString(intake, "severity", 16);
  if (!SEVERITIES.includes(severity)) {
    throw new HttpsError("invalid-argument", "Unknown severity");
  }
  const symptoms = optionalString(intake, "symptoms", 500) ?? "";
  const duration = optionalString(intake, "duration", 100) ?? "";

  // ── Booking horizon (SRS §5.1: max 30 days ahead, never in the past)
  const today = todayInIst();
  const offset = daysBetween(today, date);
  if (offset < 0) {
    throw new HttpsError("invalid-argument", "Cannot book a past date");
  }
  if (offset > MAX_BOOKING_DAYS_AHEAD) {
    throw new HttpsError(
      "invalid-argument",
      `Cannot book more than ${MAX_BOOKING_DAYS_AHEAD} days ahead`
    );
  }

  // ── Resolve and authorise the participants
  const [patientSnap, doctorSnap] = await Promise.all([
    db.collection(COL.patients).doc(patientId).get(),
    db.collection(COL.doctors).doc(doctorId).get(),
  ]);

  if (!patientSnap.exists) {
    throw new HttpsError("not-found", "Patient profile not found");
  }
  const patient = patientSnap.data() ?? {};

  // A patient may only book for themself; an operator may book for anyone.
  if (caller.role === ROLE.patient && patient.userId !== caller.uid) {
    throw new HttpsError(
      "permission-denied",
      "You can only book for your own profile"
    );
  }

  if (!doctorSnap.exists) {
    throw new HttpsError("not-found", "Doctor not found");
  }
  const doctor = doctorSnap.data() ?? {};
  if (doctor.status !== DOCTOR_STATUS.active) {
    throw new HttpsError("failed-precondition", "Doctor is not active");
  }

  const startsAt = slotStartAt(date, timeSlot);
  if (startsAt.getTime() <= Date.now()) {
    throw new HttpsError("invalid-argument", "That time has already passed");
  }

  const appointmentRef = db.collection(COL.appointments).doc();
  const availabilityRef = db
    .collection(COL.availability)
    .doc(`${doctorId}_${date}`);

  await db.runTransaction(async (tx) => {
    const availabilitySnap = await tx.get(availabilityRef);
    if (!availabilitySnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "The doctor has no availability on this date"
      );
    }

    const availability = availabilitySnap.data() ?? {};
    const slots = (availability.slots ?? []) as SlotRecord[];
    const index = findSlotIndex(slots, timeSlot);

    if (index === -1) {
      throw new HttpsError("failed-precondition", "Slot not found");
    }
    if (slots[index].isBooked === true) {
      // Mapped to SlotAlreadyBookedException on the client.
      throw new HttpsError("already-exists", "Slot already booked");
    }

    slots[index] = {
      ...slots[index],
      isBooked: true,
      appointmentId: appointmentRef.id,
    };

    tx.set(appointmentRef, {
      appointmentId: appointmentRef.id,
      patientId,
      patientUserId: patient.userId ?? null,
      patientName: patient.name ?? "",
      doctorId,
      doctorName: doctor.name ?? "",
      healthCenterId: availability.healthCenterId ?? "",
      villageId: patient.villageId ?? "",
      date,
      timeSlot,
      slotStartAt: admin.firestore.Timestamp.fromDate(startsAt),
      reason,
      status: APPOINTMENT_STATUS.pending,
      createdBy: caller.role === ROLE.operator ? "health_center" : "self",
      createdByOperatorId: caller.role === ROLE.operator ? caller.uid : null,
      prepInstructions: null,
      rejectionReason: null,
      cancelledAt: null,
      cancelledBy: null,
      intakeForm: {symptoms, duration, severity},
      visitSummary: null,
      reminderSent: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    tx.update(availabilityRef, {
      slots,
      updatedAt: serverTimestamp(),
    });
  });

  await createNotification({
    userId: doctorId,
    type: NOTIF.appointmentBooked,
    relatedId: appointmentRef.id,
    arg: (patient.name as string) ?? "",
  });

  return {appointmentId: appointmentRef.id};
});

/**
 * Cancels an appointment and frees its slot atomically.
 *
 * The ≥2-hour window is enforced here rather than in the UI because SRS
 * §11.3 P-FLOW-03 requires server-side enforcement — a client check alone is
 * advisory. Admins may override the window for operational emergencies.
 */
export const cancelAppointment = onCall(RUNTIME, async (request) => {
  const caller = await requireCaller(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const appointmentId = requireString(data, "appointmentId", 128);

  const appointmentRef = db.collection(COL.appointments).doc(appointmentId);
  const snap = await appointmentRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Appointment not found");
  }
  const appointment = snap.data() ?? {};

  const isOwningPatient =
    caller.role === ROLE.patient && appointment.patientUserId === caller.uid;
  const isOwningOperator =
    caller.role === ROLE.operator &&
    appointment.createdByOperatorId === caller.uid;
  const isAdmin = caller.role === ROLE.admin;

  if (!isOwningPatient && !isOwningOperator && !isAdmin) {
    throw new HttpsError(
      "permission-denied",
      "You cannot cancel this appointment"
    );
  }

  const cancellable: string[] = [
    APPOINTMENT_STATUS.pending,
    APPOINTMENT_STATUS.accepted,
  ];
  if (!cancellable.includes(appointment.status)) {
    throw new HttpsError(
      "failed-precondition",
      "This appointment can no longer be cancelled"
    );
  }

  if (!isAdmin) {
    const startsAt =
      appointment.slotStartAt?.toDate?.() ??
      slotStartAt(appointment.date, appointment.timeSlot);
    const cutoff = startsAt.getTime() - CANCEL_WINDOW_HOURS * 3_600_000;
    if (Date.now() > cutoff) {
      // Mapped to CancelWindowClosedException on the client.
      throw new HttpsError(
        "deadline-exceeded",
        `Cannot cancel within ${CANCEL_WINDOW_HOURS} hours of the appointment`
      );
    }
  }

  await freeSlotAndSetStatus({
    appointmentRef,
    doctorId: appointment.doctorId,
    date: appointment.date,
    timeSlot: appointment.timeSlot,
    update: {
      status: APPOINTMENT_STATUS.cancelled,
      cancelledAt: serverTimestamp(),
      cancelledBy: caller.uid,
      updatedAt: serverTimestamp(),
    },
  });

  await createNotification({
    userId: appointment.doctorId,
    type: NOTIF.appointmentCancelled,
    relatedId: appointmentId,
    arg: appointment.date,
  });

  return {ok: true};
});

/**
 * Doctor-driven status transitions: accept, reject, complete, no-show.
 * Rejection frees the slot so it can be rebooked (SRS §D-FLOW-03).
 */
export const updateAppointmentStatus = onCall(
  RUNTIME,
  async (request) => {
    const caller = await requireCaller(request);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const appointmentId = requireString(data, "appointmentId", 128);
    const status = requireString(data, "status", 32);

    const appointmentRef = db.collection(COL.appointments).doc(appointmentId);
    const snap = await appointmentRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Appointment not found");
    }
    const appointment = snap.data() ?? {};

    const isOwningDoctor =
      caller.role === ROLE.doctor && appointment.doctorId === caller.uid;
    const isAdmin = caller.role === ROLE.admin;

    // Admins may only close out an appointment (SRS: "mark complete — edge
    // case"); every other transition belongs to the treating doctor.
    const isAdminClosingOut =
      isAdmin && status === APPOINTMENT_STATUS.completed;
    if (!isOwningDoctor && !isAdminClosingOut) {
      throw new HttpsError(
        "permission-denied",
        "You cannot update this appointment"
      );
    }

    const allowedTransitions: Record<string, string[]> = {
      [APPOINTMENT_STATUS.pending]: [
        APPOINTMENT_STATUS.accepted,
        APPOINTMENT_STATUS.rejected,
      ],
      [APPOINTMENT_STATUS.accepted]: [
        APPOINTMENT_STATUS.completed,
        APPOINTMENT_STATUS.noShow,
      ],
    };
    const permitted = allowedTransitions[appointment.status] ?? [];
    if (!permitted.includes(status)) {
      throw new HttpsError(
        "failed-precondition",
        `Cannot move an appointment from ${appointment.status} to ${status}`
      );
    }

    const startsAt =
      appointment.slotStartAt?.toDate?.() ??
      slotStartAt(appointment.date, appointment.timeSlot);

    // Outcome may only be recorded once the appointment time has passed
    // (SRS §D-FLOW-03 "after appointment time passed").
    const isOutcome =
      status === APPOINTMENT_STATUS.completed ||
      status === APPOINTMENT_STATUS.noShow;
    if (isOutcome && Date.now() < startsAt.getTime()) {
      throw new HttpsError(
        "failed-precondition",
        "The appointment time has not passed yet"
      );
    }

    const update: Record<string, unknown> = {
      status,
      updatedAt: serverTimestamp(),
    };

    if (status === APPOINTMENT_STATUS.accepted) {
      update.prepInstructions = optionalString(data, "prepInstructions", 1000);
    }

    if (status === APPOINTMENT_STATUS.rejected) {
      const reason = optionalString(data, "rejectionReason", 1000);
      if (!reason) {
        throw new HttpsError(
          "invalid-argument",
          "A rejection reason is required"
        );
      }
      update.rejectionReason = reason;

      await freeSlotAndSetStatus({
        appointmentRef,
        doctorId: appointment.doctorId,
        date: appointment.date,
        timeSlot: appointment.timeSlot,
        update,
      });
    } else {
      await appointmentRef.update(update);
    }

    // Visit summary (Health Records — SRS §5.1 Patient module).
    if (status === APPOINTMENT_STATUS.completed) {
      const summary = (data.visitSummary ?? {}) as Record<string, unknown>;
      const notes = optionalString(summary, "notes", 2000);
      const prescription = optionalString(summary, "prescription", 2000);
      const nextSteps = optionalString(summary, "nextSteps", 1000);
      const followUpDate = optionalString(summary, "followUpDate", 10);
      if (notes || prescription || nextSteps) {
        await appointmentRef.update({
          visitSummary: {
            notes: notes ?? "",
            prescription: prescription ?? "",
            nextSteps: nextSteps ?? "",
            followUpDate: followUpDate,
          },
        });
      }
    }

    const notificationType = {
      [APPOINTMENT_STATUS.accepted]: NOTIF.appointmentAccepted,
      [APPOINTMENT_STATUS.rejected]: NOTIF.appointmentRejected,
      [APPOINTMENT_STATUS.completed]: NOTIF.appointmentCompleted,
      [APPOINTMENT_STATUS.noShow]: NOTIF.appointmentNoShow,
    }[status];

    if (notificationType && appointment.patientUserId) {
      await createNotification({
        userId: appointment.patientUserId,
        type: notificationType,
        relatedId: appointmentId,
        arg:
          status === APPOINTMENT_STATUS.rejected ?
            ((update.rejectionReason as string) ?? "") :
            status === APPOINTMENT_STATUS.noShow ?
              appointment.date :
              (appointment.doctorName as string) ?? "",
      });
    }

    return {ok: true};
  }
);

/**
 * Bulk-cancels every open appointment for a doctor on a date and frees all
 * of that day's slots. This is the operational escape hatch for the most
 * likely real-world failure — the doctor cannot travel (SRS A-FLOW-03, R-15).
 */
export const cancelDoctorDay = onCall(RUNTIME, async (request) => {
  const caller = await requireCaller(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const doctorId = requireString(data, "doctorId", 128);
  const date = requireSchemaDate(data, "date");

  const isOwningDoctor = caller.role === ROLE.doctor && doctorId === caller.uid;
  if (!isOwningDoctor && caller.role !== ROLE.admin) {
    throw new HttpsError("permission-denied", "Not permitted");
  }

  const open = await db
    .collection(COL.appointments)
    .where("doctorId", "==", doctorId)
    .where("date", "==", date)
    .get();

  const affected = open.docs.filter((doc) =>
    [APPOINTMENT_STATUS.pending, APPOINTMENT_STATUS.accepted].includes(
      doc.data().status
    )
  );

  const batch = db.batch();
  for (const doc of affected) {
    batch.update(doc.ref, {
      status: APPOINTMENT_STATUS.cancelled,
      cancelledAt: serverTimestamp(),
      cancelledBy: caller.uid,
      updatedAt: serverTimestamp(),
    });
  }

  // Free every slot on that date in one write rather than per appointment.
  const availabilityRef = db
    .collection(COL.availability)
    .doc(`${doctorId}_${date}`);
  const availabilitySnap = await availabilityRef.get();
  if (availabilitySnap.exists) {
    const slots = ((availabilitySnap.data()?.slots ?? []) as SlotRecord[]).map(
      (slot) => ({...slot, isBooked: false, appointmentId: null})
    );
    batch.update(availabilityRef, {slots, updatedAt: serverTimestamp()});
  }

  await batch.commit();

  await Promise.all(
    affected
      .map((doc) => doc.data())
      .filter((appointment) => Boolean(appointment.patientUserId))
      .map((appointment) =>
        createNotification({
          userId: appointment.patientUserId,
          type: NOTIF.appointmentCancelled,
          relatedId: appointment.appointmentId ?? "",
          arg: date,
        })
      )
  );

  return {cancelled: affected.length};
});

/**
 * Applies a status update to an appointment while releasing its slot, in a
 * single transaction. Shared by cancellation and rejection — both must never
 * leave a slot orphaned as booked (SRS R-3).
 */
async function freeSlotAndSetStatus(params: {
  appointmentRef: FirebaseFirestore.DocumentReference;
  doctorId: string;
  date: string;
  timeSlot: string;
  update: Record<string, unknown>;
}): Promise<void> {
  const availabilityRef = db
    .collection(COL.availability)
    .doc(`${params.doctorId}_${params.date}`);

  await db.runTransaction(async (tx) => {
    const availabilitySnap = await tx.get(availabilityRef);

    tx.update(params.appointmentRef, params.update);

    if (!availabilitySnap.exists) return;
    const slots = (availabilitySnap.data()?.slots ?? []) as SlotRecord[];
    const index = findSlotIndex(slots, params.timeSlot);
    if (index === -1) return;

    slots[index] = {...slots[index], isBooked: false, appointmentId: null};
    tx.update(availabilityRef, {slots, updatedAt: serverTimestamp()});
  });
}
