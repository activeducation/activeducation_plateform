import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette – Bleu Royal ActivEducation (couleur logo exacte)
  static const Color primary = Color(0xFF1060CF);
  static const Color primaryLight = Color(0xFF4A8AE5);
  static const Color primaryMid = Color(0xFF1752B8);
  static const Color primaryDark = Color(0xFF0A45A0);
  static const Color primarySurface = Color(0xFFE8F0FE);

  // Secondary / accent – Or Ambré ActivEducation (couleur logo exacte)
  static const Color secondary = Color(0xFFF2A423);
  static const Color secondaryLight = Color(0xFFFFD166);
  static const Color secondaryDark = Color(0xFFCC8800);
  static const Color secondarySurface = Color(0xFFFFF5E0);

  // Backgrounds – légèrement teintés bleu pour cohérence
  static const Color background = Color(0xFFF5F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4FA);
  static const Color surfaceHover = Color(0xFFEBF0F8);

  // Sidebar – Bleu ActivEducation profond (aligné landing page)
  static const Color sidebarBg = Color(0xFF060E1E);
  static const Color sidebarBgLight = Color(0xFF0B1C3C);
  static const Color sidebarText = Color(0xFFE4EEF8);
  static const Color sidebarTextMuted = Color(0xFF7AA0BC);
  static const Color sidebarItemHover = Color(0xFF1060CF);
  static const Color sidebarItemActive = Color(0xFFF2A423);
  static const Color sidebarDivider = Color(0xFF1B2E52);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFF1F5F9);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // Shadows
  static const Color cardShadow = Color(0x08000000);
  static const Color cardShadowHover = Color(0x12000000);
}
