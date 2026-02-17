import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typographie de l'application avec police Outfit
/// Design moderne et lisible
class AppTypography {
  AppTypography._();

  // ============================================
  // FAMILLE DE POLICE
  // ============================================
  static String get fontFamily => GoogleFonts.outfit().fontFamily!;

  // ============================================
  // TITRES - Display
  // ============================================
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.16,
  );

  static TextStyle get displaySmall => GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.22,
  );

  // ============================================
  // TITRES - Headline
  // ============================================
  static TextStyle get headlineLarge => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.29,
  );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  // ============================================
  // TITRES - Title
  // ============================================
  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get titleSmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.43,
  );

  // ============================================
  // CORPS - Body
  // ============================================
  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textSecondary,
    height: 1.43,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textTertiary,
    height: 1.33,
  );

  // ============================================
  // LABELS
  // ============================================
  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
    height: 1.45,
  );

  // ============================================
  // STYLES SPÉCIAUX
  // ============================================
  static TextStyle get buttonText => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textOnPrimary,
    height: 1.25,
  );

  static TextStyle get chipText => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
    height: 1.33,
  );
}
