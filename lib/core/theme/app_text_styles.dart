import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography — "Paithani".
/// Display / headline: Tiro Devanagari Marathi — a book serif with matching
///   Latin and Devanagari, used for greetings and screen titles only. It ships
///   in one weight: never bold it (Flutter would fake the bold).
/// Everything else: Mukta — a humanist sans designed for Devanagari, with
///   Latin to match. Minimum body 18sp (SRS DP-1 rural-first rule).
/// Both families are bundled in assets/fonts so nothing is fetched at runtime.
class AppTextStyles {
  AppTextStyles._();

  static const String serif = 'TiroDevanagariMarathi';
  static const String sans = 'Mukta';

  // ═══════════════════════════════════════════════════
  // DISPLAY — Serif, regular weight only
  // ═══════════════════════════════════════════════════
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: serif,
        fontSize: 38,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.2,
        letterSpacing: -0.4,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: serif,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.2,
        letterSpacing: -0.3,
      );

  // ═══════════════════════════════════════════════════
  // HEADLINES — Serif for Large/Medium, Sans for Small (section titles)
  // ═══════════════════════════════════════════════════
  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: serif,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: serif,
        fontSize: 24,
        fontWeight: FontWeight.w400,
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
