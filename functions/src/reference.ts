import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  COL,
  ROLE,
  RUNTIME,
  TRIGGER_RUNTIME,
  db,
  requireCaller,
  serverTimestamp,
} from "./common";

/** Aggregate document every client reads instead of the two collections. */
const REFERENCE_DOC = "reference/current";

/**
 * Refuse to publish an aggregate that is approaching Firestore's 1 MB
 * document ceiling. At realistic volumes (tens of villages, ~100 centres)
 * the document is ~20 KB, so hitting this means something has gone wrong —
 * better to keep serving the last good version and alert than to start
 * failing writes.
 */
const MAX_ENTRIES = 2000;

interface VillageEntry {
  name: string;
  taluka: string;
  district: string;
  state: string;
  isActive: boolean;
}

interface CentreEntry {
  name: string;
  villageId: string;
  address: string;
  phone: string;
  isActive: boolean;
}

/**
 * Rebuilds `reference/current` from the villages and health_centers
 * collections.
 *
 * Villages and health centres are small, slow-changing reference data that
 * almost every screen needs in order to render a name instead of an id. The
 * client previously streamed both collections in full, which meant every cold
 * app start paid for the whole dataset — comfortably the largest avoidable
 * read cost in the system (FIREBASE_AUDIT.md §7.2a).
 *
 * Collapsing them into one document turns ~150 reads per session into 1. The
 * rebuild cost lands here instead, on admin edits, which happen perhaps a
 * handful of times a month.
 */
async function rebuildReference(): Promise<void> {
  const [villageSnap, centreSnap] = await Promise.all([
    db.collection(COL.villages).get(),
    db.collection(COL.healthCenters).get(),
  ]);

  if (villageSnap.size + centreSnap.size > MAX_ENTRIES) {
    console.error(
      "Reference data too large to aggregate",
      {villages: villageSnap.size, centres: centreSnap.size}
    );
    return;
  }

  const villages: Record<string, VillageEntry> = {};
  for (const doc of villageSnap.docs) {
    const d = doc.data();
    villages[doc.id] = {
      name: (d.name as string) ?? "",
      taluka: (d.taluka as string) ?? "",
      district: (d.district as string) ?? "",
      state: (d.state as string) ?? "",
      isActive: d.isActive !== false,
    };
  }

  const healthCenters: Record<string, CentreEntry> = {};
  for (const doc of centreSnap.docs) {
    const d = doc.data();
    healthCenters[doc.id] = {
      name: (d.name as string) ?? "",
      villageId: (d.villageId as string) ?? "",
      address: (d.address as string) ?? "",
      phone: (d.phone as string) ?? "",
      isActive: d.isActive !== false,
    };
  }

  await db.doc(REFERENCE_DOC).set({
    villages,
    healthCenters,
    villageCount: villageSnap.size,
    healthCenterCount: centreSnap.size,
    updatedAt: serverTimestamp(),
  });

  console.info("Reference data rebuilt", {
    villages: villageSnap.size,
    centres: centreSnap.size,
  });
}

/** Rebuilds the aggregate whenever a village changes. */
export const onVillageWritten = onDocumentWritten(
  {...TRIGGER_RUNTIME, document: "villages/{villageId}"},
  async () => {
    await rebuildReference();
  }
);

/** Rebuilds the aggregate whenever a health centre changes. */
export const onHealthCenterWritten = onDocumentWritten(
  {...TRIGGER_RUNTIME, document: "health_centers/{centerId}"},
  async () => {
    await rebuildReference();
  }
);

/**
 * Builds the aggregate on demand.
 *
 * The triggers above only fire on writes, so a project with existing villages
 * would have no aggregate until someone happened to edit one. Admins call this
 * once after deploying; the client falls back to reading the collections
 * directly until it exists, so nothing breaks in the meantime.
 */
export const rebuildReferenceData = onCall(RUNTIME, async (request) => {
  const caller = await requireCaller(request);
  if (caller.role !== ROLE.admin) {
    throw new HttpsError("permission-denied", "Admins only");
  }
  await rebuildReference();
  return {ok: true};
});
