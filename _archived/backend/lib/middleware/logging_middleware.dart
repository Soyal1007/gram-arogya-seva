import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Structured JSON logging middleware.
///
/// Logs every request/response in Cloud Logging-compatible JSON format.
/// Fields: severity, method, path, status, latencyMs, timestamp.
Middleware loggingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();

      Response response;
      try {
        response = await innerHandler(request);
      } catch (e) {
        stopwatch.stop();
        _log('ERROR', request.method, request.requestedUri.path, 500,
            stopwatch.elapsedMilliseconds,
            error: e.toString());
        rethrow;
      }

      stopwatch.stop();
      _log(
        response.statusCode >= 400 ? 'WARNING' : 'INFO',
        request.method,
        request.requestedUri.path,
        response.statusCode,
        stopwatch.elapsedMilliseconds,
      );

      return response;
    };
  };
}

void _log(String severity, String method, String path, int status,
    int latencyMs,
    {String? error}) {
  final entry = {
    'severity': severity,
    'message': '$method $path → $status (${latencyMs}ms)',
    'httpRequest': {
      'requestMethod': method,
      'requestUrl': path,
      'status': status,
      'latency': '${latencyMs / 1000}s',
    },
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    if (error != null) 'error': error,
  };
  // Cloud Logging picks up structured JSON from stdout
  print(jsonEncode(entry));
}
