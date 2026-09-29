import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

// ═══════════════════════════════════════════════════
// DOCTOR PROFILE
// ═══════════════════════════════════════════════════

final doctorProfileProvider = StreamProvider<DoctorModel?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.read(firestoreServiceProvider).streamDoctor(uid);
});

// ═══════════════════════════════════════════════════
// TODAY'S APPOINTMENTS
// ═══════════════════════════════════════════════════

/// Today's queue.
///
/// Queried by date rather than fetched-then-filtered: the previous version
/// took the 20 most recent appointments overall and filtered client-side,
/// which loses today entirely once a doctor has 20 future bookings
/// (TECHNICAL_ASSESSMENT.md §11.6).
final doctorTodayAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .streamDoctorAppointmentsForDate(uid, AppDateUtils.todaySchemaDate())
      .map((appointments) => appointments
        ..sort((a, b) => (AppDateUtils.parseSlotMinutes(a.timeSlot) ?? 0)
            .compareTo(AppDateUtils.parseSlotMinutes(b.timeSlot) ?? 0)));
});

// ═══════════════════════════════════════════════════
// FILTERED APPOINTMENTS
// ═══════════════════════════════════════════════════

final doctorAppointmentFilterProvider = StateProvider<String?>((ref) => null);

final doctorFilteredAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  final filter = ref.watch(doctorAppointmentFilterProvider);
  final limit = ref.watch(pageLimitProvider(PageKeys.doctorAppointments));
  return ref.watch(firestoreServiceProvider).streamDoctorAppointments(
        uid,
        status: filter,
        limit: limit,
      );
});

// ═══════════════════════════════════════════════════
// AVAILABILITY
// ═══════════════════════════════════════════════════

final selectedDateProvider = StateProvider<String>((ref) {
  return AppDateUtils.toSchemaDate(DateTime.now());
});

final doctorAvailabilityProvider =
    StreamProvider<AvailabilityModel?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  final date = ref.watch(selectedDateProvider);
  if (uid == null) return Stream.value(null);
  return ref.read(firestoreServiceProvider).streamAvailability(uid, date);
});
