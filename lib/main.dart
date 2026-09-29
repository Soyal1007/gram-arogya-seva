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
  FirestoreService.configureOfflinePersistence();

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
  //
  // The Firebase config inside an APK is public, so without attestation anyone
  // can call the Firestore REST API with it. Security rules still protect the
  // data; App Check is what stops an attacker burning the free tier.
  //
  // Debug builds use the debug provider — register the token it prints in the
  // Firebase console when testing on a new device.
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  // Registered before runApp so a push that launched the app is handled in
  // the background isolate.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
