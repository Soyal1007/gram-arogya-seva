import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/services/firestore_service.dart';

/// Tests for the client data layer.
///
/// Booking, cancellation, status transitions and doctor creation are no
/// longer here — they are Cloud Functions, because their invariants span two
/// documents and security rules cannot validate them (see A17-1). They are
/// covered by the callable's own preconditions and by the rules suite in
/// `functions/test/`, not by `fake_cloud_firestore`, which enforces no rules.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore);
  });

  group('Users', () {
    test('createOrUpdateUser writes a new user', () async {
      const user = UserModel(
        uid: 'user_123',
        phone: '9876543210',
        name: 'Test Patient',
        role: AppConstants.rolePatient,
      );

      await service.createOrUpdateUser(user);

      final doc = await firestore.collection('users').doc('user_123').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['phone'], equals('9876543210'));
      expect(doc.data()?['role'], equals(AppConstants.rolePatient));
      expect(doc.data()?['createdAt'], isNotNull);
    });

    test('createOrUpdateUser preserves the original createdAt', () async {
      // Stamping createdAt on every merge turned it into "last login" and
      // destroyed the audit trail DP-5 depends on (Assessment §11.8).
      final original = Timestamp.fromDate(DateTime.utc(2026, 1, 1));
      await firestore.collection('users').doc('user_1').set({
        'uid': 'user_1',
        'name': 'Existing',
        'phone': '9000000000',
        'role': 'patient',
        'createdAt': original,
      });

      await service.createOrUpdateUser(const UserModel(
        uid: 'user_1',
        name: 'Existing',
        phone: '9000000000',
        role: 'patient',
      ));

      final doc = await firestore.collection('users').doc('user_1').get();
      expect(doc.data()?['createdAt'], equals(original));
    });

    test('getUser returns null for a missing document', () async {
      expect(await service.getUser('nobody'), isNull);
    });

    test('getUser maps the document id onto uid', () async {
      await firestore.collection('users').doc('user_456').set({
        'phone': '9123456789',
        'name': 'Ramesh Kumar',
        'role': 'doctor',
      });

      final user = await service.getUser('user_456');
      expect(user?.uid, equals('user_456'));
      expect(user?.name, equals('Ramesh Kumar'));
      expect(user?.role, equals('doctor'));
    });

    test('searchUsersByPhone matches on prefix', () async {
      for (final phone in ['9876543210', '9876500000', '8123456789']) {
        await firestore.collection('users').doc(phone).set({
          'uid': phone,
          'name': 'User $phone',
          'phone': phone,
          'role': 'patient',
        });
      }

      final results = await service.searchUsersByPhone('98765');
      expect(results.map((u) => u.phone),
          containsAll(['9876543210', '9876500000']));
      expect(results.any((u) => u.phone == '8123456789'), isFalse);
    });
  });

  group('Villages and health centres', () {
    test('createVillage assigns the generated id to the model', () async {
      const village = VillageModel(
        villageId: '',
        name: 'Shivaji Nagar',
        taluka: 'Haveli',
        district: 'Pune',
        state: 'Maharashtra',
      );

      final id = await service.createVillage(village);
      final doc = await firestore.collection('villages').doc(id).get();

      expect(doc.data()?['name'], equals('Shivaji Nagar'));
      expect(doc.data()?['villageId'], equals(id));
    });

    test('deactivateVillage flips isActive without deleting', () async {
      final id = await service.createVillage(const VillageModel(
        villageId: '',
        name: 'Karanja',
        taluka: 'Karanja',
        district: 'Washim',
        state: 'Maharashtra',
      ));

      await service.deactivateVillage(id, 'admin_1');

      final doc = await firestore.collection('villages').doc(id).get();
      expect(doc.exists, isTrue); // DP-5: never deleted
      expect(doc.data()?['isActive'], isFalse);
      expect(doc.data()?['updatedBy'], equals('admin_1'));
    });

    test('streamActiveVillages excludes deactivated villages', () async {
      await service.createVillage(const VillageModel(
        villageId: '',
        name: 'Active',
        taluka: 't',
        district: 'd',
        state: 's',
      ));
      final inactiveId = await service.createVillage(const VillageModel(
        villageId: '',
        name: 'Inactive',
        taluka: 't',
        district: 'd',
        state: 's',
      ));
      await service.deactivateVillage(inactiveId, 'admin_1');

      final villages = await service.streamActiveVillages().first;
      expect(villages.map((v) => v.name), equals(['Active']));
    });
  });

  group('Patients', () {
    const patient = PatientModel(
      patientId: '',
      userId: 'user_123',
      name: 'Suresh Patil',
      dob: '1990-01-01',
      gender: 'Male',
      mobile: '9876543210',
      villageId: 'v1',
    );

    test('createPatient generates an id and stores it on the document',
        () async {
      final id = await service.createPatient(patient);
      expect(id, isNotEmpty);

      final doc = await firestore.collection('patients').doc(id).get();
      expect(doc.data()?['name'], equals('Suresh Patil'));
      expect(doc.data()?['patientId'], equals(id));
    });

    test('getPatientByUserId finds the profile bound to an account', () async {
      await service.createPatient(patient);
      final found = await service.getPatientByUserId('user_123');
      expect(found?.name, equals('Suresh Patil'));
      expect(await service.getPatientByUserId('someone_else'), isNull);
    });

    test('findPatientByMobile supports operator duplicate detection', () async {
      await service.createPatient(patient);
      expect((await service.findPatientByMobile('9876543210'))?.name,
          equals('Suresh Patil'));
      expect(await service.findPatientByMobile('9999999999'), isNull);
    });

    test('updatePatient never overwrites identity or createdAt', () async {
      // A round-tripped model carries createdAt: null and the original
      // userId; writing them back erased the timestamp and, worse, would let
      // a caller reassign ownership of a clinical record (Assessment §11.8).
      final id = await service.createPatient(patient);
      final before = await firestore.collection('patients').doc(id).get();
      final createdAt = before.data()?['createdAt'];

      await service.updatePatient(id, {
        'name': 'Suresh P.',
        'userId': 'attacker_uid',
        'createdAt': null,
        'patientId': 'forged',
      });

      final after = await firestore.collection('patients').doc(id).get();
      expect(after.data()?['name'], equals('Suresh P.'));
      expect(after.data()?['userId'], equals('user_123'));
      expect(after.data()?['patientId'], equals(id));
      expect(after.data()?['createdAt'], equals(createdAt));
      expect(after.data()?['updatedAt'], isNotNull);
    });

    test('searchPatients matches on name prefix', () async {
      await service.createPatient(patient);
      await service.createPatient(
          patient.copyWith(name: 'Sunita Kale', userId: 'user_456'));

      final results = await service.searchPatients('Sur').first;
      expect(results.map((p) => p.name), equals(['Suresh Patil']));
    });
  });

  group('Appointments — reads', () {
    Future<void> seedAppointment({
      required String id,
      required String doctorId,
      required String date,
      String status = 'pending',
      String timeSlot = '09:00',
    }) {
      return firestore.collection('appointments').doc(id).set({
        'appointmentId': id,
        'patientId': 'p1',
        'patientUserId': 'u1',
        'patientName': 'Patient One',
        'doctorId': doctorId,
        'doctorName': 'Dr Test',
        'healthCenterId': 'hc1',
        'villageId': 'v1',
        'date': date,
        'timeSlot': timeSlot,
        'reason': 'Fever',
        'status': status,
      });
    }

    test('streamDoctorAppointmentsForDate returns only that date', () async {
      // Guards Assessment §11.6: the old "20 most recent, filter client-side"
      // approach lost today's queue behind future bookings.
      await seedAppointment(id: 'a1', doctorId: 'doc1', date: '2026-07-23');
      await seedAppointment(id: 'a2', doctorId: 'doc1', date: '2026-08-01');
      await seedAppointment(id: 'a3', doctorId: 'doc2', date: '2026-07-23');

      final today = await service
          .streamDoctorAppointmentsForDate('doc1', '2026-07-23')
          .first;

      expect(today.map((a) => a.appointmentId), equals(['a1']));
    });

    test('streamDoctorAppointmentsFrom returns the upcoming queue in order',
        () async {
      await seedAppointment(id: 'a1', doctorId: 'doc1', date: '2026-08-02');
      await seedAppointment(id: 'a2', doctorId: 'doc1', date: '2026-07-23');
      await seedAppointment(id: 'a3', doctorId: 'doc1', date: '2026-07-01');

      final upcoming = await service
          .streamDoctorAppointmentsFrom('doc1', '2026-07-23')
          .first;

      expect(upcoming.map((a) => a.appointmentId), equals(['a2', 'a1']));
    });

    test('streamPatientAppointments is scoped to the patient account',
        () async {
      await seedAppointment(id: 'a1', doctorId: 'doc1', date: '2026-07-23');
      await firestore.collection('appointments').doc('a2').set({
        'appointmentId': 'a2',
        'patientId': 'p2',
        'patientUserId': 'someone_else',
        'doctorId': 'doc1',
        'healthCenterId': 'hc1',
        'villageId': 'v1',
        'date': '2026-07-23',
        'timeSlot': '10:00',
        'reason': 'Checkup',
      });

      final mine = await service.streamPatientAppointments('u1').first;
      expect(mine.map((a) => a.appointmentId), equals(['a1']));
    });

    test('appointments deserialise slotStartAt when present', () async {
      final start = DateTime.utc(2026, 7, 23, 3, 30);
      await firestore.collection('appointments').doc('a1').set({
        'patientId': 'p1',
        'patientUserId': 'u1',
        'doctorId': 'doc1',
        'healthCenterId': 'hc1',
        'villageId': 'v1',
        'date': '2026-07-23',
        'timeSlot': '09:00',
        'slotStartAt': Timestamp.fromDate(start),
        'reason': 'Fever',
      });

      final appointments = await service.streamPatientAppointments('u1').first;
      // Firestore hands back a local DateTime; compare the instant, not the
      // wall clock, or the assertion depends on the machine's timezone.
      expect(appointments.single.slotStartAt!.toUtc(), equals(start));
    });
  });

  group('Notifications', () {
    Future<void> seedNotification(String id, {bool isRead = false}) {
      return firestore.collection('notifications').doc(id).set({
        'userId': 'u1',
        'type': 'appointment_accepted',
        'title': 'Appointment confirmed',
        'message': 'Your appointment is confirmed.',
        'relatedId': 'a1',
        'isRead': isRead,
        'createdAt': Timestamp.now(),
      });
    }

    test('streamNotifications carries the document id', () async {
      await seedNotification('n1');
      final items = await service.streamNotifications('u1').first;
      // Without the id there is no way to mark a notification read.
      expect(items.single.notificationId, equals('n1'));
    });

    test('streamUnreadNotificationCount counts only unread', () async {
      await seedNotification('n1');
      await seedNotification('n2', isRead: true);
      expect(await service.streamUnreadNotificationCount('u1').first, equals(1));
    });

    test('markNotificationRead flips isRead', () async {
      await seedNotification('n1');
      await service.markNotificationRead('n1');
      final doc = await firestore.collection('notifications').doc('n1').get();
      expect(doc.data()?['isRead'], isTrue);
    });
  });

  group('Doctors', () {
    test('updateDoctorStatus records the approving admin', () async {
      await firestore.collection('doctors').doc('doc_1').set({
        'doctorId': 'doc_1',
        'status': 'pending_approval',
      });

      await service.updateDoctorStatus(
        doctorId: 'doc_1',
        status: AppConstants.doctorActive,
        approvedBy: 'admin_1',
      );

      final doc = await firestore.collection('doctors').doc('doc_1').get();
      expect(doc.data()?['status'], equals('active'));
      expect(doc.data()?['approvedBy'], equals('admin_1'));
      expect(doc.data()?['approvedAt'], isNotNull);
    });

    test('streamActiveDoctors filters by village', () async {
      await firestore.collection('doctors').doc('d1').set({
        'doctorId': 'd1',
        'name': 'Dr A',
        'specialization': 'GP',
        'mobile': '9000000001',
        'nmrId': 'N1',
        'hprId': 'H1',
        'aadhaarHash': 'h',
        'aadhaarLastFour': '0001',
        'status': 'active',
        'villages': ['v1'],
      });
      await firestore.collection('doctors').doc('d2').set({
        'doctorId': 'd2',
        'name': 'Dr B',
        'specialization': 'GP',
        'mobile': '9000000002',
        'nmrId': 'N2',
        'hprId': 'H2',
        'aadhaarHash': 'h',
        'aadhaarLastFour': '0002',
        'status': 'active',
        'villages': ['v2'],
      });

      final inV1 = await service.streamActiveDoctors(villageId: 'v1').first;
      expect(inV1.map((d) => d.doctorId), equals(['d1']));
    });
  });
}
