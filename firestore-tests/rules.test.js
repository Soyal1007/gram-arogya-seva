/**
 * Firestore security-rules tests — SRS §13.5 (launch criterion).
 *
 * These run against the Firestore emulator, which evaluates `firestore.rules`
 * exactly as production does. They exist because the rules are the system's
 * authority (DP-4): a rule that reads correctly and behaves incorrectly is
 * indistinguishable from a rule that works until someone tries it.
 *
 * Two defects that shipped in the previous rule set are pinned here:
 *   • `!onlyChanges(['role'])` let any user grant themself `admin` by writing
 *     `{role, name}` together (Assessment §11.1);
 *   • the same expression blocked doctor registration's own role write
 *     (§11.2), which is why role promotion is now server-side only.
 *
 * Run: npm test   (in firestore-tests/)
 */

const assert = require('node:assert');
const {before, after, beforeEach, describe, it} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'gram-aarogya-test';

/** Role of each seeded test identity. */
const USERS = {
  admin: {uid: 'admin_1', role: 'admin'},
  doctor: {uid: 'doctor_1', role: 'doctor'},
  otherDoctor: {uid: 'doctor_2', role: 'doctor'},
  patient: {uid: 'patient_1', role: 'patient'},
  otherPatient: {uid: 'patient_2', role: 'patient'},
  operator: {uid: 'operator_1', role: 'operator'},
};

let testEnv;

/** Firestore handle for an authenticated identity. */
function db(user) {
  return testEnv.authenticatedContext(user.uid).firestore();
}

/** Firestore handle for a signed-out visitor. */
function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '..', 'firestore.rules'),
        'utf8'
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // Seed the world with rules disabled, the way Cloud Functions would.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const seed = ctx.firestore();

    for (const user of Object.values(USERS)) {
      await seed.doc(`users/${user.uid}`).set({
        uid: user.uid,
        name: `Test ${user.role}`,
        phone: '9000000000',
        role: user.role,
        language: 'en',
      });
    }

    await seed.doc('villages/v1').set({
      villageId: 'v1',
      name: 'Karanja',
      taluka: 'Karanja',
      district: 'Washim',
      state: 'Maharashtra',
      isActive: true,
    });

    await seed.doc('health_centers/hc1').set({
      centerId: 'hc1',
      name: 'Karanja PHC',
      villageId: 'v1',
      isActive: true,
    });

    await seed.doc('doctors/doctor_1').set({
      doctorId: 'doctor_1',
      name: 'Dr Active',
      specialization: 'General Physician',
      mobile: '9000000001',
      nmrId: 'NMR1',
      hprId: 'HPR1',
      aadhaarHash: 'hash',
      aadhaarLastFour: '1234',
      villages: ['v1'],
      status: 'active',
    });

    await seed.doc('doctors/doctor_2').set({
      doctorId: 'doctor_2',
      name: 'Dr Pending',
      specialization: 'Paediatrician',
      mobile: '9000000002',
      nmrId: 'NMR2',
      hprId: 'HPR2',
      aadhaarHash: 'hash',
      aadhaarLastFour: '5678',
      villages: ['v1'],
      status: 'pending_approval',
    });

    await seed.doc('patients/p1').set({
      patientId: 'p1',
      userId: USERS.patient.uid,
      name: 'Patient One',
      dob: '1990-01-01',
      gender: 'Male',
      villageId: 'v1',
      createdBy: 'self',
    });

    await seed.doc('patients/p2').set({
      patientId: 'p2',
      userId: USERS.otherPatient.uid,
      name: 'Patient Two',
      dob: '1992-01-01',
      gender: 'Female',
      villageId: 'v1',
      createdBy: 'self',
    });

    await seed.doc('doctor_availability/doctor_1_2026-08-01').set({
      doctorId: 'doctor_1',
      healthCenterId: 'hc1',
      date: '2026-08-01',
      slots: [{time: '09:00', isBooked: false, appointmentId: null}],
    });

    await seed.doc('appointments/a1').set({
      appointmentId: 'a1',
      patientId: 'p1',
      patientUserId: USERS.patient.uid,
      patientName: 'Patient One',
      doctorId: 'doctor_1',
      healthCenterId: 'hc1',
      villageId: 'v1',
      date: '2026-08-01',
      timeSlot: '09:00',
      reason: 'Fever',
      status: 'pending',
      createdBy: 'self',
    });

    await seed.doc('notifications/n1').set({
      userId: USERS.patient.uid,
      type: 'appointment_accepted',
      title: 'Confirmed',
      message: 'Your appointment is confirmed.',
      relatedId: 'a1',
      isRead: false,
    });

    await seed.doc('abdm_rate_limits/doctor_1').set({verifiedTxnId: 'txn'});
  });
});

// ── Unauthenticated ─────────────────────────────────────────────────────
describe('unauthenticated access', () => {
  it('denies reading villages', async () => {
    await assertFails(anonDb().doc('villages/v1').get());
  });

  it('denies reading doctors', async () => {
    await assertFails(anonDb().doc('doctors/doctor_1').get());
  });

  it('denies reading patients', async () => {
    await assertFails(anonDb().doc('patients/p1').get());
  });

  it('denies reading appointments', async () => {
    await assertFails(anonDb().doc('appointments/a1').get());
  });
});

// ── Users and the role field ────────────────────────────────────────────
describe('users', () => {
  it('lets a user read their own document', async () => {
    await assertSucceeds(db(USERS.patient).doc('users/patient_1').get());
  });

  it("denies reading another user's document", async () => {
    await assertFails(db(USERS.patient).doc('users/patient_2').get());
  });

  it('lets an admin read any user document', async () => {
    await assertSucceeds(db(USERS.admin).doc('users/patient_1').get());
  });

  it('lets a user update their own non-role fields', async () => {
    await assertSucceeds(
      db(USERS.patient).doc('users/patient_1').update({name: 'New Name'})
    );
  });

  it('denies a user changing their own role', async () => {
    await assertFails(
      db(USERS.patient).doc('users/patient_1').update({role: 'admin'})
    );
  });

  it('denies role escalation bundled with another field', async () => {
    // The regression that made every account an admin-in-waiting:
    // `!onlyChanges(['role'])` is true for {role, name}.
    await assertFails(
      db(USERS.patient)
        .doc('users/patient_1')
        .update({role: 'admin', name: 'Sneaky'})
    );
  });

  it('denies self-promotion through a merge-set', async () => {
    await assertFails(
      db(USERS.patient)
        .doc('users/patient_1')
        .set({role: 'admin', name: 'Sneaky'}, {merge: true})
    );
  });

  it('lets an admin change a role', async () => {
    await assertSucceeds(
      db(USERS.admin).doc('users/patient_1').update({role: 'operator'})
    );
  });

  it('denies an admin editing other fields under cover of a role change',
    async () => {
      await assertFails(
        db(USERS.admin)
          .doc('users/patient_1')
          .update({role: 'operator', phone: '9111111111'})
      );
    });

  it('lets a first-time user create their own patient document', async () => {
    const newUser = {uid: 'new_user_1', role: 'patient'};
    await assertSucceeds(
      db(newUser).doc('users/new_user_1').set({
        uid: 'new_user_1',
        name: '',
        phone: '9000000009',
        role: 'patient',
      })
    );
  });

  it('forces a self-created user document to the patient role', async () => {
    // First login creates users/{uid}; if the client could choose the role,
    // every install would be one write away from being an admin.
    const newUser = {uid: 'new_user_2', role: 'patient'};
    await assertFails(
      db(newUser).doc('users/new_user_2').set({
        uid: 'new_user_2',
        name: '',
        phone: '9000000008',
        role: 'admin',
      })
    );
  });

  it('denies creating a user document for somebody else', async () => {
    await assertFails(
      db(USERS.patient).doc('users/impostor').set({
        uid: 'impostor',
        name: '',
        phone: '9000000007',
        role: 'patient',
      })
    );
  });

  it('denies deleting a user', async () => {
    await assertFails(db(USERS.admin).doc('users/patient_1').delete());
  });
});

// ── Doctors ─────────────────────────────────────────────────────────────
describe('doctors', () => {
  it('lets a patient read an active doctor', async () => {
    await assertSucceeds(db(USERS.patient).doc('doctors/doctor_1').get());
  });

  it('denies a patient reading a pending doctor', async () => {
    await assertFails(db(USERS.patient).doc('doctors/doctor_2').get());
  });

  it('lets a doctor read their own pending profile', async () => {
    await assertSucceeds(db(USERS.otherDoctor).doc('doctors/doctor_2').get());
  });

  it('lets an admin read a pending doctor', async () => {
    await assertSucceeds(db(USERS.admin).doc('doctors/doctor_2').get());
  });

  it('denies client-side doctor creation', async () => {
    // Creation is inseparable from Aadhaar hashing and the role promotion,
    // so it belongs to submitDoctorRegistration.
    await assertFails(
      db(USERS.patient).doc('doctors/patient_1').set({
        doctorId: 'patient_1',
        name: 'Fake',
        status: 'active',
      })
    );
  });

  it('lets a doctor edit their own profile fields', async () => {
    await assertSucceeds(
      db(USERS.doctor)
        .doc('doctors/doctor_1')
        .update({name: 'Dr Renamed', specialization: 'Surgeon'})
    );
  });

  it('lets a doctor update their own profile photo', async () => {
    // The doctor profile editor writes photoBase64 through
    // updateDoctorProfile; this pins that the rules permit it.
    await assertSucceeds(
      db(USERS.doctor)
        .doc('doctors/doctor_1')
        .update({photoBase64: 'AAAA', updatedAt: 'now'})
    );
  });

  it('lets a doctor remove their own profile photo', async () => {
    // Removal is a FieldValue.delete(), which still shows up as an affected
    // key — so it has to be in the permitted set, not merely absent.
    const {deleteField} = require('firebase/firestore');
    await assertSucceeds(
      db(USERS.doctor)
        .doc('doctors/doctor_1')
        .update({photoBase64: deleteField()})
    );
  });

  it('denies a doctor editing their own credentials', async () => {
    await assertFails(
      db(USERS.doctor).doc('doctors/doctor_1').update({nmrId: 'FORGED'})
    );
  });

  it('denies a doctor approving themself', async () => {
    await assertFails(
      db(USERS.otherDoctor).doc('doctors/doctor_2').update({status: 'active'})
    );
  });

  it('lets an admin approve a doctor', async () => {
    await assertSucceeds(
      db(USERS.admin)
        .doc('doctors/doctor_2')
        .update({status: 'active', approvedBy: 'admin_1'})
    );
  });

  it("denies a doctor editing another doctor's profile", async () => {
    await assertFails(
      db(USERS.doctor).doc('doctors/doctor_2').update({name: 'Hijacked'})
    );
  });
});

// ── Patients ────────────────────────────────────────────────────────────
describe('patients', () => {
  it('lets a patient read their own record', async () => {
    await assertSucceeds(db(USERS.patient).doc('patients/p1').get());
  });

  it("denies a patient reading another patient's record", async () => {
    await assertFails(db(USERS.otherPatient).doc('patients/p1').get());
  });

  it('lets a doctor read a patient record for an appointment', async () => {
    await assertSucceeds(db(USERS.doctor).doc('patients/p1').get());
  });

  it('lets an operator register a walk-in without a phone account', async () => {
    await assertSucceeds(
      db(USERS.operator).doc('patients/p3').set({
        patientId: 'p3',
        userId: null,
        name: 'Walk In',
        dob: '1980-01-01',
        gender: 'Male',
        villageId: 'v1',
        createdBy: 'health_center',
      })
    );
  });

  it('denies creating a patient bound to somebody else', async () => {
    await assertFails(
      db(USERS.patient).doc('patients/p4').set({
        patientId: 'p4',
        userId: 'patient_2',
        name: 'Not Mine',
        dob: '1980-01-01',
        gender: 'Male',
        villageId: 'v1',
      })
    );
  });

  it('denies reassigning ownership of a clinical record', async () => {
    await assertFails(
      db(USERS.patient).doc('patients/p1').update({userId: 'patient_2'})
    );
  });

  it('denies deleting a patient record', async () => {
    await assertFails(db(USERS.admin).doc('patients/p1').delete());
  });
});

// ── Availability ────────────────────────────────────────────────────────
describe('doctor_availability', () => {
  it('lets any authenticated user read availability', async () => {
    await assertSucceeds(
      db(USERS.patient).doc('doctor_availability/doctor_1_2026-08-01').get()
    );
  });

  it('denies a patient rewriting a doctor schedule', async () => {
    // Previously `allow update: if isPatient()` with no constraints, so any
    // patient could mark every slot booked for any doctor (Assessment §11.5).
    await assertFails(
      db(USERS.patient)
        .doc('doctor_availability/doctor_1_2026-08-01')
        .update({slots: []})
    );
  });

  it('denies a doctor writing availability directly', async () => {
    // Merging already-booked slots forward has to be atomic, so it lives in
    // setDoctorAvailability.
    await assertFails(
      db(USERS.doctor)
        .doc('doctor_availability/doctor_1_2026-08-01')
        .update({slots: []})
    );
  });
});

// ── Appointments ────────────────────────────────────────────────────────
describe('appointments', () => {
  it('lets the booking patient read their appointment', async () => {
    await assertSucceeds(db(USERS.patient).doc('appointments/a1').get());
  });

  it('lets the treating doctor read the appointment', async () => {
    await assertSucceeds(db(USERS.doctor).doc('appointments/a1').get());
  });

  it("denies another doctor reading someone else's appointment", async () => {
    await assertFails(db(USERS.otherDoctor).doc('appointments/a1').get());
  });

  it("denies another patient reading someone else's appointment", async () => {
    await assertFails(db(USERS.otherPatient).doc('appointments/a1').get());
  });

  it('lets an admin read any appointment', async () => {
    await assertSucceeds(db(USERS.admin).doc('appointments/a1').get());
  });

  it('denies a client creating an appointment', async () => {
    // Booking must flip a slot in the same transaction, so it belongs to
    // bookAppointment; allowing creates here also let a client forge
    // patientUserId, patientName or an already-accepted status.
    await assertFails(
      db(USERS.patient).doc('appointments/a2').set({
        appointmentId: 'a2',
        patientId: 'p1',
        patientUserId: 'patient_1',
        doctorId: 'doctor_1',
        healthCenterId: 'hc1',
        villageId: 'v1',
        date: '2026-08-01',
        timeSlot: '09:00',
        reason: 'Fever',
        status: 'accepted',
      })
    );
  });

  it('denies a patient cancelling directly', async () => {
    await assertFails(
      db(USERS.patient).doc('appointments/a1').update({status: 'cancelled'})
    );
  });

  it('denies a doctor accepting directly', async () => {
    await assertFails(
      db(USERS.doctor).doc('appointments/a1').update({status: 'accepted'})
    );
  });

  it('denies deleting an appointment', async () => {
    await assertFails(db(USERS.admin).doc('appointments/a1').delete());
  });
});

// ── Notifications ───────────────────────────────────────────────────────
describe('notifications', () => {
  it('lets the recipient read their notification', async () => {
    await assertSucceeds(db(USERS.patient).doc('notifications/n1').get());
  });

  it("denies reading another user's notification", async () => {
    await assertFails(db(USERS.otherPatient).doc('notifications/n1').get());
  });

  it('lets the recipient mark it read', async () => {
    await assertSucceeds(
      db(USERS.patient).doc('notifications/n1').update({isRead: true})
    );
  });

  it('denies editing notification content', async () => {
    await assertFails(
      db(USERS.patient).doc('notifications/n1').update({title: 'Rewritten'})
    );
  });

  it('denies client-side notification creation', async () => {
    // Server-created only, so the inbox is a record of what the system did.
    await assertFails(
      db(USERS.admin).doc('notifications/n2').set({
        userId: 'patient_1',
        type: 'appointment_accepted',
        title: 'Spam',
        message: 'Spam',
        isRead: false,
      })
    );
  });
});

// ── Reference data ──────────────────────────────────────────────────────
describe('villages and health centres', () => {
  it('lets any authenticated user read villages', async () => {
    await assertSucceeds(db(USERS.patient).doc('villages/v1').get());
  });

  it('denies a non-admin creating a village', async () => {
    await assertFails(
      db(USERS.operator).doc('villages/v2').set({name: 'New', isActive: true})
    );
  });

  it('lets an admin create a village', async () => {
    await assertSucceeds(
      db(USERS.admin).doc('villages/v2').set({
        villageId: 'v2',
        name: 'New',
        taluka: 't',
        district: 'd',
        state: 's',
        isActive: true,
      })
    );
  });

  it('denies deleting a village', async () => {
    await assertFails(db(USERS.admin).doc('villages/v1').delete());
  });

  it('denies a non-admin creating a health centre', async () => {
    await assertFails(
      db(USERS.doctor).doc('health_centers/hc2').set({name: 'X'})
    );
  });
});

// ── ABDM verification state ─────────────────────────────────────────────
describe('abdm_rate_limits', () => {
  it('denies reading verification state', async () => {
    await assertFails(db(USERS.doctor).doc('abdm_rate_limits/doctor_1').get());
  });

  it('denies forging a verification', async () => {
    await assertFails(
      db(USERS.doctor)
        .doc('abdm_rate_limits/doctor_1')
        .set({verifiedTxnId: 'forged'})
    );
  });
});

// Guard against the suite silently shrinking below the SRS §13.5 minimum.
describe('coverage', () => {
  it('covers at least the 20 scenarios the SRS requires', () => {
    const source = fs.readFileSync(__filename, 'utf8');
    const count = (source.match(/^\s{2}it\(/gm) || []).length;
    assert.ok(count >= 20, `expected >= 20 rule scenarios, found ${count}`);
  });
});
