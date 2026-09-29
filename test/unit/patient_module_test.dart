import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/services/firestore_service.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';

/// Regression tests for the patient-module fixes recorded in
/// PATIENT_MODULE.md §14. Each group names the issue it pins.
void main() {
  AppointmentModel appointment({
    required String id,
    required String date,
    String timeSlot = '09:00',
    String status = 'pending',
    DateTime? slotStartAt,
  }) {
    return AppointmentModel(
      appointmentId: id,
      patientId: 'p1',
      patientUserId: 'u1',
      doctorId: 'doc1',
      healthCenterId: 'hc1',
      villageId: 'v1',
      date: date,
      timeSlot: timeSlot,
      slotStartAt: slotStartAt,
      reason: 'Fever',
      status: status,
    );
  }

  group('P-06 — appointment ordering', () {
    final now = DateTime(2026, 7, 28, 12, 0);

    test('upcoming appointments come first, soonest to furthest', () {
      // Firestore returns these newest-date-first, which put the appointment
      // a month out above tomorrow's on the patient's home screen.
      final sorted = sortAppointmentsForPatient(
        [
          appointment(id: 'far', date: '2026-08-27'),
          appointment(id: 'tomorrow', date: '2026-07-29'),
          appointment(id: 'next-week', date: '2026-08-04'),
        ],
        now: now,
      );

      expect(
        sorted.map((a) => a.appointmentId),
        equals(['tomorrow', 'next-week', 'far']),
      );
    });

    test('past appointments follow, most recent first', () {
      final sorted = sortAppointmentsForPatient(
        [
          appointment(id: 'old', date: '2026-06-01'),
          appointment(id: 'recent', date: '2026-07-20'),
        ],
        now: now,
      );

      expect(sorted.map((a) => a.appointmentId), equals(['recent', 'old']));
    });

    test('upcoming always precede past', () {
      final sorted = sortAppointmentsForPatient(
        [
          appointment(id: 'past', date: '2026-07-01'),
          appointment(id: 'future', date: '2026-08-01'),
        ],
        now: now,
      );

      expect(sorted.first.appointmentId, equals('future'));
      expect(sorted.last.appointmentId, equals('past'));
    });

    test('today is split by slot time, not by date', () {
      // The whole point of storing a time: an appointment at 09:00 today is
      // history by noon, while 16:00 today is still ahead.
      final sorted = sortAppointmentsForPatient(
        [
          appointment(id: 'this-morning', date: '2026-07-28', timeSlot: '09:00'),
          appointment(id: 'this-evening', date: '2026-07-28', timeSlot: '16:00'),
        ],
        now: now,
      );

      expect(
        sorted.map((a) => a.appointmentId),
        equals(['this-evening', 'this-morning']),
      );
    });

    test('prefers the server-computed slotStartAt over the strings', () {
      final sorted = sortAppointmentsForPatient(
        [
          appointment(
            id: 'authoritative',
            date: 'unparseable',
            timeSlot: 'unparseable',
            slotStartAt: DateTime(2026, 7, 20),
          ),
          appointment(id: 'future', date: '2026-08-01'),
        ],
        now: now,
      );

      // slotStartAt puts it in the past despite the unusable strings.
      expect(sorted.last.appointmentId, equals('authoritative'));
    });

    test('an unreadable appointment stays visible rather than sinking', () {
      final sorted = sortAppointmentsForPatient(
        [
          appointment(id: 'past', date: '2026-07-01'),
          appointment(id: 'broken', date: 'nonsense', timeSlot: 'nonsense'),
        ],
        now: now,
      );

      expect(sorted.first.appointmentId, equals('broken'));
    });

    test('handles an empty list', () {
      expect(sortAppointmentsForPatient(const [], now: now), isEmpty);
    });
  });

  group('P-01 — health records are queried independently', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore);
    });

    Future<void> seed({
      required String id,
      required String status,
      required String date,
      String patientUserId = 'u1',
      Map<String, dynamic>? visitSummary,
    }) {
      return firestore.collection('appointments').doc(id).set({
        'appointmentId': id,
        'patientId': 'p1',
        'patientUserId': patientUserId,
        'doctorId': 'doc1',
        'healthCenterId': 'hc1',
        'villageId': 'v1',
        'date': date,
        'timeSlot': '09:00',
        'reason': 'Fever',
        'status': status,
        'visitSummary': visitSummary,
      });
    }

    test('returns only completed appointments for that patient', () async {
      await seed(id: 'a1', status: 'completed', date: '2026-07-01');
      await seed(id: 'a2', status: 'cancelled', date: '2026-07-02');
      await seed(id: 'a3', status: 'pending', date: '2026-07-03');
      await seed(
          id: 'a4',
          status: 'completed',
          date: '2026-07-04',
          patientUserId: 'someone_else');

      final records =
          await service.streamPatientCompletedAppointments('u1').first;

      expect(records.map((a) => a.appointmentId), equals(['a1']));
    });

    test('is not limited by the dashboard page size', () async {
      // The defect: health records were filtered out of the dashboard's
      // 20-row page, so a patient with more appointments than that silently
      // lost their older visit summaries. This query has its own limit.
      for (var i = 0; i < 25; i++) {
        await seed(
          id: 'recent$i',
          status: 'cancelled',
          date: '2026-08-${(i + 1).toString().padLeft(2, '0')}',
        );
      }
      await seed(
        id: 'old-visit',
        status: 'completed',
        date: '2026-01-15',
        visitSummary: {'notes': 'Recovered well'},
      );

      final records = await service
          .streamPatientCompletedAppointments('u1', limit: 20)
          .first;

      expect(records.map((a) => a.appointmentId), contains('old-visit'));
    });

    test('newest completed visit first', () async {
      await seed(id: 'older', status: 'completed', date: '2026-05-01');
      await seed(id: 'newer', status: 'completed', date: '2026-06-01');

      final records =
          await service.streamPatientCompletedAppointments('u1').first;

      expect(records.map((a) => a.appointmentId), equals(['newer', 'older']));
    });

    test('respects its own limit', () async {
      for (var i = 0; i < 5; i++) {
        await seed(
          id: 'c$i',
          status: 'completed',
          date: '2026-07-0${i + 1}',
        );
      }

      final records =
          await service.streamPatientCompletedAppointments('u1', limit: 3).first;

      expect(records, hasLength(3));
    });
  });

  group('P-03 — past slots are not offered for today', () {
    // The booking grid filters on this helper; these pin the boundary the
    // server also enforces in bookAppointment.
    const date = '2026-07-28';
    final noon = DateTime(2026, 7, 28, 12, 0);

    test('a slot earlier today has passed', () {
      expect(
        AppDateUtils.hasSlotPassed(date: date, timeSlot: '09:00', now: noon),
        isTrue,
      );
    });

    test('a slot later today has not', () {
      expect(
        AppDateUtils.hasSlotPassed(date: date, timeSlot: '16:00', now: noon),
        isFalse,
      );
    });

    test('a slot on a future date has not', () {
      expect(
        AppDateUtils.hasSlotPassed(
            date: '2026-07-29', timeSlot: '09:00', now: noon),
        isFalse,
      );
    });

    test('an unreadable slot is left to the server to reject', () {
      expect(
        AppDateUtils.hasSlotPassed(date: date, timeSlot: 'later', now: noon),
        isFalse,
      );
    });
  });

  group('P-05 — cancellation state is three-way, not two', () {
    final noon = DateTime(2026, 7, 28, 12, 0);

    test('cancellable well before the appointment', () {
      expect(
        AppDateUtils.canCancel(
            date: '2026-07-28', timeSlot: '16:00', now: noon),
        isTrue,
      );
    });

    test('inside the 2-hour window but not yet past', () {
      expect(
        AppDateUtils.canCancel(
            date: '2026-07-28', timeSlot: '13:00', now: noon),
        isFalse,
      );
      expect(
        AppDateUtils.hasSlotPassed(
            date: '2026-07-28', timeSlot: '13:00', now: noon),
        isFalse,
      );
    });

    test('already past — the card must say nothing rather than "too late"', () {
      // An appointment the doctor never closed out stays `accepted` for ever.
      // Both flags being false/true here is what lets the UI tell the
      // difference between "too close" and "long gone".
      expect(
        AppDateUtils.canCancel(
            date: '2026-07-20', timeSlot: '09:00', now: noon),
        isFalse,
      );
      expect(
        AppDateUtils.hasSlotPassed(
            date: '2026-07-20', timeSlot: '09:00', now: noon),
        isTrue,
      );
    });
  });

  group('P-01 — records carry their visit summary', () {
    test('a completed appointment deserialises its summary', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore);

      await firestore.collection('appointments').doc('a1').set({
        'patientId': 'p1',
        'patientUserId': 'u1',
        'doctorId': 'doc1',
        'healthCenterId': 'hc1',
        'villageId': 'v1',
        'date': '2026-07-01',
        'timeSlot': '09:00',
        'reason': 'Fever',
        'status': 'completed',
        'visitSummary': {
          'notes': 'Rest and fluids',
          'prescription': 'Paracetamol',
          'nextSteps': 'Review in a week',
          'followUpDate': '2026-07-08',
        },
        'createdAt': Timestamp.now(),
      });

      final records =
          await service.streamPatientCompletedAppointments('u1').first;

      expect(records.single.visitSummary?.notes, equals('Rest and fluids'));
      expect(records.single.visitSummary?.prescription, equals('Paracetamol'));
      expect(records.single.visitSummary?.followUpDate, equals('2026-07-08'));
    });
  });

  group('P-07/P-08 — booking draft is one state with one lifetime', () {
    const doctorA = DoctorModel(
      doctorId: 'docA',
      name: 'A',
      specialization: 'GP',
      mobile: '9000000001',
      nmrId: 'N1',
      hprId: 'H1',
      aadhaarHash: 'h',
      aadhaarLastFour: '0001',
    );
    const doctorB = DoctorModel(
      doctorId: 'docB',
      name: 'B',
      specialization: 'GP',
      mobile: '9000000002',
      nmrId: 'N2',
      hprId: 'H2',
      aadhaarHash: 'h',
      aadhaarLastFour: '0002',
    );

    test('seeds the village filter from the patient profile', () {
      final notifier = BookingNotifier('v1');
      expect(notifier.state.villageId, equals('v1'));
      expect(notifier.state.step, equals(0));
    });

    test('choosing a doctor advances to the slot step', () {
      final notifier = BookingNotifier('v1')..selectDoctor(doctorA);
      expect(notifier.state.doctor, equals(doctorA));
      expect(notifier.state.step, equals(1));
    });

    test('changing doctor drops the date and slot already chosen', () {
      // Otherwise the draft could describe a slot belonging to a different
      // doctor's schedule.
      final notifier = BookingNotifier('v1')
        ..selectDoctor(doctorA)
        ..selectDate('2026-08-01')
        ..selectSlot('09:00')
        ..selectDoctor(doctorB);

      expect(notifier.state.doctor, equals(doctorB));
      expect(notifier.state.date, isNull);
      expect(notifier.state.timeSlot, isNull);
      expect(notifier.state.isComplete, isFalse);
    });

    test('changing date drops the slot', () {
      final notifier = BookingNotifier('v1')
        ..selectDoctor(doctorA)
        ..selectDate('2026-08-01')
        ..selectSlot('09:00')
        ..selectDate('2026-08-02');

      expect(notifier.state.timeSlot, isNull);
    });

    test('changing village drops the doctor chosen from the old one', () {
      final notifier = BookingNotifier('v1')
        ..selectDoctor(doctorA)
        ..selectVillage('v2');

      expect(notifier.state.villageId, equals('v2'));
      expect(notifier.state.doctor, isNull);
    });

    test('selecting all villages clears the filter, not just the doctor', () {
      final notifier = BookingNotifier('v1')..selectVillage(null);
      expect(notifier.state.villageId, isNull);
    });

    test('isComplete only once doctor, date and slot are all set', () {
      final notifier = BookingNotifier('v1');
      expect(notifier.state.isComplete, isFalse);
      notifier.selectDoctor(doctorA);
      expect(notifier.state.isComplete, isFalse);
      notifier.selectDate('2026-08-01');
      expect(notifier.state.isComplete, isFalse);
      notifier.selectSlot('09:00');
      expect(notifier.state.isComplete, isTrue);
    });

    test('a taken slot returns to slot selection with the slot cleared', () {
      final notifier = BookingNotifier('v1')
        ..selectDoctor(doctorA)
        ..selectDate('2026-08-01')
        ..selectSlot('09:00')
        ..goToStep(2)
        ..slotTaken();

      expect(notifier.state.step, equals(1));
      expect(notifier.state.timeSlot, isNull);
      expect(notifier.state.doctor, equals(doctorA), reason: 'doctor kept');
      expect(notifier.state.date, equals('2026-08-01'), reason: 'date kept');
    });

    test('back never goes below the first step', () {
      final notifier = BookingNotifier('v1')..back();
      expect(notifier.state.step, equals(0));
    });

    test('reason and severity carry sensible defaults', () {
      final notifier = BookingNotifier(null);
      expect(notifier.state.reason, equals(AppConstants.reasonCheckup));
      expect(notifier.state.severity, equals(AppConstants.severityMild));
    });
  });

  group('P-09 — optional phone fields are validated when filled', () {
    test('blank is accepted — these fields are genuinely optional', () {
      expect(Validators.validateOptionalPhone(null), isNull);
      expect(Validators.validateOptionalPhone(''), isNull);
      expect(Validators.validateOptionalPhone('   '), isNull);
    });

    test('a real 10-digit Indian mobile is accepted', () {
      expect(Validators.validateOptionalPhone('9876543210'), isNull);
      expect(Validators.validateOptionalPhone('6123456789'), isNull);
    });

    test('anything entered but wrong is rejected', () {
      // The emergency contact is the number somebody rings in an emergency.
      expect(Validators.validateOptionalPhone('12'), isNotNull);
      expect(Validators.validateOptionalPhone('1234567890'), isNotNull);
      expect(Validators.validateOptionalPhone('abcdefghij'), isNotNull);
    });
  });
}
