import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography — one family, Mukta: a humanist sans designed for Devanagari,
/// with Latin to match, bundled in assets/fonts (nothing fetched at runtime).
/// Hierarchy comes from size and weight only. Minimum body 18sp (SRS DP-1).
/// `serif` is kept as the name of the display role so call sites need not
/// change.
class AppTextStyles {
  AppTextStyles._();

  static const String serif = 'Mukta';
  static const String sans = 'Mukta';

  // ═══════════════════════════════════════════════════
  // DISPLAY — Serif, regular weight only
  // ═══════════════════════════════════════════════════
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: serif,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.2,
        letterSpacing: -0.2,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: serif,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.2,
        letterSpacing: -0.2,
      );

  // ═══════════════════════════════════════════════════
  // HEADLINES — Serif for Large/Medium, Sans for Small (section titles)
  // ═══════════════════════════════════════════════════
  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: serif,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: serif,
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.3,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: sans,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════
  // TITLES (Sans)
  // ═══════════════════════════════════════════════════
  static TextStyle get titleLarge => const TextStyle(
        fontFamily: sans,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════
  // BODY — The Workhorse (Sans, ≥18sp strict minimum)
  // ═══════════════════════════════════════════════════
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.45,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.45,
      );

  // ═══════════════════════════════════════════════════
  // LABELS (Sans — used sparingly)
  // ═══════════════════════════════════════════════════
  static TextStyle get labelLarge => const TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: sans,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: sans,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.4,
      );
}
