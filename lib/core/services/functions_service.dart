import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';

/// Client for the server-authoritative half of the system.
///
/// Every mutation that spans more than one document, or that decides who a
/// user is, lives in Cloud Functions rather than in this app
/// (TECHNICAL_ASSESSMENT.md §A17-1). This class is the only place that knows
/// the callable names and payload shapes, and it converts every transport
/// failure into an [AppException] so screens never see a Firebase code.
class FunctionsService {
  FunctionsService([FirebaseFunctions? functions])
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: _region);

  static const String _region = 'asia-south1';

  final FirebaseFunctions _functions;

  // ═══════════════════════════════════════════════════
  // DOCTOR REGISTRATION
  // ═══════════════════════════════════════════════════

  /// Requests an Aadhaar OTP through the ABDM gateway (SRS §9.2).
  Future<String> requestAadhaarOtp(String aadhaarNumber) async {
    final result = await _call('abdmRequestAadhaarOtp', {
      'aadhaarNumber': aadhaarNumber,
    });
    return result['txnId'] as String;
  }

  /// Verifies the Aadhaar OTP. The server records the outcome, so the
  /// registration submit below can require proof rather than trust the client.
  Future<void> verifyAadhaarOtp({
    required String txnId,
    required String otp,
  }) async {
    await _call('abdmVerifyAadhaarOtp', {'txnId': txnId, 'otp': otp});
  }

  /// Creates the doctor profile and promotes the caller's role.
  ///
  /// The plaintext Aadhaar is sent over TLS to be hashed with a server-side
  /// HMAC key and is never persisted (SRS §7.10).
  Future<void> submitDoctorRegistration({
    required String name,
    required String specialization,
    required String mobile,
    required String nmrId,
    required String hprId,
    required String aadhaarNumber,
    required List<String> villages,
    String? photoBase64,
  }) async {
    await _call('submitDoctorRegistration', {
      'name': name,
      'specialization': specialization,
      'mobile': mobile,
      'nmrId': nmrId,
      'hprId': hprId,
      'aadhaarNumber': aadhaarNumber,
      'villages': villages,
      'photoBase64': ?photoBase64,
    });
  }

  /// Returns a rejected registration to the approval queue (SRS D-FLOW-01).
  Future<void> resubmitDoctorRegistration() async {
    await _call('resubmitDoctorRegistration', const {});
  }

  // ═══════════════════════════════════════════════════
  // AVAILABILITY
  // ═══════════════════════════════════════════════════

  /// Saves a doctor's slots for one date. Already-booked slots are preserved
  /// server-side regardless of what is sent (SRS D-FLOW-02).
  Future<void> setAvailability({
    required String doctorId,
    required String date,
    required String healthCenterId,
    required List<String> slotTimes,
  }) async {
    await _call('setDoctorAvailability', {
      'doctorId': doctorId,
      'date': date,
      'healthCenterId': healthCenterId,
      'slots': slotTimes,
    });
  }

  // ═══════════════════════════════════════════════════
  // APPOINTMENTS
  // ═══════════════════════════════════════════════════

  /// Books a slot atomically. Returns the new appointment id.
  ///
  /// Only identifiers are sent: patient name, doctor name, health centre and
  /// village are resolved server-side so they cannot be forged.
  Future<String> bookAppointment({
    required String doctorId,
    required String patientId,
    required String date,
    required String timeSlot,
    required String reason,
    required IntakeForm intakeForm,
  }) async {
    final result = await _call('bookAppointment', {
      'doctorId': doctorId,
      'patientId': patientId,
      'date': date,
      'timeSlot': timeSlot,
      'reason': reason,
      'intakeForm': {
        'symptoms': intakeForm.symptoms,
        'duration': intakeForm.duration,
        'severity': intakeForm.severity,
      },
    });
    return result['appointmentId'] as String;
  }

  /// Cancels an appointment and frees its slot. The 2-hour window is enforced
  /// server-side (SRS P-FLOW-03).
  Future<void> cancelAppointment(String appointmentId) async {
    await _call('cancelAppointment', {'appointmentId': appointmentId});
  }

  /// Doctor status transitions: accept, reject, complete, no-show.
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? prepInstructions,
    String? rejectionReason,
    VisitSummary? visitSummary,
  }) async {
    await _call('updateAppointmentStatus', {
      'appointmentId': appointmentId,
      'status': status,
      'prepInstructions': ?prepInstructions,
      'rejectionReason': ?rejectionReason,
      if (visitSummary != null)
        'visitSummary': {
          'notes': visitSummary.notes,
          'prescription': visitSummary.prescription,
          'nextSteps': visitSummary.nextSteps,
          'followUpDate': ?visitSummary.followUpDate,
        },
    });
  }

  /// Bulk-cancels a doctor's day and frees every slot (SRS A-FLOW-03).
  /// Returns the number of appointments cancelled.
  Future<int> cancelDoctorDay({
    required String doctorId,
    required String date,
  }) async {
    final result = await _call('cancelDoctorDay', {
      'doctorId': doctorId,
      'date': date,
    });
    return (result['cancelled'] as num?)?.toInt() ?? 0;
  }

  // ═══════════════════════════════════════════════════
  // TRANSPORT
  // ═══════════════════════════════════════════════════

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } on FirebaseFunctionsException catch (e) {
      throw _mapException(name, e);
    } catch (e) {
      debugPrint('[FunctionsService] $name failed: $e');
      throw UnexpectedException(e.toString());
    }
  }

  /// Maps Cloud Functions status codes onto the app's error taxonomy.
  /// The mapping is deliberate on the server side: each `HttpsError` code is
  /// chosen for the client behaviour it should produce.
  AppException _mapException(String name, FirebaseFunctionsException e) {
    debugPrint('[FunctionsService] $name → ${e.code}: ${e.message}');
    return switch (e.code) {
      'already-exists' => SlotAlreadyBookedException(e.message),
      'deadline-exceeded' => CancelWindowClosedException(e.message),
      'permission-denied' || 'unauthenticated' =>
        PermissionDeniedException(e.message),
      'unavailable' => ServiceUnavailableException(e.message),
      'resource-exhausted' =>
        const InvalidOperationException('error_rate_limited'),
      'failed-precondition' || 'not-found' || 'invalid-argument' =>
        InvalidOperationException('error_generic', e.message),
      _ => UnexpectedException(e.message),
    };
  }
}
