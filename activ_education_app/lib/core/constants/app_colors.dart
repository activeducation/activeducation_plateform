import 'package:flutter/material.dart';

/// Palette de couleurs ActivEducation
/// Design professionnel, lumineux avec bleu + orange de la marque
class AppColors {
  AppColors._();

  // ============================================
  // COULEURS PRIMAIRES - Bleu Marque
  // ============================================
  static const Color primary = Color(0xFF1060CF);
  static const Color primaryLight = Color(0xFF4A8BE8);
  static const Color primaryDark = Color(0xFF0D4EA6);
  static const Color primarySurface = Color(0xFFE8F0FE);

  // ============================================
  // COULEURS SECONDAIRES - Orange/Ambre Marque
  // ============================================
  static const Color secondary = Color(0xFFF2A423);
  static const Color secondaryLight = Color(0xFFF7C164);
  static const Color secondaryDark = Color(0xFFD98E1B);
  static const Color secondarySurface = Color(0xFFFEF3E2);

  // ============================================
  // COULEURS ENRICHIES
  // ============================================
  static const Color primaryMedium = Color(0xFF2E7CE6);
  static const Color shimmer = Color(0xFFF5E6D0);

  // ============================================
  // STATUTS
  // ============================================
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  static const Color warning = Color(0xFFEAB308);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color warningDark = Color(0xFFA16207);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);

  // ============================================
  // FOND & SURFACES - Thème Clair
  // ============================================
  static const Color background = Color(0xFFFAFBFD);
  static const Color surface = Color(0xFFF0F2F5);
  static const Color surfaceLight = Color(0xFFF5F6F8);

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF9FAFB);

  // ============================================
  // TEXTE
  // ============================================
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ============================================
  // BORDURES & DIVIDERS
  // ============================================
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // Kept for orientation pages compatibility
  static const Color glassBorder = Color(0xFFE5E7EB);
  static const Color accent = Color(0xFF1060CF);
  static const Color xpGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surface],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, surfaceLight],
  );

  // ============================================
  // CATÉGORIES D'ORIENTATION
  // ============================================
  static const Color categoryScience = Color(0xFF0891B2);
  static const Color categoryLiterature = Color(0xFFDB2777);
  static const Color categoryEconomics = Color(0xFF16A34A);
  static const Color categoryTechnology = Color(0xFF7C3AED);
  static const Color categoryArts = Color(0xFFF59E0B);
  static const Color categoryHealth = Color(0xFFEF4444);

  // ============================================
  // DÉGRADÉS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient crossBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1060CF), Color(0xFF3B49DF)],
  );

  // ============================================
  // OMBRES
  // ============================================
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 16,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get crossBrandShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: secondary.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
