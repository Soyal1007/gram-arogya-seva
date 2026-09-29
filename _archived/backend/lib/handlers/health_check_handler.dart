import 'dart:convert';
import 'package:shelf/shelf.dart';

/// GET /health — Cloud Run liveness/readiness probe.
///
/// Returns 200 with service metadata. No auth required.
Future<Response> healthCheckHandler(Request request) async {
  return Response.ok(
    jsonEncode({
      'status': 'healthy',
      'service': 'gas-api',
      'version': '1.0.0',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    }),
    headers: {'content-type': 'application/json'},
  );
}
