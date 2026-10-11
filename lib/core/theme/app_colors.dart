import 'package:flutter/material.dart';

/// Design tokens — "Warli wall".
///
/// Drawn from Warli painting, the village art of the Maharashtra hills:
/// rice-white figures on a geru (red-earth) wall. Headers are the painted
/// wall; peacock green carries every action; turmeric (the `zari*` tokens)
/// is the accent for "needs your attention" — never a fill behind text. Contrast of every text/background
/// pair used here is ≥ 4.5:1 for outdoor readability (SRS DP-1).
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════
  // PRIMARY — Peacock
  // ═══════════════════════════════════════════════════
  static const Color primary = Color(0xFF0E4D45);
  static const Color primaryDeep = Color(0xFF083631);
  static const Color primaryContainer = Color(0xFF16675C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFCDEAE3);
  static const Color primaryFixed = Color(0xFFD5ECE6);
  static const Color primaryFixedDim = Color(0xFFA6D6CB);
  static const Color inversePrimary = Color(0xFF8FD0C2);

  // ═══════════════════════════════════════════════════
  // ZARI — gold thread accent. Rules, focus, highlights; never body text
  // on light surfaces (use zariDeep for that).
  // ═══════════════════════════════════════════════════
  static const Color zari = Color(0xFFD99A14);
  static const Color zariBright = Color(0xFFF2B632);
  static const Color zariDeep = Color(0xFF7A5300);
  static const Color zariSoft = Color(0xFFFBEFCF);

  // ═══════════════════════════════════════════════════
  // GERU — the red-earth mud wall Warli paintings are made on. Headers and
  // the splash are painted geru with rice-white Warli figures; actions stay
  // peacock so "wall" and "button" never look alike.
  // ═══════════════════════════════════════════════════
  static const Color geru = Color(0xFF8C3B1F);
  static const Color geruDeep = Color(0xFF6B2913);
  static const Color geruLight = Color(0xFFA9532F);
  static const Color onMural = Color(0xFFFFF8EE);
  static const Color onMuralMuted = Color(0xFFF3D8C6);

  /// Guided-tour spotlight: marigold, chosen to stand apart from every
  /// other colour on screen so the highlighted control is unmistakable.
  static const Color spotlight = Color(0xFFFF6B1A);

  // ═══════════════════════════════════════════════════
  // SECONDARY — Leaf green (success / accepted)
  // ═══════════════════════════════════════════════════
  static const Color secondary = Color(0xFF2F6B3A);
  static const Color secondaryContainer = Color(0xFFD6EBD4);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1D4A25);

  // ═══════════════════════════════════════════════════
  // TERTIARY — Haldi ochre (pending / attention)
  // ═══════════════════════════════════════════════════
  static const Color tertiary = Color(0xFF7E4510);
  static const Color tertiaryContainer = Color(0xFF9A5512);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFE3C7);
  static const Color tertiaryFixed = Color(0xFFFBE6CD);
  static const Color tertiaryFixedDim = Color(0xFFF1CB9C);

  // ═══════════════════════════════════════════════════
  // SURFACE HIERARCHY — Porcelain (cool, slightly green-tinted)
  // ═══════════════════════════════════════════════════
  static const Color surface = Color(0xFFF5F7F5);
  static const Color surfaceDim = Color(0xFFD3DAD6);
  static const Color surfaceBright = Color(0xFFFAFBFA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F4F2);
  static const Color surfaceContainer = Color(0xFFE9EEEB);
  static const Color surfaceContainerHigh = Color(0xFFE2E8E5);
  static const Color surfaceContainerHighest = Color(0xFFDAE1DD);
  static const Color surfaceTint = primary;
  static const Color inverseSurface = Color(0xFF1C2A27);
  static const Color inverseOnSurface = Color(0xFFEEF3F1);

  // ═══════════════════════════════════════════════════
  // ON-SURFACE — Ink
  // ═══════════════════════════════════════════════════
  static const Color onSurface = Color(0xFF142320);
  static const Color onSurfaceVariant = Color(0xFF3C4C48);
  static const Color outline = Color(0xFF66766F);
  static const Color outlineVariant = Color(0xFFC5D0CB);

  // ═══════════════════════════════════════════════════
  // ERROR — Kumkum red (also emergency)
  // ═══════════════════════════════════════════════════
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFFADBD7);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7A1410);

  // ═══════════════════════════════════════════════════
  // LEGACY ALIASES (backward compatibility)
  // ═══════════════════════════════════════════════════
  static const Color background = surface;
  static const Color onBackground = onSurface;
  static const Color disabled = outlineVariant;
  static const Color divider = outlineVariant;
  static const Color success = secondary;
  static const Color info = Color(0xFF1F5A85);
  static const Color infoContainer = Color(0xFFDCEAF5);

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
  static const Color severityMild = Color(0xFF4E9A5B);
  static const Color severityModerate = Color(0xFFC98A2E);
  static const Color severitySevere = error;

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

  /// Peacock silk — the header and hero-card fill. Name kept for existing
  /// call sites.
  static const LinearGradient healingGradient = LinearGradient(
    colors: [primaryDeep, primary, primaryContainer],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Mud wall — geru, slightly lit from the top left like a painted wall.
  static const LinearGradient muralGradient = LinearGradient(
    colors: [geruLight, geru, geruDeep],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Zari border — a thin gold rule that marks the edge of a hero surface.
  static const LinearGradient zariGradient = LinearGradient(
    colors: [zariDeep, zariBright, zari],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
