import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 theme — simple village palette.
/// Key design rules:
///  - One brand green for app bars, headers and primary actions;
///    turmeric marks "needs you"; red is for errors and emergency only
///  - Depth from tonal surfaces plus one hairline outline — no grey shadows
///  - 56dp+ tap targets, 18sp min body text
///  - Radius encodes hierarchy: 24 hero / sheets, 18 cards, 14 controls
class AppTheme {
  AppTheme._();

  static const double radiusHero = 24;
  static const double radiusCard = 18;
  static const double radiusControl = 14;

  static ThemeData get lightTheme {
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusControl),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.sans,

      // ── Color Scheme (full M3 tonal palette)
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,

      // ── AppBar — solid brand green, flows into the home header
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 64,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.onPrimary, size: 26),
        actionsIconTheme: IconThemeData(color: AppColors.onPrimary, size: 26),
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.sans,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),

      // ── Cards — white on porcelain, one hairline outline
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.outlineVariant, width: 0.8),
        ),
      ),

      // ── ElevatedButton — solid peacock, 60dp
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          disabledForegroundColor: AppColors.outline,
          minimumSize: const Size(double.infinity, 60),
          elevation: 0,
          textStyle: AppTextStyles.labelLarge,
          shape: controlShape,
        ),
      ),

      // ── FilledButton — same as Elevated
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 56),
          textStyle: AppTextStyles.labelLarge,
          shape: controlShape,
        ),
      ),

      // ── OutlinedButton — peacock hairline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 60),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: controlShape,
        ),
      ),

      // ── TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: AppTextStyles.titleMedium,
          shape: controlShape,
        ),
      ),

      // ── IconButton — 48dp minimum
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),

      // ── TextField — white field, hairline, peacock focus with zari ring feel
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: AppTextStyles.bodyMedium,
        floatingLabelStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
        hintStyle: AppTextStyles.caption,
        prefixIconColor: AppColors.outline,
        suffixIconColor: AppColors.outline,
      ),

      // ── Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
      ),

      // ── Divider — hairline
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 0.8,
        space: 32,
      ),

      // ── ListTile
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.onSurface,
        titleTextStyle: AppTextStyles.titleMedium,
        subtitleTextStyle: AppTextStyles.caption,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
      ),

      // ── SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        actionTextColor: AppColors.zariBright,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inverseOnSurface,
        ),
      ),

      // ── BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusHero)),
        ),
      ),

      // ── Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headlineMedium,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusHero),
        ),
      ),

      // ── FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: AppTextStyles.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),

      // ── Chip (Language selector, filters)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        checkmarkColor: AppColors.onPrimary,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onSurface,
        ),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
      ),

      // ── TabBar — zari underline
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.onPrimaryContainer,
        indicatorColor: AppColors.zariBright,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.titleMedium,
        unselectedLabelStyle:
            AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w500),
      ),

      // ── NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.primaryFixed,
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(AppTextStyles.labelMedium),
      ),

      // ── Selection controls
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.outline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.onPrimary : null),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : null),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainerHigh,
      ),

      // ── DropdownMenu
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
        ),
      ),

      // ── Date picker (booking flow)
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.onPrimary,
        todayBorder: const BorderSide(color: AppColors.zari, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusHero),
        ),
      ),
    );
  }
}
