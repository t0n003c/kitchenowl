import 'package:flutter/material.dart';

import 'colors.dart';

abstract class AppThemes {
  static ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.green,
    tertiary: AppColors.green,
    surface: Colors.grey[50],
    // ignore: deprecated_member_use
    background: Colors.grey[50],
    brightness: Brightness.light,
  );

  static ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.green,
    tertiary: AppColors.green,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    surface: Color(0xFF111512),
    // ignore: deprecated_member_use
    background: Color(0xFF111512),
    brightness: Brightness.dark,
  );

  static ThemeData light([ColorScheme? colorScheme]) {
    colorScheme ??= lightScheme;

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: colorScheme.primary,
        secondaryColor: ElevationOverlay.applySurfaceTint(
          colorScheme.surface,
          colorScheme.surfaceTint,
          1,
        ),
        labelStyle: TextStyle(color: colorScheme.onPrimary),
      ).copyWith(
        checkmarkColor: colorScheme.onPrimary,
        side: BorderSide.none,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        height: 70,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Use PredictiveBackPageTransitionsBuilder to get the predictive back route transition!
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        year2023: false,
      ),
    );
  }

  static ThemeData dark([ColorScheme? colorScheme]) {
    colorScheme ??= darkScheme;

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        height: 70,
      ),
      appBarTheme: AppBarTheme(
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withAlpha(150),
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceContainerHigh,
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: colorScheme.primary,
        secondaryColor: colorScheme.onPrimary,
        labelStyle: TextStyle(color: colorScheme.onPrimary),
      ).copyWith(
        checkmarkColor: colorScheme.onPrimary,
        side: BorderSide.none,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Use PredictiveBackPageTransitionsBuilder to get the predictive back route transition!
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        year2023: false,
      ),
    );
  }
}
