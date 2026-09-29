import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:gas_backend/app.dart';

/// Gram Aarogya Seva — Cloud Run API entry point.
///
/// Binds to PORT env var (Cloud Run standard) or 8080 for local dev.
Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final handler = await createApp();

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('🏥 GAS API listening on port ${server.port}');
}
