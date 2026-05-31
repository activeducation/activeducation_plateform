import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static String get fontFamily => GoogleFonts.getFont('Hanken Grotesque').fontFamily!;

  // ============================================
  // DISPLAY — 48px / w800 / -0.02em
  // ============================================
  static TextStyle get displayLarge => GoogleFonts.getFont('Hanken Grotesque', fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.96, color: AppColors.textPrimary, height: 1.17);
  static TextStyle get displayMedium => GoogleFonts.getFont('Hanken Grotesque', fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary, height: 1.15);
  static TextStyle get displaySmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.textPrimary, height: 1.2);

  // ============================================
  // HEADLINES
  // ============================================
  static TextStyle get headlineLarge => GoogleFonts.getFont('Hanken Grotesque', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.32, color: AppColors.textPrimary, height: 1.25);
  static TextStyle get headlineMedium => GoogleFonts.getFont('Hanken Grotesque', fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.33);
  static TextStyle get headlineSmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.4);

  // ============================================
  // TITLE
  // ============================================
  static TextStyle get titleLarge => GoogleFonts.getFont('Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.4);
  static TextStyle get titleMedium => GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get titleSmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.43);

  // ============================================
  // BODY
  // ============================================
  static TextStyle get bodyLarge => GoogleFonts.getFont('Hanken Grotesque', fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textSecondary, height: 1.56);
  static TextStyle get bodyMedium => GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textTertiary, height: 1.43);

  // ============================================
  // LABELS
  // ============================================
  static TextStyle get labelLarge => GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get labelMedium => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.14, color: AppColors.textSecondary, height: 1.43);
  static TextStyle get labelSmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.textTertiary, height: 1.33);

  // ============================================
  // HERO / DISPLAY (grands titres)
  // ============================================
  static TextStyle get heroDisplay => GoogleFonts.getFont('Hanken Grotesque', fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: AppColors.darkTextPrimary, height: 1.1);
  static TextStyle get heroTitle => GoogleFonts.getFont('Hanken Grotesque', fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.darkTextPrimary, height: 1.2);
  static TextStyle get heroSubtitle => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.darkTextSecondary, height: 1.5);

  // ============================================
  // GAMIFICATION — Chiffres et stats
  // ============================================
  static TextStyle get statValue => GoogleFonts.getFont('Hanken Grotesque', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkTextPrimary, height: 1.0);
  static TextStyle get statValueMedium => GoogleFonts.getFont('Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.darkTextPrimary, height: 1.1);
  static TextStyle get statValueSmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.darkTextPrimary, height: 1.2);
  static TextStyle get statLabel => GoogleFonts.getFont('Hanken Grotesque', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: AppColors.darkTextSecondary, height: 1.3);

  // ============================================
  // STYLES SPÉCIAUX
  // ============================================
  static TextStyle get buttonText => GoogleFonts.getFont('Hanken Grotesque', fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: AppColors.textOnPrimary, height: 1.25);
  static TextStyle get chipText => GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: AppColors.textPrimary, height: 1.33);
  static TextStyle get navLabel => GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.2);
  static TextStyle get badgeText => GoogleFonts.getFont('Hanken Grotesque', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, height: 1.2);
  static TextStyle get overline => GoogleFonts.getFont('Hanken Grotesque', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textTertiary, height: 1.4);
}
