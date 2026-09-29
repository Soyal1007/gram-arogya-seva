import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {COL, RUNTIME, ROLE, admin, db, serverTimestamp} from "./common";

const ADMIN_BOOTSTRAP_SECRET = defineSecret("ADMIN_BOOTSTRAP_SECRET");

/**
 * Creates the first admin account.
 *
 * The system has a genuine chicken-and-egg problem: the default role is
 * `patient` and only an admin can change roles (SRS §4.3). This is the
 * documented escape hatch, and it should be **deleted after first use**.
 *
 * Unlike the previous implementation it fills in the fields `UserModel`
 * requires. A bare `{role: 'admin'}` merge onto a missing document produced a
 * user the app could authenticate but not deserialise
 * (TECHNICAL_ASSESSMENT.md §11.17).
 */
export const bootstrapAdmin = onRequest(
  {...RUNTIME, secrets: [ADMIN_BOOTSTRAP_SECRET]},
  async (req, res) => {
    const secret = ADMIN_BOOTSTRAP_SECRET.value();
    if (!secret) {
      res.status(503).send("Bootstrap is not configured");
      return;
    }
    if (req.method !== "POST" || req.body?.secret !== secret) {
      res.status(403).send("Forbidden");
      return;
    }

    const uid = req.body?.uid;
    if (typeof uid !== "string" || uid.length === 0) {
      res.status(400).send("uid is required");
      return;
    }

    let phone = "";
    let name = "Administrator";
    try {
      const authUser = await admin.auth().getUser(uid);
      phone = (authUser.phoneNumber ?? "").replace("+91", "");
      name = authUser.displayName ?? name;
    } catch {
      res.status(404).send("No auth user with that UID");
      return;
    }

    const ref = db.collection(COL.users).doc(uid);
    const existing = await ref.get();

    await ref.set(
      {
        uid,
        role: ROLE.admin,
        name: (existing.data()?.name as string) || name,
        phone: (existing.data()?.phone as string) || phone,
        language: (existing.data()?.language as string) || "en",
        createdAt: existing.exists ?
          existing.data()?.createdAt :
          serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {merge: true}
    );

    console.info("Admin bootstrapped", {uid});
    res.send(`Admin role granted to UID: ${uid}`);
  }
);
