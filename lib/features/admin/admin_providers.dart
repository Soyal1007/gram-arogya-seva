import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';

// ═══════════════════════════════════════════════════
// DASHBOARD STATS
// ═══════════════════════════════════════════════════

class DashboardStats {
  final int totalVillages;
  final int totalDoctors;
  final int pendingDoctors;
  final int totalPatients;
  final int todayAppointments;
  final int pendingAppointments;

  const DashboardStats({
    this.totalVillages = 0,
    this.totalDoctors = 0,
    this.pendingDoctors = 0,
    this.totalPatients = 0,
    this.todayAppointments = 0,
    this.pendingAppointments = 0,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final fs = ref.read(firestoreServiceProvider);
  final today = AppDateUtils.toSchemaDate(DateTime.now());
  final results = await Future.wait([
    fs.countDocuments(AppConstants.villagesCollection,
        field: 'isActive', value: true),
    fs.countDocuments(AppConstants.doctorsCollection,
        field: 'status', value: AppConstants.doctorActive),
    fs.countDocuments(AppConstants.doctorsCollection,
        field: 'status', value: AppConstants.doctorPendingApproval),
    fs.countDocuments(AppConstants.patientsCollection),
    fs.countDocuments(AppConstants.appointmentsCollection,
        field: 'status', value: AppConstants.appointmentPending),
    fs.countDocuments(AppConstants.appointmentsCollection,
        field: 'date', value: today),
  ]);
  return DashboardStats(
    totalVillages: results[0],
    totalDoctors: results[1],
    pendingDoctors: results[2],
    totalPatients: results[3],
    pendingAppointments: results[4],
    todayAppointments: results[5],
  );
});

// ═══════════════════════════════════════════════════
// STREAMS
// ═══════════════════════════════════════════════════

final allVillagesProvider = StreamProvider<List<VillageModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamAllVillages();
});

final allHealthCentersProvider =
    StreamProvider.family<List<HealthCenterModel>, String?>(
        (ref, villageId) {
  return ref.read(firestoreServiceProvider).streamHealthCenters(villageId: villageId);
});

final pendingDoctorsProvider = StreamProvider<List<DoctorModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamPendingDoctors();
});

final allDoctorsProvider = StreamProvider<List<DoctorModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamAllDoctors();
});

final allAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String?>((ref, status) {
  final limit = ref.watch(pageLimitProvider(PageKeys.adminAppointments));
  return ref
      .watch(firestoreServiceProvider)
      .streamAllAppointments(status: status, limit: limit);
});

// ═══════════════════════════════════════════════════
// SEARCH PROVIDERS
// ═══════════════════════════════════════════════════

final patientSearchQueryProvider = StateProvider<String>((ref) => '');

final patientSearchResultsProvider =
    StreamProvider<List<PatientModel>>((ref) {
  final query = ref.watch(patientSearchQueryProvider);
  if (query.isEmpty) return Stream.value([]);
  final limit = ref.watch(pageLimitProvider(PageKeys.adminPatients));
  return ref.watch(firestoreServiceProvider).searchPatients(query, limit: limit);
});

final userSearchQueryProvider = StateProvider<String>((ref) => '');

final userSearchResultsProvider =
    FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(userSearchQueryProvider);
  if (query.isEmpty) return [];
  return ref.read(firestoreServiceProvider).searchUsersByPhone(query);
});

// ═══════════════════════════════════════════════════
// FILTER STATE
// ═══════════════════════════════════════════════════

final appointmentStatusFilterProvider = StateProvider<String?>((ref) => null);
