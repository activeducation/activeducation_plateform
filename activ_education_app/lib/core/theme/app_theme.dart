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
      // Pas de fontFamily global : un nom google_fonts litteral ici fait
      // crasher au demarrage (police chargee en async). Hanken Grotesque est
      // appliquee via les TextStyles AppTypography (GoogleFonts.hankenGrotesque).

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
        tertiaryContainer: Color(0xFF4F5152),
        onTertiaryContainer: Color(0xFFC3C4C4),
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

      // ============================================
      // APP BAR
      // ============================================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceBright,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.primary.withValues(alpha: 0.06),
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
      // CARDS — Level 1 elevation
      // ============================================
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.05),
            width: 1,
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
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: 15,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonText,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryDark.withValues(alpha: 0.2);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryDark.withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),

      // ============================================
      // OUTLINED BUTTON
      // ============================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.outline, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: 15,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonText.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // ============================================
      // TEXT BUTTON
      // ============================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
          ),
        ),
      ),

      // ============================================
      // INPUT DECORATION
      // ============================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPadding,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFF3133DD), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
      ),

      // ============================================
      // BOTTOM NAVIGATION
      // ============================================
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceBright,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ============================================
      // TAB BAR
      // ============================================
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.outlineVariant,
        overlayColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.05),
        ),
      ),

      // ============================================
      // CHIP
      // ============================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLow,
        selectedColor: AppColors.primarySurface,
        disabledColor: AppColors.surfaceDim,
        labelStyle: AppTypography.chipText,
        secondaryLabelStyle: AppTypography.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedBadge),
          side: BorderSide(color: AppColors.outlineVariant),
        ),
        side: BorderSide(color: AppColors.outlineVariant),
        elevation: 0,
        pressElevation: 0,
      ),

      // ============================================
      // FLOATING ACTION BUTTON
      // ============================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        ),
      ),

      // ============================================
      // PROGRESS INDICATOR
      // ============================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainerHighest,
        circularTrackColor: AppColors.surfaceLow,
        linearMinHeight: 8,
      ),

      // ============================================
      // DIVIDER
      // ============================================
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppSpacing.md,
      ),

      // ============================================
      // SNACKBAR
      // ============================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkBg,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedDefault),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        actionTextColor: AppColors.accent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // ============================================
      // DIALOG
      // ============================================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceBright,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.20),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
        ),
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // ============================================
      // BOTTOM SHEET
      // ============================================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceBright,
        modalBackgroundColor: AppColors.surfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.roundedXl),
          ),
        ),
        dragHandleColor: AppColors.outlineVariant,
        dragHandleSize: const Size(40, 4),
      ),

      // ============================================
      // TEXT THEME
      // ============================================
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // ============================================
      // ICON THEME
      // ============================================
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSpacing.iconMd,
      ),

      // ============================================
      // LIST TILE
      // ============================================
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
        ),
        titleTextStyle: AppTypography.titleMedium,
        subtitleTextStyle: AppTypography.bodySmall,
        leadingAndTrailingTextStyle: AppTypography.labelMedium,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),

      // ============================================
      // CHECKBOX
      // ============================================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: AppColors.outlineVariant, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
        ),
        overlayColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.08),
        ),
      ),

      // ============================================
      // TOOLTIP
      // ============================================
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ============================================
      // SWITCH
      // ============================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.outlineVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ============================================
      // SLIDER
      // ============================================
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceContainerHighest,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      // ============================================
      // POPUP MENU
      // ============================================
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceBright,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.roundedMd),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      // ============================================
      // NAVIGATION BAR
      // ============================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceBright,
        indicatorColor: AppColors.primarySurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: AppSpacing.iconMd,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiary,
            size: AppSpacing.iconMd,
          );
        }),
      ),

      // ============================================
      // NAVIGATION DRAWER
      // ============================================
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.surfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSpacing.roundedLg),
            bottomRight: Radius.circular(AppSpacing.roundedLg),
          ),
        ),
      ),

      // ============================================
      // BADGE
      // ============================================
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.textOnPrimary,
        textStyle: AppTypography.badgeText,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxxs,
        ),
        smallSize: 8,
        largeSize: 20,
        alignment: AlignmentDirectional.topEnd,
      ),

      // ============================================
      // DROPDOWN MENU
      // ============================================
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: Color(0xFF3133DD), width: 2),
          ),
        ),
      ),

      // ============================================
      // SEGMENTED BUTTON
      // ============================================
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceLow,
          selectedBackgroundColor: AppColors.primarySurface,
          foregroundColor: AppColors.textSecondary,
          selectedForegroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.roundedDefault),
          ),
          side: BorderSide(color: AppColors.outlineVariant),
          textStyle: AppTypography.labelMedium,
        ),
      ),

      // ============================================
      // EXPANSION TILE
      // ============================================
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textTertiary,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textPrimary,
        shape: Border(),
        collapsedShape: Border(),
        childrenPadding: const EdgeInsets.only(left: AppSpacing.md),
        expandedAlignment: Alignment.topLeft,
      ),
    );
  }
}
