import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY — Bleu Riche Premium
  // ============================================
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryMid = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryDarker = Color(0xFF1E3A8A); // Très riche
  static const Color primarySurface = Color(0xFFEFF6FF);
  static const Color primarySurface2 = Color(0xFFDBEAFE);
  static const Color primaryIndigo = Color(0xFF4338CA);

  // ============================================
  // SECONDARY / ACCENT — Orange Premium
  // ============================================
  static const Color secondary = Color(0xFFFF7A00); // Orange vibrant
  static const Color secondaryLight = Color(0xFFFF9D42);
  static const Color secondaryDark = Color(0xFFCC6200);
  static const Color secondarySurface = Color(0xFFFFF7ED);
  static const Color accent = Color(0xFFFF7A00);
  static const Color accentLight = Color(0xFFFF9D42);
  static const Color accentDark = Color(0xFFCC6200);
  static const Color accentSurface = Color(0xFFFFF7ED);
  static const Color shimmer = Color(0xFFFFF7ED);

  // ============================================
  // GAMIFICATION
  // ============================================
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldDark = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFFCD34D);
  static const Color goldSurface = Color(0xFFFEF3C7);
  static const Color xpGold = Color(0xFFF59E0B);
  static const Color xpGoldDark = Color(0xFFD97706);
  static const Color xpGoldSurface = Color(0xFFFEF3C7);
  static const Color xpGoldLight = Color(0xFFFCD34D);
  static const Color streakFire = Color(0xFFEF4444);
  static const Color streakFireLight = Color(0xFFF87171);
  static const Color streakFireSurface = Color(0xFFFEF2F2);
  static const Color levelPurple = Color(0xFF8B5CF6);
  static const Color levelPurpleSurface = Color(0xFFF5F3FF);
  static const Color rankGold = Color(0xFFFBBF24);
  static const Color rankSilver = Color(0xFF94A3B8);
  static const Color rankBronze = Color(0xFFB45309);
  static const Color xpBar = Color(0xFF10B981);

  // ============================================
  // SURFACES (Clean & Minimalist)
  // ============================================
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF1F5F9);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);
  static const Color surfaceLight = Color(0xFFF8FAFC);

  // Le fond global de l'app (très léger gris-bleuté pour contraster les cartes blanches)
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundAlt = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF8FAFC);

  // ============================================
  // TEXTE
  // ============================================
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF334155); // Slate 700
  static const Color textTertiary = Color(0xFF64748B); // Slate 500
  static const Color textDisabled = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ============================================
  // BORDURES & DIVIDERS
  // ============================================
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFF8FAFC);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color glassBorder = Color(0xFFE2E8F0);

  // ============================================
  // STATUTS
  // ============================================
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoSurface = Color(0xFFEFF6FF);
  static const Color infoDark = Color(0xFF2563EB);

  // ============================================
  // CATÉGORIES D'ORIENTATION
  // ============================================
  static const Color categoryScience = Color(0xFF06B6D4);
  static const Color categoryLiterature = Color(0xFFEC4899);
  static const Color categoryEconomics = Color(0xFF10B981);
  static const Color categoryTechnology = Color(0xFF8B5CF6);
  static const Color categoryArts = Color(0xFFF59E0B);
  static const Color categoryHealth = Color(0xFFEF4444);

  // ============================================
  // DÉGRADÉS PREMIUM
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryIndigo],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, secondary],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDarker, primary],
  );

  static const LinearGradient heroGradientBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDarker, primaryMid],
  );

  static const LinearGradient heroGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF8B5CF6)], // Bleu vers Violet
  );

  static const LinearGradient crossBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundAlt],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
  );

  static const LinearGradient xpBarGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient xpGoldGradient = LinearGradient(
    colors: [goldLight, gold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ============================================
  // OMBRES PREMIUM (Douces, amples, élégantes)
  // ============================================
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withOpacity(0.15),
      blurRadius: 32,
      spreadRadius: 8,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get crossBrandShadow => [
    BoxShadow(
      color: primary.withOpacity(0.20),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================
  // BACKWARD COMPATIBILITY: "DARK" UI (Now mapped to light/clean for sidebar)
  // The sidebar is now clean white, so we map these to light colors
  // ============================================
  static const Color darkBg = Color(0xFFFFFFFF); // White sidebar
  static const Color darkBg2 = Color(0xFFF8FAFC);
  static const Color darkBg3 = Color(0xFFF1F5F9);
  static const Color darkSurface = Color(0xFFF8FAFC);
  static const Color darkSurface2 = Color(0xFFF1F5F9);
  static const Color darkSurface3 = Color(0xFFE2E8F0);
  static const Color darkBorder = Color(0xFFF1F5F9); // Very subtle border
  static const Color darkBorder2 = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFFF1F5F9);

  // "Dark text" constants used by sidebar now need to be dark text since background is white
  static const Color darkTextPrimary = Color(0xFF0F172A);
  static const Color darkTextSecondary = Color(0xFF64748B);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkAccentBlue = Color(0xFF2563EB); // Use primary for accents
  static const Color darkAccentAmber = Color(0xFFFF7A00);
}
