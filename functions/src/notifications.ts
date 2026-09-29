import {COL, admin, db, serverTimestamp} from "./common";

/**
 * Notification types — must mirror `AppConstants` on the client (SRS §7.8).
 */
export const NOTIF = {
  doctorPending: "doctor_registration_pending",
  doctorApproved: "doctor_approved",
  doctorRejected: "doctor_rejected",
  appointmentBooked: "appointment_booked",
  appointmentAccepted: "appointment_accepted",
  appointmentRejected: "appointment_rejected",
  appointmentCancelled: "appointment_cancelled",
  appointmentReminder: "appointment_reminder_24h",
  appointmentCompleted: "appointment_completed",
  appointmentNoShow: "appointment_no_show",
} as const;

export type NotificationType = (typeof NOTIF)[keyof typeof NOTIF];

type Catalog = Record<string, {title: string; message: string}>;

/**
 * Notification copy is localised **at creation time** into the recipient's
 * language (SRS §7.8), because a stored notification is a historical record —
 * re-translating it later would need the raw parameters, which we do not keep.
 *
 * `{0}` is substituted with the single contextual argument (a name or a date).
 */
const CATALOG: Record<string, Catalog> = {
  en: {
    [NOTIF.doctorPending]: {
      title: "New doctor pending approval",
      message: "{0} has submitted a registration for review.",
    },
    [NOTIF.doctorApproved]: {
      title: "Registration approved",
      message: "You can now set your availability and accept appointments.",
    },
    [NOTIF.doctorRejected]: {
      title: "Registration rejected",
      message: "Reason: {0}",
    },
    [NOTIF.appointmentBooked]: {
      title: "New appointment request",
      message: "{0} has requested an appointment.",
    },
    [NOTIF.appointmentAccepted]: {
      title: "Appointment confirmed",
      message: "Your appointment with {0} is confirmed.",
    },
    [NOTIF.appointmentRejected]: {
      title: "Appointment rejected",
      message: "Reason: {0}",
    },
    [NOTIF.appointmentCancelled]: {
      title: "Appointment cancelled",
      message: "The appointment on {0} was cancelled.",
    },
    [NOTIF.appointmentCompleted]: {
      title: "Visit completed",
      message: "Your visit with {0} is marked complete.",
    },
    [NOTIF.appointmentNoShow]: {
      title: "Marked as no-show",
      message: "You were marked absent for the appointment on {0}.",
    },
    [NOTIF.appointmentReminder]: {
      title: "Appointment tomorrow",
      message: "You have an appointment on {0}.",
    },
  },
  mr: {
    [NOTIF.doctorPending]: {
      title: "नवीन डॉक्टर मंजुरीच्या प्रतीक्षेत",
      message: "{0} यांनी नोंदणी सादर केली आहे.",
    },
    [NOTIF.doctorApproved]: {
      title: "नोंदणी मंजूर झाली",
      message: "आता तुम्ही उपलब्धता ठरवू शकता आणि अपॉइंटमेंट स्वीकारू शकता.",
    },
    [NOTIF.doctorRejected]: {
      title: "नोंदणी नाकारली",
      message: "कारण: {0}",
    },
    [NOTIF.appointmentBooked]: {
      title: "नवीन अपॉइंटमेंट विनंती",
      message: "{0} यांनी अपॉइंटमेंटची विनंती केली आहे.",
    },
    [NOTIF.appointmentAccepted]: {
      title: "अपॉइंटमेंट निश्चित झाली",
      message: "{0} यांच्यासोबतची तुमची अपॉइंटमेंट निश्चित झाली आहे.",
    },
    [NOTIF.appointmentRejected]: {
      title: "अपॉइंटमेंट नाकारली",
      message: "कारण: {0}",
    },
    [NOTIF.appointmentCancelled]: {
      title: "अपॉइंटमेंट रद्द झाली",
      message: "{0} रोजीची अपॉइंटमेंट रद्द करण्यात आली.",
    },
    [NOTIF.appointmentCompleted]: {
      title: "भेट पूर्ण झाली",
      message: "{0} यांच्यासोबतची तुमची भेट पूर्ण झाली आहे.",
    },
    [NOTIF.appointmentNoShow]: {
      title: "गैरहजर नोंदवले",
      message: "{0} रोजीच्या अपॉइंटमेंटसाठी तुम्ही गैरहजर नोंदवले गेलात.",
    },
    [NOTIF.appointmentReminder]: {
      title: "उद्या अपॉइंटमेंट आहे",
      message: "{0} रोजी तुमची अपॉइंटमेंट आहे.",
    },
  },
  hi: {
    [NOTIF.doctorPending]: {
      title: "नया डॉक्टर स्वीकृति की प्रतीक्षा में",
      message: "{0} ने पंजीकरण जमा किया है.",
    },
    [NOTIF.doctorApproved]: {
      title: "पंजीकरण स्वीकृत",
      message:
        "अब आप उपलब्धता तय कर सकते हैं और अपॉइंटमेंट स्वीकार कर सकते हैं.",
    },
    [NOTIF.doctorRejected]: {
      title: "पंजीकरण अस्वीकृत",
      message: "कारण: {0}",
    },
    [NOTIF.appointmentBooked]: {
      title: "नई अपॉइंटमेंट अनुरोध",
      message: "{0} ने अपॉइंटमेंट का अनुरोध किया है.",
    },
    [NOTIF.appointmentAccepted]: {
      title: "अपॉइंटमेंट पुष्ट",
      message: "{0} के साथ आपकी अपॉइंटमेंट पुष्ट हो गई है.",
    },
    [NOTIF.appointmentRejected]: {
      title: "अपॉइंटमेंट अस्वीकृत",
      message: "कारण: {0}",
    },
    [NOTIF.appointmentCancelled]: {
      title: "अपॉइंटमेंट रद्द",
      message: "{0} की अपॉइंटमेंट रद्द कर दी गई.",
    },
    [NOTIF.appointmentCompleted]: {
      title: "मुलाकात पूर्ण",
      message: "{0} के साथ आपकी मुलाकात पूर्ण दर्ज की गई है.",
    },
    [NOTIF.appointmentNoShow]: {
      title: "अनुपस्थित दर्ज",
      message: "{0} की अपॉइंटमेंट के लिए आपको अनुपस्थित दर्ज किया गया.",
    },
    [NOTIF.appointmentReminder]: {
      title: "कल अपॉइंटमेंट है",
      message: "{0} को आपकी अपॉइंटमेंट है.",
    },
  },
};

function resolveCopy(
  type: NotificationType,
  language: string,
  arg: string
): {title: string; message: string} {
  const catalog = CATALOG[language] ?? CATALOG.en;
  const entry = catalog[type] ?? CATALOG.en[type];
  return {
    title: entry.title,
    message: entry.message.replace("{0}", arg),
  };
}

/**
 * Delivers a push to one device token.
 *
 * A stale token is the failure nobody notices: the send silently succeeds
 * from the caller's point of view while the user hears nothing. Tokens rot on
 * reinstall, restore and app data clear, so an `unregistered` response clears
 * the stored token rather than leaving it to fail forever.
 */
async function sendPush(params: {
  userId: string;
  token: string;
  title: string;
  message: string;
  type: NotificationType;
  relatedId: string;
}): Promise<void> {
  try {
    await admin.messaging().send({
      token: params.token,
      notification: {title: params.title, body: params.message},
      // The app routes on `type`; `relatedId` lets a future build deep-link
      // to the specific appointment.
      data: {type: params.type, relatedId: params.relatedId},
      android: {
        priority: "high",
        notification: {channelId: "gas_default", sound: "default"},
      },
    });
  } catch (error: unknown) {
    const code = (error as {code?: string})?.code ?? "";
    if (
      code.includes("registration-token-not-registered") ||
      code.includes("invalid-argument")
    ) {
      await db
        .collection(COL.users)
        .doc(params.userId)
        .update({fcmToken: ""})
        .catch(() => undefined);
      console.info("Cleared stale FCM token", params.userId);
      return;
    }
    console.error("Push delivery failed", params.type, error);
  }
}

/**
 * Writes one notification document for a recipient and pushes it to their
 * device, localised to their stored language preference.
 *
 * Never throws. Notification delivery is best-effort by design (SRS §12.2):
 * the Firestore document is the authoritative record and the app's live
 * streams surface it regardless, so a failed push degrades the experience but
 * never loses information — and must never fail the booking or cancellation
 * that triggered it.
 */
export async function createNotification(params: {
  userId: string;
  type: NotificationType;
  relatedId: string;
  arg?: string;
}): Promise<void> {
  try {
    const userSnap = await db.collection(COL.users).doc(params.userId).get();
    const language = (userSnap.data()?.language as string) ?? "en";
    const token = (userSnap.data()?.fcmToken as string) ?? "";
    const {title, message} = resolveCopy(
      params.type,
      language,
      params.arg ?? ""
    );

    await db.collection(COL.notifications).add({
      userId: params.userId,
      type: params.type,
      title,
      message,
      relatedId: params.relatedId,
      isRead: false,
      createdAt: serverTimestamp(),
    });

    if (token) {
      await sendPush({
        userId: params.userId,
        token,
        title,
        message,
        type: params.type,
        relatedId: params.relatedId,
      });
    }
  } catch (error) {
    console.error("Failed to create notification", params.type, error);
  }
}

/** Notifies every admin. Used for doctor-registration submissions. */
export async function notifyAdmins(params: {
  type: NotificationType;
  relatedId: string;
  arg?: string;
}): Promise<void> {
  try {
    const admins = await db
      .collection(COL.users)
      .where("role", "==", "admin")
      .limit(20)
      .get();
    await Promise.all(
      admins.docs.map((doc) =>
        createNotification({
          userId: doc.id,
          type: params.type,
          relatedId: params.relatedId,
          arg: params.arg,
        })
      )
    );
  } catch (error) {
    console.error("Failed to notify admins", error);
  }
}
