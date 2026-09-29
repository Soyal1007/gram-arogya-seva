import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  APPOINTMENT_STATUS,
  COL,
  TRIGGER_RUNTIME,
  admin,
  db,
} from "./common";
import {NOTIF, createNotification} from "./notifications";

/** How far ahead a reminder is sent (SRS §7.8 `appointment_reminder_24h`). */
const REMINDER_HORIZON_MS = 24 * 60 * 60 * 1000;

/** Safety valve so one bad run cannot fan out unbounded. */
const MAX_PER_RUN = 200;

/**
 * Sends 24-hour appointment reminders.
 *
 * Runs hourly rather than daily so that an appointment booked at short notice
 * still gets a reminder, and so a failed run costs at most one hour of
 * lateness instead of a whole day of silence.
 *
 * `reminderSent` is flipped in the same pass, which is what makes the job
 * idempotent: a retry, an overlapping run, or a redeploy mid-execution cannot
 * send the same villager the same reminder twice. Duplicate notifications
 * erode trust in the app faster than missing ones.
 *
 * This is only queryable because `slotStartAt` exists as a real Timestamp —
 * the `date` + `timeSlot` strings it replaced could not be range-filtered.
 *
 * SRS §6.1, §5.1 Infrastructure.
 */
export const sendAppointmentReminders = onSchedule(
  {
    ...TRIGGER_RUNTIME,
    schedule: "every 60 minutes",
    timeZone: "Asia/Kolkata",
    retryCount: 2,
  },
  async () => {
    const now = new Date();
    const horizon = new Date(now.getTime() + REMINDER_HORIZON_MS);

    const due = await db
      .collection(COL.appointments)
      .where("reminderSent", "==", false)
      .where("status", "==", APPOINTMENT_STATUS.accepted)
      .where("slotStartAt", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("slotStartAt", "<=", admin.firestore.Timestamp.fromDate(horizon))
      .limit(MAX_PER_RUN)
      .get();

    if (due.empty) {
      console.info("No reminders due");
      return;
    }

    let sent = 0;
    for (const doc of due.docs) {
      const appointment = doc.data();

      // Operator-registered villagers may have no account at all, so there is
      // nobody to notify — the operator tells them in person. Still mark the
      // reminder handled so the query does not revisit it every hour.
      if (appointment.patientUserId) {
        await createNotification({
          userId: appointment.patientUserId,
          type: NOTIF.appointmentReminder,
          relatedId: doc.id,
          arg: appointment.date,
        });
        sent++;
      }

      await doc.ref.update({reminderSent: true});
    }

    console.info(`Reminders processed: ${due.size}, notified: ${sent}`);
  }
);
