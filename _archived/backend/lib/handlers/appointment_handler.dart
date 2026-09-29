import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:gas_backend/middleware/auth_middleware.dart';
import 'package:gas_backend/services/firestore_admin.dart';

/// Handles all appointment-related API endpoints.
///
/// Key difference from client-side FirestoreService: all business logic
/// (double-booking prevention, cancellation window enforcement, status
/// transitions) runs server-side where it cannot be bypassed.
class AppointmentHandler {
  /// POST /api/v1/appointments/book
  ///
  /// Server-side atomic booking with double-booking prevention.
  /// SRS §P-FLOW-02: Booking requires network, runs as Firestore transaction.
  static Future<Response> book(Request request) async {
    try {
      final uid = getUid(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      // Validate required fields
      final requiredFields = [
        'patientId', 'doctorId', 'date', 'timeSlot', 'reason',
      ];
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
      final doctorId = body['doctorId'] as String;
      final date = body['date'] as String;
      final timeSlot = body['timeSlot'] as String;

      // Run atomic booking transaction
      final appointmentId = await db.runTransaction((tx) async {
        // 1. Read the slot document
        final availDocId = '${doctorId}_$date';
        final availRef = db.collection('doctor_availability').doc(availDocId);
        final availSnap = await tx.get(availRef);

        if (!availSnap.exists) {
          throw BookingException('No availability for this doctor on $date');
        }

        final availData = availSnap.data()!;
        final slots = (availData['slots'] as List<dynamic>?) ?? [];
        final slotIndex = slots.indexWhere(
            (s) => (s as Map<String, dynamic>)['time'] == timeSlot);

        if (slotIndex == -1) {
          throw BookingException('Slot $timeSlot does not exist');
        }

        final slot = slots[slotIndex] as Map<String, dynamic>;
        if (slot['isBooked'] == true) {
          throw BookingException('Slot $timeSlot is already booked');
        }

        // 2. Create appointment document
        final appointmentRef = db.collection('appointments').doc();
        final appointmentId = appointmentRef.id;

        final healthCenterId = availData['healthCenterId'] as String? ?? '';

        final appointmentData = {
          'appointmentId': appointmentId,
          'patientId': body['patientId'],
          'patientUserId': body['patientUserId'] ?? uid,
          'patientName': body['patientName'] ?? '',
          'doctorId': doctorId,
          'healthCenterId': healthCenterId,
          'villageId': body['villageId'] ?? '',
          'date': date,
          'timeSlot': timeSlot,
          'reason': body['reason'],
          'status': 'pending',
          'createdBy': body['createdBy'] ?? 'self',
          'createdByOperatorId': body['createdByOperatorId'],
          'reminderSent': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          if (body['intakeForm'] != null) 'intakeForm': body['intakeForm'],
        };

        // 3. Mark slot as booked
        slots[slotIndex] = {
          ...slot,
          'isBooked': true,
          'appointmentId': appointmentId,
        };

        tx.update(availRef, {'slots': slots});
        tx.set(appointmentRef, appointmentData);

        return appointmentId;
      });

      return Response.ok(
        jsonEncode({
          'appointmentId': appointmentId,
          'message': 'Appointment booked successfully',
        }),
        headers: {'content-type': 'application/json'},
      );
    } on BookingException catch (e) {
      return Response(409,
          body: jsonEncode({
            'error': e.message,
            'code': 'SLOT_UNAVAILABLE',
          }),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to book appointment',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/v1/appointments/<id>/cancel
  ///
  /// Server-enforced 2-hour cancellation window.
  /// SRS §P-FLOW-03: Patient can only cancel ≥2 hours before appointment.
  static Future<Response> cancel(Request request, String id) async {
    try {
      final uid = getUid(request);
      final db = FirestoreAdmin.instance;

      final appointmentRef = db.collection('appointments').doc(id);
      final appointmentSnap = await appointmentRef.get();

      if (!appointmentSnap.exists) {
        return Response(404,
            body: jsonEncode({
              'error': 'Appointment not found',
              'code': 'NOT_FOUND',
            }),
            headers: {'content-type': 'application/json'});
      }

      final data = appointmentSnap.data()!;

      // Verify ownership: patient or operator who created it
      final patientUserId = data['patientUserId'] as String?;
      final createdByOperatorId = data['createdByOperatorId'] as String?;
      if (patientUserId != uid && createdByOperatorId != uid) {
        return Response(403,
            body: jsonEncode({
              'error': 'You can only cancel your own appointments',
              'code': 'PERMISSION_DENIED',
            }),
            headers: {'content-type': 'application/json'});
      }

      // Enforce 2-hour cancellation window (server-side)
      final date = data['date'] as String;
      final timeSlot = data['timeSlot'] as String;
      if (_isWithinCancelWindow(date, timeSlot)) {
        return Response(400,
            body: jsonEncode({
              'error':
                  'Cannot cancel within 2 hours of appointment. Please contact the health centre.',
              'code': 'CANCEL_WINDOW_EXPIRED',
            }),
            headers: {'content-type': 'application/json'});
      }

      // Run cancellation transaction — free the slot
      await db.runTransaction((tx) async {
        final doctorId = data['doctorId'] as String;
        final availDocId = '${doctorId}_$date';
        final availRef =
            db.collection('doctor_availability').doc(availDocId);
        final availSnap = await tx.get(availRef);

        if (availSnap.exists) {
          final availData = availSnap.data()!;
          final slots = (availData['slots'] as List<dynamic>?) ?? [];
          final slotIndex = slots.indexWhere(
              (s) => (s as Map<String, dynamic>)['time'] == timeSlot);

          if (slotIndex != -1) {
            slots[slotIndex] = {
              ...(slots[slotIndex] as Map<String, dynamic>),
              'isBooked': false,
              'appointmentId': null,
            };
            tx.update(availRef, {'slots': slots});
          }
        }

        tx.update(appointmentRef, {
          'status': 'cancelled',
          'cancelledAt': DateTime.now().toUtc().toIso8601String(),
          'cancelledBy': uid,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      });

      return Response.ok(
        jsonEncode({'message': 'Appointment cancelled successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to cancel appointment',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// PATCH /api/v1/appointments/<id>/status
  ///
  /// Doctor updates appointment status (accept/reject/complete/no_show).
  /// SRS §D-FLOW-02/03/04/05.
  static Future<Response> updateStatus(Request request, String id) async {
    try {
      final uid = getUid(request);
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final newStatus = body['status'] as String?;

      if (newStatus == null) {
        return Response(400,
            body: jsonEncode({
              'error': 'Missing status field',
              'code': 'INVALID_ARGUMENT',
            }),
            headers: {'content-type': 'application/json'});
      }

      // Validate status is a valid doctor transition
      final validStatuses = [
        'accepted', 'rejected', 'completed', 'no_show',
      ];
      if (!validStatuses.contains(newStatus)) {
        return Response(400,
            body: jsonEncode({
              'error': 'Invalid status: $newStatus',
              'code': 'INVALID_ARGUMENT',
            }),
            headers: {'content-type': 'application/json'});
      }

      final db = FirestoreAdmin.instance;
      final appointmentRef = db.collection('appointments').doc(id);
      final appointmentSnap = await appointmentRef.get();

      if (!appointmentSnap.exists) {
        return Response(404,
            body: jsonEncode({
              'error': 'Appointment not found',
              'code': 'NOT_FOUND',
            }),
            headers: {'content-type': 'application/json'});
      }

      final data = appointmentSnap.data()!;

      // Verify the requesting user is the doctor for this appointment
      if (data['doctorId'] != uid) {
        return Response(403,
            body: jsonEncode({
              'error': 'Only the assigned doctor can update appointment status',
              'code': 'PERMISSION_DENIED',
            }),
            headers: {'content-type': 'application/json'});
      }

      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      // If rejected, free the slot
      if (newStatus == 'rejected') {
        updateData['rejectionReason'] =
            body['rejectionReason'] ?? 'Doctor unavailable';

        await db.runTransaction((tx) async {
          final doctorId = data['doctorId'] as String;
          final date = data['date'] as String;
          final timeSlot = data['timeSlot'] as String;
          final availDocId = '${doctorId}_$date';
          final availRef =
              db.collection('doctor_availability').doc(availDocId);
          final availSnap = await tx.get(availRef);

          if (availSnap.exists) {
            final availData = availSnap.data()!;
            final slots = (availData['slots'] as List<dynamic>?) ?? [];
            final slotIndex = slots.indexWhere(
                (s) => (s as Map<String, dynamic>)['time'] == timeSlot);
            if (slotIndex != -1) {
              slots[slotIndex] = {
                ...(slots[slotIndex] as Map<String, dynamic>),
                'isBooked': false,
                'appointmentId': null,
              };
              tx.update(availRef, {'slots': slots});
            }
          }

          tx.update(appointmentRef, updateData);
        });
      } else {
        // If completed, add visitSummary
        if (newStatus == 'completed' && body['visitSummary'] != null) {
          updateData['visitSummary'] = body['visitSummary'];
        }

        await appointmentRef.update(updateData);
      }

      return Response.ok(
        jsonEncode({'message': 'Appointment status updated to $newStatus'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to update appointment status',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Server-side 2-hour cancellation window check.
  /// Uses server clock (not client clock) — cannot be manipulated.
  static bool _isWithinCancelWindow(String date, String timeSlot) {
    try {
      // Parse "2026-07-01" + "09:00 AM"
      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time (simple AM/PM parser)
      final timeParts = timeSlot.split(' ');
      final hm = timeParts[0].split(':');
      var hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPm = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      final appointmentTime = DateTime(year, month, day, hour, minute);
      final hoursUntil = appointmentTime.difference(DateTime.now()).inHours;
      return hoursUntil < 2;
    } catch (_) {
      return true; // If we can't parse, block cancellation (safe default)
    }
  }
}

/// Custom exception for booking conflicts.
class BookingException implements Exception {
  final String message;
  BookingException(this.message);

  @override
  String toString() => 'BookingException: $message';
}
