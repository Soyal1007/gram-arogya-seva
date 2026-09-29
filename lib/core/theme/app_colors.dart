import 'package:flutter/material.dart';

/// Design tokens extracted from "UBA GramArogya UI" Stitch project.
/// Palette: "Deep Healing Green" — high-contrast for rural outdoor readability.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════
  // PRIMARY — "Healing Deep Green"
  // ═══════════════════════════════════════════════════
  static const Color primary = Color(0xFF004628);
  static const Color primaryContainer = Color(0xFF006039);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF88D8A7);
  static const Color primaryFixed = Color(0xFFA3F4C1);
  static const Color primaryFixedDim = Color(0xFF88D7A6);
  static const Color inversePrimary = Color(0xFF88D7A6);

  // ═══════════════════════════════════════════════════
  // SECONDARY
  // ═══════════════════════════════════════════════════
  static const Color secondary = Color(0xFF1B6D24);
  static const Color secondaryContainer = Color(0xFFA0F399);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF217128);

  // ═══════════════════════════════════════════════════
  // TERTIARY — Warm Ochre / Earth Tone
  // ═══════════════════════════════════════════════════
  static const Color tertiary = Color(0xFF751A00);
  static const Color tertiaryContainer = Color(0xFF9E2600);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFB6A2);
  static const Color tertiaryFixed = Color(0xFFFFDBD1);
  static const Color tertiaryFixedDim = Color(0xFFFFB5A1);

  // ═══════════════════════════════════════════════════
  // SURFACE HIERARCHY (Tonal Layering)
  // ═══════════════════════════════════════════════════
  static const Color surface = Color(0xFFF8FAF8);
  static const Color surfaceDim = Color(0xFFD8DAD9);
  static const Color surfaceBright = Color(0xFFF8FAF8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F2);
  static const Color surfaceContainer = Color(0xFFECEEEC);
  static const Color surfaceContainerHigh = Color(0xFFE6E9E7);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E1);
  static const Color surfaceTint = Color(0xFF176C43);
  static const Color inverseSurface = Color(0xFF2E3130);
  static const Color inverseOnSurface = Color(0xFFEFF1EF);

  // ═══════════════════════════════════════════════════
  // ON-SURFACE
  // ═══════════════════════════════════════════════════
  static const Color onSurface = Color(0xFF191C1B);
  static const Color onSurfaceVariant = Color(0xFF3F4942);
  static const Color outline = Color(0xFF6F7A71);
  static const Color outlineVariant = Color(0xFFBFC9BF);

  // ═══════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ═══════════════════════════════════════════════════
  // LEGACY ALIASES (backward compatibility)
  // ═══════════════════════════════════════════════════
  static const Color background = surface;
  static const Color onBackground = onSurface;
  static const Color disabled = outlineVariant;
  static const Color divider = outlineVariant;
  static const Color success = secondary;
  static const Color info = Color(0xFF0288D1);

  // ═══════════════════════════════════════════════════
  // STATUS COLOURS (Design System §5 — StatusBadge)
  // ═══════════════════════════════════════════════════
  static const Color statusPending = tertiaryContainer;
  static const Color statusPendingBg = tertiaryFixed;
  static const Color statusAccepted = secondary;
  static const Color statusAcceptedBg = secondaryContainer;
  static const Color statusCompleted = primary;
  static const Color statusCompletedBg = primaryFixed;
  static const Color statusRejected = error;
  static const Color statusRejectedBg = errorContainer;
  static const Color statusCancelled = outline;
  static const Color statusCancelledBg = surfaceContainerHigh;
  static const Color statusNoShow = tertiary;
  static const Color statusNoShowBg = tertiaryFixedDim;

  // ═══════════════════════════════════════════════════
  // SEVERITY
  // ═══════════════════════════════════════════════════
  static const Color severityMild = Color(0xFF88D982);
  static const Color severityModerate = Color(0xFFFFB5A1);
  static const Color severitySevere = Color(0xFFBA1A1A);

  /// Returns the foreground colour for a given appointment status string.
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'pending_approval':
        return statusPending;
      case 'accepted':
      case 'active':
        return statusAccepted;
      case 'completed':
        return statusCompleted;
      case 'rejected':
        return statusRejected;
      case 'cancelled':
        return statusCancelled;
      case 'no_show':
        return statusNoShow;
      case 'inactive':
        return outline;
      default:
        return onSurface;
    }
  }

  /// Returns the background colour for a given status.
  static Color statusBgColor(String status) {
    switch (status) {
      case 'pending':
      case 'pending_approval':
        return statusPendingBg;
      case 'accepted':
      case 'active':
        return statusAcceptedBg;
      case 'completed':
        return statusCompletedBg;
      case 'rejected':
        return statusRejectedBg;
      case 'cancelled':
        return statusCancelledBg;
      case 'no_show':
        return statusNoShowBg;
      case 'inactive':
        return surfaceContainerHigh;
      default:
        return surfaceContainer;
    }
  }

  /// The Healing Gradient — primary → primaryContainer (Design System §2).
  static const LinearGradient healingGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
