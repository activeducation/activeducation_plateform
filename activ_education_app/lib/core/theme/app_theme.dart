import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnAccent,
        secondaryContainer: AppColors.secondarySurface,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.textTertiary,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorSurface,
        onErrorContainer: AppColors.errorDark,
        surface: AppColors.surfaceBright,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceTint: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // ============================================
      // APP BAR
      // ============================================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconMd,
        ),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // ============================================
      // CARDS — Premium Soft Shadows
      // ============================================
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: Colors.transparent,
            width: 0,
          ),
        ),
        margin: const EdgeInsets.all(AppSpacing.cardMargin),
        clipBehavior: Clip.antiAlias,
      ),

      // ============================================
      // ELEVATED BUTTON
      // ============================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: 16,
          ),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: AppTypography.buttonText.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
              return 8;
            }
            return 0;
          }),
        ),
      ),

      // ============================================
      // OUTLINED BUTTON
      // ============================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: 16,
          ),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: AppTypography.buttonText.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ============================================
      // TEXT BUTTON
      // ============================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // ============================================
      // INPUT DECORATION
      // ============================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceBright,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // ============================================
      // BOTTOM NAVIGATION (Mobile)
      // ============================================
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent, // Sera géré par le wrapper
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ============================================
      // FLOATING ACTION BUTTON
      // ============================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 6,
        hoverElevation: 12,
        focusElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ============================================
      // DIVIDER
      // ============================================
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 24,
      ),

      // ============================================
      // TEXT THEME
      // ============================================
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.primaryDarker,
        primaryContainer: AppColors.primaryDarker,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.secondaryDark,
        secondaryContainer: AppColors.secondaryDark,
        onSecondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.textDisabled,
        onTertiary: Colors.white,
        error: AppColors.errorLight,
        onError: AppColors.errorDark,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.errorLight,
        surface: AppColors.textPrimary, // Très sombre, ex: Slate 900
        onSurface: AppColors.surfaceBright, // Blanc pour le texte
        surfaceContainerHighest: AppColors.textSecondary,
        onSurfaceVariant: AppColors.textDisabled,
        outline: AppColors.textSecondary,
        outlineVariant: AppColors.textPrimary,
        surfaceTint: AppColors.primaryLight,
      ),
      scaffoldBackgroundColor: const Color(0xFF020617), // Slate 950
      
      // ============================================
      // APP BAR
      // ============================================
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: AppSpacing.iconMd,
        ),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // ============================================
      // CARDS
      // ============================================
      cardTheme: CardThemeData(
        color: const Color(0xFF0F172A), // Slate 900
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: Colors.transparent,
            width: 0,
          ),
        ),
        margin: const EdgeInsets.all(AppSpacing.cardMargin),
        clipBehavior: Clip.antiAlias,
      ),

      // ============================================
      // TEXT THEME
      // ============================================
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: Colors.white),
        displayMedium: AppTypography.displayMedium.copyWith(color: Colors.white),
        displaySmall: AppTypography.displaySmall.copyWith(color: Colors.white),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: Colors.white),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: Colors.white),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: Colors.white),
        titleLarge: AppTypography.titleLarge.copyWith(color: Colors.white),
        titleMedium: AppTypography.titleMedium.copyWith(color: Colors.white),
        titleSmall: AppTypography.titleSmall.copyWith(color: Colors.white),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.outlineVariant),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.outlineVariant),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.outlineVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: Colors.white),
        labelMedium: AppTypography.labelMedium.copyWith(color: Colors.white),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.outlineVariant),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.outlineVariant,
        size: 24,
      ),
    );
  }
}
