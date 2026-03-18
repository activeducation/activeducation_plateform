import 'package:flutter/material.dart';

/// Palette ActivEducation — Design "Deep Navy + Amber Gold"
/// Thème premium avec sidebar sombre, contenus clairs, accents ambre gamifiés
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY — Bleu Royal (couleur logo)
  // ============================================
  static const Color primary = Color(0xFF1060CF);
  static const Color primaryLight = Color(0xFF4D6EF0);
  static const Color primaryDark = Color(0xFF1530C4);
  static const Color primarySurface = Color(0xFFEAEEFD);
  static const Color primarySurface2 = Color(0xFFD4DBFB);
  static const Color primaryMedium = Color(0xFF3355EC);
  static const Color primaryIndigo = Color(0xFF3045E0);

  // ============================================
  // SECONDARY — Orange Vif (couleur logo)
  // ============================================
  static const Color secondary = Color(0xFFFF9E18);
  static const Color secondaryLight = Color(0xFFFFB84A);
  static const Color secondaryDark = Color(0xFFE08010);
  static const Color secondarySurface = Color(0xFFFFF3E0);
  static const Color shimmer = Color(0xFFFFF0D0);

  // ============================================
  // DARK UI — Sidebar, headers hero, sections sombres
  // ============================================
  static const Color darkBg = Color(0xFF070F1E);
  static const Color darkBg2 = Color(0xFF0C1828);
  static const Color darkBg3 = Color(0xFF111F34);
  static const Color darkSurface = Color(0xFF162540);
  static const Color darkSurface2 = Color(0xFF1C2F50);
  static const Color darkSurface3 = Color(0xFF213860);
  static const Color darkBorder = Color(0xFF1E3055);
  static const Color darkBorder2 = Color(0xFF253D6A);
  static const Color darkDivider = Color(0xFF172845);

  static const Color darkTextPrimary = Color(0xFFE6EFF8);
  static const Color darkTextSecondary = Color(0xFF7A9DB8);
  static const Color darkTextMuted = Color(0xFF4A6880);
  static const Color darkAccentBlue = Color(0xFF4A8BE8);
  static const Color darkAccentAmber = Color(0xFFFFB83F);

  // ============================================
  // GAMIFICATION — XP, niveaux, streaks, badges
  // ============================================
  static const Color xpGold = Color(0xFFFFCA28);
  static const Color xpGoldDark = Color(0xFFE6A800);
  static const Color xpGoldSurface = Color(0xFFFFF8DC);
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color streakFireLight = Color(0xFFFF9060);
  static const Color streakFireSurface = Color(0xFFFFF0EA);
  static const Color levelPurple = Color(0xFF8B5CF6);
  static const Color levelPurpleSurface = Color(0xFFF3EBFF);
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color xpBar = Color(0xFF34D399);

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
  // FOND & SURFACES — Thème Clair
  // ============================================
  static const Color background = Color(0xFFF2F5FC);
  static const Color backgroundAlt = Color(0xFFEBEFF9);
  static const Color surface = Color(0xFFF6F8FD);
  static const Color surfaceLight = Color(0xFFF9FAFD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF5F8FF);

  // ============================================
  // TEXTE
  // ============================================
  static const Color textPrimary = Color(0xFF0D1832);
  static const Color textSecondary = Color(0xFF4A6280);
  static const Color textTertiary = Color(0xFF8AAAC0);
  static const Color textDisabled = Color(0xFFC0D0E0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ============================================
  // BORDURES & DIVIDERS
  // ============================================
  static const Color border = Color(0xFFDDE4F0);
  static const Color borderLight = Color(0xFFEDF2FA);
  static const Color divider = Color(0xFFE5EDF6);

  // Kept for compatibility
  static const Color glassBorder = Color(0xFFDDE4F0);
  static const Color accent = Color(0xFF1060CF);

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
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  /// Dégradé hero sombre — fond de la sidebar et du header home
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBg, darkBg3],
  );

  /// Dégradé hero bleu — bannière d'orientation
  static const LinearGradient heroGradientBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C1828), Color(0xFF1060CF)],
  );

  static const LinearGradient heroGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryIndigo],
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
    colors: [card, surfaceLight],
  );

  /// Barre XP — dégradé vert-émeraude
  static const LinearGradient xpBarGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Dégradé or pour XP/récompenses
  static const LinearGradient xpGoldGradient = LinearGradient(
    colors: [xpGold, xpGoldDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ============================================
  // OMBRES
  // ============================================
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0D1832).withValues(alpha: 0.07),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0D1832).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: const Color(0xFF0D1832).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.30),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get crossBrandShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.20),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: secondary.withValues(alpha: 0.14),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// Ombre portée de la sidebar sombre
  static List<BoxShadow> get darkNavShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 40,
      offset: const Offset(6, 0),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.45),
      blurRadius: 48,
      offset: const Offset(0, 20),
    ),
  ];

  static List<BoxShadow> get secondaryShadow => [
    BoxShadow(
      color: secondary.withValues(alpha: 0.30),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
