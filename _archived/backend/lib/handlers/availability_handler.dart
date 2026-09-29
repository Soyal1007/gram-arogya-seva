import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:gas_backend/middleware/auth_middleware.dart';
import 'package:gas_backend/services/firestore_admin.dart';

/// Handles doctor availability API endpoints.
class AvailabilityHandler {
  /// GET /api/v1/availability/<doctorId>/<date>
  ///
  /// Returns availability and slots for a doctor on a specific date.
  static Future<Response> getSlots(
      Request request, String doctorId, String date) async {
    try {
      final db = FirestoreAdmin.instance;
      final docId = '${doctorId}_$date';
      final snap =
          await db.collection('doctor_availability').doc(docId).get();

      if (!snap.exists) {
        return Response.ok(
          jsonEncode({'available': false, 'slots': []}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'available': true,
          ...snap.data()!,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to fetch availability',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// POST /api/v1/availability/set
  ///
  /// Doctor sets their availability for a date.
  /// SRS §D-FLOW-02: Doctor creates/updates availability with time slots.
  static Future<Response> setAvailability(Request request) async {
    try {
      final uid = getUid(request);
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final date = body['date'] as String?;
      final healthCenterId = body['healthCenterId'] as String?;
      final slots = body['slots'] as List<dynamic>?;

      if (date == null || healthCenterId == null || slots == null) {
        return Response(400,
            body: jsonEncode({
              'error': 'Missing required fields: date, healthCenterId, slots',
              'code': 'INVALID_ARGUMENT',
            }),
            headers: {'content-type': 'application/json'});
      }

      // Verify requesting user is actually a doctor
      final db = FirestoreAdmin.instance;
      final doctorSnap = await db.collection('doctors').doc(uid).get();
      if (!doctorSnap.exists ||
          doctorSnap.data()?['status'] != 'active') {
        return Response(403,
            body: jsonEncode({
              'error': 'Only active doctors can set availability',
              'code': 'PERMISSION_DENIED',
            }),
            headers: {'content-type': 'application/json'});
      }

      final docId = '${uid}_$date';
      final availRef = db.collection('doctor_availability').doc(docId);
      final existingSnap = await availRef.get();

      if (existingSnap.exists) {
        // Merge: preserve already-booked slots
        final existingSlots =
            (existingSnap.data()?['slots'] as List<dynamic>?) ?? [];
        final bookedSlots = existingSlots
            .where((s) => (s as Map<String, dynamic>)['isBooked'] == true)
            .toList();
        final bookedTimes = bookedSlots
            .map((s) => (s as Map<String, dynamic>)['time'] as String)
            .toSet();

        // New slots = provided slots (skip already booked times) + booked slots
        final mergedSlots = <Map<String, dynamic>>[];
        for (final slot in slots) {
          final slotMap = slot as Map<String, dynamic>;
          if (!bookedTimes.contains(slotMap['time'])) {
            mergedSlots.add(slotMap);
          }
        }
        mergedSlots.addAll(bookedSlots.cast<Map<String, dynamic>>());
        // Sort by time
        mergedSlots.sort((a, b) =>
            (a['time'] as String).compareTo(b['time'] as String));

        await availRef.update({
          'slots': mergedSlots,
          'healthCenterId': healthCenterId,
          'lastUpdatedBy': uid,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await availRef.set({
          'doctorId': uid,
          'healthCenterId': healthCenterId,
          'date': date,
          'slots': slots,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'lastUpdatedBy': uid,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      }

      return Response.ok(
        jsonEncode({'message': 'Availability set for $date'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to set availability',
          'code': 'INTERNAL',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
