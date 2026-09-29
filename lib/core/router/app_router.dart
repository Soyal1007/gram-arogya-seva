import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';

// Auth screens
import 'package:gram_aarogya_seva/features/auth/splash_screen.dart';
import 'package:gram_aarogya_seva/features/auth/phone_input_screen.dart';
import 'package:gram_aarogya_seva/features/auth/otp_verification_screen.dart';

// Doctor registration
import 'package:gram_aarogya_seva/features/doctor_registration/doctor_registration_screen.dart';
import 'package:gram_aarogya_seva/features/doctor_registration/awaiting_approval_screen.dart';

// Admin screens
import 'package:gram_aarogya_seva/features/admin/admin_dashboard_screen.dart';
import 'package:gram_aarogya_seva/features/admin/pending_approvals_screen.dart';
import 'package:gram_aarogya_seva/features/admin/village_management_screen.dart';
import 'package:gram_aarogya_seva/features/admin/health_center_management_screen.dart';
import 'package:gram_aarogya_seva/features/admin/manage_doctors_screen.dart';
import 'package:gram_aarogya_seva/features/admin/view_patients_screen.dart';
import 'package:gram_aarogya_seva/features/admin/monitor_appointments_screen.dart';
import 'package:gram_aarogya_seva/features/admin/role_management_screen.dart';

// Doctor screens
import 'package:gram_aarogya_seva/features/doctor/doctor_dashboard_screen.dart';
import 'package:gram_aarogya_seva/features/doctor/availability_management_screen.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_appointments_screen.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_profile_screen.dart';

// Patient screens
import 'package:gram_aarogya_seva/features/patient/patient_dashboard_screen.dart';
import 'package:gram_aarogya_seva/features/patient/patient_profile_screen.dart';
import 'package:gram_aarogya_seva/features/patient/book_appointment_screen.dart';
import 'package:gram_aarogya_seva/features/patient/health_records_screen.dart';

// Cross-role screens
import 'package:gram_aarogya_seva/features/notifications/notifications_screen.dart';

// Operator screens
import 'package:gram_aarogya_seva/features/operator/operator_dashboard_screen.dart';
import 'package:gram_aarogya_seva/features/operator/operator_register_patient_screen.dart';
import 'package:gram_aarogya_seva/features/operator/operator_book_appointment_screen.dart';
import 'package:gram_aarogya_seva/features/operator/operator_appointments_screen.dart';
import 'package:gram_aarogya_seva/features/operator/operator_availability_screen.dart';



/// GoRouter instance with role-based redirect guards.
/// SRS §6.2, §11.1 A-FLOW-01 routing rules.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: _GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userState = ref.read(currentUserProvider);

      final isLoggedIn = authState.valueOrNull != null;
      final isAuthLoading = authState.isLoading;
      final isOnLogin =
          state.matchedLocation == AppConstants.routePhoneInput ||
          state.matchedLocation == AppConstants.routeOtpVerification;
      final isOnSplash = state.matchedLocation == AppConstants.routeSplash;

      // Debug logging
      debugPrint('[ROUTER] path=${state.matchedLocation} '
          'loggedIn=$isLoggedIn authLoading=$isAuthLoading '
          'userRole=${userState.valueOrNull?.role}');

      // Auth still loading — stay on splash
      if (isAuthLoading && isOnSplash) return null;

      // Routes any authenticated user may open regardless of role. Without
      // this, the role check below compares the path's first segment against
      // the user's dashboard and bounces them away from shared screens.
      const sharedRoutes = <String>{
        '/doctor/register',
        AppConstants.routeNotifications,
      };
      if (sharedRoutes.contains(state.matchedLocation)) {
        return isLoggedIn ? null : AppConstants.routePhoneInput;
      }

      // Not logged in — send to login (unless already there)
      if (!isLoggedIn) {
        return isOnLogin ? null : AppConstants.routePhoneInput;
      }

      // Logged in — get user doc
      final user = userState.valueOrNull;

      // On login/splash — redirect by role
      if (isOnLogin || isOnSplash) {
        if (user == null) {
          if (userState.isLoading) {
            return isOnSplash ? null : AppConstants.routeSplash;
          }
          return AppConstants.routePhoneInput;
        }
        return _roleBasedRoute(ref, user, isOnSplash: isOnSplash);
      }

      // Already on a dashboard — check if on the CORRECT one
      if (user != null) {
        final correctRoute = _roleBasedRoute(ref, user, isOnSplash: isOnSplash);
        if (correctRoute != null) {
          final currentBase = '/${state.matchedLocation.split('/')[1]}';
          final correctBase = '/${correctRoute.split('/')[1]}';
          // If user role changed (e.g. patient→admin), redirect
          if (currentBase != correctBase) {
            debugPrint('[ROUTER] Role mismatch! '
                'current=$currentBase correct=$correctBase → redirecting');
            return correctRoute;
          }
        }
      }

      return null; // Allow current navigation
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routePhoneInput,
        builder: (_, __) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: AppConstants.routeOtpVerification,
        builder: (_, __) => const OtpVerificationScreen(),
      ),

      // ── Doctor Registration
      GoRoute(
        path: '/doctor/register',
        builder: (_, __) => const DoctorRegistrationScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDoctorAwaiting,
        builder: (_, __) => const AwaitingApprovalScreen(),
      ),

      // ── Admin
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/pending-approvals',
        builder: (_, __) => const PendingApprovalsScreen(),
      ),
      GoRoute(
        path: '/admin/villages',
        builder: (_, __) => const VillageManagementScreen(),
      ),
      GoRoute(
        path: '/admin/health-centers',
        builder: (_, __) => const HealthCenterManagementScreen(),
      ),
      GoRoute(
        path: '/admin/doctors',
        builder: (_, __) => const ManageDoctorsScreen(),
      ),
      GoRoute(
        path: '/admin/patients',
        builder: (_, __) => const ViewPatientsScreen(),
      ),
      GoRoute(
        path: '/admin/appointments',
        builder: (_, __) => const MonitorAppointmentsScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        builder: (_, __) => const RoleManagementScreen(),
      ),

      // ── Doctor
      GoRoute(
        path: AppConstants.routeDoctorDashboard,
        builder: (_, __) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor/availability',
        builder: (_, __) => const AvailabilityManagementScreen(),
      ),
      GoRoute(
        path: '/doctor/appointments',
        builder: (_, __) => const DoctorAppointmentsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDoctorProfile,
        builder: (_, __) => const DoctorProfileScreen(),
      ),

      // ── Patient
      GoRoute(
        path: AppConstants.routePatientDashboard,
        builder: (_, __) => const PatientDashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routePatientProfile,
        builder: (_, __) => const PatientProfileScreen(),
      ),
      GoRoute(
        path: '/patient/book',
        builder: (_, __) => const BookAppointmentScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHealthRecords,
        builder: (_, __) => const HealthRecordsScreen(),
      ),

      // ── Cross-role
      GoRoute(
        path: AppConstants.routeNotifications,
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Operator
      GoRoute(
        path: AppConstants.routeOperatorDashboard,
        builder: (_, __) => const OperatorDashboardScreen(),
      ),
      GoRoute(
        path: '/operator/register-patient',
        builder: (_, __) => const OperatorRegisterPatientScreen(),
      ),
      GoRoute(
        path: '/operator/book',
        builder: (_, __) => const OperatorBookAppointmentScreen(),
      ),
      GoRoute(
        path: '/operator/appointments',
        builder: (_, __) => const OperatorAppointmentsScreen(),
      ),
      GoRoute(
        path: '/operator/availability',
        builder: (_, __) => const OperatorAvailabilityScreen(),
      ),
    ],
  );
});

/// Determines the correct route based on user role and status.
String? _roleBasedRoute(Ref ref, UserModel user, {bool isOnSplash = false}) {
  final isDoctorIntent = ref.read(isDoctorRegistrationIntentProvider);
  if (isDoctorIntent && user.role == AppConstants.rolePatient) {
    return '/doctor/register';
  }

  switch (user.role) {
    case AppConstants.roleAdmin:
      return AppConstants.routeAdminDashboard;
    case AppConstants.roleDoctor:
      // Check doctor approval status before routing to dashboard.
      // SRS §D-FLOW-01: pending doctors see the awaiting screen.
      final doctorAsync = ref.read(currentDoctorProvider);

      // If doctor document is loading or has a transient connection error,
      // wait on splash screen until doctor document is loaded.
      if (doctorAsync.isLoading || doctorAsync.hasError || !doctorAsync.hasValue) {
        return isOnSplash ? null : AppConstants.routeSplash;
      }

      final doctor = doctorAsync.value;
      if (doctor == null) {
        return AppConstants.routeDoctorAwaiting;
      }

      if (doctor.status == AppConstants.doctorPendingApproval ||
          doctor.status == AppConstants.doctorRejected) {
        return AppConstants.routeDoctorAwaiting;
      }
      return AppConstants.routeDoctorDashboard;
    case AppConstants.rolePatient:
      return AppConstants.routePatientDashboard;
    case AppConstants.roleOperator:
      return AppConstants.routeOperatorDashboard;
    default:
      return AppConstants.routePatientDashboard;
  }
}

/// Converts Riverpod stream changes into GoRouter's Listenable.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
    ref.listen(currentDoctorProvider, (_, __) => notifyListeners());
    ref.listen(isDoctorRegistrationIntentProvider, (_, __) => notifyListeners());
  }
}
