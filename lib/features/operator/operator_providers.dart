import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

// ═══════════════════════════════════════════════════
// TODAY'S OPERATOR BOOKINGS
// ═══════════════════════════════════════════════════

final operatorTodayBookingsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  final today = AppDateUtils.toSchemaDate(DateTime.now());
  return ref.read(firestoreServiceProvider).streamOperatorAppointments(
        uid,
        date: today,
      );
});

// ═══════════════════════════════════════════════════
// OPERATOR BOOKING FLOW
// ═══════════════════════════════════════════════════

final opBookingDoctorsProvider = StreamProvider<List<DoctorModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamActiveDoctors();
});

final opBookingDoctorProvider = StateProvider<DoctorModel?>((ref) => null);
final opBookingDateProvider = StateProvider<String?>((ref) => null);
final opBookingSlotProvider = StateProvider<String?>((ref) => null);

final opBookingAvailabilityProvider =
    FutureProvider<AvailabilityModel?>((ref) async {
  final doctor = ref.watch(opBookingDoctorProvider);
  final date = ref.watch(opBookingDateProvider);
  if (doctor == null || date == null) return null;
  return ref.read(firestoreServiceProvider).getAvailability(doctor.doctorId, date);
});

// ═══════════════════════════════════════════════════
// ASSISTED APPOINTMENTS (SRS §5.1 Operator)
// ═══════════════════════════════════════════════════

/// Every appointment this operator created, newest first.
///
/// Distinct from [operatorTodayBookingsProvider], which is the dashboard's
/// today-only view. An operator needs the full list to cancel on behalf of a
/// villager who cannot do it themselves — often the same villager who had no
/// phone to book with in the first place.
final operatorAssistedAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  final limit = ref.watch(pageLimitProvider(PageKeys.operatorAppointments));
  return ref
      .watch(firestoreServiceProvider)
      .streamOperatorAppointments(uid, limit: limit);
});

// ═══════════════════════════════════════════════════
// AVAILABILITY FALLBACK (SRS O-FLOW-04)
// ═══════════════════════════════════════════════════

/// Doctor whose availability the operator is editing on their behalf.
final opAvailabilityDoctorProvider = StateProvider<DoctorModel?>((ref) => null);

/// Date being edited in the fallback flow.
final opAvailabilityDateProvider = StateProvider<String>(
  (ref) => AppDateUtils.todaySchemaDate(),
);

/// Existing availability for the selected doctor and date.
final opAvailabilityProvider = StreamProvider<AvailabilityModel?>((ref) {
  final doctor = ref.watch(opAvailabilityDoctorProvider);
  final date = ref.watch(opAvailabilityDateProvider);
  if (doctor == null) return Stream.value(null);
  return ref
      .watch(firestoreServiceProvider)
      .streamAvailability(doctor.doctorId, date);
});
