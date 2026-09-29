import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system from "UBA GramArogya UI" design system.
/// Headline: Public Sans (geometric authority)
/// Body/Label: Lexend (proven readability for low-literacy users)
/// Minimum body: 18sp (SRS DP-1 rural-first rule).
class AppTextStyles {
  AppTextStyles._();

  // ═══════════════════════════════════════════════════
  // DISPLAY — Editorial Hero (Public Sans)
  // ═══════════════════════════════════════════════════
  static TextStyle get displayLarge => GoogleFonts.publicSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.publicSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.2,
      );

  // ═══════════════════════════════════════════════════
  // HEADLINES — Authority (Public Sans)
  // ═══════════════════════════════════════════════════
  static TextStyle get headlineLarge => GoogleFonts.publicSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.publicSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.publicSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════
  // TITLES (Public Sans)
  // ═══════════════════════════════════════════════════
  static TextStyle get titleLarge => GoogleFonts.publicSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  static TextStyle get titleMedium => GoogleFonts.publicSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════
  // BODY — The Workhorse (Lexend, ≥18sp strict minimum)
  // ═══════════════════════════════════════════════════
  static TextStyle get bodyLarge => GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.5,
      );

  // ═══════════════════════════════════════════════════
  // LABELS (Lexend — used sparingly)
  // ═══════════════════════════════════════════════════
  static TextStyle get labelLarge => GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get caption => GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      );
}
