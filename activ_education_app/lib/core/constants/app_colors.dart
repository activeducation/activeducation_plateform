import 'package:flutter/material.dart';

/// Palette ActivEducation — Design "Deep Navy + Amber Gold"
/// Thème premium avec sidebar sombre, contenus clairs, accents ambre gamifiés
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY — Bleu Royal (couleur logo exacte)
  // ============================================
  static const Color primary = Color(0xFF1060CF);
  static const Color primaryLight = Color(0xFF4A8AE5);
  static const Color primaryMid = Color(0xFF1752B8);
  static const Color primaryDark = Color(0xFF0A45A0);
  static const Color primarySurface = Color(0xFFE8F0FE);
  static const Color primarySurface2 = Color(0xFFCFDEFA);
  static const Color primaryMedium = Color(0xFF2B6ED4);
  static const Color primaryIndigo = Color(0xFF1060CF);

  // ============================================
  // SECONDARY — Or Ambré (couleur logo exacte #F2A423)
  // ============================================
  static const Color secondary = Color(0xFFF2A423);
  static const Color secondaryLight = Color(0xFFFFD166);
  static const Color secondaryDark = Color(0xFFCC8800);
  static const Color secondarySurface = Color(0xFFFFF5E0);
  static const Color shimmer = Color(0xFFFFF0D0);

  // ============================================
  // DARK UI — Sidebar, headers hero, sections sombres
  // Aligné avec la landing page (#060E1E)
  // ============================================
  static const Color darkBg = Color(0xFF060E1E);
  static const Color darkBg2 = Color(0xFF0B1C3C);
  static const Color darkBg3 = Color(0xFF0F2550);
  static const Color darkSurface = Color(0xFF142240);
  static const Color darkSurface2 = Color(0xFF1A2E55);
  static const Color darkSurface3 = Color(0xFF1F3868);
  static const Color darkBorder = Color(0xFF1B2E52);
  static const Color darkBorder2 = Color(0xFF243B68);
  static const Color darkDivider = Color(0xFF152748);

  static const Color darkTextPrimary = Color(0xFFE4EEF8);
  static const Color darkTextSecondary = Color(0xFF7AA0BC);
  static const Color darkTextMuted = Color(0xFF4A6B85);
  static const Color darkAccentBlue = Color(0xFF4A8AE5);
  static const Color darkAccentAmber = Color(0xFFF2A423);

  // ============================================
  // GAMIFICATION — XP, niveaux, streaks, badges
  // ============================================
  static const Color xpGold = Color(0xFFF2A423);
  static const Color xpGoldDark = Color(0xFFCC8800);
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
    colors: [darkBg, darkBg2],
  );

  /// Dégradé hero bleu — bannière d'orientation
  static const LinearGradient heroGradientBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1C3C), Color(0xFF1060CF)],
  );

  static const LinearGradient heroGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  /// Dégradé cross-brand bleu→or (identique à la landing page)
  static const LinearGradient crossBrandGradient = LinearGradient(
    begin: Alignment(-1.0, -0.6),
    end: Alignment(1.0, 0.6),
    colors: [primaryLight, secondary],
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
