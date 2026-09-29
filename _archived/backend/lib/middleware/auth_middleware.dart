import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;

/// Firebase Auth JWT validation middleware.
///
/// Verifies the `Authorization: Bearer <token>` header by calling
/// Google's tokeninfo endpoint. In production, use Firebase Admin SDK
/// for local validation with cached public keys.
///
/// Injects `uid` and `phone` into request context for downstream handlers.
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401,
            body: jsonEncode({
              'error': 'Missing or invalid Authorization header',
              'code': 'UNAUTHENTICATED',
            }),
            headers: {'content-type': 'application/json'});
      }

      final token = authHeader.substring(7);

      try {
        // Verify token with Google's tokeninfo endpoint
        // In production, replace with Firebase Admin SDK local verification
        final response = await http.get(Uri.parse(
          'https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=$token',
        ));

        if (response.statusCode != 200) {
          return Response(401,
              body: jsonEncode({
                'error': 'Invalid or expired token',
                'code': 'UNAUTHENTICATED',
              }),
              headers: {'content-type': 'application/json'});
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final uid = payload['sub'] as String?;

        if (uid == null) {
          return Response(401,
              body: jsonEncode({
                'error': 'Token missing user ID',
                'code': 'UNAUTHENTICATED',
              }),
              headers: {'content-type': 'application/json'});
        }

        // Inject auth context into request
        final updatedRequest = request.change(context: {
          'uid': uid,
          'phone': payload['phone_number'] ?? '',
        });

        return innerHandler(updatedRequest);
      } catch (e) {
        return Response(401,
            body: jsonEncode({
              'error': 'Token verification failed',
              'code': 'UNAUTHENTICATED',
              'details': e.toString(),
            }),
            headers: {'content-type': 'application/json'});
      }
    };
  };
}

/// Extracts the authenticated user's UID from the request context.
/// Must be called after [authMiddleware].
String getUid(Request request) => request.context['uid'] as String;
