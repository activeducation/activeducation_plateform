import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY — Bleu (#3133DD)
  // ============================================
  static const Color primary = Color(0xFF3133DD);
  static const Color primaryLight = Color(0xFF6062E8);
  static const Color primaryMid = Color(0xFF2322D3);
  static const Color primaryDark = Color(0xFF0E00C8);
  static const Color primarySurface = Color(0xFFE1E0FF);
  static const Color primarySurface2 = Color(0xFFC0C1FF);
  static const Color primaryIndigo = Color(0xFF3133DD);

  // ============================================
  // SECONDARY / ACCENT — Orange Vif gamifié (#FAA100)
  // ============================================
  static const Color secondary = Color(0xFFFAA100);
  static const Color secondaryLight = Color(0xFFFFB94D);
  static const Color secondaryDark = Color(0xFFD48700);
  static const Color secondarySurface = Color(0xFFFFF3E0);
  static const Color accent = Color(0xFFFAA100);
  static const Color accentLight = Color(0xFFFFB94D);
  static const Color accentDark = Color(0xFFD48700);
  static const Color accentSurface = Color(0xFFFFF3E0);
  static const Color shimmer = Color(0xFFFFF0D0);

  // ============================================
  // GAMIFICATION
  // ============================================
  static const Color gold = Color(0xFFFAA100);
  static const Color goldDark = Color(0xFFD48700);
  static const Color goldLight = Color(0xFFFFB94D);
  static const Color goldSurface = Color(0xFFFFF3E0);
  static const Color xpGold = Color(0xFFFAA100);
  static const Color xpGoldDark = Color(0xFFD48700);
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
  // SURFACES
  // ============================================
  static const Color surface = Color(0xFFFBF8FF);
  static const Color surfaceDim = Color(0xFFDCD9E0);
  static const Color surfaceBright = Color(0xFFFBF8FF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF6F2FA);
  static const Color surfaceContainer = Color(0xFFF0ECF4);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EE);
  static const Color surfaceContainerHighest = Color(0xFFE4E1E9);
  static const Color surfaceLight = Color(0xFFF6F2FA);

  static const Color background = Color(0xFFFBF8FF);
  static const Color backgroundAlt = Color(0xFFF6F2FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF6F2FA);

  // ============================================
  // TEXTE
  // ============================================
  static const Color textPrimary = Color(0xFF1B1B20);
  static const Color textSecondary = Color(0xFF454556);
  static const Color textTertiary = Color(0xFF767587);
  static const Color textDisabled = Color(0xFFC6C4D8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF1B1B20);

  // ============================================
  // BORDURES & DIVIDERS
  // ============================================
  static const Color outline = Color(0xFF767587);
  static const Color outlineVariant = Color(0xFFC6C4D8);
  static const Color border = Color(0xFFC6C4D8);
  static const Color borderLight = Color(0xFFE4E1E9);
  static const Color divider = Color(0xFFE4E1E9);
  static const Color glassBorder = Color(0xFFC6C4D8);

  // ============================================
  // DARK UI — Sidebar, headers hero, sections sombres
  // ============================================
  static const Color darkBg = Color(0xFF121217);
  static const Color darkBg2 = Color(0xFF1E1E26);
  static const Color darkBg3 = Color(0xFF2A2A35);
  static const Color darkSurface = Color(0xFF303035);
  static const Color darkSurface2 = Color(0xFF3A3A45);
  static const Color darkSurface3 = Color(0xFF454556);
  static const Color darkBorder = Color(0xFF454556);
  static const Color darkBorder2 = Color(0xFF555566);
  static const Color darkDivider = Color(0xFF303035);

  static const Color darkTextPrimary = Color(0xFFF3EFF7);
  static const Color darkTextSecondary = Color(0xFFC6C4D8);
  static const Color darkTextMuted = Color(0xFF767587);
  static const Color darkAccentBlue = Color(0xFF6062E8);
  static const Color darkAccentAmber = Color(0xFFFAA100);

  // ============================================
  // STATUTS
  // ============================================
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  static const Color warning = Color(0xFFEAB308);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color warningDark = Color(0xFFA16207);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFDAD6);
  static const Color errorDark = Color(0xFF93000A);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);

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
    colors: [accent, accentDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBg, darkBg2],
  );

  static const LinearGradient heroGradientBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E26), primary],
  );

  static const LinearGradient heroGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient crossBrandGradient = LinearGradient(
    begin: Alignment(-1.0, -0.6),
    end: Alignment(1.0, 0.6),
    colors: [primaryLight, accent],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundAlt],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, surfaceLow],
  );

  static const LinearGradient xpBarGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

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
      color: primary.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: primary.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 6),
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
      color: accent.withValues(alpha: 0.14),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

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

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get modalShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 48,
      offset: const Offset(0, 24),
    ),
  ];
}
