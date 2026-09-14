class AppSpacing {
  AppSpacing._();

  static const double unit = 4;

  // ============================================
  // ESPACEMENTS DE BASE (4px baseline)
  // ============================================
  static const double none = 0;
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;
  static const double xxxl = 96;

  static const double gutter = 32; // Desktop
  static const double marginMobile = 16;
  static const double marginDesktop = 32;

  // ============================================
  // PADDING PAGE
  // ============================================
  static const double pagePaddingHorizontal = 16;
  static const double pagePaddingVertical = 24;
  static const double pagePaddingTop = 16;
  static const double pagePaddingBottom = 32;

  // ============================================
  // CARDS (Radius 16px selon DA)
  // ============================================
  static const double cardPadding = 16;
  static const double cardPaddingLarge = 24;
  static const double cardMargin = 12;
  static const double cardRadius = 16;
  static const double cardRadiusLarge = 24;
  static const double cardRadiusSmall = 12;

  // ============================================
  // BOUTONS (Radius 12px selon DA)
  // ============================================
  static const double buttonHeight = 52; // Tailles fixes DA (36, 44, 52)
  static const double buttonHeightSmall = 36;
  static const double buttonHeightLarge = 52;
  static const double buttonHeightMedium = 44;
  static const double buttonRadius = 12;
  static const double buttonRadiusFull = 9999;
  static const double buttonPaddingHorizontal = 24;
  static const double buttonScalePress = 0.98;

  // ============================================
  // INPUTS (Radius 8px selon DA)
  // ============================================
  static const double inputHeight = 44;
  static const double inputRadius = 8;
  static const double inputPadding = 12;

  // ============================================
  // ICONS
  // ============================================
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  static const double iconXxl = 64;

  // ============================================
  // AVATARS
  // ============================================
  static const double avatarXs = 32;
  static const double avatarSm = 40;
  static const double avatarMd = 56;
  static const double avatarLg = 80;
  static const double avatarXl = 120;

  // ============================================
  // GAMIFICATION
  // ============================================
  static const double badgeSize = 64;
  static const double badgeSizeSmall = 48;
  static const double badgeSizeLarge = 96;
  static const double progressBarHeight = 8;
  static const double progressBarHeightLarge = 12;
  static const double xpBarHeight = 16;
  static const double levelBadgeSize = 40;

  // ============================================
  // BOTTOM NAVIGATION
  // ============================================
  static const double bottomNavHeight = 80;
  static const double bottomNavIconSize = 28;

  // ============================================
  // APP BAR
  // ============================================
  static const double appBarHeight = 64;
  static const double appBarHeightLarge = 120;

  // ============================================
  // ROUNDED CORNERS
  // ============================================
  static const double roundedSm = 4;
  static const double roundedDefault = 8;
  static const double roundedMd = 12; // Boutons
  static const double roundedLg = 16; // Cards
  static const double roundedXl = 24; // Modales
  static const double roundedBadge = 8; // Badges
  static const double roundedFull = 9999;

  // ============================================
  // ANIMATIONS
  // ============================================
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
}

