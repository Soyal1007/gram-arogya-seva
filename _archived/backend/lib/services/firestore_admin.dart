import 'dart:io';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart'
    hide Credential;

/// Singleton wrapper around firebase_admin_sdk Firestore.
///
/// Initialised lazily on first access. Uses Application Default Credentials
/// (ADC) on Cloud Run, or GOOGLE_APPLICATION_CREDENTIALS for local dev.
///
/// Usage:
///   final db = FirestoreAdmin.instance;
///   final snap = await db.collection('users').doc('abc').get();
class FirestoreAdmin {
  static Firestore? _firestore;
  static FirebaseApp? _app;

  FirestoreAdmin._();

  /// Returns the Firestore instance, initialising on first call.
  static Firestore get instance {
    if (_firestore != null) return _firestore!;

    final projectId = Platform.environment['GCP_PROJECT'] ??
        Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
        'gram-aarogya-seva';

    _app = FirebaseApp.initializeApp(
      options: AppOptions(
        projectId: projectId,
        credential: Credential.fromApplicationDefaultCredentials(),
      ),
    );

    _firestore = _app!.firestore();
    print('🔥 Firestore Admin initialised for project: $projectId');
    return _firestore!;
  }

  /// Graceful shutdown — flushes pending writes.
  static Future<void> close() async {
    await _app?.close();
    _firestore = null;
    _app = null;
  }
}
