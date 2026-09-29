import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gram_aarogya_seva/core/services/firestore_service.dart';
import 'package:gram_aarogya_seva/core/services/functions_service.dart';
import 'package:gram_aarogya_seva/core/services/notification_service.dart';
import 'package:gram_aarogya_seva/core/services/update_service.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/models/notification_model.dart';

/// Firebase Auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user's Firestore document stream (for role and profile).
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(firestoreServiceProvider).streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Current user's role (convenience provider).
final currentRoleProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).whenData((user) => user?.role).value;
});

/// Doctor profile stream — only emits for users with role 'doctor'.
/// Used by the router to check doctor approval status before routing.
final currentDoctorProvider = StreamProvider<DoctorModel?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.role != 'doctor') return Stream.value(null);
  return ref.read(firestoreServiceProvider).streamDoctor(user.uid);
});

/// Singleton FirestoreService provider — reads and rule-validated writes.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Singleton FunctionsService provider — every privileged mutation.
/// See TECHNICAL_ASSESSMENT.md §A17-1 for why these are two services.
final functionsServiceProvider = Provider<FunctionsService>((ref) {
  return FunctionsService();
});

/// The signed-in user's notification inbox (newest first).
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).streamNotifications(uid);
});

/// Unread notification count, for the app-bar badge.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0);
  return ref.watch(firestoreServiceProvider).streamUnreadNotificationCount(uid);
});

/// Tracks whether the user entered login with intent to register as a doctor.
final isDoctorRegistrationIntentProvider = StateProvider<bool>((ref) => false);

/// FCM lifecycle (token registration, tap routing).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(firestoreServiceProvider));
});

/// Remote Config force-update check.
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Whether the installed build is below `minimum_app_version` (SRS R-17).
///
/// Fails open: a device that cannot reach Remote Config keeps working rather
/// than being locked out by a network problem.
final forceUpdateProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(updateServiceProvider);
  await service.initialise();
  return service.isUpdateRequired();
});

/// Signs out, clearing the device's push token first.
///
/// Shared phones are normal in the target deployment, so leaving a token
/// behind would send the next user's appointment notifications to the previous
/// user's device. Order matters: the token write needs the old credentials.
Future<void> signOutCompletely(NotificationService notifications) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await notifications.unregisterFor(uid);
  }
  await FirebaseAuth.instance.signOut();
}
