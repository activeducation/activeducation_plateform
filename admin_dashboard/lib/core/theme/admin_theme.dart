import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AdminTheme {
  AdminTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // Pas de fontFamily global : un nom google_fonts litteral ici fait
    // crasher au demarrage (police chargee en async). Hanken Grotesque est
    // appliquee via le textTheme (GoogleFonts.getFont) plus bas.

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3133DD),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE1E0FF),
      onPrimaryContainer: Color(0xFF04006D),
      secondary: Color(0xFF855400),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFA50C),
      onSecondaryContainer: Color(0xFF684000),
      tertiary: Color(0xFF383A3B),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFFBF8FF),
      onSurface: Color(0xFF1B1B20),
      surfaceContainerHighest: Color(0xFFF0ECF4),
      onSurfaceVariant: Color(0xFF454556),
      outline: Color(0xFF767587),
      outlineVariant: Color(0xFFC6C4D8),
        inverseSurface: Color(0xFF303035),
        inversePrimary: Color(0xFFC0C1FF),
      surfaceTint: Color(0xFF4145EA),
    ),

    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.getFont('Hanken Grotesque', fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.02 * 48, height: 56 / 48, color: AppColors.textPrimary),
      headlineLarge: GoogleFonts.getFont('Hanken Grotesque', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.01 * 32, height: 40 / 32, color: AppColors.textPrimary),
      headlineMedium: GoogleFonts.getFont('Hanken Grotesque', fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24, color: AppColors.textPrimary),
      headlineSmall: GoogleFonts.getFont('Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20, color: AppColors.textPrimary),
      titleLarge: GoogleFonts.getFont('Hanken Grotesque', fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20, color: AppColors.textPrimary),
      titleMedium: GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16, color: AppColors.textPrimary),
      bodyLarge: GoogleFonts.getFont('Hanken Grotesque', fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18, color: AppColors.textSecondary),
      bodyMedium: GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: AppColors.textSecondary),
      bodySmall: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: AppColors.textTertiary),
      labelLarge: GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16, color: AppColors.textPrimary),
      labelMedium: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.01 * 14, height: 20 / 14, color: AppColors.textSecondary),
      labelSmall: GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05 * 12, height: 16 / 12, color: AppColors.textTertiary),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.05), width: 1),
      ),
      shadowColor: AppColors.cardShadow,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: const BorderSide(color: Color(0xFF3133DD), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, color: AppColors.textMuted),
      labelStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, color: AppColors.textSecondary),
      floatingLabelStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, color: AppColors.primary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        textStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.outline),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3),
      dataTextStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 13, color: AppColors.textPrimary),
      decoration: const BoxDecoration(),
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant.withValues(alpha: 0.5)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      side: BorderSide(color: AppColors.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl)),
      surfaceTintColor: Colors.transparent,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.outlineVariant;
      }),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      textStyle: GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, color: Colors.white),
    ),
  );
}
