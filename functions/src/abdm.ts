import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineString, defineSecret} from "firebase-functions/params";
import axios from "axios";
import {
  ABDM_BASE_URL,
  COL,
  RUNTIME,
  db,
  requireString,
  serverTimestamp,
} from "./common";

const ABDM_CLIENT_ID = defineString("ABDM_CLIENT_ID", {default: ""});
const ABDM_CLIENT_SECRET = defineSecret("ABDM_CLIENT_SECRET");

/** Seconds a user must wait between Aadhaar OTP requests (SRS §9.2). */
const RATE_LIMIT_MS = 60_000;
const REQUEST_TIMEOUT_MS = 30_000;

/**
 * `abdm_rate_limits/{uid}` carries both the OTP cooldown and the outcome of
 * the most recent verification. Keeping them in one document means the
 * registration submit path can prove verification happened without trusting
 * the client to report it. Firestore rules deny all access to this collection;
 * only the Admin SDK touches it.
 */
interface AbdmRecord {
  lastRequestTime?: FirebaseFirestore.Timestamp;
  requestedTxnId?: string;
  aadhaarLastFour?: string;
  verifiedTxnId?: string;
  verifiedAt?: FirebaseFirestore.Timestamp;
}

async function abdmAccessToken(): Promise<string> {
  const clientId = ABDM_CLIENT_ID.value();
  const clientSecret = ABDM_CLIENT_SECRET.value();
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      "failed-precondition",
      "Verification service is not configured"
    );
  }
  const response = await axios.post(
    `${ABDM_BASE_URL.value()}/v0.5/sessions`,
    {clientId, clientSecret},
    {timeout: REQUEST_TIMEOUT_MS}
  );
  return response.data.accessToken;
}

/**
 * Requests an Aadhaar OTP through the ABDM gateway.
 * Credentials never leave the server (SRS §10 — "ABDM API calls must not
 * originate from the Flutter client").
 */
export const abdmRequestAadhaarOtp = onCall(
  {...RUNTIME, secrets: [ABDM_CLIENT_SECRET]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    const uid = request.auth.uid;

    const data = (request.data ?? {}) as Record<string, unknown>;
    const aadhaarNumber = requireString(data, "aadhaarNumber", 12);
    if (!/^\d{12}$/.test(aadhaarNumber)) {
      throw new HttpsError("invalid-argument", "Invalid Aadhaar number");
    }

    const ref = db.collection(COL.abdmRateLimits).doc(uid);
    const snap = await ref.get();
    const record = snap.data() as AbdmRecord | undefined;
    const lastRequestMs = record?.lastRequestTime?.toDate?.().getTime() ?? 0;
    if (Date.now() - lastRequestMs < RATE_LIMIT_MS) {
      throw new HttpsError(
        "resource-exhausted",
        "Wait 60 seconds before trying again"
      );
    }

    try {
      const token = await abdmAccessToken();
      const otpResponse = await axios.post(
        `${ABDM_BASE_URL.value()}/v0.5/registration/aadhaar/generateOtp`,
        {aadhaar: aadhaarNumber},
        {
          headers: {"Authorization": `Bearer ${token}`, "X-CM-ID": "sbx"},
          timeout: REQUEST_TIMEOUT_MS,
        }
      );

      const txnId = otpResponse.data.txnId as string;
      await ref.set(
        {
          lastRequestTime: serverTimestamp(),
          requestedTxnId: txnId,
          // Retained so the submit path can confirm the verified Aadhaar is
          // the same one being registered. The full number is never stored.
          aadhaarLastFour: aadhaarNumber.slice(8),
          verifiedTxnId: null,
          verifiedAt: null,
        },
        {merge: true}
      );

      return {txnId};
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("ABDM OTP request failed", error);
      throw new HttpsError(
        "unavailable",
        "Verification service temporarily unavailable"
      );
    }
  }
);

/**
 * Verifies the Aadhaar OTP and records the result server-side, so that
 * `submitDoctorRegistration` can require proof of verification rather than
 * trusting a client-supplied transaction id.
 */
export const abdmVerifyAadhaarOtp = onCall(
  {...RUNTIME, secrets: [ABDM_CLIENT_SECRET]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }
    const uid = request.auth.uid;

    const data = (request.data ?? {}) as Record<string, unknown>;
    const txnId = requireString(data, "txnId", 128);
    const otp = requireString(data, "otp", 8);

    const ref = db.collection(COL.abdmRateLimits).doc(uid);
    const record = (await ref.get()).data() as AbdmRecord | undefined;
    if (record?.requestedTxnId !== txnId) {
      throw new HttpsError(
        "failed-precondition",
        "No pending verification for this request"
      );
    }

    try {
      const token = await abdmAccessToken();
      const verifyResponse = await axios.post(
        `${ABDM_BASE_URL.value()}/v0.5/registration/aadhaar/verifyOTP`,
        {txnId, otp},
        {
          headers: {"Authorization": `Bearer ${token}`, "X-CM-ID": "sbx"},
          timeout: REQUEST_TIMEOUT_MS,
        }
      );

      const verifiedTxnId = (verifyResponse.data.txnId as string) ?? txnId;
      await ref.set(
        {verifiedTxnId, verifiedAt: serverTimestamp()},
        {merge: true}
      );

      return {verified: true, txnId: verifiedTxnId};
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("ABDM OTP verification failed", error);
      throw new HttpsError(
        "invalid-argument",
        "OTP verification failed. Please check the code and try again."
      );
    }
  }
);
