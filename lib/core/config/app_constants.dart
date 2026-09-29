/// All string constants used across the application.
/// Centralised to prevent typos and ensure consistency with Firestore schema.
class AppConstants {
  AppConstants._();

  // ── App Info
  static const String appName = 'Gram Aarogya Seva';
  static const String appVersion = '1.0.0';

  // ── Firestore Collection Names
  static const String usersCollection = 'users';
  static const String doctorsCollection = 'doctors';
  static const String patientsCollection = 'patients';
  static const String villagesCollection = 'villages';
  static const String healthCentersCollection = 'health_centers';
  static const String availabilityCollection = 'doctor_availability';
  static const String appointmentsCollection = 'appointments';
  static const String notificationsCollection = 'notifications';
  static const String abdmRateLimitsCollection = 'abdm_rate_limits';

  // ── User Roles
  static const String roleAdmin = 'admin';
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';
  static const String roleOperator = 'operator';

  // ── Doctor Statuses
  static const String doctorPendingApproval = 'pending_approval';
  static const String doctorActive = 'active';
  static const String doctorInactive = 'inactive';
  static const String doctorRejected = 'rejected';

  // ── Appointment Statuses
  static const String appointmentPending = 'pending';
  static const String appointmentAccepted = 'accepted';
  static const String appointmentRejected = 'rejected';
  static const String appointmentCompleted = 'completed';
  static const String appointmentCancelled = 'cancelled';
  static const String appointmentNoShow = 'no_show';

  static const List<String> allAppointmentStatuses = [
    appointmentPending,
    appointmentAccepted,
    appointmentCompleted,
    appointmentRejected,
    appointmentCancelled,
    appointmentNoShow,
  ];

  /// Localisation key for an appointment status label.
  /// Keeps status copy in the l10n files instead of switch statements
  /// duplicated across the doctor, admin and operator screens.
  static String statusLabelKey(String status) {
    switch (status) {
      case appointmentPending:
        return 'status_pending';
      case appointmentAccepted:
        return 'status_accepted';
      case appointmentCompleted:
        return 'status_completed';
      case appointmentRejected:
        return 'status_rejected';
      case appointmentCancelled:
        return 'status_cancelled';
      case appointmentNoShow:
        return 'status_no_show';
      default:
        return 'status_pending';
    }
  }

  // ── Appointment Reasons
  static const String reasonFever = 'Fever';
  static const String reasonCheckup = 'Checkup';
  static const String reasonFollowUp = 'Follow-up';
  static const String reasonOther = 'Other';

  static const List<String> appointmentReasons = [
    reasonFever,
    reasonCheckup,
    reasonFollowUp,
    reasonOther,
  ];

  /// Localisation key for a visit reason. The stored value stays English
  /// (it is schema data, SRS §7.7) while the label follows the user's
  /// language.
  static String reasonLabelKey(String reason) {
    switch (reason) {
      case reasonFever:
        return 'reason_fever';
      case reasonCheckup:
        return 'reason_checkup';
      case reasonFollowUp:
        return 'reason_followup';
      default:
        return 'reason_other';
    }
  }

  // ── Severity Levels
  static const String severityMild = 'mild';
  static const String severityModerate = 'moderate';
  static const String severitySevere = 'severe';

  // ── Gender
  // Stored capitalised, matching the existing production data. SRS §7.5
  // documents lowercase; changing it now would require migrating every
  // patient record for no functional gain, so the schema doc is corrected
  // instead (see TECHNICAL_ASSESSMENT.md §12).
  static const String genderMale = 'Male';
  static const String genderFemale = 'Female';
  static const String genderOther = 'Other';

  static const List<String> genders = [genderMale, genderFemale, genderOther];

  /// Localisation key for a gender value.
  static String genderLabelKey(String gender) {
    switch (gender) {
      case genderMale:
        return 'gender_male';
      case genderFemale:
        return 'gender_female';
      default:
        return 'gender_other';
    }
  }

  // ── Created By
  static const String createdBySelf = 'self';
  static const String createdByHealthCenter = 'health_center';

  // ── Languages
  static const String langEnglish = 'en';
  static const String langMarathi = 'mr';
  static const String langHindi = 'hi';

  // ── Notification Types
  static const String notifDoctorPending = 'doctor_registration_pending';
  static const String notifDoctorApproved = 'doctor_approved';
  static const String notifDoctorRejected = 'doctor_rejected';
  static const String notifAppointmentBooked = 'appointment_booked';
  static const String notifAppointmentAccepted = 'appointment_accepted';
  static const String notifAppointmentRejected = 'appointment_rejected';
  static const String notifAppointmentCancelled = 'appointment_cancelled';
  static const String notifAppointmentReminder = 'appointment_reminder_24h';
  static const String notifAppointmentCompleted = 'appointment_completed';
  static const String notifAppointmentNoShow = 'appointment_no_show';

  // ── Route Paths
  static const String routeSplash = '/';
  static const String routePhoneInput = '/login';
  static const String routeOtpVerification = '/otp';
  static const String routeAdminDashboard = '/admin/dashboard';
  static const String routeDoctorDashboard = '/doctor/dashboard';
  static const String routeDoctorAwaiting = '/doctor/awaiting';
  static const String routePatientDashboard = '/patient/dashboard';
  static const String routePatientProfile = '/patient/profile';
  static const String routeOperatorDashboard = '/operator/dashboard';
  static const String routeDoctorProfile = '/doctor/profile';
  static const String routeNotifications = '/notifications';
  static const String routeHealthRecords = '/patient/records';

  // ── UX Constants (Rural-First)
  static const double minTapTarget = 56.0;
  static const double minBodyFontSize = 18.0;
  static const double minHeadingFontSize = 22.0;
  static const int maxBookingDaysAhead = 30;
  static const int cancelWindowHours = 2;
  static const int paginationLimit = 20;
}
