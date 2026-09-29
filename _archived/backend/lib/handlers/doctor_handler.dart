import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:gas_backend/middleware/auth_middleware.dart';
import 'package:gas_backend/services/firestore_admin.dart';

/// Handles doctor registration and admin approval/rejection.
class DoctorHandler {
  /// POST /api/v1/doctors/register
  ///
  /// Doctor submits registration with credentials.
  /// SRS §D-FLOW-01: 4-step registration → pending_approval.
  static Future<Response> register(Request request) async {
    try {
      final uid = getUid(request);
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final requiredFields = ['name', 'specialization', 'registrationNumber'];
      for (final field in requiredFields) {
        if (body[field] == null || (body[field] as String).isEmpty) {
          return Response(400,
              body: jsonEncode({
                'error': 'Missing required field: $field',
                'code': 'INVALID_ARGUMENT',
              }),
              headers: {'content-type': 'application/json'});
        }
      }

      final db = FirestoreAdmin.instance;

      // Check if doctor already exists
      final existing = await db.collection('doctors').doc(uid).get();
      if (existing.exists) {
        return Response(409,
            body: jsonEncode({
              'error': 'Doctor profile already exists',
              'code': 'ALREADY_EXISTS',
              'status': existing.data()?['status'],
            }),
            headers: {'content-type': 'application/json'});
      }

      final doctorData = {
        'doctorId': uid,
        'name': body['name'],
        'specialization': body['specialization'],
        'registrationNumber': body['registrationNumber'],
        'phone': body['phone'] ?? '',
        'healthCenterId': body['healthCenterId'] ?? '',
        'aadhaarHash': body['aadhaarHash'] ?? '',
        'abdmVerified': body['abdmVerified'] ?? false,
        'status': 'pending_approval',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await db.collection('doctors').doc(uid).set(doctorData);

      // Update user role to 'doctor'
      await db.collection('users').doc(uid).update({
        'role': 'doctor',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      return Response.ok(
        jsonEncode({
          'message': 'Doctor registration submitted for approval',
          'doctorId': uid,
          'status': 'pending_approval',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to register doctor',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// PATCH /api/v1/doctors/<id>/approve
  ///
  /// Admin approves a pending doctor.
  /// SRS §A-FLOW-02: Admin reviews and approves doctor.
  static Future<Response> approve(Request request, String id) async {
    try {
      final uid = getUid(request);
      final db = FirestoreAdmin.instance;

      // Verify the caller is an admin
      final callerUser = await db.collection('users').doc(uid).get();
      if (!callerUser.exists || callerUser.data()?['role'] != 'admin') {
        return Response(403,
            body: jsonEncode({
              'error': 'Only admins can approve doctors',
              'code': 'PERMISSION_DENIED',
            }),
            headers: {'content-type': 'application/json'});
      }

      final doctorRef = db.collection('doctors').doc(id);
      final doctorSnap = await doctorRef.get();

      if (!doctorSnap.exists) {
        return Response(404,
            body: jsonEncode({
              'error': 'Doctor not found',
              'code': 'NOT_FOUND',
            }),
            headers: {'content-type': 'application/json'});
      }

      if (doctorSnap.data()?['status'] != 'pending_approval') {
        return Response(400,
            body: jsonEncode({
              'error':
                  'Doctor is not in pending_approval status (current: ${doctorSnap.data()?['status']})',
              'code': 'INVALID_STATE',
            }),
            headers: {'content-type': 'application/json'});
      }

      await doctorRef.update({
        'status': 'active',
        'approvedBy': uid,
        'approvedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      // TODO: Send FCM notification to doctor (Phase 4)

      return Response.ok(
        jsonEncode({'message': 'Doctor approved successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to approve doctor',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// PATCH /api/v1/doctors/<id>/reject
  ///
  /// Admin rejects a pending doctor.
  static Future<Response> reject(Request request, String id) async {
    try {
      final uid = getUid(request);
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final db = FirestoreAdmin.instance;

      // Verify the caller is an admin
      final callerUser = await db.collection('users').doc(uid).get();
      if (!callerUser.exists || callerUser.data()?['role'] != 'admin') {
        return Response(403,
            body: jsonEncode({
              'error': 'Only admins can reject doctors',
              'code': 'PERMISSION_DENIED',
            }),
            headers: {'content-type': 'application/json'});
      }

      final doctorRef = db.collection('doctors').doc(id);
      final doctorSnap = await doctorRef.get();

      if (!doctorSnap.exists) {
        return Response(404,
            body: jsonEncode({
              'error': 'Doctor not found',
              'code': 'NOT_FOUND',
            }),
            headers: {'content-type': 'application/json'});
      }

      await doctorRef.update({
        'status': 'rejected',
        'rejectionNote': body['rejectionNote'] ?? 'Application rejected',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedBy': uid,
      });

      // TODO: Send FCM notification to doctor (Phase 4)

      return Response.ok(
        jsonEncode({'message': 'Doctor rejected'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to reject doctor',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
