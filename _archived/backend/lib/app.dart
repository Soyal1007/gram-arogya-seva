import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:gas_backend/middleware/auth_middleware.dart';
import 'package:gas_backend/middleware/logging_middleware.dart';
import 'package:gas_backend/middleware/cors_middleware.dart';
import 'package:gas_backend/handlers/appointment_handler.dart';
import 'package:gas_backend/handlers/availability_handler.dart';
import 'package:gas_backend/handlers/doctor_handler.dart';
import 'package:gas_backend/handlers/health_check_handler.dart';

/// Creates the full Shelf handler with middleware pipeline and routes.
///
/// Middleware order (outermost first):
/// 1. CORS — allows Flutter web (future) + local dev
/// 2. Logging — structured JSON request/response logging
/// 3. Auth — Firebase JWT token validation
/// 4. Router — dispatches to handlers
Future<Handler> createApp() async {
  final router = Router();

  // Health check (no auth required)
  router.get('/health', healthCheckHandler);

  // API v1 routes (all require auth)
  final apiRouter = Router();

  // Appointments
  apiRouter.post('/appointments/book', AppointmentHandler.book);
  apiRouter.post('/appointments/<id>/cancel', AppointmentHandler.cancel);
  apiRouter.patch('/appointments/<id>/status', AppointmentHandler.updateStatus);

  // Availability
  apiRouter.get('/availability/<doctorId>/<date>',
      AvailabilityHandler.getSlots);
  apiRouter.post('/availability/set', AvailabilityHandler.setAvailability);

  // Doctors
  apiRouter.post('/doctors/register', DoctorHandler.register);
  apiRouter.patch('/doctors/<id>/approve', DoctorHandler.approve);
  apiRouter.patch('/doctors/<id>/reject', DoctorHandler.reject);

  // Mount API routes under /api/v1 with auth middleware
  router.mount(
    '/api/v1/',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(apiRouter.call),
  );

  // Build full pipeline
  final handler = const Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(loggingMiddleware())
      .addHandler(router.call);

  return handler;
}
