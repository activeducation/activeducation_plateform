import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static String get fontFamily => 'Hanken Grotesque';

  // ============================================
  // DISPLAY — 48px / w800 / -0.02em
  // ============================================
  static TextStyle get displayLarge => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.96, color: AppColors.textPrimary, height: 1.17);
  static TextStyle get displayMedium => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary, height: 1.15);
  static TextStyle get displaySmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.textPrimary, height: 1.2);

  // ============================================
  // HEADLINES
  // ============================================
  static TextStyle get headlineLarge => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.32, color: AppColors.textPrimary, height: 1.25);
  static TextStyle get headlineMedium => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.33);
  static TextStyle get headlineSmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.4);

  // ============================================
  // TITLE
  // ============================================
  static TextStyle get titleLarge => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.4);
  static TextStyle get titleMedium => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get titleSmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.43);

  // ============================================
  // BODY
  // ============================================
  static TextStyle get bodyLarge => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textSecondary, height: 1.56);
  static TextStyle get bodyMedium => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get bodySmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textTertiary, height: 1.43);

  // ============================================
  // LABELS
  // ============================================
  static TextStyle get labelLarge => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get labelMedium => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.14, color: AppColors.textSecondary, height: 1.43);
  static TextStyle get labelSmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.textTertiary, height: 1.33);

  // ============================================
  // HERO / DISPLAY (grands titres)
  // ============================================
  static TextStyle get heroDisplay => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: AppColors.darkTextPrimary, height: 1.1);
  static TextStyle get heroTitle => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.darkTextPrimary, height: 1.2);
  static TextStyle get heroSubtitle => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.darkTextSecondary, height: 1.5);

  // ============================================
  // GAMIFICATION — Chiffres et stats
  // ============================================
  static TextStyle get statValue => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkTextPrimary, height: 1.0);
  static TextStyle get statValueMedium => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.darkTextPrimary, height: 1.1);
  static TextStyle get statValueSmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.darkTextPrimary, height: 1.2);
  static TextStyle get statLabel => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: AppColors.darkTextSecondary, height: 1.3);

  // ============================================
  // STYLES SPÉCIAUX
  // ============================================
  static TextStyle get buttonText => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: AppColors.textOnPrimary, height: 1.25);
  static TextStyle get chipText => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: AppColors.textPrimary, height: 1.33);
  static TextStyle get navLabel => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.2);
  static TextStyle get badgeText => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, height: 1.2);
  static TextStyle get overline => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textTertiary, height: 1.4);
}
