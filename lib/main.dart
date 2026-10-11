import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/app.dart';
import 'package:gram_aarogya_seva/core/services/firestore_service.dart';
import 'package:gram_aarogya_seva/core/services/notification_service.dart';
import 'package:gram_aarogya_seva/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline reads (SRS DP-2). Configured through FirestoreService so the
  // `cloud_firestore` import stays confined to the data layer (SRS §6.2).
  try {
    FirestoreService.configureOfflinePersistence();
  } catch (e) {
    debugPrint('[Firestore] configureOfflinePersistence failed: $e');
  }

  // ── Crash reporting (SRS §21, risk R-16)
  //
  // A pilot runs on phones nobody can inspect, used by people who will not
  // file bug reports — they will simply stop opening the app. Without
  // Crashlytics, a crash specific to one device model is invisible forever.
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── App Check (SRS §21, concern S-6)
  // App Check is only enforced in RELEASE builds. In debug builds we skip it
  // entirely so OTP calls are never blocked by a missing debug-token
  // registration in the Firebase console.
  if (!kDebugMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    } catch (e) {
      debugPrint('[AppCheck] activation failed: $e');
    }
  }

  // Registered before runApp so a push that launched the app is handled in
  // the background isolate.
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Messaging] background handler registration failed: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('mr'),
        Locale('hi'),
      ],
      path: 'assets/l10n',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: GramAarogyaSevaApp(),
      ),
    ),
  );
}
