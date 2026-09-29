import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/router/app_router.dart';
import 'package:gram_aarogya_seva/core/theme/app_theme.dart';
import 'package:gram_aarogya_seva/shared/widgets/force_update_screen.dart';

/// Root widget: router, theme, localisation, and the two cross-cutting
/// lifecycles that need somewhere to live — push registration and the
/// force-update gate.
class GramAarogyaSevaApp extends ConsumerStatefulWidget {
  const GramAarogyaSevaApp({super.key});

  @override
  ConsumerState<GramAarogyaSevaApp> createState() =>
      _GramAarogyaSevaAppState();
}

class _GramAarogyaSevaAppState extends ConsumerState<GramAarogyaSevaApp> {
  StreamSubscription<String>? _tapSubscription;
  String? _registeredUid;

  @override
  void initState() {
    super.initState();

    // Opening the inbox when a push is tapped. Subscribed once, for the life
    // of the app, because a push can arrive before any screen is mounted.
    _tapSubscription =
        ref.read(notificationServiceProvider).onNotificationTap.listen((route) {
      if (mounted) ref.read(routerProvider).push(route);
    });
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    super.dispose();
  }

  /// Registers this device for push once the user document is available.
  ///
  /// Keyed on uid so a sign-out followed by a different sign-in on the same
  /// (shared) phone re-registers rather than reusing the previous token.
  void _syncPushRegistration(UserModel? user) {
    if (user == null) {
      _registeredUid = null;
      return;
    }
    if (_registeredUid == user.uid) return;
    _registeredUid = user.uid;
    ref.read(notificationServiceProvider).registerFor(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    ref.listen(currentUserProvider, (_, next) {
      _syncPushRegistration(next.valueOrNull);
    });

    // Fails open — a device that cannot reach Remote Config keeps working.
    final updateRequired =
        ref.watch(forceUpdateProvider).valueOrNull ?? false;

    return MaterialApp.router(
      title: 'Gram Aarogya Seva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        if (updateRequired) return const ForceUpdateScreen();
        // Keying on the locale forces routed pages to rebuild on a language
        // change; GoRouter would otherwise keep serving cached ones with the
        // previous language still rendered.
        return KeyedSubtree(
          key: ValueKey(context.locale.languageCode),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
