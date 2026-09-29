import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';

/// App-bar logout, present on every dashboard (SRS §13.6 checklist).
///
/// Exists as a shared widget because signing out is not just
/// `FirebaseAuth.signOut()` — the device's push token has to be cleared first,
/// or the next person to use a shared phone receives the previous user's
/// appointment notifications. Four dashboards previously called `signOut()`
/// directly and would each have had to remember that.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: tr('logout'),
      onPressed: () =>
          signOutCompletely(ref.read(notificationServiceProvider)),
    );
  }
}
