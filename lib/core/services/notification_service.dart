import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/services/firestore_service.dart';

/// Handles a push that arrives while the app is terminated or backgrounded.
///
/// Must be a top-level function: Android runs it in a separate isolate with no
/// access to the app's state. It deliberately does nothing — Android already
/// displays the notification tray entry from the `notification` payload, and
/// the authoritative record is the Firestore document the Cloud Function wrote
/// alongside the push. Doing work here would duplicate that.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
}

/// FCM lifecycle: permission, token, and what to do when a push is tapped.
///
/// Push is **best-effort** by design (SRS §12.2). Every event that produces a
/// push also writes a `notifications` document, and the app's Firestore
/// streams update live — so a dropped push degrades the experience but never
/// loses information. That is what makes it safe to fail silently here.
class NotificationService {
  NotificationService(this._firestore, [FirebaseMessaging? messaging])
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirestoreService _firestore;
  final FirebaseMessaging _messaging;

  /// Route to open when the user taps a push, or null to stay put.
  static String? routeForType(String? type) {
    if (type == null) return null;
    if (type.startsWith('doctor_')) return AppConstants.routeDoctorAwaiting;
    return AppConstants.routeNotifications;
  }

  /// Requests notification permission and registers the device token.
  ///
  /// Android 13+ requires a runtime prompt. A user who declines still gets
  /// every status change in the in-app inbox, so we ask once and move on
  /// rather than nagging.
  Future<void> registerFor(String uid) async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.updateFcmToken(uid, token);
      }

      // Tokens rotate — on reinstall, restore, or when FCM decides to. A
      // stale token means silent delivery failure, which is exactly the
      // failure mode nobody notices, so refresh writes straight through.
      _messaging.onTokenRefresh.listen((refreshed) {
        _firestore.updateFcmToken(uid, refreshed).catchError((Object e) {
          debugPrint('[FCM] token refresh write failed: $e');
        });
      });
    } catch (e) {
      // Never block sign-in on notification setup.
      debugPrint('[FCM] registration failed: $e');
    }
  }

  /// Clears the stored token so a shared device stops receiving pushes for
  /// the user who just signed out. Shared phones are common in the target
  /// deployment, so this is a privacy requirement rather than tidiness.
  Future<void> unregisterFor(String uid) async {
    try {
      await _firestore.updateFcmToken(uid, '');
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] unregister failed: $e');
    }
  }

  /// Stream of routes to navigate to, from pushes tapped by the user.
  Stream<String> get onNotificationTap async* {
    try {
      // App opened from a terminated state by tapping a push.
      final initial = await _messaging.getInitialMessage();
      final initialRoute = routeForType(initial?.data['type'] as String?);
      if (initialRoute != null) yield initialRoute;
    } catch (e) {
      debugPrint('[FCM] getInitialMessage failed: $e');
    }

    // App resumed from background by tapping a push.
    yield* FirebaseMessaging.onMessageOpenedApp
        .map((message) => routeForType(message.data['type'] as String?))
        .where((route) => route != null)
        .cast<String>();
  }

  /// Foreground pushes.
  ///
  /// Deliberately not rendered as a system notification: the screens are
  /// already driven by live Firestore streams, so the list updates and the
  /// unread badge increments on its own. Showing a tray notification for
  /// something the user is looking at is noise.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
