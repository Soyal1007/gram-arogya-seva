import 'package:flutter/foundation.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

// ═══════════════════════════════════════════════════
// PATIENT PROFILE
// ═══════════════════════════════════════════════════

final patientProfileProvider = FutureProvider<PatientModel?>((ref) async {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return null;
  return ref.read(firestoreServiceProvider).getPatientByUserId(uid);
});

// ═══════════════════════════════════════════════════
// MY APPOINTMENTS
// ═══════════════════════════════════════════════════

/// The patient's appointments, ordered the way a patient actually reads them.
///
/// Firestore returns them newest-date-first, which put an appointment thirty
/// days out above tomorrow's and buried today's in the middle — on the one
/// screen whose job is to answer "when am I seeing the doctor"
/// (PATIENT_MODULE.md P-06).
///
/// Re-sorted here rather than in the query because the two halves want
/// opposite orders: upcoming ascending (soonest first), past descending (most
/// recent first). No index can express that, and at a page at a time the sort
/// is free.
final myAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  final limit = ref.watch(pageLimitProvider(PageKeys.patientAppointments));
  return ref
      .watch(firestoreServiceProvider)
      .streamPatientAppointments(uid, limit: limit)
      .map(sortAppointmentsForPatient);
});

/// Upcoming first (soonest → furthest), then past (most recent → oldest).
@visibleForTesting
List<AppointmentModel> sortAppointmentsForPatient(
  List<AppointmentModel> appointments, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();

  bool isUpcoming(AppointmentModel a) {
    final start = a.slotStartAt ?? AppDateUtils.slotDateTime(a.date, a.timeSlot);
    // An appointment whose time cannot be parsed is treated as upcoming so it
    // stays visible rather than sinking into history unnoticed.
    return start == null || start.isAfter(reference);
  }

  DateTime sortKey(AppointmentModel a) =>
      a.slotStartAt ??
      AppDateUtils.slotDateTime(a.date, a.timeSlot) ??
      DateTime.tryParse(a.date) ??
      reference;

  final upcoming = appointments.where(isUpcoming).toList()
    ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));
  final past = appointments.where((a) => !isUpcoming(a)).toList()
    ..sort((a, b) => sortKey(b).compareTo(sortKey(a)));

  return [...upcoming, ...past];
}

// ═══════════════════════════════════════════════════
// BOOKING FLOW
// ═══════════════════════════════════════════════════

/// Everything the booking wizard has collected so far.
///
/// The wizard used to split its state across two lifetimes: doctor, date and
/// slot lived in app-scoped `StateProvider`s while the step and intake fields
/// lived in `setState`. App-scoped state outlives the screen, so abandoning
/// the wizard left a stale doctor and slot selected for the next attempt,
/// while the widget half reset — two bugs from one root cause
/// (PATIENT_MODULE.md P-07, P-08).
///
/// One immutable draft behind one `autoDispose` notifier gives the whole
/// wizard a single lifetime: the screen's.
@immutable
class BookingDraft {
  const BookingDraft({
    this.step = 0,
    this.villageId,
    this.doctor,
    this.date,
    this.timeSlot,
    this.reason = AppConstants.reasonCheckup,
    this.severity = AppConstants.severityMild,
  });

  /// 0 = choose doctor · 1 = choose date and slot · 2 = reason and confirm.
  final int step;

  /// Village filter. Null means "all villages".
  final String? villageId;

  final DoctorModel? doctor;
  final String? date;
  final String? timeSlot;
  final String reason;
  final String severity;

  /// True when the draft holds everything `bookAppointment` requires.
  bool get isComplete =>
      doctor != null && date != null && timeSlot != null;

  BookingDraft copyWith({
    int? step,
    String? villageId,
    DoctorModel? doctor,
    String? date,
    String? timeSlot,
    String? reason,
    String? severity,
    bool clearVillage = false,
    bool clearDoctor = false,
    bool clearDate = false,
    bool clearSlot = false,
  }) {
    return BookingDraft(
      step: step ?? this.step,
      villageId: clearVillage ? null : (villageId ?? this.villageId),
      doctor: clearDoctor ? null : (doctor ?? this.doctor),
      date: clearDate ? null : (date ?? this.date),
      timeSlot: clearSlot ? null : (timeSlot ?? this.timeSlot),
      reason: reason ?? this.reason,
      severity: severity ?? this.severity,
    );
  }
}

/// Wizard transitions.
///
/// Each transition clears what it invalidates — choosing a different doctor
/// drops the date and slot, choosing a different date drops the slot — so the
/// draft can never describe a combination the patient did not actually pick.
class BookingNotifier extends StateNotifier<BookingDraft> {
  BookingNotifier(String? initialVillageId)
      : super(BookingDraft(villageId: initialVillageId));

  void selectVillage(String? villageId) {
    state = state.copyWith(
      villageId: villageId,
      clearVillage: villageId == null,
      clearDoctor: true,
      clearDate: true,
      clearSlot: true,
    );
  }

  void selectDoctor(DoctorModel doctor) {
    state = state.copyWith(
      doctor: doctor,
      clearDate: true,
      clearSlot: true,
      step: 1,
    );
  }

  void selectDate(String date) {
    state = state.copyWith(date: date, clearSlot: true);
  }

  void selectSlot(String timeSlot) {
    state = state.copyWith(timeSlot: timeSlot);
  }

  void setReason(String reason) => state = state.copyWith(reason: reason);
  void setSeverity(String severity) =>
      state = state.copyWith(severity: severity);

  void goToStep(int step) => state = state.copyWith(step: step);
  void back() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  /// Returns to slot selection after the chosen slot was taken by someone else.
  void slotTaken() =>
      state = state.copyWith(clearSlot: true, step: 1);
}

/// The booking wizard's state, scoped to the screen.
///
/// `autoDispose` is the fix for P-07: when the patient leaves the screen the
/// notifier is disposed, so the next attempt starts clean instead of inheriting
/// a half-finished booking.
///
/// The village is seeded once with `ref.read` rather than `ref.watch`. Watching
/// would rebuild the notifier — discarding a part-filled draft — if the profile
/// happened to re-emit mid-flow. The booking screen is only reachable once the
/// profile has resolved (P-02), so a one-time read is sound.
final bookingDraftProvider =
    StateNotifierProvider.autoDispose<BookingNotifier, BookingDraft>((ref) {
  final villageId =
      ref.read(patientProfileProvider).valueOrNull?.villageId;
  return BookingNotifier(villageId);
});

/// Active doctors in the selected village.
final bookingDoctorsProvider =
    StreamProvider.autoDispose<List<DoctorModel>>((ref) {
  final villageId =
      ref.watch(bookingDraftProvider.select((d) => d.villageId));
  return ref
      .watch(firestoreServiceProvider)
      .streamActiveDoctors(villageId: villageId);
});

/// Availability for the selected doctor and date.
///
/// A stream rather than a one-shot read: slots are the most contended data in
/// the system, and a patient staring at a stale grid is exactly how the
/// "slot just got booked" error happens.
final bookingAvailabilityProvider =
    StreamProvider.autoDispose<AvailabilityModel?>((ref) {
  final doctor = ref.watch(bookingDraftProvider.select((d) => d.doctor));
  final date = ref.watch(bookingDraftProvider.select((d) => d.date));
  if (doctor == null || date == null) return Stream.value(null);
  return ref
      .watch(firestoreServiceProvider)
      .streamAvailability(doctor.doctorId, date);
});

// ═══════════════════════════════════════════════════
// HEALTH RECORDS
// ═══════════════════════════════════════════════════

/// The patient's completed visits, newest first.
///
/// Queried independently of [myAppointmentsProvider]. Deriving it from that
/// list meant health records inherited the dashboard's page size, so a patient
/// with more than one page of appointments silently lost their older visit
/// summaries (PATIENT_MODULE.md P-01). Clinical history must never be a
/// by-product of how a UI list happens to paginate.
final healthRecordsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  final limit = ref.watch(pageLimitProvider(PageKeys.patientRecords));
  return ref
      .watch(firestoreServiceProvider)
      .streamPatientCompletedAppointments(uid, limit: limit)
      // A completed visit only becomes a record once the doctor has written
      // the summary; until then there is nothing to show.
      .map((appointments) =>
          appointments.where((a) => a.visitSummary != null).toList());
});
