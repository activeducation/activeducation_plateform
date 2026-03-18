import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typographie ActivEducation — Outfit + Sora
/// Outfit pour le corps, Sora pour les grands titres display
class AppTypography {
  AppTypography._();

  // ============================================
  // FAMILLES DE POLICE
  // ============================================
  static String get fontFamily => GoogleFonts.outfit().fontFamily!;
  static String get displayFontFamily => GoogleFonts.sora().fontFamily!;

  // ============================================
  // DISPLAY — Grands titres hero (Sora)
  // ============================================

  /// Très grand titre pour les écrans de bienvenue / splash
  static TextStyle get heroDisplay => GoogleFonts.sora(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    color: AppColors.darkTextPrimary,
    height: 1.1,
  );

  /// Titre d'accueil sur le header sombre
  static TextStyle get heroTitle => GoogleFonts.sora(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.darkTextPrimary,
    height: 1.2,
  );

  /// Sous-titre sur fond sombre
  static TextStyle get heroSubtitle => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.darkTextSecondary,
    height: 1.5,
  );

  // ============================================
  // TITRES — Display (Outfit)
  // ============================================
  static TextStyle get displayLarge => GoogleFonts.sora(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.sora(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.sora(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // ============================================
  // TITRES — Headline (Outfit)
  // ============================================
  static TextStyle get headlineLarge => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.28,
  );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
    height: 1.32,
  );

  // ============================================
  // TITRES — Title
  // ============================================
  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get titleMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static TextStyle get titleSmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    color: AppColors.textPrimary,
    height: 1.43,
  );

  // ============================================
  // CORPS — Body
  // ============================================
  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textTertiary,
    height: 1.4,
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
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textTertiary,
    height: 1.45,
  );

  // ============================================
  // GAMIFICATION — Chiffres et stats
  // ============================================

  /// Grande valeur numérique (XP, score, nombre)
  static TextStyle get statValue => GoogleFonts.sora(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.darkTextPrimary,
    height: 1.0,
  );

  /// Valeur numérique moyenne
  static TextStyle get statValueMedium => GoogleFonts.sora(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.darkTextPrimary,
    height: 1.1,
  );

  /// Petite valeur numérique
  static TextStyle get statValueSmall => GoogleFonts.sora(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.darkTextPrimary,
    height: 1.2,
  );

  /// Label sous les stats (XP, Niv., Streak)
  static TextStyle get statLabel => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: AppColors.darkTextSecondary,
    height: 1.3,
  );

  // ============================================
  // STYLES SPÉCIAUX
  // ============================================
  static TextStyle get buttonText => GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textOnPrimary,
    height: 1.25,
  );

  static TextStyle get chipText => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  /// Texte de navigation (sidebar + bottom nav)
  static TextStyle get navLabel => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
  );

  /// Badge / pill text
  static TextStyle get badgeText => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Section header overline
  static TextStyle get overline => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.textTertiary,
    height: 1.4,
  );
}
