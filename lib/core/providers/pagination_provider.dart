import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';

/// Page size for a named list, grown by "load more".
///
/// **Why a growing limit rather than `startAfterDocument` cursors.**
///
/// Cursor pagination is the textbook answer and the right one at scale, but it
/// requires passing `DocumentSnapshot` cursors through the provider layer —
/// which would leak `cloud_firestore` types out of `FirestoreService` and
/// break the invariant that only two files import the SDK (SRS §6.2).
///
/// Growing the limit keeps every list a single live stream: new items still
/// appear in real time, which cursor pages cannot do without extra
/// bookkeeping. The cost is that page N re-reads the first N-1 pages — served
/// from the offline cache in practice, since the same documents were just
/// fetched by the narrower query.
///
/// At village scale (tens of appointments per doctor, hundreds of patients per
/// district) that trade is clearly worth it. Revisit if any list routinely
/// exceeds a few hundred rows.
///
/// Fixes the defect this replaces: every list was hard-capped at `limit(20)`
/// with no way to see row 21, so the data shown was not merely incomplete —
/// it was silently wrong (FIREBASE_AUDIT.md §7.3).
final pageLimitProvider = StateProvider.family<int, String>(
  (ref, listKey) => AppConstants.paginationLimit,
);

/// Stable keys for each paginated list.
class PageKeys {
  PageKeys._();

  static const String adminAppointments = 'admin_appointments';
  static const String adminPatients = 'admin_patients';
  static const String adminDoctors = 'admin_doctors';
  static const String doctorAppointments = 'doctor_appointments';
  static const String patientAppointments = 'patient_appointments';
  static const String patientRecords = 'patient_records';
  static const String operatorAppointments = 'operator_appointments';
}
